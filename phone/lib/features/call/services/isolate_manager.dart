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
       _callkeep = callkeep {
    // setBackgroundServiceDelegate is called in the constructor so callkeep can
    // route performAnswerCall / performEndCall as soon as the object exists,
    // before [init] is called.
    _callkeep.setBackgroundServiceDelegate(this);
  }

  final Logger logger;
  final CallLogsRepository? callLogsRepository;
  final Future<void> Function(String callId, String? callerName) _onMissedCall;
  final SignalingModule Function() _createSignaling;

  final PushSessionCallkeep _callkeep;

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

  /// Completer of the session: resolved once nothing is left for the session to do. The plugin
  /// keeps the incoming-call service up until [run]'s future completes, so the work a signaling
  /// event starts - the missed-call record and its notification - is tracked in [_inFlight] and
  /// awaited before the future completes, even when the Activity takes over meanwhile.
  Completer<void>? _completer;

  /// Work started by signaling events that has not finished yet.
  final Set<Future<void>> _inFlight = {};

  /// Set once callkeep confirmed the session's own call is no longer its concern
  /// ([performHandoff]): the app holds it, or it ended elsewhere. The session then
  /// never releases that call, whatever it saw of it.
  bool _handedOff = false;

  /// Set once this session reported the end of its own call: callkeep ended it then, and
  /// releasing it again on close would decline a connection that is already gone.
  bool _reportedOwnEnd = false;

  /// The callId of the call answered via the push notification.
  ///
  /// Set in [performAnswerCall] only when a network connection is confirmed.
  /// Used in [close] to leave the call to the Activity instead of releasing
  /// it, so the PhoneConnection is not terminated before the Activity adopts it.
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
  /// work is done (notifications shown, logs written). The plugin stops the
  /// incoming-call service once that future completes.
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
    await _giveBackOwnCall();
    _completeWithError(StateError('PushNotificationIsolateManager closed'));
  }

  /// Gives the session's own call back to callkeep as the session closes. A call callkeep took
  /// off the session, one that was answered here, one whose end this session reported or one
  /// still live on the server is left alone; the plugin stops the service itself once [run]'s
  /// future completes. A call the session never saw arrive is released, as before.
  Future<void> _giveBackOwnCall() async {
    if (_handedOff ||
        _reportedOwnEnd ||
        _answeredCallId != null ||
        _incomingCallEvents.containsKey(_metadata?.callId)) {
      return;
    }
    await _releaseCall(_metadata?.callId);
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

  /// Callkeep no longer needs this session for [callId]: the app holds the call, or it ended
  /// through another handler. For the session's own call that is the end of the session - the
  /// only one, besides its own call ending here: an Activity on screen or a connected WebSocket
  /// says nothing about who receives the call's events. Work still in flight finishes first.
  @override
  void performHandoff(String callId) {
    if (!_isOwnCall(callId)) {
      logger.info('performHandoff: $callId is not this session\'s call (${_metadata?.callId}) - ignored');
      return;
    }
    logger.info('performHandoff: $callId is the app\'s now - completing the session');
    _handedOff = true;
    _complete();
  }

  Future<void> _handlePerformAnswerCall(String callId) async {
    final hasNetwork = await Connectivity().checkConnectivity().then(
      (r) => r.isNotEmpty && !r.contains(ConnectivityResult.none),
    );
    if (!hasNetwork) {
      logger.warning('performAnswerCall: no network for callId=$callId, not remembering the answer');
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
          // The Activity's socket displaced this one; the session goes on until callkeep says
          // the app holds the call (performHandoff) or the call is over - the server's hangup
          // now reaches the app, which reports it.
          if (knownCode == SignalingDisconnectCode.controllerForceAttachClose) {
            logger.info('Signaling: displaced by the Activity - waiting for callkeep to hand the call off');
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
      // call _onOwnCallGone() before the IncomingCallEvent from _callEventHistory
      // replay is processed. Defer to the next event-loop turn so any pending
      // port messages (including replayed protocol events) are handled first.
      logger.info('Handshake: no active lines, deferring check for protocol-event calls');
      _checkOwnCallNextTurn(
        () => _incomingCallEvents.containsKey(_metadata?.callId),
        arrived: 'Handshake deferred: found incoming call from history callId=${_metadata?.callId}, proceeding',
        gone: 'Handshake deferred: no incoming call found - ending calls',
      );
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
      _checkOwnCallNextTurn(
        () => _lines.containsKey(ownCallId) || _incomingCallEvents.containsKey(ownCallId),
        arrived: 'Handshake deferred: own call $ownCallId arrived, proceeding',
        gone: 'Handshake deferred: own call $ownCallId is gone - ending it',
      );
      return;
    }
    _executePendingRequests();
  }

  /// Looks for the session's own call again after the current event-loop turn, once the
  /// events queued behind the handshake (replayed calls) have been handled: the session goes
  /// on when [ownCallArrived], and ends its call otherwise.
  void _checkOwnCallNextTurn(bool Function() ownCallArrived, {required String arrived, required String gone}) {
    Future(() {
      if (ownCallArrived()) {
        logger.info(arrived);
        _executePendingRequests();
      } else {
        logger.info(gone);
        _onOwnCallGone();
      }
    });
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
          _onOwnCallHangup(event, call);
        } else {
          _onOtherCallHangup(event, call, wasIncoming: incomingEventLog != null);
        }
      case UnregisteredEvent():
        _onUnregistered();
      default:
        break;
    }
  }

  /// The session's own call is no longer on the server: it ended before the session could see
  /// its hangup, so it is recorded and released from what the push said about it.
  void _onOwnCallGone() {
    logger.info('No active lines: releasing call');
    if (_metadata == null) {
      logger.severe('_onOwnCallGone: metadata is null, cannot release call');
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
    _endOwnCall(event, call);
  }

  /// The session's own call is over: callkeep ends it in Telecom now, before the missed call is
  /// recorded - the record can wait on the main thread and the database while the Activity
  /// starts. The session ends once the record is done; the plugin then stops the service.
  void _endOwnCall(HangupEvent event, NewCall call) {
    _reportedOwnEnd = true;
    _track(() async {
      await _reportEndCall(event.callId, CallkeepEndCallReason.missedWhileConnecting);
      await _recordMissed(event, call);
    }());
    _complete();
  }

  void _onUnregistered() => _releaseOwnCallAndEnd('_onUnregistered');

  void _onSignalingError(Object error) {
    logger.severe('Signaling connection failed: $error - releasing call');
    _releaseOwnCallAndEnd('_onSignalingError');
  }

  /// The session can no longer follow its call (the server dropped it): the call is released
  /// without being recorded, and the session ends.
  void _releaseOwnCallAndEnd(String source) async {
    try {
      final callId = _metadata?.callId;
      if (callId == null) {
        logger.severe('$source: metadata is null, cannot release call');
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

  void _onOwnCallHangup(HangupEvent event, NewCall call) {
    logger.info('Hangup event: callId=${event.callId} reason=${event.reason}');
    _endOwnCall(event, call);
  }

  /// Another call on this session's lines ended while the session's own call
  /// is still going.
  ///
  /// The session stays open: ending it here handed the own call off while it
  /// still rang, which took its notification away and left its connection
  /// ringing with nobody to hear its hangup. The other call is still ended
  /// natively and recorded, and the record is tracked like the own call's:
  /// the session does not complete over it, whatever ends the session.
  ///
  /// Only an incoming call the session saw arrive ([wasIncoming]) is recorded as missed: the other
  /// lines can also carry an outgoing call from another device or a call answered elsewhere, and
  /// those are not missed calls.
  void _onOtherCallHangup(HangupEvent event, NewCall call, {required bool wasIncoming}) {
    logger.info(
      'Hangup event for another call: callId=${event.callId} reason=${event.reason} - session stays on ${_metadata?.callId}',
    );
    _lines.remove(event.callId);
    // Only a call that rang here was never presented: that reason arms callkeep's guard against
    // presenting it again. A call this device never registered has nothing to guard.
    final reason = wasIncoming ? CallkeepEndCallReason.missedWhileConnecting : CallkeepEndCallReason.remoteEnded;
    _track(() async {
      await _reportEndCall(event.callId, reason);
      if (wasIncoming) await _recordMissed(event, call);
    }());
  }

  // ---------------------------------------------------------------------------
  // Pending request queue
  // ---------------------------------------------------------------------------

  void _executePendingRequests() {
    logger.info('Executing ${_pendingRequests.length} pending requests...');
    for (final pending in List<_PendingRequest>.from(_pendingRequests)) {
      final lineIndex = _lines[pending.callId];
      if (lineIndex == null) {
        _dropPending(pending, 'Line not found for callId: ${pending.callId}');
        continue;
      }

      final future = _signalingModule.execute(
        pending.requestBuilder(lineIndex, pending.callId, WebtritSignalingClient.generateTransactionId()),
      );
      if (future == null) {
        _dropPending(pending, StateError('Signaling disconnected while flushing callId: ${pending.callId}'));
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

  void _dropPending(_PendingRequest pending, Object error) {
    pending.completer.completeError(error);
    pending.timeoutTimer.cancel();
    _pendingRequests.remove(pending);
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

  /// Tells callkeep the call is over, so it ends it in Telecom at once and never presents it
  /// again. The session goes on: only [_complete] ends it.
  Future<void> _reportEndCall(String callId, CallkeepEndCallReason reason) async {
    try {
      await _callkeep.reportEndCall(callId, reason);
    } catch (e) {
      logger.severe('_reportEndCall failed: $e');
    }
  }

  Future<void> _releaseCall(String? callId) async {
    if (callId == null) return;
    try {
      await _callkeep.releaseCall(callId);
    } catch (e) {
      logger.severe('_releaseCall failed: $e');
    }
  }

  /// Keeps [work] in [_inFlight] until it is done, so [_complete] does not complete over it.
  void _track(Future<void> work) {
    _inFlight.add(work);
    work.whenComplete(() => _inFlight.remove(work));
  }

  /// Completes the session once every tracked piece of work is done: draining, not stopping.
  /// A missed-call record still in flight finishes first, whatever ended the session.
  void _complete() {
    final completer = _completer;
    if (completer == null || completer.isCompleted) return;
    completer.complete(_drained());
  }

  Future<void> _drained() async {
    while (_inFlight.isNotEmpty) {
      await Future.wait(_inFlight.toList());
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

  /// Shows the missed-call notification for [event]'s call and writes it to the call log.
  Future<void> _recordMissed(HangupEvent event, NewCall call) async {
    await _showMissedCallNotification(event, call);
    await _logCall(call);
  }

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
/// receives answer/decline, and the two ways the session ends a call.
abstract interface class PushSessionCallkeep {
  void setBackgroundServiceDelegate(CallkeepBackgroundServiceDelegate? delegate);

  /// The call [callId] is over on the server: ends it natively at once, keeps the session
  /// and its service running, and keeps a replay or a late push from presenting it again.
  Future<void> reportEndCall(String callId, CallkeepEndCallReason reason);

  /// Ends [callId] natively and stops the incoming-call service if it shows that call.
  Future<void> releaseCall(String callId);
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
  Future<void> reportEndCall(String callId, CallkeepEndCallReason reason) => _service.reportEndCall(callId, reason);

  @override
  Future<void> releaseCall(String callId) async => await _service.releaseCall(callId);
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
