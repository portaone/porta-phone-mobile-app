import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../models/jsep_value.dart';

/// Manages the signaling session for the CallKeep push-notification background isolate.
///
/// Opened once per incoming push notification, connects to the signaling server
/// to retrieve call state, handles missed-call logging and notifications, and
/// releases the incoming call service when all work is done.
/// Never reconnects - the isolate is short-lived by design.
///
/// On both Android and iOS the connection runs directly in the current isolate.
/// Call [init] after construction and before [run].
class PushNotificationIsolateManager implements CallkeepBackgroundServiceDelegate {
  PushNotificationIsolateManager({
    required PushSessionCallkeep callkeep,
    required SignalingModule Function() createSignaling,
    required this.logger,
    required Future<void> Function(String callId, String? callerName) onMissedCall,
    this.callLogsRepository,
  }) : _onMissedCall = onMissedCall,
       _createSignaling = createSignaling,
       _pushService = callkeep {
    // setBackgroundServiceDelegate is called in the constructor so callkeep can
    // route performAnswerCall / performEndCall as soon as the object exists,
    // before [init] is called.
    _pushService.setBackgroundServiceDelegate(this);
  }

  final Logger logger;
  final CallLogsRepository? callLogsRepository;
  final Future<void> Function(String callId, String? callerName) _onMissedCall;
  final SignalingModule Function() _createSignaling;

  final PushSessionCallkeep _pushService;

  // Assigned exactly once in [init], before any call to [run] or [close].
  late SignalingModule _signalingModule;
  late StreamSubscription<SignalingModuleEvent> _signalingSubscription;
  bool _initialized = false;

  /// Metadata from the incoming push notification.
  /// Used as a fallback for missed-call display name and call logging.
  CallkeepIncomingCallMetadata? _metadata;

  /// callId -> line index (populated from StateHandshake)
  final Map<String, int> _lines = {};

  /// callId -> IncomingCallEvent (populated from StateHandshake and protocol events)
  final Map<String, IncomingCallEvent> _incomingCallEvents = {};

  /// Requests queued while the signaling module is not yet connected.
  final List<_PendingRequest> _pendingRequests = [];

  /// Completer resolved when all isolate work is done and [_releaseCall] or
  /// [_handoffCall] has been called (depending on whether the call was answered).
  Completer<void>? _completer;

  /// The callId of the call answered via the push notification.
  ///
  /// Set in [performAnswerCall] only when a network connection is confirmed.
  /// Used in [close] to call [_handoffCall] instead of [_releaseCall] so the
  /// PhoneConnection is not terminated before the Activity can adopt it.
  /// Null means the call was not answered (missed, declined, or no network).
  String? _answeredCallId;

  // Workaround: captures init time as fallback timestamp for call logs.
  final DateTime _initialConnectionTime = DateTime.now();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Initialises the signaling module.
  ///
  /// Must be called once after construction and before [run]. Creates the
  /// signaling module and wires up the event subscription.
  /// The WebSocket connection starts when [connect] is called from [run].
  void init() {
    _initSignaling();
    _initialized = true;
  }

  /// Connects to the signaling server, processes call state for the given push
  /// notification [metadata], and returns a [Future] that completes after all
  /// work is done (notifications shown, logs written, native service released).
  Future<void> run(CallkeepIncomingCallMetadata? metadata) {
    if (!_initialized) {
      throw StateError('PushNotificationIsolateManager.run() called before init()');
    }
    _metadata = metadata;
    _answeredCallId = null;
    _completer = Completer<void>();
    logger.info('run: callId=${metadata?.callId} isConnected=${_signalingModule.isConnected}');
    // WebtritSignalingService.connect() is idempotent: the internal
    // _startPending / _isConnected guard makes repeated calls safe.
    // Always call it - idempotent on any subsequent call.
    _signalingModule.connect();
    return _completer!.future;
  }

  /// Called by the plugin when the Activity's WebSocket has connected in direct
  /// push-bound mode. Completes [run]'s future early so [close] executes via the
  /// [onPushNotificationSyncCallback] finally block, disposing the module and
  /// cancelling any pending reconnect timers before they fire.
  void notifyActivityTookOver() {
    logger.info('notifyActivityTookOver: Activity WebSocket connected - completing push session early');
    _complete();
  }

  /// Cancels all timers and pending requests, then disposes the signaling module.
  Future<void> close() async {
    logger.info(
      'close: disposing module=${_initialized ? _signalingModule.runtimeType : "not initialized"} pendingRequests=${_pendingRequests.length}',
    );
    for (final pending in _pendingRequests) {
      pending.timeoutTimer.cancel();
      if (!pending.completer.isCompleted) {
        pending.completer.completeError(StateError('PushNotificationIsolateManager closed'));
      }
    }
    _pendingRequests.clear();
    if (_initialized) {
      await _signalingSubscription.cancel();
      await _signalingModule.dispose();
    }
    if (_answeredCallId != null) {
      await _handoffCall(_answeredCallId);
    } else if (_incomingCallEvents.containsKey(_metadata?.callId)) {
      // The call is still active server-side (no HangupEvent received) - the
      // Activity has likely taken over via a full-screen intent. Hand off
      // instead of releasing so the ringing call is not terminated prematurely.
      await _handoffCall(_metadata?.callId);
    } else {
      // In direct mode the push isolate's WebSocket is independent from the
      // Activity's. If the Activity took over before IncomingCallEvent arrived
      // (empty _incomingCallEvents), releaseCall only stops IncomingCallService
      // here - the Activity keeps its own connection and handles the call normally.
      await _releaseCall(_metadata?.callId);
    }
    _completeWithError(StateError('PushNotificationIsolateManager closed'));
  }

  // ---------------------------------------------------------------------------
  // CallkeepBackgroundServiceDelegate
  // ---------------------------------------------------------------------------

  @override
  void performEndCall(String callId) async {
    try {
      await _sendRequest(callId, (line, id, tx) => DeclineRequest(transaction: tx, line: line, callId: id));
    } catch (e) {
      logger.severe(e);
    }
  }

  @override
  void performAnswerCall(String callId) {
    _handlePerformAnswerCall(callId);
  }

  Future<void> _handlePerformAnswerCall(String callId) async {
    final hasNetwork = await Connectivity().checkConnectivity().then(
      (r) => r.isNotEmpty && !r.contains(ConnectivityResult.none),
    );
    if (!hasNetwork) {
      logger.warning('performAnswerCall: no network for callId=$callId, skipping handoff');
      return;
    }
    _answeredCallId = callId;
  }

  // ---------------------------------------------------------------------------
  // Signaling init
  // ---------------------------------------------------------------------------

  /// Creates the signaling module for this isolate (in production a
  /// [WebtritSignalingService] in [SignalingServiceMode.pushBound] mode: each
  /// isolate, push and Activity, opens its own direct WebSocket - no shared FGS
  /// hub). [connect] is called from [run], not here, so the connection starts
  /// only when processing begins.
  void _initSignaling() {
    logger.info('_initSignaling: creating the signaling module');
    _signalingModule = _createSignaling();

    _signalingSubscription = _signalingModule.events.listen((event) {
      switch (event) {
        case SignalingConnecting():
          logger.info('Signaling: connecting');
        case SignalingConnected():
          logger.info('Signaling: connected');
        case SignalingHandshakeReceived(:final handshake):
          _onHandshake(handshake);
        case SignalingProtocolEvent(:final event):
          _onProtocolEvent(event);
        case SignalingDisconnecting():
          logger.info('Signaling: disconnecting');
        case SignalingDisconnected(:final code, :final reason, :final knownCode):
          logger.info('Signaling: disconnected code=$code reason=$reason knownCode=$knownCode');
          if (knownCode == SignalingDisconnectCode.controllerForceAttachClose) {
            _complete();
          }
        case SignalingConnectionFailed(:final error):
          _onSignalingError(error);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Signaling event handlers
  // ---------------------------------------------------------------------------

  void _onHandshake(StateHandshake handshake) {
    final lines = handshake.lines.whereType<Line>().toList();
    logger.info('Handshake received: ${lines.length} active line(s)');

    _lines.clear();
    _incomingCallEvents.clear();
    for (var i = 0; i < lines.length; i++) {
      _lines[lines[i].callId] = i;
    }

    if (_lines.isEmpty) {
      // The hub sends StateHandshake first, then replays IncomingCallEvent entries
      // from _callEventHistory. When a call arrived as a protocol event (not in
      // StateHandshake lines), the push isolate would see 0 lines and immediately
      // call _onNoActiveLines() before the IncomingCallEvent from _callEventHistory
      // replay is processed. Defer to the next event-loop turn so any pending
      // port messages (including replayed protocol events) are handled first.
      logger.info('Handshake: no active lines, deferring check for protocol-event calls');
      Future(() {
        if (_incomingCallEvents.containsKey(_metadata?.callId)) {
          logger.info('Handshake deferred: found incoming call from history callId=${_metadata?.callId}, proceeding');
          _executePendingRequests();
        } else {
          logger.info('Handshake deferred: no incoming call found - ending calls');
          _onNoActiveLines();
        }
      });
      return;
    }

    // Every incoming line, not only the first: the session's own call is not
    // necessarily on line 0, and close() hands it off only if it finds it here.
    for (final activeLine in lines) {
      final callEvent = activeLine.callLogs.whereType<CallEventLog>().map((log) => log.callEvent).firstOrNull;

      if (callEvent is IncomingCallEvent) {
        logger.info('Handshake: incoming call found callId=${callEvent.callId}');
        _incomingCallEvents[callEvent.callId] = callEvent;
      }
    }

    if (_incomingCallEvents.isEmpty) {
      logger.info('Handshake: active lines present but no IncomingCallEvent found - lines=${_lines.keys}');
    }

    // Other calls on the lines do not keep this session: only its own call does. When that call
    // is not among them it has already ended, and no hangup of another call will end the session
    // any more - so check it the way an empty handshake is checked.
    final ownCallId = _metadata?.callId;
    if (ownCallId != null && !_lines.containsKey(ownCallId)) {
      logger.info('Handshake: own call $ownCallId not among the lines, deferring check');
      Future(() {
        if (_lines.containsKey(ownCallId) || _incomingCallEvents.containsKey(ownCallId)) {
          logger.info('Handshake deferred: own call $ownCallId arrived, proceeding');
          _executePendingRequests();
        } else {
          logger.info('Handshake deferred: own call $ownCallId is gone - ending it');
          _onNoActiveLines();
        }
      });
      return;
    }
    _executePendingRequests();
  }

  void _onProtocolEvent(Event event) {
    logger.info('Received event: $event');
    switch (event) {
      case IncomingCallEvent():
        _incomingCallEvents[event.callId] = event;
        // Populate _lines so _sendRequest can resolve the line index for this call.
        // Calls that arrive as protocol events (not in StateHandshake) are not
        // present in _lines after _onHandshake; add them here so pending requests
        // can be executed once the deferred handshake check runs.
        if (event.line != null) {
          _lines[event.callId] = event.line!;
        }
      case HangupEvent():
        final incomingEventLog = _incomingCallEvents.remove(event.callId);
        final call = (
          direction: CallDirection.incoming,
          number: incomingEventLog?.caller ?? _metadata?.handle?.value ?? '',
          video: JsepValue.fromOptional(incomingEventLog?.jsep)?.hasVideo ?? false,
          username: incomingEventLog?.callerDisplayName,
          createdTime: _initialConnectionTime,
          acceptedTime: null,
          hungUpTime: DateTime.now(),
        );
        if (_isOwnCall(event.callId)) {
          _onHangupCall(event, call);
        } else {
          _onOtherCallHangup(event, call, wasIncoming: incomingEventLog != null);
        }
      case UnregisteredEvent():
        _onUnregistered(event);
      default:
        break;
    }
  }

  void _onNoActiveLines() async {
    logger.info('No active lines: releasing call');
    if (_metadata == null) {
      logger.severe('_onNoActiveLines: metadata is null, cannot release call');
      _complete();
      return;
    }
    final event = HangupEvent(callId: _metadata!.callId, line: -1, reason: 'Missed', code: -1);
    final call = (
      direction: CallDirection.incoming,
      number: _metadata!.handle!.value,
      video: _metadata!.hasVideo,
      username: _metadata!.displayName,
      createdTime: DateTime.now(),
      acceptedTime: null,
      hungUpTime: DateTime.now(),
    );
    await _showMissedCallNotification(event, call);
    await _logCall(call);
    await _releaseCall(_metadata!.callId);
    _complete();
  }

  void _onUnregistered(UnregisteredEvent event) async {
    try {
      final callId = _metadata?.callId;
      if (callId == null) {
        logger.severe('_onUnregistered: metadata is null, cannot release call');
        _complete();
        return;
      }
      await _releaseCall(callId);
    } catch (e) {
      logger.severe(e);
    } finally {
      _complete();
    }
  }

  void _onSignalingError(Object error) async {
    logger.severe('Signaling connection failed: $error - releasing call');
    try {
      final callId = _metadata?.callId;
      if (callId == null) {
        logger.severe('_onSignalingError: metadata is null, cannot release call');
        _complete();
        return;
      }
      await _releaseCall(callId);
    } catch (e) {
      logger.severe(e);
    } finally {
      _complete();
    }
  }

  /// Whether [callId] is the call this session was opened for.
  ///
  /// A session without push metadata has no call of its own; it keeps the old
  /// behaviour and treats every call as its own.
  bool _isOwnCall(String callId) => _metadata == null || _metadata!.callId == callId;

  void _onHangupCall(HangupEvent event, NewCall call) async {
    logger.info('Hangup event: callId=${event.callId} reason=${event.reason}');
    await _showMissedCallNotification(event, call);
    await _logCall(call);
    await _releaseCall(event.callId);
    _complete();
  }

  /// Another call on this session's lines ended while the session's own call
  /// is still going.
  ///
  /// The session stays open: ending it here handed the own call off while it
  /// still rang, which took its notification away and left its connection
  /// ringing with nobody to hear its hangup. The other call is still recorded
  /// and ended natively, and callkeep keeps the incoming-call service up,
  /// because it shows the session's own call.
  ///
  /// Only an incoming call the session saw arrive ([wasIncoming]) is recorded as missed: the other
  /// lines can also carry an outgoing call from another device or a call answered elsewhere, and
  /// those are not missed calls.
  void _onOtherCallHangup(HangupEvent event, NewCall call, {required bool wasIncoming}) async {
    logger.info(
      'Hangup event for another call: callId=${event.callId} reason=${event.reason} - session stays on ${_metadata?.callId}',
    );
    _lines.remove(event.callId);
    if (wasIncoming) {
      await _showMissedCallNotification(event, call);
      await _logCall(call);
    }
    await _releaseCall(event.callId);
  }

  // ---------------------------------------------------------------------------
  // Pending request queue
  // ---------------------------------------------------------------------------

  void _executePendingRequests() {
    logger.info('Executing ${_pendingRequests.length} pending requests...');
    for (final pending in List<_PendingRequest>.from(_pendingRequests)) {
      final lineIndex = _lines[pending.callId];
      if (lineIndex == null) {
        pending.completer.completeError('Line not found for callId: ${pending.callId}');
        pending.timeoutTimer.cancel();
        _pendingRequests.remove(pending);
        continue;
      }

      final future = _signalingModule.execute(
        pending.requestBuilder(lineIndex, pending.callId, WebtritSignalingClient.generateTransactionId()),
      );
      if (future == null) {
        pending.completer.completeError(StateError('Signaling disconnected while flushing callId: ${pending.callId}'));
        pending.timeoutTimer.cancel();
        _pendingRequests.remove(pending);
        continue;
      }
      future
          .then((_) => pending.completer.complete())
          .catchError((e, s) => pending.completer.completeError(e, s))
          .whenComplete(() {
            pending.timeoutTimer.cancel();
            _pendingRequests.remove(pending);
          });
    }
  }

  Future<void> _sendRequest(String callId, Request Function(int line, String callId, String tx) requestBuilder) async {
    if (!_signalingModule.isConnected) {
      logger.warning('Not connected. Queueing request for $callId');

      final completer = Completer<void>();
      final timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Request timed out for $callId'));
          _pendingRequests.removeWhere((r) => r.completer == completer);
        }
      });

      _pendingRequests.add(
        _PendingRequest(
          callId: callId,
          requestBuilder: requestBuilder,
          completer: completer,
          timeoutTimer: timeoutTimer,
        ),
      );

      return completer.future;
    }

    final lineIndex = _lines[callId];
    if (lineIndex == null) {
      logger.warning('_sendRequest: callId=$callId not in active lines - dropping request');
      return;
    }

    final future = _signalingModule.execute(
      requestBuilder(lineIndex, callId, WebtritSignalingClient.generateTransactionId()),
    );
    if (future == null) {
      logger.warning('execute returned null for callId $callId (disconnected after isConnected check)');
      return;
    }
    await future;
  }

  // ---------------------------------------------------------------------------
  // Native release
  // ---------------------------------------------------------------------------

  Future<void> _releaseCall(String? callId) async {
    if (callId == null) return;
    try {
      await _pushService.releaseCall(callId);
    } catch (e) {
      logger.severe('_releaseCall failed: $e');
    }
  }

  Future<void> _handoffCall(String? callId) async {
    if (callId == null) return;
    try {
      await _pushService.handoffCall(callId);
    } catch (e, st) {
      logger.severe('_handoffCall failed: $e', e, st);
    }
  }

  void _complete() {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete();
    }
  }

  void _completeWithError(Object error) {
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.completeError(error);
    }
  }

  // ---------------------------------------------------------------------------
  // Notifications and logging
  // ---------------------------------------------------------------------------

  Future<void> _logCall(NewCall call) async {
    if (callLogsRepository == null) {
      logger.warning('_logCall: repository unavailable, skipping');
      return;
    }
    try {
      await callLogsRepository!.add(call);
    } catch (e, st) {
      logger.severe('Failed to add call log', e, st);
    }
  }

  Future<void> _showMissedCallNotification(HangupEvent event, NewCall call) async {
    try {
      await _onMissedCall(event.callId, _getDisplayNameForMissedCall(event, call));
    } catch (e) {
      logger.severe('Failed to show missed call notification', e);
    }
  }

  /// Returns the best available display name for the missed-call notification.
  ///
  /// Priority: signaling caller name -> push metadata display name -> phone number.
  String? _getDisplayNameForMissedCall(HangupEvent event, NewCall call) {
    final metadataName = _metadata?.callId == event.callId ? _metadata?.displayName : null;
    return [call.username, metadataName, call.number].firstWhere((s) => s != null && s.isNotEmpty, orElse: () => null);
  }
}

// ---------------------------------------------------------------------------

/// What a push session needs from callkeep, and nothing more: the delegate that
/// receives answer/decline, and the two ways the session gives its call back.
abstract interface class PushSessionCallkeep {
  void setBackgroundServiceDelegate(CallkeepBackgroundServiceDelegate? delegate);

  /// Ends [callId] natively and stops the incoming-call service if it shows that call.
  Future<void> releaseCall(String callId);

  /// Stops the incoming-call service for [callId] and leaves the connection alive.
  Future<void> handoffCall(String callId);
}

/// [PushSessionCallkeep] over the plugin's [BackgroundPushNotificationService].
class BackgroundPushSessionCallkeep implements PushSessionCallkeep {
  BackgroundPushSessionCallkeep([BackgroundPushNotificationService? service])
    : _service = service ?? BackgroundPushNotificationService();

  final BackgroundPushNotificationService _service;

  @override
  void setBackgroundServiceDelegate(CallkeepBackgroundServiceDelegate? delegate) =>
      _service.setBackgroundServiceDelegate(delegate);

  @override
  Future<void> releaseCall(String callId) async => await _service.releaseCall(callId);

  @override
  Future<void> handoffCall(String callId) async => await _service.handoffCall(callId);
}

// ---------------------------------------------------------------------------

class _PendingRequest {
  final String callId;
  final Request Function(int line, String callId, String tx) requestBuilder;
  final Completer<void> completer;
  final Timer timeoutTimer;

  _PendingRequest({
    required this.callId,
    required this.requestBuilder,
    required this.completer,
    required this.timeoutTimer,
  });
}
