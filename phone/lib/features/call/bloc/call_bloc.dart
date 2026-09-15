import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart' hide Notification;

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:async/async.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:webtrit_phone/mappers/signaling/signaling.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:signaling_service/signaling_service.dart';

import '../conference/conference.dart';
import '../extensions/extensions.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/utils.dart';

export 'package:webtrit_callkeep/webtrit_callkeep.dart' show CallkeepHandle, CallkeepHandleType;

part 'call_bloc.freezed.dart';

part 'call_event.dart';

part 'call_state.dart';

const int _kUndefinedLine = -1;

final _logger = Logger('CallBloc');

/// A callback function type for handling diagnostic reports for call request errors.
/// It takes the [callId] of the failed call and the specific [CallkeepCallRequestError]
/// as parameters, allowing for detailed error logging or reporting.
typedef OnDiagnosticReportRequested = void Function(String callId, CallkeepCallRequestError error);

/// Resolves the final SIP `from` number for an outgoing call.
///
/// [callerProvidedFromNumber] is whatever the UI passed via
/// [CallControlEvent.started] (a guest-line number, the user's main number,
/// or `null`). [destination] is the dialed number (used for caller-ID matcher
/// lookup when [callerProvidedFromNumber] is null).
///
/// The closure owns the full policy: main-number normalisation,
/// matcher-based fallback, default fallback. Composition root supplies it
/// (see `main_shell.dart`); the bloc only knows the shape.
typedef OutgoingFromNumberResolver = String? Function(String? callerProvidedFromNumber, String destination);

const _getUserMediaPushKitTimeout = Duration(seconds: 8);

class CallBloc extends Bloc<CallEvent, CallState> with WidgetsBindingObserver implements CallkeepDelegate {
  final CallLogsRepository callLogsRepository;
  final void Function(String callId, String callerName) _onMissedCall;
  final LinesStateRepository linesStateRepository;
  final PresenceInfoRepository presenceInfoRepository;
  final DialogInfoRepository dialogInfoRepository;
  final PresenceSettingsRepository presenceSettingsRepository;
  final QueuedTerminationRequestsRepository queuedTerminationRequestsRepository;
  final OutgoingFromNumberResolver resolveOutgoingFromNumber;
  final Function(Notification) submitNotification;

  /// Resolves the current camera permission state. Used to confirm that an
  /// audio-only downgrade on an incoming video call was caused by a denied
  /// camera permission (rather than a hardware failure) before steering the
  /// user toward app settings. When [null], no downgrade hint is raised.
  final Future<bool> Function()? isCameraPermissionGranted;

  /// Callback invoked when the signaling client reports a critical session
  /// error (e.g. [SignalingDisconnectCode.sessionMissedError]). The
  /// composition root owns the resolution of the logout reason and the
  /// logout dispatch (see `SessionInvalidationHandler`), so the bloc only
  /// reports.
  final Future<void> Function() onSessionMissedReported;

  final Callkeep callkeep;
  final CallkeepConnections callkeepConnections;
  late final CallMediaManager _mediaManager;

  final SDPMunger? sdpMunger;
  final SdpSanitizer? sdpSanitizer;
  final WebrtcOptionsBuilder? webRtcOptionsBuilder;
  final IceFilter? iceFilter;
  final UserMediaBuilder userMediaBuilder;
  final PeerConnectionPolicyApplier? peerConnectionPolicyApplier;
  final ContactResolver contactResolver;
  final CallErrorReporter callErrorReporter;
  final bool sendPresenceSettings;

  /// What the deployment lets a call do, as one value rather than a flag per
  /// feature: the pull-video strategy, whether the core takes `peer_message`
  /// (an older core closes the signaling socket with code 4600 on an unknown
  /// request, so [_sendMediaState] is suppressed unless it does), and the
  /// capabilities the UI reads. The same value the call screen gets.
  final CallCapabilitiesConfig capabilities;

  /// How long a merge may wait for the room's offer before this client gives
  /// the calls back; see [_armConferenceAssembly]. Longer than the server's
  /// own deadline, so its word wins whenever the socket is alive.
  final Duration conferenceAssemblyTimeout;

  final VoidCallback? onCallEnded;
  final OnDiagnosticReportRequested onDiagnosticReportRequested;

  StreamSubscription<ConnectivityResult>? _connectivityChangedSubscription;
  StreamSubscription<void>? _foregroundCallPushSubscription;
  final _iceRestartDebounce = DebounceMap<String>(const Duration(seconds: 2));

  /// Auto-hides the slowlink network-quality indicator once events stop, and
  /// drives the brief "recovered" confirmation. Keyed by callId; rescheduling
  /// the same key resets the countdown, so a steady stream of slowlink events
  /// keeps the indicator visible.
  final _slowlinkDebounce = DebounceMap<String>(const Duration(seconds: 2));

  /// Per-call slowlink hit counter; feeds the severity heuristic (more frequent
  /// events escalate severity). Cleared when the indicator is hidden.
  final Map<String, int> _slowlinkHits = {};

  /// Signaling error code meaning the call no longer exists on the server.
  ///
  /// Named because two handlers read it and a bare 410 says nothing: it is the
  /// difference between a request that failed and a call that is already gone.
  static const _callGoneErrorCode = 410;

  /// Owns when the app's own ringback tone is heard on an outgoing call: the
  /// wait for possible network audio, and every reason to go silent again.
  late final _ringback = OutgoingRingbackController(
    play: _mediaManager.playRingbackSound,
    stop: _mediaManager.stopRingbackSound,
    isWanted: (callId) => state.retrieveActiveCall(callId)?.shouldPlayLocalRingback ?? false,
  );

  late final SignalingModule _signalingModule;
  late final StreamSubscription<SignalingModuleEvent> _signalingSubscription;
  late final SignalingReconnectController _reconnectController;
  Timer? _presenceInfoSyncTimer;

  late final CallPeerConnectionManager _callPeerConnectionManager;
  late final HandshakeProcessor _handshakeProcessor;

  /// The host's connection to the conference room's mixer; idle without a room.
  late final ConferencePeerConnection _conferencePeerConnection;

  /// Runs while a merge waits for the room's offer; see [_armConferenceAssembly].
  Timer? _conferenceAssemblyTimer;

  /// Which room this client is on its way into, or holds. Bumped whenever
  /// that changes, so that work started for an earlier one - answering the
  /// mixer takes a media round trip - can tell it is no longer wanted.
  int _conferenceAttempt = 0;

  /// Keeps the platform's mute for every leg in step with the room's, and
  /// tells this client's own echoes from a person pressing mute.
  late final LegMuteSync _legMutes = LegMuteSync(callkeep);

  final ConnectivityService _connectivityService;

  CallBloc({
    required this.callLogsRepository,
    required void Function(String callId, String callerName) onMissedCall,
    required this.linesStateRepository,
    required this.presenceInfoRepository,
    required this.dialogInfoRepository,
    required this.presenceSettingsRepository,
    required this.queuedTerminationRequestsRepository,
    required this.resolveOutgoingFromNumber,
    required this.onSessionMissedReported,
    required this.submitNotification,
    required this.callkeep,
    required this.callkeepConnections,
    required this.userMediaBuilder,
    required this.contactResolver,
    required this.callErrorReporter,
    required this.sendPresenceSettings,
    required this.capabilities,
    required this.onDiagnosticReportRequested,
    this.isCameraPermissionGranted,
    this.sdpMunger,
    this.sdpSanitizer,
    this.webRtcOptionsBuilder,
    this.iceFilter,
    this.peerConnectionPolicyApplier,
    required SignalingModule signalingModule,
    required CallPeerConnectionManager callPeerConnectionManager,
    required ConnectivityService connectivityService,
    this.onCallEnded,
    Stream<void>? foregroundCallPushSignal,
    this.conferenceAssemblyTimeout = const Duration(seconds: 20),
  }) : _onMissedCall = onMissedCall,
       _connectivityService = connectivityService,
       super(const CallState()) {
    _mediaManager = CallMediaManager(callkeep: callkeep);
    _signalingModule = signalingModule;
    _callPeerConnectionManager = callPeerConnectionManager;
    _handshakeProcessor = HandshakeProcessor(queuedTerminationRequestsRepository: queuedTerminationRequestsRepository);
    _conferencePeerConnection = ConferencePeerConnection(
      factory: callPeerConnectionManager.factory,
      userMediaBuilder: userMediaBuilder,
      // The room's connection outlives close(): it is torn down after the bloc has
      // stopped taking events, and a candidate gathered in between has
      // nowhere to go.
      onLocalCandidate: (candidate) {
        if (!isClosed) add(_CallMutationEvent.conferenceLocalCandidate(candidate));
      },
      onConnectionLost: () {
        if (!isClosed) add(const _CallMutationEvent.conferenceLost());
      },
    );

    _reconnectController = SignalingReconnectController(
      signalingModule: signalingModule,
      onConnectionFailed: _handleConnectionFailed,
      onConnectionPresenceChanged: (isAvailable) =>
          _logger.info('signaling presence changed: isAvailable=$isAvailable'),
    );

    _foregroundCallPushSubscription = foregroundCallPushSignal?.listen(
      (_) => _reconnectController.notifyForceReconnect(),
    );

    // Translates SignalingModule events into BLoC state-transition events.
    // Reconnect scheduling and notification decisions are fully handled by
    // [_reconnectController] — this listener only drives [CallState] changes.
    _signalingSubscription = _signalingModule.events.listen((event) {
      switch (event) {
        case SignalingConnecting():
          add(const _SignalingClientEvent.connecting());
        case SignalingConnected():
          add(const _SignalingClientEvent.connected());
        case SignalingConnectionFailed(:final error):
          add(_SignalingClientEvent.failed(error));
        case SignalingDisconnecting():
          add(const _SignalingClientEvent.disconnecting());
        case SignalingDisconnected(:final code, :final reason):
          add(_SignalingClientEvent.disconnected(code, reason));
        case SignalingHandshakeReceived(:final handshake):
          _handleHandshakeReceived(handshake);
        case SignalingProtocolEvent(:final event):
          _handleSignalingEvent(event);
      }
    });

    on<CallStarted>(_onCallStarted, transformer: sequential());
    on<_AppLifecycleStateChanged>(_onAppLifecycleStateChanged, transformer: sequential());
    on<_ConnectivityResultChanged>(_onConnectivityResultChanged, transformer: sequential());
    on<_NavigatorMediaDevicesChange>(_onNavigatorMediaDevicesChange, transformer: debounce());
    on<_IceRestartTriggered>(_onIceRestartTriggered, transformer: sequential());
    on<_RegistrationChange>(_onRegistrationChange, transformer: droppable());
    on<_ResetStateEvent>(_onResetStateEvent, transformer: droppable());
    on<_SignalingClientEvent>(_onSignalingClientEvent, transformer: restartable());
    on<_HandshakeSignalingEventState>(_onHandshakeSignalingEventState, transformer: sequential());
    on<_CallSignalingEvent>(_onCallSignalingEvent, transformer: sequential());
    on<_CallPushEventIncoming>(_onCallPushEventIncoming, transformer: sequential());
    on<_RestoreAcceptedCall>(_onRestoreAcceptedCall, transformer: sequential());
    on<CallControlEvent>(
      _onCallControlEvent,
      transformer: (events, mapper) => StreamGroup.merge([
        droppable<CallControlEvent>().call(events.where((e) => e is _CallControlEventStarted), mapper),
        sequential<CallControlEvent>().call(events.where((e) => e is! _CallControlEventStarted), mapper),
      ]),
    );
    on<_CallPerformEvent>(_onCallPerformEvent, transformer: sequential());
    on<_PeerConnectionEvent>(_onPeerConnectionEvent, transformer: sequential());
    on<CallScreenEvent>(_onCallScreenEvent, transformer: sequential());
    on<CallConfigEvent>(_onConfigEvent, transformer: sequential());
    on<_GlobalEvent>(_onGlobalEvent, transformer: sequential());
    on<_CallMutationEvent>(_onCallMutationEvent, transformer: sequential());

    navigator.mediaDevices.ondevicechange = (event) {
      add(const _NavigatorMediaDevicesChange());
    };

    WidgetsBinding.instance.addObserver(this);

    callkeep.setDelegate(this);

    if (sendPresenceSettings) {
      _presenceInfoSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) => syncPresenceSettings());
    }
  }

  @override
  Future<void> close() async {
    callkeep.setDelegate(null);

    WidgetsBinding.instance.removeObserver(this);
    navigator.mediaDevices.ondevicechange = null;

    await _connectivityChangedSubscription?.cancel();
    await _foregroundCallPushSubscription?.cancel();

    _reconnectController.dispose();

    // First, so nothing below can leave a pending start behind or the tone on.
    await _ringback.stopAll().catchError((Object e) {
      _logger.warning('close: stopping the ringback failed', e);
    });

    _presenceInfoSyncTimer?.cancel();

    _conferenceAssemblyTimer?.cancel();
    _iceRestartDebounce.dispose();

    _slowlinkDebounce.dispose();
    _slowlinkHits.clear();

    await _signalingSubscription.cancel();

    for (final activeCall in state.activeCalls) {
      await _releaseLocalStream(activeCall.localStream);
    }

    await _callPeerConnectionManager.dispose();

    await super.close();

    // After the handlers have stopped, not before: super.close() is what
    // waits for one that is mid-answer, and a teardown racing it would find
    // nothing to close and leave the microphone captured.
    await _conferencePeerConnection.teardown();
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    _logger.warning('onError', error, stackTrace);
    // onError stays a pure logger by design: it has no call context (only error +
    // stackTrace) and a live call must survive a transient signaling drop. Finalizing
    // a call whose signaling is lost is handled by the disconnect/hangup/ICE paths.
    // See docs/features/call_arch.md, section
    // "Signaling edges (onChange / onError)" > "Call finalization on signaling loss (onError)".
  }

  @override
  void onChange(Change<CallState> change) {
    super.onChange(change);

    // Re-notify the reconnect controller when the call-active state flips while
    // the app is backgrounded - covers the gap the lifecycle handler misses
    // (it only samples isActive at the instant the app foregrounds/backgrounds).
    // See docs/features/call_arch.md, section
    // "Signaling edges (onChange / onError)" > "Background call-active edge (onChange)".
    if (change.currentState.isActive != change.nextState.isActive) {
      final appLifecycleState = change.nextState.currentAppLifecycleState;
      final appInactive =
          appLifecycleState == AppLifecycleState.paused ||
          appLifecycleState == AppLifecycleState.detached ||
          appLifecycleState == AppLifecycleState.inactive;
      final hasActiveCalls = change.nextState.isActive;
      final connected = _signalingModule.isConnected;

      if (appInactive) {
        _reconnectController.notifyHasActiveCalls(hasActiveCalls: hasActiveCalls);
        if (hasActiveCalls && !connected) {
          _reconnectController.notifyForceReconnect();
        }
        if (!hasActiveCalls && connected) {
          _reconnectController.notifyAppPaused(hasActiveCalls: false);
        }
      }
    }

    final currentActiveCallUuids = Set.from(change.currentState.activeCalls.map((e) => e.callId));
    _logger.fine('onChange currentActiveCallUuids: $currentActiveCallUuids');
    final nextActiveCallUuids = Set.from(change.nextState.activeCalls.map((e) => e.callId));
    _logger.fine('onChange nextActiveCallUuids: $nextActiveCallUuids');

    for (final removeUuid in currentActiveCallUuids.difference(nextActiveCallUuids)) {
      // Disposal is intentionally not awaited to avoid blocking the Bloc processing loop.
      // The CallPeerConnectionManager implements an internal "disposal barrier" (via _pendingDisposals)
      // which guarantees that any subsequent createPeerConnection() for this CallId will
      // automatically wait for this disposal to finish before proceeding.
      _callPeerConnectionManager.disposePeerConnection(removeUuid).catchError((error, stackTrace) {
        _logger.warning('Error disposing peer connection for $removeUuid', error, stackTrace);
      });
    }

    for (final addUuid in nextActiveCallUuids.difference(currentActiveCallUuids)) {
      _callPeerConnectionManager.add(addUuid);
    }

    final currentProcessingStatuses = Set.from(
      change.currentState.activeCalls.map((e) => '${e.line}:${e.processingStatus.name}'),
    ).join(', ');
    final nextProcessingStatuses = Set.from(
      change.nextState.activeCalls.map((e) => '${e.line}:${e.processingStatus.name}'),
    ).join(', ');
    if (currentProcessingStatuses != nextProcessingStatuses) {
      _logger.info(() => 'status transitions: $currentProcessingStatuses -> $nextProcessingStatuses');
    }

    /// RegistrationStatus can be null if the signaling state
    /// was not yet fully initialized. In this case, RegistrationStatus was made nullable to indicate that signaling has not been initialized yet.
    ///
    /// This scenario is particularly relevant when a call is triggered before the app
    /// is fully active, such as via [CallkeepDelegate.continueStartCallIntent]
    /// (e.g., from phone recents). That callback is delivered on iOS only - Android
    /// has no equivalent, so the scenario cannot arise there.

    final newRegistration = change.nextState.callServiceState.registration;
    final previousRegistration = change.currentState.callServiceState.registration;

    if (newRegistration != previousRegistration && newRegistration != null) {
      _logger.fine('_onRegistrationChange: $newRegistration to $previousRegistration');

      final newRegistrationStatus = newRegistration.status;
      final previousRegistrationStatus = previousRegistration?.status;

      if (previousRegistrationStatus?.isRegistered == false && newRegistrationStatus.isRegistered == true) {
        presenceSettingsRepository.resetLastSettingsSync();
        // submitNotification(AppOnlineNotification());
      }

      if (previousRegistrationStatus?.isRegistered == true && newRegistrationStatus.isRegistered == false) {
        // submitNotification(AppOfflineNotification());
      }

      if (newRegistrationStatus.isFailed == true || newRegistrationStatus.isUnregistered == true) {
        add(const _ResetStateEvent.completeCalls());
      }

      if (newRegistrationStatus.isFailed == true) {
        _logger.severe('Registration failed - code: ${newRegistration.code}, reason: ${newRegistration.reason}');

        final knownCode = SignalingRegistrationFailedCode.values.byCode(newRegistration.code);
        if (knownCode != SignalingRegistrationFailedCode.sipServerUnavailable) {
          // TODO?: maybe not skip serviceUnavaliable error recodring,
          // skipping for maintance windows is ok, but if this error happens in the wild it can be a sign of a bigger issue that we want to be aware
          CrashlyticsUtils.recordError(
            'CallBloc.Registration failed - code: ${newRegistration.code}, reason: ${newRegistration.reason}',
            information: [
              'newRegistration.code: ${newRegistration.code}',
              'newRegistration.reason: ${newRegistration.reason}',
              'newRegistration.status: ${newRegistration.status}',
              'previousRegistration?.code: ${previousRegistration?.code}',
              'previousRegistration?.reason: ${previousRegistration?.reason}',
              'previousRegistration?.status: ${previousRegistration?.status}',
            ],
          );
        }
      }
    }

    linesStateRepository.setState(change.nextState.toLinesState());
    _handleSignalingSessionError(
      previous: change.currentState.callServiceState,
      current: change.nextState.callServiceState,
    );

    if (change.nextState.activeCalls.length < change.currentState.activeCalls.length) {
      onCallEnded?.call();
    }

    /// Manages global side effects triggered by call lifecycle transitions.
    /// Key responsibility:
    /// - **iOS Audio Reset:** On the start of the *first* call, it forces the
    ///   audio route back to the Receiver (Earpiece). This prevents the "sticky speaker"
    ///   issue where iOS remembers the Speaker output from a previous session.
    _handleCallLifecycleTransitions(
      previousCalls: change.currentState.activeCalls,
      currentCalls: change.nextState.activeCalls,
    );
  }

  /// Analyzes changes in the active call list to trigger specific lifecycle hooks.
  ///
  /// This method identifies keys transitions:
  /// * **First Call Started (`0 -> 1`):** A cold start of the calling session.
  ///     Crucial for initializing hardware resources (e.g., resetting speaker output on iOS).
  /// * **Last Call Ended (`N -> 0`):** The termination of the calling session.
  ///     Used for global cleanup and resource release.
  void _handleCallLifecycleTransitions({
    required List<ActiveCall> previousCalls,
    required List<ActiveCall> currentCalls,
  }) {
    final wasEmpty = previousCalls.isEmpty;
    final isEmpty = currentCalls.isEmpty;

    // First call started (0 → 1).
    if (wasEmpty && !isEmpty) unawaited(_mediaManager.setSpeaker(enabled: false));

    // Last call ended (N → 0).
    if (!wasEmpty && isEmpty) {
      unawaited(_mediaManager.setSpeaker(enabled: false));
      _mediaManager.clearCommunicationDevice();
    }
  }

  /// Reacts to mid-call video state transitions and adjusts audio routing.
  ///
  /// Only handles transitions for EXISTING calls (prevCall != null).
  /// Called once after getUserMedia completes for a video call.
  ///
  /// At this point AudioSwitch has been activated (getUserMedia triggers
  /// AudioSwitchManager.start → activate) and the PhoneConnection exists
  /// in Telecom, so setAudioDevice can route to speaker safely.
  Future<void> _onVideoStreamReady(String callId) async {
    final call = state.retrieveActiveCall(callId);
    if (call?.video == true) {
      await _mediaManager.onVideoEnabled(callId, speakerDevice: state.availableAudioDevices.getSpeaker);
    }
  }

  void _handleConnectionFailed(SignalingFailureInfo failure) {
    final (:knownCode, :systemCode, :systemReason) = failure;

    // Skip logging and notification for expected disconnect scenarios that trigger automatic reconnects without user impact.
    switch (knownCode) {
      case SignalingDisconnectCode.signalingKeepaliveTimeoutError:
      case SignalingDisconnectCode.controllerForceAttachClose:
      case SignalingDisconnectCode.appUnregisteredError:
        // Expected silent reconnect: keepalive timeout on lock-screen, duplicate-session
        // cleanup, or SIP unregistration after the user toggles Online off.
        _logger.fine('onConnectionFailed: silent reconnect for code=$knownCode');
        return;
      case SignalingDisconnectCode.controllerUnknownError:
        // controllerUnknownError (4400): the server-side Controller process died because
        // the Janus connection went down. The new WebSocket timed out (GenServer.call,
        // 5s default) waiting for the Controller to finish re-initializing (new Janus
        // session + SIP registration). The Controller continues initializing in the
        // background — the next reconnect attempt will succeed once it is ready.
        //
        // Silent reconnect: no user-visible notification needed.
        _logger.warning('onConnectionFailed: silent reconnect for code=$knownCode');
        return;
      default:
        break;
    }

    // Record unexpected disconnects with as much detail as possible to facilitate debugging and resolution.
    //
    // If you encounter a new disconnect code in the wild, add it to the above switch statement
    // and monitor its frequency and impact before deciding whether to log it as a warning or fine level.
    _logger.severe('onConnectionFailed: $failure');
    CrashlyticsUtils.recordError(
      'CallBloc - onConnectionFailed ${knownCode?.name ?? 'unknown code'}',
      information: ['knownCode: $knownCode', 'systemCode: $systemCode', 'systemReason: $systemReason'],
    );
  }

  void _handleSignalingSessionError({required CallServiceState previous, required CallServiceState current}) {
    final signalingChanged =
        previous.signalingClientStatus != current.signalingClientStatus ||
        previous.lastSignalingDisconnectCode != current.lastSignalingDisconnectCode;

    if (!signalingChanged) return;

    if (current.signalingClientStatus == SignalingClientStatus.disconnect &&
        current.lastSignalingDisconnectCode is int) {
      final code = SignalingDisconnectCode.values.byCode(current.lastSignalingDisconnectCode as int);

      if (code == SignalingDisconnectCode.sessionMissedError) {
        _logger.info('Signaling session listener: session is missing ${current.lastSignalingDisconnectCode}');

        unawaited(onSessionMissedReported());
      }
    }
  }

  //

  Future<void> _onCallStarted(CallStarted event, Emitter<CallState> emit) async {
    // Initialize app lifecycle state
    final lifecycleState = WidgetsFlutterBinding.ensureInitialized().lifecycleState;
    emit(state.copyWith(currentAppLifecycleState: lifecycleState));
    _logger.fine('_onCallStarted initial lifecycle state: $lifecycleState');

    // Initialize connectivity state from the centralized service. The service
    // owns the call subsystem's subscription to `Connectivity().onConnectivityChanged`
    // and exposes a deduplicated stream of changes, so the bloc no longer
    // talks to the plugin directly.
    final connectivityState = _connectivityService.currentConnectivityResult;
    emit(
      state.copyWith(
        callServiceState: state.callServiceState.copyWith(networkStatus: connectivityState.toNetworkStatus()),
      ),
    );
    _logger.finer('_onCallStarted initial connectivity state: $connectivityState');

    // Subscribe to deduplicated future connectivity changes. The first replay
    // event from `Connectivity().onConnectivityChanged` is already filtered by
    // the service when it matches the cached initial value, so no bootstrap
    // call to the reconnect controller is needed here - the initial WS connect
    // is initiated by MainShell `..connect()` and runtime changes flow through
    // this subscription.
    _connectivityChangedSubscription = _connectivityService.connectivityResultStream.listen(
      (result) => add(_ConnectivityResultChanged(result)),
    );

    // Initial WS connect is initiated by MainShell `..connect()`; runtime
    // connectivity changes flow through the subscription above. No bootstrap
    // call to the reconnect controller is needed - calling notifyNetworkAvailable
    // here would proactively disconnect a healthy WS that just delivered the
    // handshake (the disconnect path inside notifyNetworkAvailable assumes a
    // real interface change, which a bootstrap snapshot is not).

    WebRTC.initialize(options: webRtcOptionsBuilder?.build());
  }

  Future<void> _onAppLifecycleStateChanged(_AppLifecycleStateChanged event, Emitter<CallState> emit) async {
    final appLifecycleState = event.state;
    _logger.fine('_onAppLifecycleStateChanged: $appLifecycleState');

    emit(state.copyWith(currentAppLifecycleState: appLifecycleState));

    if (appLifecycleState == AppLifecycleState.paused || appLifecycleState == AppLifecycleState.detached) {
      _reconnectController.notifyAppPaused(hasActiveCalls: state.isActive);
    } else if (appLifecycleState == AppLifecycleState.resumed) {
      _reconnectController.notifyAppResumed();
    }
  }

  Future<void> _onConnectivityResultChanged(_ConnectivityResultChanged event, Emitter<CallState> emit) async {
    final connectivityResult = event.result;
    _logger.fine('_onConnectivityResultChanged: $connectivityResult');
    if (connectivityResult == ConnectivityResult.none) {
      _reconnectController.notifyNetworkUnavailable();
    } else {
      _reconnectController.notifyNetworkAvailable();

      // Restart ICE for all active calls to trigger faster recovery from connectivity loss.
      //
      //  - in network loss scenario restarts RTP from almost imediately compating to built-in WebRTC connectivity checks which can take around 10-20 seconds
      //  - in double network scenario (e.g already has mobile network, but also connected to wifi)
      //    it helps to switch to better network instead of staying on old until rtp breaks.
      //
      // ICE restart is debounced to allow the new network interface (e.g. VPN tunnel) to fully
      // initialize before probing starts. Calling restartIce() immediately after onConnectivityChanged
      // can cause ICE failure because the interface is registered but not yet ready to carry traffic.
      for (var activeCall in state.activeCalls) {
        if (!activeCall.processingStatus.hasPeerConnectionReady) {
          _logger.info(
            '_onConnectivityResultChanged: skipping ICE restart for call ${activeCall.callId} — PC not ready (status: ${activeCall.processingStatus})',
          );
          continue;
        }
        _logger.info(
          '_onConnectivityResultChanged: scheduling ICE restart for call ${activeCall.callId} (status: ${activeCall.processingStatus})',
        );
        _scheduleIceRestart(activeCall.callId);
      }
    }

    emit(
      state.copyWith(
        callServiceState: state.callServiceState.copyWith(networkStatus: connectivityResult.toNetworkStatus()),
      ),
    );
  }

  Future<void> _onNavigatorMediaDevicesChange(_NavigatorMediaDevicesChange event, Emitter<CallState> emit) async {
    if (Platform.isIOS) {
      // Cleanup devices info if change happened after hangup
      // to avoid presenting stale data on next call initialization
      if (state.activeCalls.isEmpty) return emit(state.copyWith(availableAudioDevices: [], audioDevice: null));

      final devices = await navigator.mediaDevices.enumerateDevices();
      final output = devices.where((d) => d.kind == 'audiooutput').toList();
      final input = devices.where((d) => d.kind == 'audioinput').toList();
      _logger.info('Devices change - out:${output.map((e) => e.str).toList()}, in:${input.map((e) => e.str).toList()}');

      final available = [
        CallAudioDevice(type: CallAudioDeviceType.speaker),
        ...input.map(CallAudioDevice.fromMediaInput),
      ];

      CallAudioDevice current;

      if (output.isNotEmpty) {
        current = CallAudioDevice.fromMediaOutput(output.first);
      } else {
        // Fallback behavior for iOS when out:[]
        // We prioritize the Earpiece (Receiver) if available (derived from MicrophoneBuiltIn),
        // otherwise fallback to the first available device (which is Speaker based on the list above).
        current = available.firstWhere(
          (device) => device.type == CallAudioDeviceType.earpiece,
          orElse: () => available.first,
        );

        _logger.warning(
          'No "audiooutput" devices reported. Fallback selected: ${current.name} (type: ${current.type})',
        );
      }

      emit(state.copyWith(availableAudioDevices: available, audioDevice: current));
    }
  }

  // processing the registration event change

  Future<void> _onRegistrationChange(_RegistrationChange event, Emitter<CallState> emit) async {
    emit(state.copyWith(callServiceState: state.callServiceState.copyWith(registration: event.registration)));
  }

  // processing the handling of the app state
  Future<void> _onResetStateEvent(_ResetStateEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _ResetStateEventCompleteCalls() => __onResetStateEventCompleteCalls(event, emit),
      _ResetStateEventCompleteCall() => __onResetStateEventCompleteCall(event, emit),
    };
  }

  Future<void> __onResetStateEventCompleteCalls(_ResetStateEventCompleteCalls event, Emitter<CallState> emit) async {
    _logger.warning('__onResetStateEventCompleteCalls: ${state.activeCalls}');

    // Everything is going away, and the per-call teardowns below are droppable -
    // silence the tone once, here, instead of relying on each of them arriving.
    await _ringback.stopAll();

    if (state.conference.isPresent) {
      await _conferencePeerConnection.teardown();
      emit(state.copyWith(conference: const ConferenceState()));
    }

    for (var element in state.activeCalls) {
      add(_ResetStateEvent.completeCall(element.callId));
    }
  }

  Future<void> __onResetStateEventCompleteCall(_ResetStateEventCompleteCall event, Emitter<CallState> emit) async {
    _logger.warning('__onResetStateEventCompleteCall: ${event.callId}');

    _iceRestartDebounce.cancel(event.callId);
    _slowlinkDebounce.cancel(event.callId);
    _slowlinkHits.remove(event.callId);
    await _ringback.stop(event.callId);

    try {
      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          return activeCall.copyWith(processingStatus: CallProcessingStatus.disconnecting);
        }),
      );

      await state.performOnActiveCall(event.callId, (activeCall) async {
        // Dispose the peer connection first. If it was already completed with an error
        // (e.g. UserMediaError in the answer path), disposePeerConnection may throw.
        // Wrap it so that callkeep notification and stream release always run.
        try {
          await _callPeerConnectionManager.disposePeerConnection(activeCall.callId);
        } catch (e) {
          _logger.warning('__onResetStateEventCompleteCall: disposePeerConnection error $e');
        }

        await callkeep.reportEndCall(
          activeCall.callId,
          activeCall.displayName ?? activeCall.handle.value,
          event.endReason,
        );
        await _releaseLocalStream(activeCall.localStream);
      });
      emit(state.copyWithPopActiveCall(event.callId));
    } catch (e) {
      _logger.warning('__onResetStateEventCompleteCall: $e');
    }
  }

  // processing signaling client events

  Future<void> _onSignalingClientEvent(_SignalingClientEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _SignalingClientEventConnecting() => __onSignalingClientEventConnecting(event, emit),
      _SignalingClientEventConnected() => __onSignalingClientEventConnected(event, emit),
      _SignalingClientEventFailed() => __onSignalingClientEventFailed(event, emit),
      _SignalingClientEventDisconnecting() => __onSignalingClientEventDisconnecting(event, emit),
      _SignalingClientEventDisconnected() => __onSignalingClientEventDisconnected(event, emit),
    };
  }

  Future<void> __onSignalingClientEventConnecting(
    _SignalingClientEventConnecting event,
    Emitter<CallState> emit,
  ) async {
    emit(
      state.copyWith(
        callServiceState: state.callServiceState.copyWith(
          signalingClientStatus: SignalingClientStatus.connecting,
          lastSignalingClientConnectError: null,
          lastSignalingClientDisconnectError: null,
          lastSignalingDisconnectCode: null,
        ),
      ),
    );
  }

  Future<void> __onSignalingClientEventConnected(_SignalingClientEventConnected event, Emitter<CallState> emit) async {
    // Renegotiate active calls if there was reconnect
    //
    // Important to do in case if there was connection loss for a while and then webrtc detects network loss and restarts ice e.g
    // user turn off all network interfaces >> __onPeerConnectionEventIceConnectionStateChanged >> RTCIceConnectionStateFailed >> peerConnection.restartIce() >> onRenegotiationNeeded >> __onMutationRenegotiate >> if(!signalingConnected) return;
    // user turn on network interfaces >> _onSignalingClientEventConnected >> safeRenegotiate
    for (final call in state.activeCalls.where((c) => c.processingStatus == CallProcessingStatus.connected)) {
      _logger.warning('__onSignalingClientEventConnected: triggering safe renegotiation for call ${call.callId}');
      add(_CallMutationEvent.renegotiate(call.callId, call.line));
    }

    emit(
      state.copyWith(
        callServiceState: state.callServiceState.copyWith(
          signalingClientStatus: SignalingClientStatus.connect,
          lastSignalingClientConnectError: null,
          lastSignalingDisconnectCode: null,
        ),
      ),
    );
  }

  Future<void> __onSignalingClientEventFailed(_SignalingClientEventFailed event, Emitter<CallState> emit) async {
    if (emit.isDone) return;
    emit(
      state.copyWith(
        callServiceState: state.callServiceState.copyWith(
          signalingClientStatus: SignalingClientStatus.failure,
          lastSignalingClientConnectError: event.error,
        ),
      ),
    );
  }

  Future<void> __onSignalingClientEventDisconnecting(
    _SignalingClientEventDisconnecting event,
    Emitter<CallState> emit,
  ) async {
    emit(
      state.copyWith(
        callServiceState: state.callServiceState.copyWith(
          signalingClientStatus: SignalingClientStatus.disconnecting,
          lastSignalingClientConnectError: null,
        ),
      ),
    );
  }

  Future<void> __onSignalingClientEventDisconnected(
    _SignalingClientEventDisconnected event,
    Emitter<CallState> emit,
  ) async {
    final code = SignalingDisconnectCode.values.byCode(event.code ?? -1);

    // Notification decisions are handled by SignalingReconnectController via its
    // onConnectionFailed callback. This method only updates [CallState].

    CallState newState = state.copyWith(
      callServiceState: state.callServiceState.copyWith(
        signalingClientStatus: SignalingClientStatus.disconnect,
        lastSignalingDisconnectCode: event.code,
      ),
    );

    if (code == SignalingDisconnectCode.appUnregisteredError) {
      add(const _CallSignalingEvent.registration(RegistrationStatus.unregistered));
    } else if (code == SignalingDisconnectCode.requestCallIdError) {
      state.activeCalls.where((e) => e.wasHungUp).forEach((e) => add(_ResetStateEvent.completeCall(e.callId)));
    } else if (code == SignalingDisconnectCode.controllerExitError) {
      _logger.info('__onSignalingClientEventDisconnected: skipping expected system unregistration notification');
    } else if (code == SignalingDisconnectCode.signalingKeepaliveTimeoutError) {
      // Keepalive timeout while backgrounded (Android network restrictions).
      // Keep lastSignalingDisconnectCode null so connectIssue is never shown.
      newState = state.copyWith(
        callServiceState: state.callServiceState.copyWith(
          signalingClientStatus: SignalingClientStatus.disconnect,
          lastSignalingDisconnectCode: null,
        ),
      );
    } else if (code == SignalingDisconnectCode.controllerForceAttachClose) {
      // Server closed the connection because a duplicate signaling session was detected
      // (e.g. background push isolate still connected when main engine reconnects).
      // Keep lastSignalingDisconnectCode null so connectIssue is never shown.
      _logger.warning(
        '__onSignalingClientEventDisconnected: signaling race detected - '
        'server force-closed duplicate session (code=${event.code}, reason="${event.reason}").',
      );
      newState = state.copyWith(
        callServiceState: state.callServiceState.copyWith(
          signalingClientStatus: SignalingClientStatus.disconnect,
          lastSignalingDisconnectCode: null,
        ),
      );
    } else if (code == SignalingDisconnectCode.controllerUnknownError) {
      // Server-side transient state after long inactivity or multi-device reconnect.
      // The subsequent reconnect resolves it; keep lastSignalingDisconnectCode null
      // so connectIssue status is never shown to the user.
      _logger.warning(
        '__onSignalingClientEventDisconnected: transient controllerUnknownError - '
        'silent reconnect (code=${event.code}, reason="${event.reason}").',
      );
      newState = state.copyWith(
        callServiceState: state.callServiceState.copyWith(
          signalingClientStatus: SignalingClientStatus.disconnect,
          lastSignalingDisconnectCode: null,
        ),
      );
    } else if (code.type == SignalingDisconnectCodeType.auxiliary) {
      /// Fun facts
      /// - in case of network disconnection on android this section is evaluating faster than [_onConnectivityResultChanged].
      /// - also in case of network disconnection error code is protocolError instead of normalClosure by unknown reason
      /// so we need to handle it here as regular disconnection
      _logger.info('__onSignalingClientEventDisconnected: socket goes down');
    }

    emit(newState);
  }

  // processing call push events

  Future<void> _onCallPushEventIncoming(_CallPushEventIncoming event, Emitter<CallState> emit) async {
    final eventError = event.error;
    if (eventError != null) {
      // iOS only: CXProvider rejected the incoming call registration before it was
      // ever presented to the user (e.g. DND / Focus active, Call Directory blocklist,
      // missing VoIP entitlement, or unexpected CXProvider failure).
      //
      // Consequences:
      // - performEndCall will NOT fire (CallKit never registered the call).
      // - _signalingModule is very likely disconnected: VoIP push wakes the app
      //   before the WebSocket is established, so the CXProvider completion fires
      //   before signaling reconnects.
      //
      // Recovery path: when signaling reconnects the server replays the incoming
      // call event via the handshake. HandshakeProcessor generates a
      // HandleIncomingCallAction for the unknown callId, which re-enters
      // __onCallSignalingEventIncoming. At that point we have the SIP line and
      // can send a DeclineRequest immediately (see that method below).
      _logger.warning(
        '_onCallPushEventIncoming: OS rejected call registration '
        '(callId: ${event.callId}, error: $eventError) — server will be notified on next handshake',
      );
      return;
    }

    final contactName = (await contactResolver.resolve(event.handle.value))?.maybeName;
    final displayName = contactName ?? (event.displayName?.isEmpty == true ? null : event.displayName);

    // Re-check after the async gap: the signaling path may have created an entry
    // for this callId while contact resolution was in progress.
    if (state.activeCalls.any((c) => c.callId == event.callId)) {
      _logger.fine(
        '_onCallPushEventIncoming: callId ${event.callId} handled during contact resolution - skipping push duplicate',
      );
      return;
    }

    emit(
      state.copyWithPushActiveCall(
        ActiveCall(
          direction: CallDirection.incoming,
          line: _kUndefinedLine,
          callId: event.callId,
          handle: event.handle,
          displayName: displayName,
          video: event.video,
          createdTime: clock.now(),
          processingStatus: CallProcessingStatus.incomingFromPush,
        ),
      ),
    );

    // Replace the display name in Callkeep if it differs from the one in the event
    // mostly needed for ios, coz android can do it on background fcm isolate directly before push
    // TODO:
    // - do it on backend side same as for messaging
    //   currently push notification contain display name from sip header
    if (displayName != event.displayName) {
      await callkeep.reportUpdateCall(event.callId, displayName: displayName);
    }

    // Function to verify speaker availability for the upcoming event, ensuring the speaker button is correctly enabled or disabled
    add(const _NavigatorMediaDevicesChange());

    // the rest logic implemented within _onSignalingStateHandshake on IncomingCallEvent from call logs processing
  }

  // processing handshake signaling events

  Future<void> _onHandshakeSignalingEventState(_HandshakeSignalingEventState event, Emitter<CallState> emit) async {
    emit(state.copyWith(linesCount: event.linesCount));

    add(_RegistrationChange(registration: event.registration));
  }

  // processing call signaling events

  Future<void> _onCallSignalingEvent(_CallSignalingEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _CallSignalingEventIncoming() => __onCallSignalingEventIncoming(event, emit),
      _CallSignalingEventRinging() => __onCallSignalingEventRinging(event, emit),
      _CallSignalingEventProceeding() => __onCallSignalingEventProceeding(event, emit),
      _CallSignalingEventProgress() => __onCallSignalingEventProgress(event, emit),
      _CallSignalingEventAccepted() => __onCallSignalingEventAccepted(event, emit),
      _CallSignalingEventHangup() => __onCallSignalingEventHangup(event, emit),
      _CallSignalingEventUpdating() => __onCallSignalingEventUpdating(event, emit),
      _CallSignalingEventCallUpdating() => __onCallSignalingEventCallUpdating(event, emit),
      _CallSignalingEventUpdated() => __onCallSignalingEventUpdated(event, emit),
      _CallSignalingEventPeerMediaState() => __onCallSignalingEventPeerMediaState(event, emit),
      _CallSignalingEventTransfer() => __onCallSignalingEventTransfer(event, emit),
      _CallSignalingEventTransferring() => __onCallSignalingEventTransfering(event, emit),
      _CallSignalingEventTransferAccepted() => __onCallSignalingEventTransferAccepted(event, emit),
      _CallSignalingEventTransferFailed() => __onCallSignalingEventTransferFailed(event, emit),
      _CallSignalingEventNotifyRefer() => __onCallSignalingEventNotifyRefer(event, emit),
      _CallSignalingEventNotifyUnknown() => __onCallSignalingEventNotifyUnknown(event, emit),
      _CallSignalingEventRegistration() => __onCallSignalingEventRegistration(event, emit),
      _CallSignalingEventCallError() => __onCallSignalingEventCallError(event, emit),
    };
  }

  // processing global events

  Future<void> _onGlobalEvent(_GlobalEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _GlobalEventNumberPresenceUpdate() => __onGlobalEventNumberPresenceUpdate(event, emit),
      _GlobalEventNumberDialogsUpdate() => __onGlobalEventNumberDialogsUpdate(event, emit),
    };
  }

  /// Handles incoming call offer.
  ///
  /// - Creates a new full [ActiveCall] with offer and line.
  /// - Or enriches existing [ActiveCall] with line and offer if
  /// its placed by push [__onCallPushEventIncoming] before the signaling was initialized.
  ///
  /// - continues in  [__onCallControlEventAnswered], [__onCallPerformEventAnswered] or [__onCallControlEventEnded], [__onCallPerformEventEnded]
  ///
  /// Be aware the answering intent can be submitted before the full [ActiveCall].
  /// So the answering method [__onCallPerformEventAnswered] will wait until offer and line is assigned
  /// to the [ActiveCall] by logic below, do not change status in that case.
  Future<void> __onCallSignalingEventIncoming(_CallSignalingEventIncoming event, Emitter<CallState> emit) async {
    _logger.infoPretty(event.jsep?.sdp, tag: '__onCallSignalingEventIncoming');

    final handle = CallkeepHandle.number(event.caller);

    if (event.jsep != null) {
      final waitingCall = state.retrieveActiveCall(event.callId);
      if (waitingCall != null && waitingCall.incomingOffer == null) {
        final s = waitingCall.processingStatus;
        if (s == CallProcessingStatus.incomingFromPush ||
            s == CallProcessingStatus.incomingSubmittedAnswer ||
            s == CallProcessingStatus.incomingPerformingStarted) {
          _logger.info(
            '__onCallSignalingEventIncoming: fast-pathing offer to awaiting push call — '
            'callId=${event.callId} status=$s',
          );
          // The offer wakes an answer that may already be waiting for it, and
          // the answer reads the media flags the moment it wakes - so the
          // call is applied here exactly as the incoming mutation queued
          // behind that answer will apply it, camera state included.
          emit(
            state.copyWithMappedActiveCall(
              event.callId,
              (call) => call.withIncomingOffer(event.jsep, line: event.line, remoteVideo: event.remoteVideo),
            ),
          );
        }
      }
    }

    final contactName = (await contactResolver.resolve(handle.value))?.maybeName;
    final displayName = contactName ?? (event.callerDisplayName?.isEmpty == true ? null : event.callerDisplayName);

    final activeCallWithSameId = state.retrieveActiveCall(event.callId);
    // Skip the "call to myself" check when the existing call was registered via push
    // with an undefined line (_kUndefinedLine). In that case the signaling event carries
    // the real line and should update the call rather than decline it.
    if (activeCallWithSameId != null &&
        activeCallWithSameId.line != _kUndefinedLine &&
        activeCallWithSameId.line != event.line) {
      _logger.info(
        '__onCallSignalingEventIncoming: received incoming call with existing callId but different line - callId: ${event.callId}, probably call to myself or transfer to myself',
      );
      try {
        await _dispatchTerminationRequest(
          request: QueuedTerminationRequest(
            type: QueuedTerminationRequestType.decline,
            line: event.line,
            callId: event.callId,
          ),
          source: '__onCallSignalingEventIncoming',
        );
      } catch (e, s) {
        callErrorReporter.handle(e, s, '__onCallSignalingEventIncoming declineRequest error');
      }
      return;
    }

    // Glare detection: check if there is an active outgoing call with the same caller which is not yet connected or disconnecting.
    // Typical useccase is when two devices with the same account are calling each other at the same time, e.g. by pressing "call" button in recents or notifications.
    final nonConnectedCallWithSameCaller = state.activeCalls
        .where(
          (call) =>
              call.handle.value == event.caller &&
              call.callId != event.callId &&
              call.direction == CallDirection.outgoing &&
              call.processingStatus != CallProcessingStatus.connected &&
              call.processingStatus != CallProcessingStatus.disconnecting,
        )
        .firstOrNull;

    if (nonConnectedCallWithSameCaller != null) {
      // Polite glare resolution: compare call IDs lexicographically so both sides independently
      // reach the same deterministic decision - exactly one device yields.
      // The side whose outgoing callId is lexicographically greater yields: it ends its outgoing
      // call and lets the incoming proceed. The other side declines the incoming and keeps its outgoing.
      final q = [nonConnectedCallWithSameCaller.callId, event.callId]..sort();
      final shouldYield = q.first == event.callId;
      _logger.info(
        '__onCallSignalingEventIncoming: glare detected - nonConnectedCallWithSameCaller.callId: ${nonConnectedCallWithSameCaller.callId}, event.callId: ${event.callId}, shouldYield: $shouldYield',
      );

      if (shouldYield) {
        _logger.info(
          '__onCallSignalingEventIncoming: glare detected - yielding, ending outgoing call '
          '(callId: ${nonConnectedCallWithSameCaller.callId}), letting incoming (${event.callId}) proceed',
        );
        add(CallControlEvent.ended(nonConnectedCallWithSameCaller.callId));
      }
    }

    add(
      _CallMutationEvent.signalingIncoming(
        line: event.line,
        callId: event.callId,
        caller: event.caller,
        callee: event.callee,
        callerDisplayName: displayName,
        referredBy: event.referredBy,
        replaceCallId: event.replaceCallId,
        isFocus: event.isFocus,
        jsep: event.jsep,
        remoteVideo: event.remoteVideo,
      ),
    );
  }

  // ringing - the tone start decision belongs to the ringback controller
  Future<void> __onCallSignalingEventRinging(_CallSignalingEventRinging event, Emitter<CallState> emit) async {
    // The controller waits a moment in case the network is about to send audio
    // of its own; a proceeding answer with a plain alerting code cuts the wait
    // short (see [__onCallSignalingEventProceeding]). The current state is
    // re-read when the wait is over - the call may have moved on, including the
    // trailing plain ringing some switches send after their early media.
    _ringback.ringing(event.callId);

    emit(
      state.copyWithMappedActiveCall(event.callId, (call) {
        return call.copyWith(processingStatus: CallProcessingStatus.outgoingRinging);
      }),
    );

    _maybeSendPendingMediaState(event.callId);
  }

  /// The SIP code of a provisional answer travels in its own event right behind
  /// the matching ringing one. A plain 180 says the network will not send audio
  /// of its own for now, so the wait started by the ringing handler is cut
  /// short and the tone plays right away; a 183 promises nothing yet - the
  /// wait for possible early media stays on.
  Future<void> __onCallSignalingEventProceeding(_CallSignalingEventProceeding event, Emitter<CallState> emit) async {
    switch (event.code) {
      case 180:
        _logger.info(
          '__onCallSignalingEventProceeding: 180 - no early media expected, '
          'starting the local ringback now (callId: ${event.callId})',
        );
        _ringback.startNow(event.callId);
      case 183:
        _logger.info(
          '__onCallSignalingEventProceeding: 183 - early media may follow, '
          'keeping the local ringback on hold (callId: ${event.callId})',
        );
      default:
        _logger.info(
          '__onCallSignalingEventProceeding: ${event.code} - not a ringing indication, '
          'the local ringback is left as is (callId: ${event.callId})',
        );
    }
  }

  /// Best-effort informational signal so the remote side can reflect the
  /// camera state without SDP renegotiation - the only channel that works
  /// while the call is still ringing.
  void _sendMediaState(ActiveCall call, {required bool video}) {
    // An older core does not know the peer_message request and would tear down
    // the whole signaling socket (code 4600) in response, so skip the signal
    // entirely when the core does not advertise support.
    if (!capabilities.isPeerMessageEnabled) {
      _logger.fine('_sendMediaState: skipped (core does not support peer_message) for call ${call.callId}');
      return;
    }

    final transaction = WebtritSignalingClient.generateTransactionId();
    _signalingModule
        .execute(
          MediaStatePeerMessageRequest(transaction: transaction, line: call.line, callId: call.callId, video: video),
        )
        ?.catchError((Object e) => _logger.info('_sendMediaState: $e'));
  }

  /// A media_state sent before the first provisional response is rejected
  /// upstream (no early dialog to route it yet), so once 180/183 arrives
  /// re-send the current camera state. Covers both directions: camera turned
  /// off on a video call and a video track added to an audio call. Idempotent
  /// payload, so repeating the offer's own state is harmless.
  void _maybeSendPendingMediaState(String callId) {
    final call = state.retrieveActiveCall(callId);
    if (call == null || call.wasAccepted) return;

    final videoTrack = call.localStream?.getVideoTracks().firstOrNull;
    if (videoTrack != null) {
      _sendMediaState(call, video: videoTrack.enabled);
    }
  }

  /// Early media: the remote side sends audio before the call is answered -
  /// a network ringback, an announcement, an IVR prompt.
  ///
  /// The gateway raises this only for a provisional answer that CARRIES A
  /// SESSION DESCRIPTION (a 183, or a 180 that comes with one); the same codes
  /// without a description arrive as plain ringing instead, and other
  /// provisional answers never reach the app at all. So the code itself does
  /// not matter here - the description is the whole signal.
  ///
  /// Applying it wires the remote audio up, which is also what puts the app's
  /// own tone away for the rest of the call setup. A repeat of the same
  /// description arrives without one (the gateway sends it once per call), and
  /// is simply ignored - the call already knows it has network audio.
  Future<void> __onCallSignalingEventProgress(_CallSignalingEventProgress event, Emitter<CallState> emit) async {
    // Wiring the remote audio up takes a moment (the peer connection may still
    // be under construction), and the tone must not start during that window -
    // yet it must come back if the wiring fails, or the caller would be left in
    // total silence. So the pending start is held here and re-armed on failure,
    // while the tone itself is silenced only once the audio is really in place.
    _ringback.holdPending(event.callId);

    final jsep = event.jsep;
    if (jsep != null) {
      final peerConnection = await _callPeerConnectionManager.retrieve(event.callId);
      if (peerConnection == null) {
        _logger.warning('__onCallSignalingEventProgress: peerConnection is null - most likely some permissions issue');
        _ringback.ringing(event.callId);
      } else {
        final remoteDescription = jsep.toDescription();
        sdpSanitizer?.apply(remoteDescription);
        _logger.infoPretty(remoteDescription.sdp, tag: '__onCallSignalingEventProgress remoteDescription');
        try {
          await peerConnection.setRemoteDescription(remoteDescription);
          emit(state.copyWithMappedActiveCall(event.callId, (call) => call.copyWith(earlyMedia: true)));
          await _ringback.stop(event.callId);
        } catch (e, stackTrace) {
          callErrorReporter.handle(e, stackTrace, '__onCallSignalingEventProgress');
          _ringback.ringing(event.callId);
        }
      }
    } else {
      _logger.warning('__onCallSignalingEventProgress: jsep must not be null');
      _ringback.ringing(event.callId);
    }

    _maybeSendPendingMediaState(event.callId);
  }

  /// Informational media state from the remote side (e.g. the caller turned
  /// the camera off while this incoming call is still ringing). Carries no
  /// SDP, so no renegotiation is involved - only the video flag and the
  /// native call UI are updated.
  Future<void> __onCallSignalingEventPeerMediaState(
    _CallSignalingEventPeerMediaState event,
    Emitter<CallState> emit,
  ) async {
    final activeCall = state.retrieveActiveCall(event.callId);
    if (activeCall == null) return;

    final video = event.video;

    if (!activeCall.isIncoming) {
      _logger.info('__onCallSignalingEventPeerMediaState: ignoring for ${activeCall.direction.name}');
      return;
    }

    if (activeCall.wasAccepted) {
      // In-call: only the remote camera state changes. The negotiated track
      // keeps flowing (soft mute = black frames), so without this flag the UI
      // would keep presenting a video call; `video` stays untouched - it is
      // the LOCAL camera intent.
      emit(state.copyWithMappedActiveCall(event.callId, (call) => call.copyWith(remoteCameraEnabled: video)));
      return;
    }

    // Pre-answer: the flag drives both the incoming-call UI and the answer
    // default (a call downgraded to audio is answered as an audio call).
    emit(
      state.copyWithMappedActiveCall(event.callId, (call) => call.copyWith(video: video, remoteCameraEnabled: video)),
    );
    await callkeep.reportUpdateCall(event.callId, hasVideo: video);
  }

  /// Event fired when the call is accepted by any! user or call update request aplied.
  /// main cases:
  /// as call connected event after [__onCallPerformEventAnswered] or [__onCallPerformEventStarted]
  /// or as acknowledge of [UpdateRequest] with new jsep.
  Future<void> __onCallSignalingEventAccepted(_CallSignalingEventAccepted event, Emitter<CallState> emit) async {
    final call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    // The mutation below may sit behind other queued mutations, and until it
    // runs the call still looks unanswered - silence the tone right here so it
    // cannot start over an already connected conversation.
    _ringback.stopUnawaited(event.callId);

    add(_CallMutationEvent.signalingAccepted(callId: event.callId, jsep: event.jsep));
  }

  Future<void> __onCallSignalingEventHangup(_CallSignalingEventHangup event, Emitter<CallState> emit) async {
    final code = SignalingResponseCode.values.byCode(event.code);
    final call = state.retrieveActiveCall(event.callId);
    _logger.info(
      '__onCallSignalingEventHangup callId=${event.callId} '
      'code=${event.code}(${code?.name}) reason="${event.reason}" '
      'direction=${call?.direction.name} status=${call?.processingStatus.name}',
    );

    switch (code) {
      case null:
        break;
      case SignalingResponseCode.declineCall:
        break;
      case SignalingResponseCode.normalUnspecified:
        break;
      case SignalingResponseCode.requestTerminated:
        break;
      case SignalingResponseCode.unauthorizedRequest:
        submitNotification(CallWhileUnregisteredNotification());
      case SignalingResponseCode.rejected:
        submitNotification(CallRejectedNotification());
      case SignalingResponseCode.unwanted:
        submitNotification(CallUnwantedNotification());
      case SignalingResponseCode.userNotExist:
        submitNotification(CallUserNotExistNotification());
      case SignalingResponseCode.busyEverywhere || SignalingResponseCode.userBusy:
        submitNotification(CallBusyNotification());
      case SignalingResponseCode.invalidNumberFormat:
        submitNotification(CallInvalidNumberNotification());
      default:
        submitNotification(CallUnableToCompleteNotification());
        _logger.severe('onCallSignalingEventHangup: $code');
        CrashlyticsUtils.recordError(
          'CallBloc - onCallSignalingEventHangup ${code.name}',
          information: [
            'callId: ${event.callId}',
            'reason: ${event.reason}',
            if (call != null) 'callDirection: ${call.direction.name}',
            if (call != null) 'callStatus: ${call.processingStatus.name}',
          ],
        );
    }

    // The server confirms a termination this side asked for with a hangup:
    // the queued request has done its work and is not replayed.
    for (final request in queuedTerminationRequestsRepository.getAll.values) {
      if (request.callId == event.callId) queuedTerminationRequestsRepository.remove(request);
    }
    add(_CallMutationEvent.signalingHangup(callId: event.callId, code: event.code, reason: event.reason));
  }

  Future<void> __onCallSignalingEventCallUpdating(
    _CallSignalingEventCallUpdating event,
    Emitter<CallState> emit,
  ) async {
    final handle = CallkeepHandle.number(event.caller);
    final contactName = (await contactResolver.resolve(handle.value))?.maybeName;
    final displayName = contactName ?? event.callerDisplayName;

    final activeCall = state.retrieveActiveCall(event.callId)!;

    if (activeCall.processingStatus == CallProcessingStatus.disconnecting) {
      _logger.warning(
        '__onCallSignalingEventCallUpdating: ignoring call update for callId ${event.callId} because call is disconnecting',
      );
      return;
    }

    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(
          handle: handle,
          displayName: displayName ?? activeCall.displayName,
          // Do NOT update `video` here from remote SDP. `video` tracks local camera
          // intent (user-controlled). Setting it from the remote offer causes a
          // transient isCameraActive=true flash when a disabled policy-applier track
          // already exists in localStream. The mutation handler resets video if needed.
          updating: true,
        );
      }),
    );

    add(
      _CallMutationEvent.signalingCallUpdating(
        callId: event.callId,
        caller: event.caller,
        callee: event.callee,
        callerDisplayName: displayName,
        jsep: event.jsep,
      ),
    );
  }

  Future<void> __onCallSignalingEventUpdating(_CallSignalingEventUpdating event, Emitter<CallState> emit) async {
    // intercepted right inside [_CallMutationEvent.signalingCallUpdating] [__onMutationRenegotiate] call after [UpdateRequest] executed
  }

  Future<void> __onCallSignalingEventUpdated(_CallSignalingEventUpdated event, Emitter<CallState> emit) async {
    // intercepted right inside [_CallMutationEvent.signalingCallUpdating] [__onMutationRenegotiate] call after [UpdateRequest] executed
  }

  Future<void> __onCallSignalingEventTransfer(_CallSignalingEventTransfer event, Emitter<CallState> emit) async {
    final replaceCallId = event.replaceCallId;
    final referredBy = event.referredBy;
    final referId = event.referId;
    final referTo = event.referTo;

    // If replaceCallId exists, it means that the REFER request for attended transfer
    if (replaceCallId != null && referredBy != null) {
      // Find the active call that is should be replaced
      final callToReplace = state.retrieveActiveCall(replaceCallId);
      if (callToReplace == null) return;

      // Update call with confirmation request state
      final transfer = Transfer.attendedTransferConfirmationRequested(
        referId: referId,
        referTo: referTo,
        referredBy: referredBy,
      );
      final callUpdate = callToReplace.copyWith(transfer: transfer);
      emit(state.copyWithMappedActiveCall(replaceCallId, (_) => callUpdate));
    }
  }

  Future<void> __onCallSignalingEventTransfering(_CallSignalingEventTransferring event, Emitter<CallState> emit) async {
    final call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    final prev = call.transfer;
    final transfer = Transfer.transfering(
      fromAttendedTransfer: prev is AttendedTransferTransferSubmitted,
      fromBlindTransfer: prev is BlindTransferTransferSubmitted,
      toNumber: prev is BlindTransferTransferSubmitted ? prev.toNumber : null,
    );

    final callUpdate = call.copyWith(transfer: transfer);
    emit(state.copyWithMappedActiveCall(event.callId, (_) => callUpdate));
  }

  /// The transfer completed - the backend hangs up both of the transferor's
  /// legs right after this, so there is nothing to roll back here. Clears
  /// the transient [Transfer] state defensively in case that hangup is
  /// delayed, so the UI never gets stuck showing "Transferring...".
  Future<void> __onCallSignalingEventTransferAccepted(
    _CallSignalingEventTransferAccepted event,
    Emitter<CallState> emit,
  ) async {
    final call = state.retrieveActiveCall(event.callId);
    if (call == null || call.transfer == null) return;

    emit(state.copyWithMappedActiveCall(event.callId, (activeCall) => activeCall.copyWith(transfer: null)));
  }

  /// The backend rejected the transfer (e.g. a self-referential REFER, or the
  /// consultation party is unreachable). Unlike [TransferringEvent] the call
  /// is NOT hung up automatically, so roll back the transient [Transfer]
  /// state, un-hold the call so the user can keep talking or retry, and
  /// surface a notification - mirroring how [ReferFailed] already recovers a
  /// blind transfer rejected mid-flight.
  Future<void> __onCallSignalingEventTransferFailed(
    _CallSignalingEventTransferFailed event,
    Emitter<CallState> emit,
  ) async {
    final call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    _logger.warning('__onCallSignalingEventTransferFailed: transfer failed (code=${event.code}) for ${event.callId}');

    emit(state.copyWithMappedActiveCall(event.callId, (activeCall) => activeCall.copyWith(transfer: null)));
    await callkeep.setHeld(event.callId, onHold: false);
    // The wording ("Transfer failed, returning to active call") is generic
    // enough for both flavors - `transfer_failed` fires the same way for
    // blind and attended transfer, and a dedicated notification/l10n key
    // isn't worth it just to rename this for the attended case.
    submitNotification(BlindTransferFailedNotification());
  }

  Future<void> __onGlobalEventNumberPresenceUpdate(
    _GlobalEventNumberPresenceUpdate event,
    Emitter<CallState> emit,
  ) async {
    _logger.fine('_GlobalEventNumberPresenceUpdate: $event');
    await _assignNumberPresence(event.number, event.presenceInfo);
  }

  Future<void> __onGlobalEventNumberDialogsUpdate(
    _GlobalEventNumberDialogsUpdate event,
    Emitter<CallState> emit,
  ) async {
    _logger.fine('_GlobalEventNumberDialogsUpdate: $event');
    await _assignNumberDialogs(event.number, event.dialogInfos);
  }

  Future<void> __onCallSignalingEventNotifyRefer(_CallSignalingEventNotifyRefer event, Emitter<CallState> emit) async {
    _logger.fine('_CallSignalingEventNotifyRefer: $event');
    if (event.subscriptionState != SubscriptionState.terminated) return;

    switch (event.state) {
      case ReferAccepted():
        if (state.activeCalls.any((it) => it.callId == event.callId)) {
          add(CallControlEvent.ended(event.callId));
        } else {
          _logger.fine('__onCallSignalingEventNotifyRefer: ReferAccepted for unknown call ${event.callId}, ignoring');
        }
      case ReferFailed():
        final callId = event.callId;
        if (state.activeCalls.any((it) => it.callId == callId)) {
          _logger.warning(
            '__onCallSignalingEventNotifyRefer: transfer failed (${event.state}), restoring call $callId',
          );
          emit(state.copyWithMappedActiveCall(callId, (activeCall) => activeCall.copyWith(transfer: null)));
          await callkeep.setHeld(callId, onHold: false);
          submitNotification(BlindTransferFailedNotification());
        }
      case ReferProvisional():
        break;
    }
  }

  Future<void> __onCallSignalingEventNotifyUnknown(
    _CallSignalingEventNotifyUnknown event,
    Emitter<CallState> emit,
  ) async {
    _logger.fine('_CallSignalingEventNotifyUnknown: $event');
  }

  Future<void> __onCallSignalingEventRegistration(
    _CallSignalingEventRegistration event,
    Emitter<CallState> emit,
  ) async {
    final registration = Registration(status: event.status, code: event.code, reason: event.reason);
    add(_RegistrationChange(registration: registration));
  }

  Future<void> __onCallSignalingEventCallError(_CallSignalingEventCallError event, Emitter<CallState> emit) async {
    _logger.warning('_CallSignalingEventCallError: $event');
  }

  // processing call control events

  Future<void> _onCallControlEvent(CallControlEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _CallControlEventStarted() => __onCallControlEventStarted(event, emit),
      _CallControlEventCallSelected() => __onCallControlEventCallSelected(event, emit),
      _CallControlEventAnswered() => __onCallControlEventAnswered(event, emit),
      _CallControlEventAnsweredEndingOthers() => __onCallControlEventAnsweredEndingOthers(event, emit),
      _CallControlEventAnsweredHoldingOthers() => __onCallControlEventAnsweredHoldingOthers(event, emit),
      _CallControlEventResumedHoldingOthers() => __onCallControlEventResumedHoldingOthers(event, emit),
      _CallControlEventEnded() => __onCallControlEventEnded(event, emit),
      _CallControlEventSetHeld() => __onCallControlEventSetHeld(event, emit),
      _CallControlEventSetMuted() => __onCallControlEventSetMuted(event, emit),
      _CallControlEventSentDTMF() => __onCallControlEventSentDTMF(event, emit),
      _CallControlEventCameraSwitched() => _onCallControlEventCameraSwitched(event, emit),
      _CallControlEventCameraEnabled() => _onCallControlEventCameraEnabled(event, emit),
      _CallControlEventAudioDeviceSet() => _onCallControlEventAudioDeviceSet(event, emit),
      _CallControlEventFailureApproved() => _onCallControlEventFailureApproved(event, emit),
      _CallControlEventBlindTransferInitiated() => _onCallControlEventBlindTransferInitiated(event, emit),
      _CallControlEventAttendedTransferInitiated() => _onCallControlEventAttendedTransferInitiated(event, emit),
      _CallControlEventBlindTransferSubmitted() => _onCallControlEventBlindTransferSubmitted(event, emit),
      _CallControlEventAttendedTransferSubmitted() => _onCallControlEventAttendedTransferSubmitted(event, emit),
      _CallControlEventAttendedRequestApproved() => _onCallControlEventAttendedRequestApproved(event, emit),
      _CallControlEventAttendedRequestDeclined() => _onCallControlEventAttendedRequestDeclined(event, emit),
      _CallControlEventMerged() => __onCallControlEventMerged(event, emit),
      _CallControlEventConferenceAdded() => __onCallControlEventConferenceAdded(event, emit),
      _CallControlEventConferenceParticipantMuted() => __onCallControlEventConferenceParticipantMuted(event, emit),
      _CallControlEventConferenceSelfMuted() => __onCallControlEventConferenceSelfMuted(event, emit),
      _CallControlEventConferenceEnded() => __onCallControlEventConferenceEnded(event, emit),
    };
  }

  // Outgoing-call pipeline:
  //
  //   CallControlEvent.started
  //     -> _CallMutationEvent.controlStart        (sequential mutation queue)
  //         -> callkeep.startCall                 (native call UI opens)
  //             -> _CallPerformEvent.started      (callkeep delegate)
  //                 -> _CallMutationEvent.performStart -> SIP INVITE
  //
  // Each arrow may park the call as `outgoingConnectingToSignaling` while we
  // wait for handshake + registration + linesCount (see
  // `_shouldExitOutgoingSignalingWait`). The two decision points are:
  //   - `resolveOutgoingFromNumber` (injected callback - SIP `from`)
  //   - `state.pickOutgoingMainLine` (initial line at mutation time; the
  //     parked call's real line is later picked via `state.retrieveIdleLine`
  //     once the wait completes in `__onCallPerformEventStarted`)

  Future<void> __onCallControlEventStarted(_CallControlEventStarted event, Emitter<CallState> emit) async {
    // WT-1554: do NOT reject here when not registered. The downstream
    // [__onCallPerformEventStarted] path handles signaling/registration wait
    // and surfaces the appropriate notifications after the timeout.
    final fromNumber = resolveOutgoingFromNumber(event.fromNumber, event.handle.value);

    add(
      _CallMutationEvent.controlStart(
        handle: event.handle,
        video: event.video,
        displayName: event.displayName,
        fromNumber: fromNumber,
        fromReplaces: event.replaces,
      ),
    );
  }

  /// Focuses a call in the list-based call screen. Pure UI selection: clamps to
  /// a live call via [CallState.copyWithSelectedCall] (no media side effects).
  Future<void> __onCallControlEventCallSelected(_CallControlEventCallSelected event, Emitter<CallState> emit) async {
    emit(state.copyWithSelectedCall(event.callId));
  }

  // Combined-action intents. Each re-dispatches the ordered primitive events
  // produced by the pure plans on [CallControlEvent]; state only supplies the
  // other-call ids ([CallState.otherCallIds]). This replaces the per-call loops
  // the call screen used to synthesize itself. The primitives go through the
  // same sequential CallControlEvent queue as before, so semantics are
  // unchanged.

  /// "End & Answer": ends every other active call, then answers [event.callId].
  Future<void> __onCallControlEventAnsweredEndingOthers(
    _CallControlEventAnsweredEndingOthers event,
    Emitter<CallState> emit,
  ) async {
    CallControlEvent.answerEndingOthersPlan(event.callId, state.otherCallIds(event.callId)).forEach(add);
  }

  /// "Hold & Answer": holds every other active call, then answers [event.callId].
  Future<void> __onCallControlEventAnsweredHoldingOthers(
    _CallControlEventAnsweredHoldingOthers event,
    Emitter<CallState> emit,
  ) async {
    CallControlEvent.answerHoldingOthersPlan(event.callId, state.otherCallIds(event.callId)).forEach(add);
  }

  /// Resume on a held focus: holds the other live calls, then resumes
  /// [event.callId], so exactly one call stays live.
  Future<void> __onCallControlEventResumedHoldingOthers(
    _CallControlEventResumedHoldingOthers event,
    Emitter<CallState> emit,
  ) async {
    CallControlEvent.resumeHoldingOthersPlan(event.callId, state.otherCallIdsToHold(event.callId)).forEach(add);
  }

  /// Submitting the answer intent to system when answer button is pressed from app ui
  ///
  /// quick shortcut:
  /// call placed in [__onCallSignalingEventIncoming] or [__onCallPushEventIncoming]
  /// continues in [__onCallPerformEventAnswered]
  Future<void> __onCallControlEventAnswered(_CallControlEventAnswered event, Emitter<CallState> emit) async {
    final call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    // Prevents event doubling and race conditions
    // Upd (mutations sequence introdce) - TODO maybe use transformer to drop _CallMutationEvent.controlAnswer with same callid
    final canSubmitAnswer = switch (call.processingStatus) {
      CallProcessingStatus.incomingFromPush => true,
      CallProcessingStatus.incomingFromOffer => true,
      _ => false,
    };

    if (canSubmitAnswer == false) {
      _logger.info('__onCallControlEventAnswered: skipping due to stale status: ${call.processingStatus}');
      return;
    }

    emit(
      state.copyWithMappedActiveCall(
        event.callId,
        (call) => call.copyWith(processingStatus: CallProcessingStatus.incomingSubmittedAnswer),
      ),
    );

    add(_CallMutationEvent.controlAnswer(event.callId));
  }

  Future<void> __onCallControlEventEnded(_CallControlEventEnded event, Emitter<CallState> emit) async {
    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(processingStatus: CallProcessingStatus.disconnecting);
      }),
    );

    add(_CallMutationEvent.controlEnd(event.callId));
  }

  Future<void> __onCallControlEventSetHeld(_CallControlEventSetHeld event, Emitter<CallState> emit) async {
    add(_CallMutationEvent.controlSetHeld(event.callId, event.onHold));
  }

  Future<void> __onCallControlEventSetMuted(_CallControlEventSetMuted event, Emitter<CallState> emit) async {
    add(_CallMutationEvent.controlSetMuted(event.callId, event.muted));
  }

  Future<void> __onCallControlEventSentDTMF(_CallControlEventSentDTMF event, Emitter<CallState> emit) async {
    add(_CallMutationEvent.controlSendDTMF(event.callId, event.key));
  }

  Future<void> __onCallControlEventMerged(_CallControlEventMerged event, Emitter<CallState> emit) async {
    add(_CallMutationEvent.controlMerge(event.callIds));
  }

  Future<void> __onCallControlEventConferenceAdded(
    _CallControlEventConferenceAdded event,
    Emitter<CallState> emit,
  ) async {
    add(_CallMutationEvent.controlConferenceAdd(event.callId));
  }

  Future<void> __onCallControlEventConferenceParticipantMuted(
    _CallControlEventConferenceParticipantMuted event,
    Emitter<CallState> emit,
  ) async {
    add(_CallMutationEvent.controlConferenceMute(event.callId, event.muted));
  }

  Future<void> __onCallControlEventConferenceSelfMuted(
    _CallControlEventConferenceSelfMuted event,
    Emitter<CallState> emit,
  ) async {
    add(_CallMutationEvent.controlConferenceSelfMute(event.muted));
  }

  Future<void> __onCallControlEventConferenceEnded(
    _CallControlEventConferenceEnded event,
    Emitter<CallState> emit,
  ) async {
    add(const _CallMutationEvent.controlConferenceEnd());
  }

  Future<void> _onCallControlEventCameraSwitched(_CallControlEventCameraSwitched event, Emitter<CallState> emit) async {
    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(frontCamera: null);
      }),
    );
    add(_CallMutationEvent.controlSwitchCamera(event.callId));
  }

  Future<void> _onCallControlEventCameraEnabled(_CallControlEventCameraEnabled event, Emitter<CallState> emit) async {
    add(_CallMutationEvent.controlSetCameraEnabled(event.callId, event.enabled));
  }

  Future<void> _onCallControlEventAudioDeviceSet(_CallControlEventAudioDeviceSet event, Emitter<CallState> emit) async {
    await state.performOnActiveCall(event.callId, (activeCall) async {
      await _mediaManager.setDevice(event.callId, event.device, hasVideo: activeCall.video);
    });
  }

  Future<void> _onCallControlEventFailureApproved(
    _CallControlEventFailureApproved event,
    Emitter<CallState> emit,
  ) async {
    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(failure: null);
      }),
    );
  }

  Future<void> _onCallControlEventBlindTransferInitiated(
    _CallControlEventBlindTransferInitiated event,
    Emitter<CallState> emit,
  ) async {
    final isSpeakerOn = state.audioDevice?.type == CallAudioDeviceType.speaker;

    var newState = state.copyWith(minimized: true);

    newState = newState.copyWithMappedActiveCall(event.callId, (activeCall) {
      return activeCall.copyWith(
        transfer: const Transfer.blindTransferInitiated(),
        speakerOnBeforeMinimize: isSpeakerOn,
      );
    });

    emit(newState);

    await callkeep.reportUpdateCall(state.activeCalls.current.callId, proximityEnabled: state.shouldListenToProximity);

    // Hendgehog been there and removed putting on hold
    // He knows it was nessacery for first implementation of attended! transfer when our code can't auto hold on new call creation
    // but now we have it and hold inside _onCallControlEventAttendedTransferInitiated removed too
    //
    // The question is why it was added there (blind transter) also, because it cause race conditions
    // Attentioin: if you wanna bring it back, consider to prevent race condition (WT-1399) beetween holding and submitting refer (e.g fast initiating above recents tab and click on user)
  }

  Future<void> _onCallControlEventAttendedTransferInitiated(
    _CallControlEventAttendedTransferInitiated event,
    Emitter<CallState> emit,
  ) async {
    final isSpeakerOn = state.audioDevice?.type == CallAudioDeviceType.speaker;

    var newState = state.copyWith(minimized: true);

    newState = newState.copyWithMappedActiveCall(event.callId, (activeCall) {
      return activeCall.copyWith(speakerOnBeforeMinimize: isSpeakerOn);
    });

    emit(newState);
  }

  Future<void> _onCallControlEventBlindTransferSubmitted(
    _CallControlEventBlindTransferSubmitted event,
    Emitter<CallState> emit,
  ) async {
    final activeCallBlindTransferInitiated = state.activeCalls.blindTransferInitiated;
    final currentCall = state.activeCalls.current;

    final line = activeCallBlindTransferInitiated?.line ?? currentCall.line;
    final callId = activeCallBlindTransferInitiated?.callId ?? currentCall.callId;

    add(_CallMutationEvent.controlBlindTransfer(callId, line: line, number: event.number));
  }

  Future<void> _onCallControlEventAttendedTransferSubmitted(
    _CallControlEventAttendedTransferSubmitted event,
    Emitter<CallState> emit,
  ) async {
    add(_CallMutationEvent.controlAttendedTransfer(referorCall: event.referorCall, replaceCall: event.replaceCall));
  }

  Future<void> _onCallControlEventAttendedRequestApproved(
    _CallControlEventAttendedRequestApproved event,
    Emitter<CallState> emit,
  ) async {
    add(_CallMutationEvent.controlAttendedApprove(referId: event.referId, referTo: event.referTo));
  }

  Future<void> _onCallControlEventAttendedRequestDeclined(
    _CallControlEventAttendedRequestDeclined event,
    Emitter<CallState> emit,
  ) async {
    final call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    add(_CallMutationEvent.controlAttendedDecline(callId: event.callId, referId: event.referId));
  }

  // processing call perform events

  /// Returns true when [__onCallPerformEventStarted] should stop waiting for
  /// signaling readiness.
  ///
  /// Exits as soon as the handshake and signaling are established, the SIP
  /// REGISTER has been accepted (WT-1554) AND the line config has arrived
  /// (linesCount > 0 - so a cold-start outgoing call that parked before the
  /// handshake only proceeds once a line is actually known).
  ///
  /// Also exits fast when registration has definitively failed, so a known-bad
  /// state does not block the call for the full [kOutgoingCallSignalingWaitTimeout].
  ///
  /// Finally exits when the call leaves
  /// [CallProcessingStatus.outgoingConnectingToSignaling] - for example because
  /// the user pressed hangup (status -> disconnecting) or another code path
  /// removed the call entirely.
  bool _shouldExitOutgoingSignalingWait(CallState next, String callId) {
    if (next.isReadyForOutgoingCall) {
      _logger.info('outgoing signaling wait: ready for outgoing call (callId=$callId)');
      return true;
    }
    final registration = next.callServiceState.registration;
    if (registration?.status.isFailed == true) {
      _logger.info(
        'outgoing signaling wait: registration failed - code=${registration?.code} '
        'reason="${registration?.reason}" (callId=$callId)',
      );
      return true;
    }
    final call = next.retrieveActiveCall(callId);
    if (call == null || call.processingStatus != CallProcessingStatus.outgoingConnectingToSignaling) {
      _logger.info(
        'outgoing signaling wait: call escaped wait '
        '(callId=$callId, present=${call != null}, processingStatus=${call?.processingStatus.name})',
      );
      return true;
    }
    return false;
  }

  Future<void> _onCallPerformEvent(_CallPerformEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _CallPerformEventStarted() => __onCallPerformEventStarted(event, emit),
      _CallPerformEventAnswered() => __onCallPerformEventAnswered(event, emit),
      _CallPerformEventEnded() => __onCallPerformEventEnded(event, emit),
      _CallPerformEventSetHeld() => __onCallPerformEventSetHeld(event, emit),
      _CallPerformEventSetMuted() => __onCallPerformEventSetMuted(event, emit),
      _CallPerformEventSentDTMF() => __onCallPerformEventSentDTMF(event, emit),
      _CallPerformEventAudioDeviceSet() => __onCallPerformEventAudioDeviceSet(event, emit),
      _CallPerformEventAudioDevicesUpdate() => __onCallPerformEventAudioDevicesUpdate(event, emit),
    };
  }

  Future<void> __onCallPerformEventStarted(_CallPerformEventStarted event, Emitter<CallState> emit) async {
    // _kUndefinedLine is not an instant fail here: it means the call was
    // started before the signaling handshake arrived (cold start) and the
    // main line will be allocated below, after the wait. WT-1554.

    final restoredCall = state.retrieveActiveCall(event.callId);
    final canPerformStart = switch (restoredCall?.processingStatus) {
      CallProcessingStatus.outgoingCreated => true,
      CallProcessingStatus.outgoingCreatedFromRefer => true,
      CallProcessingStatus.outgoingConnectingToSignaling => true,
      _ => false,
    };
    if (!canPerformStart) {
      _logger.info('__onCallPerformEventStarted: skipping due to stale status: ${restoredCall?.processingStatus}');
      await callkeep.reportConnectedOutgoingCall(event.callId);
      event.fulfill();
      return;
    } else {
      _logger.info('__onCallPerformEventStarted: proceeding with status: ${restoredCall?.processingStatus}');
    }

    ///
    /// Ensuring that the signaling client is connected before attempting to make an outgoing call
    ///

    var currentState = state;

    // Attempt to wait for signaling+handshake+registration+lines readiness
    // within kOutgoingCallSignalingWaitTimeout. Also covers the cold-start
    // case: if the call was parked with [_kUndefinedLine], wait until
    // linesCount > 0 so a real main line can be allocated below.
    final activeCallNow = currentState.retrieveActiveCall(event.callId);
    final hasUndefinedLine = activeCallNow?.line == _kUndefinedLine;
    final needsWait = !currentState.isReadyForOutgoingCall || hasUndefinedLine;

    if (needsWait) {
      // Force-reconnect ONLY when the wait is caused by an actual signaling
      // gap (no handshake or no socket). Other wait reasons - registration
      // in flight, line config still pending, line parked - run over a
      // healthy socket and tearing it down would do harm.
      if (!currentState.isHandshakeEstablished || !currentState.isSignalingEstablished) {
        _reconnectController.notifyForceReconnect();
      }

      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          return activeCall.copyWith(processingStatus: CallProcessingStatus.outgoingConnectingToSignaling);
        }),
      );

      currentState = await stream
          .firstWhere((next) => _shouldExitOutgoingSignalingWait(next, event.callId), orElse: () => state)
          .timeout(kOutgoingCallSignalingWaitTimeout, onTimeout: () => state);
      if (isClosed) return;
    }

    // If the signaling client is not connected, decide how to clean up.
    if (!currentState.isSignalingEstablished) {
      event.fail();

      // If the call is no longer in outgoingConnectingToSignaling the hangup flow
      // has already taken over — avoid double-ending or showing a wrong notification.
      final waitingCall = state.retrieveActiveCall(event.callId);
      if (waitingCall?.processingStatus != CallProcessingStatus.outgoingConnectingToSignaling) {
        return;
      }

      // Notice that the tube was already hung up to avoid sending an extra event to the server
      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          return activeCall.copyWith(hungUpTime: clock.now());
        }),
      );

      // Remove local connection
      callkeep.endCall(event.callId);
      submitNotification(const CallWhileOfflineNotification());
      return;
    }

    if (currentState.callServiceState.registration?.status.isRegistered != true) {
      _logger.info('__onCallPerformEventStarted account is not registered');
      submitNotification(CallWhileUnregisteredNotification());
      event.fail();
      return;
    }

    // Resolve the main line that was parked at mutation time (cold start, WT-1554).
    if (currentState.retrieveActiveCall(event.callId)?.line == _kUndefinedLine) {
      final line = currentState.retrieveIdleLine();
      if (line == null) {
        _logger.info('no idle main line after outgoing signaling wait (callId=${event.callId})');
        event.fail();
        emit(state.copyWithPopActiveCall(event.callId));
        submitNotification(const GeneralUnableToCallNotification());
        return;
      }
      emit(state.copyWithMappedActiveCall(event.callId, (c) => c.copyWith(line: line)));
    }

    event.fulfill();
    add(_CallMutationEvent.performStart(event.callId, video: event.video));
  }

  Future<void> __onCallPerformEventAnswered(_CallPerformEventAnswered event, Emitter<CallState> emit) async {
    event.fulfill();

    final call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    // Prevent performing double answer and race conditions
    //
    // Main case happens when the call is answered from background(ios) or from the lock screen using navite controls
    // In such case performAnswered called emidiately and after signaling initialized via
    // [IncomingEvent] + (callAlreadyAnswered == true) > [callControlAnswered] > [performAnswered] called again
    //
    final canPerformAnswer = switch (call.processingStatus) {
      CallProcessingStatus.incomingFromPush => true,
      CallProcessingStatus.incomingFromOffer => true,
      CallProcessingStatus.incomingSubmittedAnswer => true,
      _ => false,
    };

    _logger.info(
      '__onCallPerformEventAnswered: callId=${event.callId} status=${call.processingStatus} '
      'hasOffer=${call.incomingOffer != null} signalingConnected=${_signalingModule.isConnected} '
      'appLifecycle=${state.currentAppLifecycleState}',
    );

    if (!canPerformAnswer) {
      _logger.info('__onCallPerformEventAnswered: skipping due to stale status: ${call.processingStatus}');
      return;
    }

    emit(
      state.copyWithMappedActiveCall(event.callId, (call) {
        return call.copyWith(processingStatus: CallProcessingStatus.incomingPerformingStarted);
      }),
    );

    add(_CallMutationEvent.performAnswer(event.callId));
  }

  Future<void> __onCallPerformEventEnded(_CallPerformEventEnded event, Emitter<CallState> emit) async {
    // Condition occur when the user interacts with a push notification before signaling is properly initialized.
    // In this case, the CallKeep method "reportNewIncomingCall" may return callIdAlreadyTerminated.
    if (state.retrieveActiveCall(event.callId)?.line == _kUndefinedLine) {
      // The call has no line yet, so the decline cannot be sent from here; it
      // is recorded for the next handshake, which knows the line and sends it
      // (the server's hangup, when it comes first, clears it). Until then the
      // record keeps a handshake plan from presenting the call again.
      queuedTerminationRequestsRepository.put(
        QueuedTerminationRequest(type: QueuedTerminationRequestType.decline, callId: event.callId, line: null),
      );
      add(_ResetStateEvent.completeCall(event.callId));
      return;
    }

    if (state.retrieveActiveCall(event.callId)?.wasHungUp == true) {
      // TODO: There's an issue where the user might have already ended the call, but the active call screen remains visible.
      if (state.isActive) emit(state.copyWithPopActiveCall(event.callId));
      event.fail();
      return;
    }

    event.fulfill();
    add(_CallMutationEvent.performEnd(event.callId));
  }

  Future<void> __onCallPerformEventSetHeld(_CallPerformEventSetHeld event, Emitter<CallState> emit) async {
    event.fulfill();
    add(_CallMutationEvent.performSetHeld(event.callId, event.onHold));
  }

  Future<void> __onCallPerformEventSetMuted(_CallPerformEventSetMuted event, Emitter<CallState> emit) async {
    event.fulfill();
    add(_CallMutationEvent.performSetMuted(event.callId, event.muted));
  }

  Future<void> __onCallPerformEventSentDTMF(_CallPerformEventSentDTMF event, Emitter<CallState> emit) async {
    event.fulfill();
    add(_CallMutationEvent.performSendDTMF(event.callId, event.key));
  }

  Future<void> __onCallPerformEventAudioDeviceSet(
    _CallPerformEventAudioDeviceSet event,
    Emitter<CallState> emit,
  ) async {
    _logger.info('CallPerformEventAudioDeviceSet: ${event.device}');
    event.fulfill();
    add(_CallMutationEvent.performSetAudioDevice(event.callId, event.device));
  }

  Future<void> __onCallPerformEventAudioDevicesUpdate(
    _CallPerformEventAudioDevicesUpdate event,
    Emitter<CallState> emit,
  ) async {
    _logger.info('CallPerformEventAudioDevicesUpdate: ${event.devices}');
    event.fulfill();
    emit(state.copyWith(availableAudioDevices: event.devices));
  }

  // ─── Mutation event dispatcher ────────────────────────────────────────────

  Future<void> _onCallMutationEvent(_CallMutationEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _CallMutationEventPerformStart() => __onMutationPerformStart(event, emit),
      _CallMutationEventPerformAnswer() => __onMutationPerformAnswer(event, emit),
      _CallMutationEventPerformEnd() => __onMutationPerformEnd(event, emit),
      _CallMutationEventPerformSetHeld() => __onMutationPerformSetHeld(event, emit),
      _CallMutationEventPerformSetMuted() => __onMutationPerformSetMuted(event, emit),
      _CallMutationEventPerformSendDTMF() => __onMutationPerformSendDTMF(event, emit),
      _CallMutationEventPerformSetAudioDevice() => __onMutationPerformSetAudioDevice(event, emit),
      _CallMutationEventControlStart() => __onMutationControlStart(event, emit),
      _CallMutationEventControlAnswer() => __onMutationControlAnswer(event, emit),
      _CallMutationEventControlEnd() => __onMutationControlEnd(event, emit),
      _CallMutationEventControlSetHeld() => __onMutationControlSetHeld(event, emit),
      _CallMutationEventControlSetMuted() => __onMutationControlSetMuted(event, emit),
      _CallMutationEventControlSendDTMF() => __onMutationControlSendDTMF(event, emit),
      _CallMutationEventControlSwitchCamera() => __onMutationControlSwitchCamera(event, emit),
      _CallMutationEventControlSetCameraEnabled() => __onMutationControlSetCameraEnabled(event, emit),
      _CallMutationEventControlBlindTransfer() => __onMutationControlBlindTransfer(event, emit),
      _CallMutationEventControlAttendedTransfer() => __onMutationControlAttendedTransfer(event, emit),
      _CallMutationEventControlAttendedApprove() => __onMutationControlAttendedApprove(event, emit),
      _CallMutationEventControlAttendedDecline() => __onMutationControlAttendedDecline(event, emit),
      _CallMutationEventSignalingIncoming() => __onMutationSignalingIncoming(event, emit),
      _CallMutationEventSignalingAccepted() => __onMutationSignalingAccepted(event, emit),
      _CallMutationEventSignalingHangup() => __onMutationSignalingHangup(event, emit),
      _CallMutationEventSignalingCallUpdating() => __onMutationSignalingCallUpdating(event, emit),
      _CallMutationEventRenegotiate() => __onMutationRenegotiate(event, emit),
      _CallMutationEventTrickleIce() => __onMutationTrickleIce(event, emit),
      _CallMutationEventIceGatheringComplete() => __onMutationIceGatheringComplete(event, emit),
      _CallMutationEventIceConnectionFailed() => __onMutationIceConnectionFailed(event, emit),
      _CallMutationEventRestartIce() => __onMutationRestartIce(event, emit),
      _CallMutationEventSlowlinkDetected() => __onMutationSlowlinkDetected(event, emit),
      _CallMutationEventSlowlinkCleared() => __onMutationSlowlinkCleared(event, emit),
      _CallMutationEventSlowlinkHidden() => __onMutationSlowlinkHidden(event, emit),
      _CallMutationEventRestoreCall() => __onMutationRestoreCall(event, emit),
      _CallMutationEventControlMerge() => __onMutationControlMerge(event, emit),
      _CallMutationEventControlConferenceAdd() => __onMutationControlConferenceAdd(event, emit),
      _CallMutationEventControlConferenceMute() => __onMutationControlConferenceMute(event, emit),
      _CallMutationEventControlConferenceSelfMute() => __onMutationControlConferenceSelfMute(event, emit),
      _CallMutationEventControlConferenceEnd() => __onMutationControlConferenceEnd(event, emit),
      _CallMutationEventConferenceOffer() => __onMutationConferenceOffer(event, emit),
      _CallMutationEventConferenceRemoteCandidate() => __onMutationConferenceRemoteCandidate(event, emit),
      _CallMutationEventConferenceLocalCandidate() => __onMutationConferenceLocalCandidate(event, emit),
      _CallMutationEventConferenceUpdated() => __onMutationConferenceUpdated(event, emit),
      _CallMutationEventConferenceFailed() => __onMutationConferenceFailed(event, emit),
      _CallMutationEventConferenceTerminated() => __onMutationConferenceTerminated(event, emit),
      _CallMutationEventConferenceLost() => __onMutationConferenceLost(event, emit),
      _CallMutationEventConferenceAnswered() => __onMutationConferenceAnswered(event, emit),
      _CallMutationEventConferenceAnswerFailed() => __onMutationConferenceAnswerFailed(event, emit),
    };
  }

  // Stub handlers — replaced in Tasks 3-6
  Future<void> __onMutationPerformStart(_CallMutationEventPerformStart event, Emitter<CallState> emit) async {
    ///
    /// Initializing media streams
    ///
    ///
    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(processingStatus: CallProcessingStatus.outgoingInitializingMedia);
      }),
    );

    late final MediaStream localStream;
    try {
      localStream = await userMediaBuilder.build(
        video: event.video,
        frontCamera: state.retrieveActiveCall(event.callId)?.frontCamera,
      );
      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          return activeCall.copyWith(localStream: localStream);
        }),
      );
      await _onVideoStreamReady(event.callId);
    } catch (e, stackTrace) {
      _logger.warning('__onMutationPerformStart _getUserMedia', e, stackTrace);
      _callPeerConnectionManager.completeError(event.callId, e, stackTrace);
      add(_ResetStateEvent.completeCall(event.callId, endReason: CallkeepEndCallReason.failed));
      if (e is UserMediaTrackSetupError) {
        submitNotification(const CallMediaTrackSetupErrorNotification());
      } else {
        submitNotification(const CallUserMediaErrorNotification());
      }
      return;
    }

    ///
    /// Initializing peer connection and sending outgoing offer
    ///
    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(processingStatus: CallProcessingStatus.outgoingOfferPreparing);
      }),
    );

    try {
      final activeCall = state.retrieveActiveCall(event.callId);
      if (activeCall == null) return;

      final peerConnection = await _createPeerConnection(event.callId, activeCall.line);
      await Future.wait(localStream.getTracks().map((track) => peerConnection.addTrack(track, localStream)));

      // A pull (Replaces) takes over an existing call whose remote answer keeps its
      // original video m-line. Under the soft-mute strategy, add a recvonly video
      // m-line to the pull offer so the offer/answer media layouts match (otherwise
      // setRemoteDescription rejects the answer "order of m-lines ..."). recvonly
      // adds the m-line WITHOUT opening the camera, so an audio pull on a camera-
      // denied / camera-less device is unaffected. Under the hide-video strategy
      // video calls are not pullable at all; under the mirror strategy a video pull
      // already carries a real (camera-backed) video track from the started event's
      // video flag - so in both cases the recvonly m-line is not needed here.
      if (activeCall.fromReplaces != null && capabilities.callPullVideoStrategy == CallPullVideoStrategy.softMute) {
        await peerConnectionPolicyApplier?.apply(
          peerConnection,
          hasRemoteVideo: true,
          strategy: VideoOfferStrategy.recvonly,
        );
      }

      final localDescription = await peerConnection.createOffer({});
      sdpMunger?.apply(localDescription);
      _logger.infoPretty(localDescription.sdp, tag: '__onMutationPerformStart');

      // Need to initiate outgoing call before set localDescription to avoid races
      // between [OutgoingCallRequest] and [IceTrickleRequest]s.
      await _signalingModule.execute(
        OutgoingCallRequest(
          transaction: WebtritSignalingClient.generateTransactionId(),
          line: activeCall.line,
          from: activeCall.fromNumber,
          callId: activeCall.callId,
          number: activeCall.handle.normalizedValue(),
          jsep: localDescription.toMap(),
          referId: activeCall.fromReferId,
          replaces: activeCall.fromReplaces,
        ),
      );

      // In other cases setLocalDescription is called first; here it's delayed to avoid ICE race
      await peerConnection.setLocalDescription(localDescription);
      _callPeerConnectionManager.complete(event.callId, peerConnection);
      await callkeep.reportConnectingOutgoingCall(event.callId);

      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          return activeCall.copyWith(processingStatus: CallProcessingStatus.outgoingOfferSent);
        }),
      );
    } catch (e, stackTrace) {
      // Handles exceptions during the outgoing call perform event, sends a notification, stops the ringtone, and completes the peer connection with an error.
      // The specific error "Error setting ICE locally" indicates an issue with ICE (Interactive Connectivity Establishment) negotiation in the WebRTC signaling process.
      callErrorReporter.handle(e, stackTrace, '__onMutationPerformStart error:');
      await _ringback.stop(event.callId);
      _callPeerConnectionManager.completeError(event.callId, e, stackTrace);
      add(_ResetStateEvent.completeCall(event.callId));
    }
  }

  Future<void> __onMutationPerformAnswer(_CallMutationEventPerformAnswer event, Emitter<CallState> emit) async {
    ActiveCall? call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    try {
      /// Prevent performing answer without offer
      ///
      /// Main case happens when the call is answered from push event while signaling is disconnected
      /// and main [IncomingEvent] with offer wasnt received yet
      ///
      if (call.incomingOffer == null) {
        _logger.info(
          '__onMutationPerformAnswer: wait for offer '
          'signalingConnected=${_signalingModule.isConnected}',
        );

        // Signaling may still be disconnected when answering from push while the app was in background.
        // Trigger reconnect immediately so the offer can arrive — don't wait for AppLifecycleState.resumed.
        if (!_signalingModule.isConnected) {
          _logger.info('__onMutationPerformAnswer: signaling not connected, forcing reconnect');
          _reconnectController.notifyForceReconnect();
        }

        final offerWaitStart = DateTime.now();
        await stream
            .firstWhere((s) {
              final activeCall = s.retrieveActiveCall(event.callId);
              if (activeCall?.incomingOffer == null) {
                _logger.fine(
                  '__onMutationPerformAnswer: offer still pending '
                  'status=${activeCall?.processingStatus} '
                  'signalingConnected=${_signalingModule.isConnected} '
                  'elapsed=${DateTime.now().difference(offerWaitStart).inMilliseconds}ms',
                );
              }
              return activeCall?.incomingOffer != null;
            })
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                _logger.warning(
                  '__onMutationPerformAnswer: offer wait timed out — '
                  'signalingConnected=${_signalingModule.isConnected} '
                  'elapsed=${DateTime.now().difference(offerWaitStart).inMilliseconds}ms',
                );
                throw TimeoutException('Timed out waiting for offer');
              },
            );

        final offerWaitMs = DateTime.now().difference(offerWaitStart).inMilliseconds;
        _logger.info('__onMutationPerformAnswer: offer received after ${offerWaitMs}ms');

        call = state.retrieveActiveCall(event.callId)!;
      }
      final offer = call.incomingOffer!;

      _logger.info('__onMutationPerformAnswer: processing offer, hasVideo=${offer.hasVideo}, callVideo=${call.video}');

      emit(
        state.copyWithMappedActiveCall(event.callId, (call) {
          return call.copyWith(processingStatus: CallProcessingStatus.incomingInitializingMedia);
        }),
      );

      // The camera follows the state the call PRESENTS, not the raw offer:
      // after a soft-mute downgrade the offer still advertises m=video, and
      // answering with the camera on would silently put the user on air in a
      // call their UI shows as audio. `call.video` carries the offer value
      // updated by media_state; the explicit remoteCameraEnabled check also
      // survives incoming-event replays that reset `video` from the jsep.
      final answerWithVideo = call.video && call.remoteCameraEnabled != false;
      final localStream = await userMediaBuilder
          .build(video: answerWithVideo, frontCamera: call.frontCamera, allowAudioFallback: true)
          .timeout(_getUserMediaPushKitTimeout, onTimeout: _onGetUserMediaPushKitTimeout);
      final peerConnection = await _createPeerConnection(event.callId, call.line);
      await Future.forEach(localStream.getTracks(), (t) => peerConnection.addTrack(t, localStream));

      final hasVideo = localStream.getVideoTracks().isNotEmpty;
      // The offer requested video but the stream came back audio-only: the
      // camera was downgraded. Confirm it is a permission denial (not a
      // hardware failure) before hinting the user toward app settings.
      final videoDowngraded = offer.hasVideo && !hasVideo;
      final videoPermissionDenied = videoDowngraded && !(await _isCameraPermissionGranted());
      emit(
        state.copyWithMappedActiveCall(event.callId, (call) {
          return call.copyWith(
            video: hasVideo,
            videoPermissionDenied: videoPermissionDenied,
            localStream: localStream,
            processingStatus: CallProcessingStatus.incomingAnswering,
          );
        }),
      );
      if (videoPermissionDenied) {
        submitNotification(const CallVideoDowngradedNotification());
      }
      await _onVideoStreamReady(event.callId);

      final remoteDescription = offer.toDescription();
      sdpSanitizer?.apply(remoteDescription);
      _logger.infoPretty(remoteDescription.sdp, tag: '__onMutationPerformAnswer remoteDescription');
      await peerConnection.setRemoteDescription(remoteDescription);
      _logger.info('__onMutationPerformAnswer: remoteDescription set');

      final localDescription = await peerConnection.createAnswer({});
      sdpMunger?.apply(localDescription);
      _logger.infoPretty(localDescription.sdp, tag: '__onMutationPerformAnswer localDescription');

      // According to RFC 8829 5.6 (https://datatracker.ietf.org/doc/html/rfc8829#section-5.6),
      // localDescription should be set before sending the answer to transition into stable state.
      await peerConnection.setLocalDescription(localDescription).catchError((e) => throw SDPConfigurationError(e));
      _logger.info('__onMutationPerformAnswer: localDescription set, sending AcceptRequest');

      // Re-check that the call still exists before sending AcceptRequest.
      // __onCallSignalingEventHangup may have run concurrently (e.g. 487 "Request Terminated"
      // from the server while SDP was being prepared), removing the call from state.
      // Sending accept on an already-terminated line results in a 4610 disconnect.
      if (state.retrieveActiveCall(event.callId) == null) {
        _logger.info('__onMutationPerformAnswer: call terminated during SDP setup, skipping AcceptRequest');
        _callPeerConnectionManager.completeError(
          event.callId,
          Exception('call terminated during SDP setup'),
          StackTrace.current,
        );
        // __onCallSignalingEventHangup emits copyWithPopActiveCall before awaiting
        // callkeep.reportEndCall, so the native side may not have been notified yet.
        // Call it explicitly here to avoid leaving the Telecom connection in ACTIVE state.
        // Callkeep handles double calls gracefully (already-disconnected is a no-op).
        await callkeep.reportEndCall(
          event.callId,
          call.displayName ?? call.handle.value,
          CallkeepEndCallReason.unanswered,
        );
        return;
      }

      _logger.info(
        '__onMutationPerformAnswer: AcceptRequest callId=${call.callId} line=${call.line} eventCallId=${event.callId}',
      );
      await _signalingModule.execute(
        AcceptRequest(
          transaction: WebtritSignalingClient.generateTransactionId(),
          line: call.line,
          callId: call.callId,
          jsep: localDescription.toMap(),
        ),
      );

      _logger.info('__onMutationPerformAnswer: AcceptRequest sent, completing peer connection');
      _callPeerConnectionManager.complete(event.callId, peerConnection);
    } catch (e, stackTrace) {
      _logger.warning(
        '__onMutationPerformAnswer: failed callId=${event.callId} error=$e code:${e is WebtritSignalingErrorException ? e.code : 'N/A'}, reason=${e is WebtritSignalingErrorException ? e.reason : 'N/A'}',
        stackTrace,
      );

      // If call gone right before answer, consider it as normal flow and avoid showing error notification
      // TODO: implement signaling request response mechanism and handle request specific result instead of catching global errors
      if (e is WebtritSignalingErrorException && e.code == _callGoneErrorCode) {
        _callPeerConnectionManager.completeError(event.callId, e, stackTrace);
        add(_ResetStateEvent.completeCall(event.callId));
        _addToRecents(call!);
        return;
      }

      // If the server closed the connection because the line no longer exists (4610 "call request on wrong line"),
      // the call is already gone on the server side — clean up locally without sending a decline request.
      // Sending decline here would cause a reconnect loop: each reconnect attempt would send decline again,
      // receive 4610 again, disconnect again, and reconnect indefinitely.
      if (e is WebtritSignalingTransactionTerminateByDisconnectException &&
          e.closeCode == SignalingDisconnectCode.requestCallIdError.code) {
        _callPeerConnectionManager.completeError(event.callId, e, stackTrace);
        _addToRecents(call!);
        add(_ResetStateEvent.completeCall(event.callId, endReason: CallkeepEndCallReason.unanswered));
        return;
      }

      _callPeerConnectionManager.completeError(event.callId, e, stackTrace);
      _addToRecents(call!);
      add(_ResetStateEvent.completeCall(event.callId, endReason: CallkeepEndCallReason.unanswered));

      // If the WS was already closed when the answer flow failed, the server-side
      // call session is gone — sending DeclineRequest on the reconnected WS would
      // target a stale call and trigger another 4610 close.
      if (e is WebtritSignalingTransactionTerminateByDisconnectException) {
        callErrorReporter.handle(e, stackTrace, '__onMutationPerformAnswer error:');
        return;
      }

      // If the call was already removed from state (e.g. __onCallSignalingEventHangup
      // ran concurrently while we were building media or preparing SDP), the server
      // already terminated the call — no need to decline.
      if (state.retrieveActiveCall(event.callId) == null) {
        callErrorReporter.handle(e, stackTrace, '__onMutationPerformAnswer error:');
        return;
      }

      // For non-disconnect errors (e.g. UserMediaError, SDP errors) the server line
      // may still be alive. Send DeclineRequest to clean it up, and handle 4610 in
      // the inner catch — that means the caller already hung up server-side.

      _dispatchTerminationRequest(
        request: QueuedTerminationRequest(
          type: QueuedTerminationRequestType.decline,
          line: call.line,
          callId: call.callId,
        ),
        source: '__onMutationPerformAnswer',
      );
    }
  }

  Future<void> __onMutationPerformEnd(_CallMutationEventPerformEnd event, Emitter<CallState> emit) async {
    try {
      await _ringback.stop(event.callId);

      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          final activeCallUpdated = activeCall.copyWith(hungUpTime: clock.now());
          _addToRecents(activeCallUpdated);
          return activeCallUpdated;
        }),
      );

      await state.performOnActiveCall(event.callId, (activeCall) async {
        if (activeCall.isIncoming && !activeCall.wasAccepted) {
          await _dispatchTerminationRequest(
            request: QueuedTerminationRequest(
              type: QueuedTerminationRequestType.decline,
              line: activeCall.line,
              callId: activeCall.callId,
            ),
            source: '__onMutationPerformEnd',
          ).timeout(Duration(seconds: 1), onTimeout: () {});
        } else {
          // Skip hangup when a blind transfer is in Transfering state (server started to process it).
          // In this state the SIP dialog may already be closed server-side via REFER; sending hangup
          // results in a 4610 "call request on wrong line" rejection and an unexpected WebSocket disconnect.
          final isBlindTransferInTransferingState = switch (activeCall.transfer) {
            Transfering(:final fromBlindTransfer) => fromBlindTransfer,
            _ => false,
          };

          if (!isBlindTransferInTransferingState) {
            await _dispatchTerminationRequest(
              request: QueuedTerminationRequest(
                type: QueuedTerminationRequestType.hangup,
                line: activeCall.line,
                callId: activeCall.callId,
              ),
              source: '__onMutationPerformEnd',
            ).timeout(Duration(seconds: 1), onTimeout: () {});
          }
        }

        // Need to close peer connection after the signaling request (decline/hangup) has been sent,
        // or after skipping it for blind transfer, to prevent "Simulate a 'hangup' coming from the
        // application" triggered by "No WebRTC media anymore".
        await _callPeerConnectionManager.disposePeerConnection(activeCall.callId);
        await _releaseLocalStream(activeCall.localStream);
      });

      emit(state.copyWithPopActiveCall(event.callId));
    } finally {
      // Release the post-cancel enqueue guard so the entry does not accumulate
      // for the lifetime of the signaling module.
      _signalingModule.clearTerminatingMark(event.callId);
    }
  }

  Future<void> __onMutationPerformSetHeld(_CallMutationEventPerformSetHeld event, Emitter<CallState> emit) async {
    if (state.isConferenced(event.callId)) {
      // A leg of the room is not held or resumed on its own: the plugin
      // already answers such a request with callIsGrouped, and the server
      // would refuse it as line_in_conference. Nothing changes here.
      _logger.info('__onMutationPerformSetHeld: ${event.callId} is a conference leg, ignoring onHold=${event.onHold}');
      return;
    }
    try {
      await state.performOnActiveCall(event.callId, (activeCall) {
        if (event.onHold) {
          return _signalingModule.execute(
            HoldRequest(
              transaction: WebtritSignalingClient.generateTransactionId(),
              line: activeCall.line,
              callId: activeCall.callId,
              direction: HoldDirection.inactive,
            ),
          );
        } else {
          return _signalingModule.execute(
            UnholdRequest(
              transaction: WebtritSignalingClient.generateTransactionId(),
              line: activeCall.line,
              callId: activeCall.callId,
            ),
          );
        }
      });

      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          return activeCall.copyWith(held: event.onHold);
        }),
      );
    } on NotConnectedException {
      _logger.warning('__onMutationPerformSetHeld: not connected, let call survive');
    } on WebtritSignalingTransactionTimeoutException {
      _logger.warning('__onMutationPerformSetHeld: transaction timeout, let call survive');
    } on WebtritSignalingErrorException catch (e, stackTrace) {
      // A hold the server declined is only a hold that did not happen: the call is
      // still up and still carrying audio, and the one thing lost is the state
      // change. Ending the call over it would turn a refused control into a
      // dropped call. Once a line can belong to a conference the server declines
      // to hold a single leg of one, so this is a routine answer, not a fault.
      if (e.code != _callGoneErrorCode) {
        _logger.warning('__onMutationPerformSetHeld: server declined (${e.code}), let call survive');
        return;
      }
      // Code 410 does not say the hold failed, it says there is no call to hold.
      // Keeping it alive locally would strand a call the server has already
      // forgotten.
      _endCallAfterFailedHold(event.callId, e, stackTrace);
    } catch (e, stackTrace) {
      // A fault in this client, not a refused request.
      _endCallAfterFailedHold(event.callId, e, stackTrace);
    }
  }

  void _endCallAfterFailedHold(String callId, Object error, StackTrace stackTrace) {
    callErrorReporter.handle(error, stackTrace, '__onMutationPerformSetHeld error');
    _callPeerConnectionManager.completeError(callId, error, stackTrace);
    add(_ResetStateEvent.completeCall(callId));
  }

  Future<void> __onMutationPerformSetMuted(_CallMutationEventPerformSetMuted event, Emitter<CallState> emit) async {
    if (state.isConferenced(event.callId)) {
      // The leg's own microphone left its connection when it joined the room,
      // so there is nothing there to silence: what the host speaks into is
      // the room. A mute for a leg is a mute of the room, and this is the
      // entrypoint the operating system's own call controls come through.
      //
      // Nothing in the notice says whether a person asked for it: the
      // platform reports a call's mute state for any reason at all, its own
      // republications and this client's own commands included, and a report
      // can be overtaken by a later intent while it is still on its way.
      // What tells them apart is what was asked for and in which order, so a
      // report that answers the oldest command still outstanding for that
      // call is that command coming home and nothing more.
      if (!_legMutes.consume(event.callId, event.muted) && event.muted != state.conference.selfMuted) {
        await _setRoomMuted(event.muted, emit);
      }
    } else {
      await _setMicrophoneAttached(event.callId, attached: !event.muted);
    }

    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(muted: event.muted);
      }),
    );
  }

  Future<void> __onMutationPerformSendDTMF(_CallMutationEventPerformSendDTMF event, Emitter<CallState> emit) async {
    await state.performOnActiveCall(event.callId, (activeCall) async {
      final peerConnection = await _callPeerConnectionManager.retrieve(event.callId);
      if (peerConnection == null) {
        _logger.warning('__onMutationPerformSendDTMF: peerConnection is null');
      } else {
        final senders = await peerConnection.senders;
        try {
          final audioSender = senders.firstWhere((sender) {
            final track = sender.track;
            if (track != null) return track.kind == 'audio';
            return false;
          });
          await audioSender.dtmfSender.insertDTMF(event.key);
        } on StateError catch (_) {
          _logger.warning('__onMutationPerformSendDTMF: can\'t send DTMF');
        }
      }
    });
  }

  Future<void> __onMutationPerformSetAudioDevice(
    _CallMutationEventPerformSetAudioDevice event,
    Emitter<CallState> emit,
  ) async {
    emit(state.copyWith(audioDevice: event.device));
  }

  Future<void> __onMutationControlStart(_CallMutationEventControlStart e, Emitter<CallState> emit) async {
    // De-duplicate retry taps on the same destination while a previous attempt
    // has not yet sent its SIP INVITE. Covers every pre-offer-sent outgoing
    // status (created / created-from-refer / connecting-to-signaling /
    // initializing-media / offer-preparing) so the dedup catches both the
    // parked cold-start case and the short window before callkeep's perform
    // callback fires. Without this, each tap allocates the next idle line and
    // the user ends up with N parallel pending calls to the same number
    // instead of a single retry. WT-1554.
    final hasPendingToSameHandle = state.activeCalls.any(
      (c) =>
          c.direction == CallDirection.outgoing &&
          c.processingStatus.isPreOfferSent &&
          c.handle.value == e.handle.value,
    );
    if (hasPendingToSameHandle) {
      _logger.info(
        '__onMutationControlStart: ignoring duplicate tap, outgoing call to ${e.handle.value} already pending',
      );
      // Bring the user back to the pending call screen so the tap feels acknowledged.
      emit(state.copyWith(minimized: false));
      return;
    }

    int? line;
    if (e.fromNumber != null) {
      // Guest line is implied; signaling layer handles it without a line index.
      line = null;
    } else {
      line = state.pickOutgoingMainLine();
      if (line == null) {
        // Lines are known and all main lines are in use - fail fast.
        _logger.info('__onMutationControlStart no idle line');
        submitNotification(const GeneralUnableToCallNotification());
        return;
      }
    }

    /// If there is an active call, the call should be put on hold before making a new call.
    /// Or it will be ended automatically by platform (via callkeep:performEndAction).
    /// The conference room's legs are not among them - see [CallState.callIdsToHoldBeforeOutgoing].
    await Future.forEach(state.callIdsToHoldBeforeOutgoing, (String callId) async {
      await callkeep.setHeld(callId, onHold: true);
    });

    final callId = WebtritSignalingClient.generateCallId();
    final contactName = (await contactResolver.resolve(e.handle.value))?.maybeName;
    final displayName = contactName ?? e.displayName;

    final newCall = ActiveCall(
      direction: CallDirection.outgoing,
      line: line,
      callId: callId,
      handle: e.handle,
      displayName: displayName,
      video: e.video,
      fromNumber: e.fromNumber,
      fromReplaces: e.fromReplaces,
      createdTime: clock.now(),
      processingStatus: CallProcessingStatus.outgoingCreated,
    );
    emit(state.copyWithPushActiveCall(newCall).copyWith(minimized: false));

    final callkeepError = await callkeep.startCall(
      callId,
      e.handle,
      displayNameOrContactIdentifier: displayName,
      hasVideo: e.video,
      proximityEnabled: !e.video,
    );

    if (callkeepError != null) {
      if (callkeepError == CallkeepCallRequestError.selfManagedPhoneAccountNotRegistered) {
        CrashlyticsUtils.recordError(
          'CallBloc - __onMutationControlStart selfManagedPhoneAccountNotRegistered',
          information: ['callId: $callId', 'handle: ${e.handle.value}'],
        );
      } else {
        _logger.warning('__onMutationControlStart error: $callkeepError');
        onDiagnosticReportRequested(callId, callkeepError);
      }
      emit(state.copyWithPopActiveCall(callId));
    }
  }

  Future<void> __onMutationControlAnswer(_CallMutationEventControlAnswer e, Emitter<CallState> emit) async {
    final error = await callkeep.answerCall(e.callId);
    if (error != null) _logger.warning('__onMutationControlAnswer error: $error');
  }

  Future<void> __onMutationControlEnd(_CallMutationEventControlEnd e, Emitter<CallState> emit) async {
    // Cancel any queued signaling requests for this call immediately.
    // Handles the case where OutgoingCallRequest is still waiting in the queue
    // (no connection yet) — without this, it would be sent on reconnect,
    // causing the callee to see a phantom incoming call, and local cleanup
    // (ringback stop, PeerConnection disposal) would be delayed by the
    // 30-second queue timeout.
    _signalingModule.cancelRequestsByCallId(e.callId);

    final error = await callkeep.endCall(e.callId);
    // Handle the case where the local connection is no longer available,
    // sending the call completion event directly to the signaling.
    if (error == CallkeepCallRequestError.unknownCallUuid) {
      add(_CallPerformEvent.ended(e.callId));
    }
    if (error != null) _logger.warning('__onMutationControlEnd error: $error');
  }

  Future<void> __onMutationControlSetHeld(_CallMutationEventControlSetHeld e, Emitter<CallState> emit) async {
    final error = await callkeep.setHeld(e.callId, onHold: e.onHold);
    if (error != null) _logger.warning('__onMutationControlSetHeld error: $error');
  }

  Future<void> __onMutationControlSetMuted(_CallMutationEventControlSetMuted e, Emitter<CallState> emit) async {
    final error = await callkeep.setMuted(e.callId, muted: e.muted);
    if (error != null) _logger.warning('__onMutationControlSetMuted error: $error');
  }

  Future<void> __onMutationControlSendDTMF(_CallMutationEventControlSendDTMF e, Emitter<CallState> emit) async {
    final error = await callkeep.sendDTMF(e.callId, e.key);
    if (error != null) _logger.warning('__onMutationControlSendDTMF error: $error');
  }

  Future<void> __onMutationControlSwitchCamera(_CallMutationEventControlSwitchCamera e, Emitter<CallState> emit) async {
    final frontCamera = await state.performOnActiveCall(e.callId, (activeCall) {
      final videoTrack = activeCall.localStream?.getVideoTracks()[0];
      if (videoTrack != null) return Helper.switchCamera(videoTrack);
    });
    emit(
      state.copyWithMappedActiveCall(e.callId, (activeCall) {
        return activeCall.copyWith(frontCamera: frontCamera);
      }),
    );
  }

  /// Enables or disables the camera for the active call, using local track enable state.
  ///
  /// If its audiocall, try to upgrade to videocal using renegotiation
  /// by adding the tracks to the peer connection.
  /// after success [_createPeerConnection].onRenegotiationNeeded will fired accordingly to webrtc state
  /// then [__onCallSignalingEventAccepted] will be called as acknowledge of [UpdateRequest] with new remote jsep.
  ///
  /// **Mute Implementation Note:**
  /// Currently, this method implements a **"Soft Mute"** strategy by toggling
  /// [MediaStreamTrack.enabled] instead of a **"Hard Mute"** (changing
  /// [RTCRtpTransceiver] direction to [TransceiverDirection.RecvOnly]).
  ///
  /// **Reason:** It was observed that switching to `RecvOnly` causes the server
  /// to stop sending the *incoming* video stream to the client.
  /// This behavior suggests that the server infrastructure might interpret the cessation
  /// of outgoing RTP packets as a connection timeout or does not correctly handle
  /// the session modification in the current configuration. "Soft Mute" avoids this
  /// by keeping the channel active (sending black/empty frames).
  Future<void> __onMutationControlSetCameraEnabled(
    _CallMutationEventControlSetCameraEnabled e,
    Emitter<CallState> emit,
  ) async {
    final activeCall = state.retrieveActiveCall(e.callId);
    if (activeCall == null) return;
    final callId = e.callId;

    final localStream = activeCall.localStream;
    if (localStream == null) return;

    final currentVideoTrack = localStream.getVideoTracks().firstOrNull;
    if (currentVideoTrack != null) {
      currentVideoTrack.enabled = e.enabled;
      // A usable video track exists, so camera permission is granted: clear any
      // stale downgrade hint left from an earlier audio-only answer.
      emit(
        state.copyWithMappedActiveCall(callId, (call) => call.copyWith(video: e.enabled, videoPermissionDenied: false)),
      );
      // Soft mute changes no SDP, so the remote side cannot learn about the
      // camera state from the media plane - signal it explicitly (matters
      // most while the call is still ringing on the other end).
      _sendMediaState(activeCall, video: e.enabled);
      if (e.enabled) {
        await _mediaManager.onVideoEnabled(e.callId, speakerDevice: state.availableAudioDevices.getSpeaker);
      } else {
        final speakerActive = state.audioDevice?.type == CallAudioDeviceType.speaker;
        await _mediaManager.onVideoDisabled(
          e.callId,
          speakerActive: speakerActive,
          earpieceDevice: state.availableAudioDevices.getEarpiece,
        );
        await callkeep.reportUpdateCall(e.callId, hasVideo: false);
      }
      return;
    }

    if (activeCall.held == true) return;

    final peerConnection = await _callPeerConnectionManager.retrieve(e.callId);
    if (peerConnection == null) return;

    // Randomize a little bit to avoid double upgrade collisions
    final preDelay = Random().nextInt(2000);
    await Future.delayed(Duration(milliseconds: preDelay));

    try {
      final newVideoTrack = await userMediaBuilder.ensureVideoTrack(localStream, frontCamera: activeCall.frontCamera);
      if (newVideoTrack == null) {
        submitNotification(const CallUserMediaErrorNotification());
        await _syncVideoPermissionDenied(callId, emit);
        return;
      }

      final senders = await peerConnection.getSenders();
      final videoSender = senders.firstWhereOrNull((s) => s.track?.kind == 'video');

      if (videoSender != null) {
        await videoSender.replaceTrack(newVideoTrack);
      } else {
        final videoSenderResult = await peerConnection.safeAddTrack(newVideoTrack, localStream);
        _checkSenderResult(videoSenderResult, 'video');
      }

      emit(
        state.copyWithMappedActiveCall(e.callId, (call) => call.copyWith(video: true, videoPermissionDenied: false)),
      );
      // The added track reaches the remote side only after renegotiation
      // completes (post-answer for a ringing call) - signal the camera state
      // explicitly so the remote UI can reflect the upgrade right away.
      _sendMediaState(activeCall, video: true);
      await _mediaManager.onVideoEnabled(e.callId, speakerDevice: state.availableAudioDevices.getSpeaker);
      await callkeep.reportUpdateCall(e.callId, hasVideo: true);
    } on UserMediaError catch (e) {
      _logger.warning('__onMutationControlSetCameraEnabled cant enable: $e');
      submitNotification(const CallUserMediaErrorNotification());
      await _syncVideoPermissionDenied(callId, emit);
    }
  }

  /// Re-derives [ActiveCall.videoPermissionDenied] from the live camera
  /// permission after a camera-enable attempt fails. Clears a stale hint once
  /// the user has granted access, and keeps it when permission is still denied,
  /// so the camera button never misreports the reason video is unavailable.
  Future<void> _syncVideoPermissionDenied(String callId, Emitter<CallState> emit) async {
    final denied = !(await _isCameraPermissionGranted());
    // The check awaits, so the call may have ended meanwhile; skip the emit then.
    if (state.retrieveActiveCall(callId) == null) return;
    emit(state.copyWithMappedActiveCall(callId, (call) => call.copyWith(videoPermissionDenied: denied)));
  }

  /// Live camera-permission check that never throws. A failing permission plugin
  /// (e.g. a `PlatformException`) must not break call answering or camera
  /// toggling, so the unknown case is treated as granted: we never block the
  /// flow and never raise a misleading "permission denied" hint.
  Future<bool> _isCameraPermissionGranted() async {
    try {
      return await isCameraPermissionGranted?.call() ?? true;
    } catch (e, s) {
      _logger.warning('camera permission check failed, assuming granted', e, s);
      return true;
    }
  }

  Future<void> __onMutationControlBlindTransfer(
    _CallMutationEventControlBlindTransfer e,
    Emitter<CallState> emit,
  ) async {
    // Commented out to emphasize that the check is disabled by intention
    // to not add it again in future, to see why open ticket [WT-1160]
    // final isNumberAlreadyConnected = state.activeCalls.any((call) => call.handle.value == event.number);
    // if (isNumberAlreadyConnected) {
    //   submitNotification(ActiveLineBlindTransferWarningNotification());
    //   return;
    // }

    try {
      final transferRequest = TransferRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        line: e.line,
        callId: e.callId,
        number: e.number,
      );

      await _signalingModule.execute(transferRequest);

      var newState = state.copyWith(minimized: false);
      newState = newState.copyWithMappedActiveCall(e.callId, (activeCall) {
        final transfer = Transfer.blindTransferTransferSubmitted(toNumber: e.number);
        return activeCall.copyWith(transfer: transfer);
      });
      emit(newState);

      await callkeep.reportUpdateCall(
        state.activeCalls.current.callId,
        proximityEnabled: state.shouldListenToProximity,
      );

      final callBeingTransferred = state.retrieveActiveCall(e.callId);
      if (callBeingTransferred?.speakerOnBeforeMinimize == true) {
        final speakerDevice = state.availableAudioDevices.getSpeaker;
        if (speakerDevice != null) {
          add(CallControlEvent.audioDeviceSet(e.callId, speakerDevice));
        } else {
          _logger.warning('__onMutationControlBlindTransfer: speaker was on before minimize but its not available now');
        }
      }

      // After request succesfully submitted, transfer flow will continue
      // by TransferringEvent event from anus and handled in [_CallSignalingEventTransferring]
      // that means that call transfering is now in progress
    } on NotConnectedException {
      _logger.warning('__onMutationControlBlindTransfer: not connected, rollback and survive');
      emit(state.copyWithMappedActiveCall(e.callId, (activeCall) => activeCall.copyWith(transfer: null)));
    } on WebtritSignalingTransactionTimeoutException {
      _logger.warning('__onMutationControlBlindTransfer: transaction timeout, rollback and survive');
      emit(state.copyWithMappedActiveCall(e.callId, (activeCall) => activeCall.copyWith(transfer: null)));
    } catch (e, s) {
      callErrorReporter.handle(e, s, '__onMutationControlBlindTransfer request error:');
    }
  }

  Future<void> __onMutationControlAttendedTransfer(
    _CallMutationEventControlAttendedTransfer e,
    Emitter<CallState> emit,
  ) async {
    final referorCall = e.referorCall;
    final replaceCall = e.replaceCall;

    // A self-referential transfer (a REFER whose Replaces points at its own
    // dialog) is never valid and the backend rejects it; drop the request
    // instead of sending it, but surface it the same way a rejected request
    // would be so a wiring regression never looks like a dead button.
    if (referorCall.callId == replaceCall.callId) {
      callErrorReporter.handle(
        StateError('attended transfer: referorCall == replaceCall (${referorCall.callId})'),
        StackTrace.current,
        '__onMutationControlAttendedTransfer request error:',
      );
      return;
    }

    try {
      final transferRequest = TransferRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        line: referorCall.line,
        callId: referorCall.callId,
        number: replaceCall.handle.normalizedValue(),
        replaceCallId: replaceCall.callId,
      );

      await _signalingModule.execute(transferRequest);

      emit(
        state.copyWithMappedActiveCall(referorCall.callId, (activeCall) {
          final transfer = Transfer.attendedTransferTransferSubmitted(replaceCallId: replaceCall.callId);
          return activeCall.copyWith(transfer: transfer);
        }),
      );

      // After request succesfully submitted, transfer flow will continue
      // by TransferringEvent event from anus and handled in [_CallSignalingEventTransferring]
      // that means that call transfering is now in progress
    } on NotConnectedException {
      _logger.warning('__onMutationControlAttendedTransfer: not connected, rollback and survive');
      emit(state.copyWithMappedActiveCall(referorCall.callId, (activeCall) => activeCall.copyWith(transfer: null)));
    } on WebtritSignalingTransactionTimeoutException {
      _logger.warning('__onMutationControlAttendedTransfer: transaction timeout, rollback and survive');
      emit(state.copyWithMappedActiveCall(referorCall.callId, (activeCall) => activeCall.copyWith(transfer: null)));
    } catch (e, s) {
      callErrorReporter.handle(e, s, '__onMutationControlAttendedTransfer request error:');
    }
  }

  Future<void> __onMutationControlAttendedApprove(
    _CallMutationEventControlAttendedApprove e,
    Emitter<CallState> emit,
  ) async {
    final newHandle = CallkeepHandle.number(e.referTo);
    final callId = WebtritSignalingClient.generateCallId();

    final error = await callkeep.startCall(callId, newHandle, hasVideo: false, proximityEnabled: true);

    if (error != null) {
      _logger.warning('__onMutationControlAttendedApprove error: $error');
      return;
    }

    final newCall = ActiveCall(
      direction: CallDirection.outgoing,
      line: state.retrieveIdleLine() ?? _kUndefinedLine,
      callId: callId,
      handle: newHandle,
      fromReferId: e.referId,
      video: false,
      createdTime: clock.now(),
      processingStatus: CallProcessingStatus.outgoingCreatedFromRefer,
    );

    emit(state.copyWithPushActiveCall(newCall).copyWith(minimized: false));
  }

  Future<void> __onMutationControlAttendedDecline(
    _CallMutationEventControlAttendedDecline e,
    Emitter<CallState> emit,
  ) async {
    final call = state.retrieveActiveCall(e.callId);
    if (call == null) return;

    try {
      final declineRequest = DeclineRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        line: call.line,
        callId: e.callId,
        referId: e.referId,
      );

      await _signalingModule.execute(declineRequest);

      emit(
        state.copyWithMappedActiveCall(e.callId, (activeCall) {
          return activeCall.copyWith(transfer: null);
        }),
      );
    } catch (e, s) {
      callErrorReporter.handle(e, s, '__onMutationControlAttendedDecline request error:');
    }
  }

  Future<void> __onMutationSignalingIncoming(_CallMutationEventSignalingIncoming event, Emitter<CallState> emit) async {
    // A call restored from a log is answered as the caller left it: an offer
    // with video whose camera was turned off since is an audio call, the same
    // as the live media-state handler would have made it. The rule lives in
    // [ActiveCall.incomingVideo], shared with the fast path above.
    final remoteVideo = event.remoteVideo;
    final video = ActiveCall.incomingVideo(event.jsep, remoteVideo);
    final handle = CallkeepHandle.number(event.caller);
    final displayName = event.callerDisplayName;

    final error = await callkeep.reportNewIncomingCall(event.callId, handle, displayName: displayName, hasVideo: video);

    // Check if a call instance already exists in the callkeep, which might have been added via push notifications
    // before the signaling was initialized.
    final callAlreadyExists = error == CallkeepIncomingCallError.callIdAlreadyExists;

    // Check if a call instance already exists in the callkeep, which might have been added via push notifications
    // before the signaling  was initialized. Also, check if the call status has been changed to "answered,"
    // indicating it can be triggered by pressing the answer button in the notification.
    final callAlreadyAnswered = error == CallkeepIncomingCallError.callIdAlreadyExistsAndAnswered;

    // Check if a call instance already terminated in the callkeep, which might have been added via push notifications
    // before the signaling  was initialized. Also, check if the call status has been changed to "terminated"
    // indicating it can be triggered by pressing the decline button in the notification or flutter ui.
    final callAlreadyTerminated = error == CallkeepIncomingCallError.callIdAlreadyTerminated;

    if (error != null && !callAlreadyExists && !callAlreadyAnswered && !callAlreadyTerminated) {
      // reportNewIncomingCall rejected the call with an unexpected error:
      //   - Android: callRejectedBySystem — Telecom already has a call in RINGING state
      //     (AOSP behaviour, Android 11+), or the 5 s Telecom confirmation timeout elapsed.
      //   - iOS: unknown / unentitled / internal — rare CXProvider failure on the
      //     signaling-path reportNewIncomingCall (not the VoIP-push path).
      //
      // The call was never presented to the user, so performEndCall will NOT fire.
      // Notify the server immediately so the remote party is not left ringing.
      // _signalingModule.execute returns null when disconnected — the ?. handles that safely.
      _logger.warning(
        '__onMutationSignalingIncoming: reportNewIncomingCall error=$error '
        '(callId: ${event.callId}, line: ${event.line}) — sending decline',
      );
      try {
        await _dispatchTerminationRequest(
          request: QueuedTerminationRequest(
            type: QueuedTerminationRequestType.decline,
            line: event.line,
            callId: event.callId,
          ),
          source: '__onMutationSignalingIncoming',
        );
      } catch (e, s) {
        callErrorReporter.handle(e, s, '__onMutationSignalingIncoming declineRequest error');
      }
      return;
    }

    final transfer = (event.referredBy != null && event.replaceCallId != null)
        ? InviteToAttendedTransfer(replaceCallId: event.replaceCallId!, referredBy: event.referredBy!)
        : null;

    ActiveCall? activeCall = state.retrieveActiveCall(event.callId);

    if (activeCall != null) {
      // withIncomingOffer preserves an already-stored offer when the server
      // re-delivers the IncomingCallEvent without a jsep (e.g. a state-sync
      // message after reconnect that omits the SDP). Overwriting with null
      // here would silently clear the offer and cause
      // __onCallPerformEventAnswered to time out waiting for it.
      if (event.jsep == null && activeCall.incomingOffer != null) {
        _logger.info(
          '__onMutationSignalingIncoming: keeping existing offer — '
          'incoming event has no jsep '
          'callId=${event.callId} status=${activeCall.processingStatus}',
        );
      }
      if (event.jsep != null && activeCall.incomingOffer != null) {
        _logger.info(
          '__onMutationSignalingIncoming: replacing existing offer with new one '
          'callId=${event.callId} status=${activeCall.processingStatus}',
        );
      }
      activeCall = activeCall
          .withIncomingOffer(event.jsep, line: event.line, remoteVideo: remoteVideo)
          .copyWith(handle: handle, displayName: displayName, transfer: transfer);
      emit(state.copyWithMappedActiveCall(event.callId, (_) => activeCall!));
    } else {
      activeCall = ActiveCall(
        direction: CallDirection.incoming,
        line: event.line,
        callId: event.callId,
        handle: handle,
        displayName: displayName,
        video: video,
        remoteCameraEnabled: remoteVideo,
        createdTime: clock.now(),
        transfer: transfer,
        incomingOffer: event.jsep,
        processingStatus: CallProcessingStatus.incomingFromOffer,
      );
      emit(state.copyWithPushActiveCall(activeCall));
    }

    // Ensure to continue processing call if push action(answer, decline) pressed but app was'nt active at this moment
    // typically happens on android from terminated or background state,
    // on ios it produce second call of [__onCallPerformEventAnswered] or [__onCallPerformEventEnded]
    // so make sure to guard it from race conditions
    _logger.warning(
      '__onMutationSignalingIncoming: callId=${event.callId} '
      'callAlreadyExists=$callAlreadyExists '
      'callAlreadyAnswered=$callAlreadyAnswered '
      'callAlreadyTerminated=$callAlreadyTerminated '
      'hasOffer=${event.jsep != null} '
      'status=${state.retrieveActiveCall(event.callId)?.processingStatus}',
    );

    await Future.delayed(Duration.zero);
    if (callAlreadyAnswered) add(CallControlEvent.answered(event.callId));
    if (callAlreadyTerminated) add(CallControlEvent.ended(event.callId));
  }

  Future<void> __onMutationSignalingAccepted(_CallMutationEventSignalingAccepted event, Emitter<CallState> emit) async {
    ActiveCall? call = state.retrieveActiveCall(event.callId);
    if (call == null) return;

    final initialAccept = call.acceptedTime == null;
    final outgoing = call.direction == CallDirection.outgoing;
    final jsep = event.jsep;

    if (initialAccept) {
      call = call.copyWith(processingStatus: CallProcessingStatus.connected, acceptedTime: clock.now());

      if (outgoing) {
        await _ringback.stop(event.callId);
        await callkeep.reportConnectedOutgoingCall(event.callId);
      }
    } else {
      call = call.copyWith(updating: false);
    }

    emit(state.copyWithMappedActiveCall(event.callId, (_) => call!));

    final peerConnection = await _callPeerConnectionManager.retrieve(event.callId);
    if (jsep != null && peerConnection != null) {
      final remoteDescription = jsep.toDescription();
      sdpSanitizer?.apply(remoteDescription);

      // An accepted event with an answer jsep is only valid when the PC is in
      // have-local-offer state. During a glare race the local offer may have
      // been rolled back in __onCallSignalingEventCallUpdating, leaving the PC in
      // stable. Applying a stale answer in stable throws a wrong-state error,
      // so skip it and rely on libwebrtc re-firing onRenegotiationNeeded once
      // the PC returns to stable.
      final signalingState = peerConnection.signalingState;
      if (remoteDescription.type == 'answer' && signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        _logger.warning(
          '__onMutationSignalingAccepted: skipping setRemoteDescription(answer) '
          'because signalingState=$signalingState (expected have-local-offer).',
        );
        return;
      }

      _logger.info('__onMutationSignalingAccepted answer SDP (callId=${event.callId}, initialAccept=$initialAccept)');
      _logger.infoPretty(remoteDescription.sdp, tag: '__onMutationSignalingAccepted answer SDP');

      try {
        await peerConnection.setRemoteDescription(remoteDescription);
        final transceivers = await peerConnection.getTransceivers();
        for (final t in transceivers) {
          final dir = await t.getDirection();
          final curDir = await t.getCurrentDirection();
          _logger.info(
            '__onMutationSignalingAccepted transceiver: mid=${t.mid} '
            'direction=$dir currentDirection=$curDir',
          );
        }
      } on String catch (e) {
        _logger.warning('__onMutationSignalingAccepted: setRemoteDescription failed ($e)');
      }
    }
  }

  Future<void> __onMutationSignalingHangup(_CallMutationEventSignalingHangup event, Emitter<CallState> emit) async {
    _ringback.stopUnawaited(event.callId);
    _signalingModule.cancelRequestsByCallId(event.callId);

    ActiveCall? call = state.retrieveActiveCall(event.callId);
    if (call == null) {
      // The call was never registered in state - the signaling hangup won the race against
      // a still-connecting incoming call (e.g. a push->foreground handoff where the caller hung
      // up before CallBloc was seeded). Report the end to callkeep with the missedWhileConnecting
      // reason: it marks the call terminated AND flags that the app never presented this call, so a
      // late connection-state replay that re-drives reportNewIncomingCall for the same callId is
      // rejected (no ghost). The flag is specific to this never-presented case, so a transfer-back
      // (which reuses a call the app did know) is unaffected. reportEndCall does not invoke
      // performEndCall and sends no server request - signaling already terminated the call.
      await callkeep.reportEndCall(event.callId, '', CallkeepEndCallReason.missedWhileConnecting);
      return;
    }

    if (call.wasHungUp == false) {
      call = call.copyWith(hungUpTime: clock.now());
      _addToRecents(call);
      // Publish it before the teardown awaits below: until the call is popped
      // the state is what every other queue reads, and a provisional event
      // arriving meanwhile must not treat this call as still ringing.
      emit(state.copyWithMappedActiveCall(event.callId, (_) => call!));
    }

    final code = SignalingResponseCode.values.byCode(event.code);
    var endReason = CallkeepEndCallReason.remoteEnded;
    if (call.direction == CallDirection.incoming && !call.wasAccepted) {
      if (code == SignalingResponseCode.declineCall) endReason = CallkeepEndCallReason.declinedElsewhere;
      if (code == SignalingResponseCode.requestTerminated) endReason = CallkeepEndCallReason.unanswered;
      if (Platform.isAndroid && code != SignalingResponseCode.declineCall) {
        _onMissedCall(event.callId, call.displayName ?? call.handle.value);
      }
    }

    // Invoke _releaseLocalStream before disposePeerConnection to ensure that the local media tracks are stopped and released properly.
    // or there might be a record indicator stuck after call
    await _releaseLocalStream(call.localStream).catchError((e) {
      _logger.warning('__onMutationSignalingHangup: _releaseLocalStream error $e');
    });
    await _callPeerConnectionManager.disposePeerConnection(event.callId).catchError((e) {
      _logger.warning('__onMutationSignalingHangup: disposePeerConnection error $e');
    });

    emit(state.copyWithPopActiveCall(event.callId));

    await callkeep.reportEndCall(event.callId, call.displayName ?? call.handle.value, endReason);
  }

  Future<void> __onMutationSignalingCallUpdating(
    _CallMutationEventSignalingCallUpdating event,
    Emitter<CallState> emit,
  ) async {
    final handle = CallkeepHandle.number(event.caller);
    final displayName = event.callerDisplayName;
    final activeCall = state.retrieveActiveCall(event.callId);
    if (activeCall == null) return;

    await callkeep.reportUpdateCall(
      event.callId,
      handle: handle,
      displayName: displayName ?? activeCall.displayName,
      hasVideo: event.jsep?.hasVideo ?? activeCall.video,
      proximityEnabled: state.shouldListenToProximity,
    );

    try {
      final jsep = event.jsep;
      if (jsep != null) {
        final remoteDescription = jsep.toDescription();
        sdpSanitizer?.apply(remoteDescription);
        _logger.infoPretty(remoteDescription.sdp, tag: '__onMutationSignalingCallUpdating received new offer SDP');
        await state.performOnActiveCall(event.callId, (activeCall) async {
          final peerConnection = await _callPeerConnectionManager.retrieve(event.callId);
          if (peerConnection == null) {
            _logger.warning('__onMutationSignalingCallUpdating: peerConnection is null - most likely some state issue');
          } else {
            // Optimistic pre-check for glare condition. May be stale because
            // flutter_webrtc caches signalingState and updates it only when the
            // onSignalingState callback fires - not when setLocalDescription completes.
            // The try-catch below is the authoritative fallback.
            final signalingState = peerConnection.signalingState;
            if (signalingState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
              _logger.warning(
                '__onMutationSignalingCallUpdating: glare detected via pre-check (signalingState=$signalingState), rolling back local offer',
              );
              await peerConnection.setLocalDescription(RTCSessionDescription('', 'rollback'));
            }

            try {
              await peerConnection.setRemoteDescription(remoteDescription);
            } on String catch (e) {
              // Glare condition: signalingState pre-check was stale (flutter_webrtc
              // caching), setLocalDescription completed on the native side but the
              // Dart-side callback had not yet fired. Roll back and retry.
              if (e.contains('have-local-offer')) {
                _logger.warning(
                  '__onMutationSignalingCallUpdating: glare detected via catch ($e), rolling back local offer and retrying',
                );
                await peerConnection.setLocalDescription(RTCSessionDescription('', 'rollback'));
                await peerConnection.setRemoteDescription(remoteDescription);
              } else {
                rethrow;
              }
            }

            // Apply policy AFTER setRemoteDescription so that any stopped transceivers
            // from a previous failed negotiation are re-activated by the remote offer
            // before addTrack runs. If addTrack runs first, it creates a duplicate
            // transceiver (RFC 8829: stopped transceivers are ineligible for reuse),
            // which causes setLocalDescription to fail with a mid mismatch.
            final localStream = activeCall.localStream;
            final hadLocalVideo = localStream?.getVideoTracks().any((t) => t.enabled) ?? false;
            if (localStream != null) {
              await peerConnectionPolicyApplier?.apply(
                peerConnection,
                hasRemoteVideo: jsep.hasVideo,
                localStream: localStream,
                frontCamera: activeCall.frontCamera,
                strategy: VideoOfferStrategy.inactiveSendrecv,
              );
            }

            // According to RFC 8829 5.6 (https://datatracker.ietf.org/doc/html/rfc8829#section-5.6),
            // localDescription should be set before sending the answer to transition into stable state.
            final localDescription = await peerConnection.createAnswer({});
            sdpMunger?.apply(localDescription);
            _logger.infoPretty(localDescription.sdp, tag: '__onMutationSignalingCallUpdating created answer SDP');

            await peerConnection.setLocalDescription(localDescription);

            final transaction = WebtritSignalingClient.generateTransactionId();

            await _signalingModule.execute(
              UpdateRequest(
                transaction: transaction,
                line: activeCall.line,
                callId: activeCall.callId,
                jsep: localDescription.toMap(),
              ),
            );

            // Some events have double comfirmation like this,
            // so lets wait for the final result to make sure the update request is processed, and only then pass mutation queue to next event
            final result = await _signalingModule.events
                .firstWhere((event) {
                  if (event is SignalingProtocolEvent && event.event is SessionEvent) {
                    final sessionEvent = event.event as SessionEvent;
                    if (sessionEvent.transaction == transaction) return true;
                  }
                  return false;
                })
                .then((event) => (event as SignalingProtocolEvent).event)
                .timeout(const Duration(seconds: 10));

            _logger.info('__onMutationSignalingCallUpdating: received response for update request: $result');

            if (result is UpdatedEvent) {
              emit(state.copyWithMappedActiveCall(activeCall.callId, (call) => call.copyWith(updating: false)));
            } else if (result is UpdatingEvent) {
              emit(state.copyWithMappedActiveCall(activeCall.callId, (call) => call.copyWith(updating: true)));
            } else if (result is CallErrorEvent) {
              emit(state.copyWithMappedActiveCall(activeCall.callId, (call) => call.copyWith(updating: false)));
              _logger.warning(
                '__onCallSignalingEventCallError: received CallErrorEvent for update request: code=${result.code} reason="${result.reason}"',
              );

              // May help to recover from the error by renegotiating the call again
              // According to sip 491 error resolution spec, randomize the delay before retrying to avoid potential collision
              final delaySeconds = 2 + Random().nextInt(8);
              Future.delayed(Duration(seconds: delaySeconds), () => _scheduleIceRestart(activeCall.callId));
              _logger.info('__onCallSignalingEventCallError: dispatch renegotiation after (delay: $delaySeconds)');
            } else {
              throw result;
            }

            if (!hadLocalVideo && localStream?.getVideoTracks().firstOrNull?.enabled == false) {
              emit(
                state.copyWithMappedActiveCall(event.callId, (activeCall) {
                  return activeCall.copyWith(localStream: localStream, video: false);
                }),
              );
            }
          }
        });
      }
    } catch (e, s) {
      callErrorReporter.handle(e, s, '__onMutationSignalingCallUpdating && jsep error:');
      _callPeerConnectionManager.completeError(event.callId, e);
      add(_ResetStateEvent.completeCall(event.callId));
    }
  }

  /// Performs a safe renegotiation by first checking if the active call and peer connection still exist before proceeding and no "updating" state is detected on the call.
  ///
  /// Designed to be triggered in response to the `onRenegotiationNeeded` or manually for scenarios like:
  /// - boost call recovery after network switch
  ///   (currently WebRTC built-in detector triggers after 10-15s, better to synchronize it with our signaling reconnection)
  /// - force renegotiation after double network
  ///   (when device had poor GSM, and then WIFI connected as second interface
  ///   but WebRTC prefer stay on GSM network interface instead of switching to WIFI, so we can trigger renegotiation to make WebRTC switch to WIFI)
  /// - if "STALLED" rtp traffic is detected
  ///   (of something unexpected happens with RTP stream, will be good to try to recorer it with renegotiation)
  /// - you name it..
  Future<void> __onMutationRenegotiate(_CallMutationEventRenegotiate e, Emitter<CallState> emit) async {
    final pc = await _callPeerConnectionManager.retrieve(e.callId);
    if (pc == null) {
      _logger.info('__onMutationRenegotiate: pc disposed, skipping renegotiation');
      return;
    }

    // pc.signalingState is a Dart-side cache populated only after the first
    // native state event. On a freshly created PC the event may not have
    // arrived yet; force a platform round-trip in that case so the guard
    // gets the real native state instead of guessing what null means.
    final cachedSigState = pc.signalingState;
    final sigState = cachedSigState ?? await pc.getSignalingState();
    _logger.info('__onMutationRenegotiate: sigState=$sigState (cache=$cachedSigState)');
    if (sigState != RTCSignalingState.RTCSignalingStateStable) {
      _logger.fine(() => '__onMutationRenegotiate: pc signalingState is $sigState, skipping renegotiation');
      return;
    }

    // Look up the active call up-front so we can gate the createOffer constraints
    // on the actual media policy (audio-only vs video). The existing null/state
    // guards below still run after the offer to preserve the original race semantics.
    final renegotiateCall = state.retrieveActiveCall(e.callId);
    final renegotiateHasVideo = renegotiateCall?.video ?? false;

    // Pass explicit OfferToReceive* constraints so the underlying flutter-webrtc
    // layer does not silently add a recvonly video transceiver as a side-effect
    // of createOffer({}) for an audio-only call. Without this, an audio-only
    // restoration produces a BUNDLE 0 1 offer (m=audio + m=video recvonly), and
    // the next renegotiate cycle drifts the mids to 2/3 — which Janus then
    // answers with mid:0 and libwebrtc rejects on mid mismatch, killing audio.
    final offerCandidate = await pc.createOffer(<String, dynamic>{
      'mandatory': <String, dynamic>{'OfferToReceiveAudio': true, 'OfferToReceiveVideo': renegotiateHasVideo},
      'optional': <dynamic>[],
    });

    // Note: prepare all asychronous info before checking synchrounous state below
    // to avoid races as possible,
    // for example:
    // - while [await _callPeerConnectionManager.retrieve, await pc.createOffer], activeCall.updating or signalingConnected can be changed

    final activeCall = state.retrieveActiveCall(e.callId);
    if (activeCall == null) {
      _logger.info('__onMutationRenegotiate: activeCall disposed, skipping renegotiation');
      return;
    }

    if (activeCall.line == null || activeCall.line == _kUndefinedLine) {
      _logger.info('__onMutationRenegotiate: activeCall line is ${activeCall.line}, skipping renegotiation');
      return;
    }

    if (activeCall.processingStatus.hasPeerConnectionReady == false) {
      _logger.info(
        '__onMutationRenegotiate: activeCall processingStatus is ${activeCall.processingStatus}, skipping renegotiation',
      );
      return;
    }

    // Warning, this code block will executes even in case when app has no connection at all
    // Example1:
    // user turn off all network interfaces >> __onPeerConnectionEventIceConnectionStateChanged >> RTCIceConnectionStateFailed >> peerConnection.restartIce() >> onRenegotiationNeeded >> __onMutationRenegotiate
    //
    // so its important to prevent it from creating new offer and send it to nowhere or it will lead to hasLocalOffer stuck.
    // Dont forget to invoke __onMutationRenegotiate manualy when signaling reconnected to make sure the new offer will be sended
    //
    final signalingConnected = state.isSignalingEstablished;
    if (!signalingConnected) {
      _logger.info('__onMutationRenegotiate: signaling not connected, skipping renegotiation');
      return;
    }

    // If call already in updating state, mostly by remote renegetiation, hold, transfer etc..
    // skip it but schedule another renegotiation in 1 second later to ensure the pending one is finished
    if (activeCall.updating) {
      await Future.delayed(Duration(seconds: 1));
      _logger.info('__onMutationRenegotiate: activeCall is updating, retrying renegotiation');
      add(_CallMutationEventRenegotiate(e.callId, e.lineId));
    }

    try {
      final offer = offerCandidate;
      sdpMunger?.apply(offer);
      _logger.infoPretty(offer.sdp, tag: 'onRenegotiationNeeded offer SDP (callId=${e.callId}):');
      await pc.setLocalDescription(offer);

      final transaction = WebtritSignalingClient.generateTransactionId();

      final updateRequest = UpdateRequest(
        transaction: transaction,
        line: activeCall.line,
        callId: e.callId,
        jsep: offer.toMap(),
      );
      await _signalingModule.execute(updateRequest);

      // Some events have double comfirmation like this,
      // so lets wait for the final result to make sure the update request is processed, and only then pass mutation queue to next event
      final result = await _signalingModule.events
          .firstWhere((event) {
            if (event is SignalingProtocolEvent && event.event is SessionEvent) {
              final sessionEvent = event.event as SessionEvent;
              if (sessionEvent.transaction == transaction) return true;
            }
            return false;
          })
          .then((event) => (event as SignalingProtocolEvent).event)
          .timeout(const Duration(seconds: 10));

      _logger.info('__onMutationSignalingCallUpdating: received response for update request: $result');

      if (result is UpdatedEvent) {
        emit(state.copyWithMappedActiveCall(activeCall.callId, (call) => call.copyWith(updating: false)));
      } else if (result is UpdatingEvent) {
        emit(state.copyWithMappedActiveCall(activeCall.callId, (call) => call.copyWith(updating: true)));
      } else if (result is CallErrorEvent) {
        _logger.warning(
          '__onCallSignalingEventCallError: received CallErrorEvent for update request: code=${result.code} reason="${result.reason}"',
        );

        emit(state.copyWithMappedActiveCall(activeCall.callId, (call) => call.copyWith(updating: false)));
        // May help to recover from the error by renegotiating the call again
        // According to sip 491 error resolution spec, randomize the delay before retrying to avoid potential collision
        final delaySeconds = 2 + Random().nextInt(8);
        Future.delayed(Duration(seconds: delaySeconds), () => _scheduleIceRestart(activeCall.callId));
        _logger.info('__onCallSignalingEventCallError: dispatch renegotiation after (delay: $delaySeconds)');
      } else {
        throw result;
      }
    } catch (er, st) {
      callErrorReporter.handle(er, st, '__onMutationRenegotiate failed for callId=${e.callId}');
      _callPeerConnectionManager.completeError(activeCall.callId, er, st);
      add(_ResetStateEvent.completeCall(activeCall.callId));
    }
  }

  Future<void> __onMutationTrickleIce(_CallMutationEventTrickleIce event, Emitter<CallState> emit) async {
    final callId = event.callId;

    final activeCall = state.retrieveActiveCall(callId);
    if (activeCall == null) return;
    if (activeCall.wasHungUp) return;

    try {
      final iceTrickleRequest = IceTrickleRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        line: activeCall.line,
        candidate: event.candidate.toMap(),
      );
      await _signalingModule.execute(iceTrickleRequest);
    } on NotConnectedException {
      _logger.warning('__onMutationTrickleIce: not connected, let call survive');
    } on WebtritSignalingTransactionTimeoutException {
      _logger.warning('__onMutationTrickleIce: transaction timeout, let call survive');
    } catch (e, stackTrace) {
      callErrorReporter.handle(e, stackTrace, '__onMutationTrickleIce error');
      _callPeerConnectionManager.completeError(callId, e, stackTrace);
      add(_ResetStateEvent.completeCall(callId));
    }
  }

  Future<void> __onMutationIceGatheringComplete(
    _CallMutationEventIceGatheringComplete event,
    Emitter<CallState> emit,
  ) async {
    final callId = event.callId;
    final activeCall = state.retrieveActiveCall(callId);
    if (activeCall == null) return;
    if (activeCall.wasHungUp) return;

    try {
      final iceTrickleRequest = IceTrickleRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        line: activeCall.line,
        candidate: null,
      );
      await _signalingModule.execute(iceTrickleRequest);
    } on NotConnectedException {
      _logger.warning('__onMutationIceGatheringComplete: not connected, let call survive');
    } on WebtritSignalingTransactionTimeoutException {
      _logger.warning('__onMutationIceGatheringComplete: transaction timeout, let call survive');
    } catch (e, stackTrace) {
      callErrorReporter.handle(e, stackTrace, '__onMutationIceGatheringComplete error');
      _callPeerConnectionManager.completeError(callId, e, stackTrace);
      add(_ResetStateEvent.completeCall(callId));
    }
  }

  Future<void> __onMutationIceConnectionFailed(
    _CallMutationEventIceConnectionFailed event,
    Emitter<CallState> emit,
  ) async {
    try {
      final activeCall = state.retrieveActiveCall(event.callId);
      if (activeCall == null) return;
      if (activeCall.wasHungUp) return;

      final peerConnection = await _callPeerConnectionManager.retrieve(event.callId);
      if (peerConnection == null) return;
      final pcState = peerConnection.signalingState;
      _logger.warning('__onMutationIceConnectionFailed: ICE failed, pcState: $pcState');
      if (pcState == RTCSignalingState.RTCSignalingStateStable) {
        // Will trigger [onPeerConnectionEventRenegotiationNeeded]
        // No need to create and send a new offer here, as the renegotiation flow will handle that.
        await peerConnection.restartIce();
      }
    } catch (e, stackTrace) {
      callErrorReporter.handle(e, stackTrace, '__onMutationIceConnectionFailed error');
    }
  }

  Future<void> __onMutationRestartIce(_CallMutationEventRestartIce event, Emitter<CallState> emit) async {
    final activeCall = state.retrieveActiveCall(event.callId);
    if (activeCall == null) {
      _logger.warning('__onMutationRestartIce: active call not found, skipping ICE restart');
      return;
    }

    if (activeCall.processingStatus.hasPeerConnectionReady == false) {
      _logger.warning('__onMutationRestartIce: call is not in connected state, skipping ICE restart');
      return;
    }

    final pc = await _callPeerConnectionManager.retrieve(event.callId);
    if (pc == null) {
      _logger.warning('__onMutationRestartIce: peer connection not found, skipping ICE restart');
      return;
    }
    _logger.info('__onMutationRestartIce: restarting ICE for call ${event.callId}');
    pc.restartIce();
  }

  /// Handles an incoming Janus `slowlink` event: surfaces a transient
  /// network-quality indicator on the call and (re)arms the auto-hide timer.
  /// A real ICE failure ([iceConnectionIssue]) takes precedence and suppresses it.
  Future<void> __onMutationSlowlinkDetected(_CallMutationEventSlowlinkDetected event, Emitter<CallState> emit) async {
    final activeCall = state.retrieveActiveCall(event.callId);
    if (activeCall == null) return;
    if (activeCall.iceConnectionIssue != null) return;

    final hits = (_slowlinkHits[event.callId] ?? 0) + 1;
    _slowlinkHits[event.callId] = hits;

    final quality = CallNetworkQuality(
      severity: CallNetworkQualitySeverity.fromSlowlink(hits: hits, lost: event.lost),
      uplink: event.uplink,
      media: event.media,
    );
    emit(state.copyWithMappedActiveCall(event.callId, (call) => call.copyWith(networkQuality: quality)));

    _slowlinkDebounce.schedule(event.callId, () => add(_CallMutationEvent.slowlinkCleared(event.callId)));
  }

  /// Slowlink events stopped arriving: show the brief "recovered" confirmation,
  /// then arm a final timer to hide the indicator entirely.
  Future<void> __onMutationSlowlinkCleared(_CallMutationEventSlowlinkCleared event, Emitter<CallState> emit) async {
    final activeCall = state.retrieveActiveCall(event.callId);
    final quality = activeCall?.networkQuality;
    if (quality == null || quality.recovered) return;

    emit(
      state.copyWithMappedActiveCall(
        event.callId,
        (call) => call.copyWith(networkQuality: quality.copyWith(recovered: true)),
      ),
    );

    _slowlinkDebounce.schedule(event.callId, () => add(_CallMutationEvent.slowlinkHidden(event.callId)));
  }

  /// Removes the network-quality indicator after the recovered confirmation.
  Future<void> __onMutationSlowlinkHidden(_CallMutationEventSlowlinkHidden event, Emitter<CallState> emit) async {
    _slowlinkHits.remove(event.callId);
    final activeCall = state.retrieveActiveCall(event.callId);
    if (activeCall?.networkQuality == null) return;
    emit(state.copyWithMappedActiveCall(event.callId, (call) => call.copyWith(networkQuality: null)));
  }

  Future<void> __onMutationRestoreCall(_CallMutationEventRestoreCall event, Emitter<CallState> emit) async {
    final activeCall = state.retrieveActiveCall(event.callId);
    if (activeCall == null) return;

    final direction = activeCall.direction;
    final handle = activeCall.handle;
    final displayName = activeCall.displayName;
    final video = activeCall.video;

    if (direction == CallDirection.incoming) {
      final reportError = await callkeep.reportNewIncomingCall(
        event.callId,
        handle,
        displayName: displayName,
        hasVideo: video,
      );

      final acceptableReportErrors = {
        null,
        CallkeepIncomingCallError.callIdAlreadyExists,
        CallkeepIncomingCallError.callIdAlreadyExistsAndAnswered,
      };

      _logger.warning(
        '__onMutationRestoreCall: reportNewIncomingCall result=$reportError '
        'callId=${event.callId} hasOffer=${activeCall.incomingOffer != null} '
        'alreadyAnswered=${reportError == CallkeepIncomingCallError.callIdAlreadyExistsAndAnswered}',
      );

      if (!acceptableReportErrors.contains(reportError)) {
        _logger.warning('__onMutationRestoreCall: reportNewIncomingCall returned $reportError, aborting');
        add(_ResetStateEvent.completeCall(event.callId));
        return;
      }

      if (reportError == null || reportError == CallkeepIncomingCallError.callIdAlreadyExists) {
        final answerError = await callkeep.answerCall(event.callId);
        if (answerError != null) {
          _logger.warning('__onMutationRestoreCall: answerCall error: $answerError, aborting');
          add(_ResetStateEvent.completeCall(event.callId));
          return;
        }
      }
    } else {
      final startCallError = await callkeep.startCall(
        event.callId,
        handle,
        displayNameOrContactIdentifier: displayName,
        hasVideo: video,
        proximityEnabled: !video,
      );
      if (startCallError != null) {
        _logger.warning('__onMutationRestoreCall: startCall error: $startCallError');
      }
    }

    MediaStream? localStream;
    RTCPeerConnection? peerConnection;

    try {
      localStream = await userMediaBuilder.build(video: video, frontCamera: activeCall.frontCamera);
      peerConnection = await _createPeerConnection(event.callId, event.line);
      await Future.forEach(localStream.getTracks(), (t) => peerConnection!.addTrack(t, localStream!));

      emit(
        state.copyWithMappedActiveCall(
          event.callId,
          (c) => c.copyWith(
            localStream: localStream,
            processingStatus: CallProcessingStatus.connected,
            acceptedTime: event.acceptedTime,
          ),
        ),
      );
      await _onVideoStreamReady(event.callId);
      localStream = null;

      _callPeerConnectionManager.complete(event.callId, peerConnection);
      peerConnection = null;

      add(_PeerConnectionEvent.renegotiationNeeded(event.callId, event.line));
    } catch (e, stackTrace) {
      localStream?.getTracks().forEach((t) => t.stop());
      await _releaseLocalStream(localStream);
      await peerConnection?.dispose();
      _callPeerConnectionManager.completeError(event.callId, e, stackTrace);
      add(_ResetStateEvent.completeCall(event.callId));
      callErrorReporter.handle(e, stackTrace, '__onMutationRestoreCall error:');
    }
  }

  // processing peer connection events

  Future<void> _onPeerConnectionEvent(_PeerConnectionEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _PeerConnectionEventSignalingStateChanged() => __onPeerConnectionEventSignalingStateChanged(event, emit),
      _PeerConnectionEventConnectionStateChanged() => __onPeerConnectionEventConnectionStateChanged(event, emit),
      _PeerConnectionEventIceGatheringStateChanged() => __onPeerConnectionEventIceGatheringStateChanged(event, emit),
      _PeerConnectionEventIceConnectionStateChanged() => __onPeerConnectionEventIceConnectionStateChanged(event, emit),
      _PeerConnectionEventIceCandidateIdentified() => __onPeerConnectionEventIceCandidateIdentified(event, emit),
      _PeerConnectionEventStreamAdded() => __onPeerConnectionEventStreamAdded(event, emit),
      _PeerConnectionEventStreamRemoved() => __onPeerConnectionEventStreamRemoved(event, emit),
      _PeerConnectionEventRenegotiationNeeded() => __onPeerConnectionEventRenegotiationNeeded(event, emit),
    };
  }

  Future<void> __onPeerConnectionEventSignalingStateChanged(
    _PeerConnectionEventSignalingStateChanged event,
    Emitter<CallState> emit,
  ) async {}

  Future<void> __onPeerConnectionEventConnectionStateChanged(
    _PeerConnectionEventConnectionStateChanged event,
    Emitter<CallState> emit,
  ) async {}

  Future<void> __onPeerConnectionEventRenegotiationNeeded(
    _PeerConnectionEventRenegotiationNeeded event,
    Emitter<CallState> emit,
  ) async {
    _logger.info('__onPeerConnectionEventRenegotiationNeeded: ${event.callId}');
    add(_CallMutationEvent.renegotiate(event.callId, event.lineId));
  }

  Future<void> __onPeerConnectionEventIceGatheringStateChanged(
    _PeerConnectionEventIceGatheringStateChanged event,
    Emitter<CallState> emit,
  ) async {
    if (event.state == RTCIceGatheringState.RTCIceGatheringStateGathering) {
      emit(state.copyWithMappedActiveCall(event.callId, (call) => call.copyWith(iceCandidates: const [])));
    } else if (event.state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
      add(_CallMutationEvent.iceGatheringComplete(event.callId));
    }
  }

  Future<void> __onPeerConnectionEventIceConnectionStateChanged(
    _PeerConnectionEventIceConnectionStateChanged event,
    Emitter<CallState> emit,
  ) async {
    final activeCall = state.retrieveActiveCall(event.callId);
    if (activeCall == null) return;

    if (event.state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      add(_CallMutationEvent.iceConnectionFailed(event.callId));

      // Additional error processing for diagnostics
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.any((c) => c != ConnectivityResult.none)) {
        final (host, relay, srflx) = activeCall.iceCandidates.typesCount;
        _logger.warning('__onMutationIceConnectionFailed: candidates - srflx=$srflx, relay=$relay, host=$host');

        var iceConnectionIssue = IceConnectionIssue.iceFail;
        final noMediaPath = srflx == 0 && relay == 0 && host != 0;
        final vpnActive = connectivity.any((e) => e == ConnectivityResult.vpn);

        if (noMediaPath) {
          reportWannaTurn(activeCall.iceCandidates, connectivity);
          if (vpnActive) {
            iceConnectionIssue = IceConnectionIssue.iceFailNoIcePathViaVpn;
          } else {
            iceConnectionIssue = IceConnectionIssue.iceFailNoIcePath;
          }
        }

        emit(
          state.copyWithMappedActiveCall(
            activeCall.callId,
            (call) => call.copyWith(iceConnectionIssue: iceConnectionIssue),
          ),
        );
      }
    } else {
      emit(state.copyWithMappedActiveCall(event.callId, (call) => call.copyWith(iceConnectionIssue: null)));
    }
  }

  // Special case for collect statistics about calls network issues that can be solved by adding TURN server
  // WARN: Use separate function to create recognizable stack trace in crashlytics console
  // TODO: remove or change name if TURN will be added
  void reportWannaTurn(List<RTCIceCandidate> candidates, List<ConnectivityResult> connectivity) {
    final stack = StackTrace.current;
    final iceInfo = 'ices:${candidates.map((e) => e.candidate).join('\n')}';
    final connectivityInfo = 'connections:${connectivity.map((e) => e.name).join(',')})';

    CrashlyticsUtils.recordError(
      'ICE failed, WANNA TURN',
      stack: stack,
      information: [iceInfo, connectivityInfo],
      fatal: true,
    );
  }

  Future<void> __onPeerConnectionEventIceCandidateIdentified(
    _PeerConnectionEventIceCandidateIdentified event,
    Emitter<CallState> emit,
  ) async {
    if (iceFilter?.filter(event.candidate) == true) {
      _logger.fine('__onPeerConnectionEventIceCandidateIdentified: skip by iceFiler');
      return;
    }

    emit(
      state.copyWithMappedActiveCall(
        event.callId,
        (call) => call.copyWith(iceCandidates: [...call.iceCandidates, event.candidate]),
      ),
    );
    add(_CallMutationEvent.trickleIce(event.callId, event.candidate));
  }

  Future<void> __onPeerConnectionEventStreamAdded(
    _PeerConnectionEventStreamAdded event,
    Emitter<CallState> emit,
  ) async {
    final currentStream = state.retrieveActiveCall(event.callId)?.remoteStream;
    final sameRef = identical(currentStream, event.stream);
    _logger.info(
      '__onPeerConnectionEventStreamAdded: callId=${event.callId} '
      'streamId=${event.stream.id} '
      'videoTracks=${event.stream.getVideoTracks().length} '
      'sameRef=$sameRef',
    );

    // When onAddTrack fires with the same stream reference (existing stream gains
    // a new video track during renegotiation), the Freezed equality check on
    // ActiveCall would consider the state unchanged and skip the emit, leaving the
    // RTCVideoRenderer subscribed to the old track. Clear remoteStream first to
    // force a reference change that triggers renderer refresh.
    if (sameRef) {
      emit(
        state.copyWithMappedActiveCall(event.callId, (activeCall) {
          return activeCall.copyWith(remoteStream: null);
        }),
      );
    }

    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        return activeCall.copyWith(remoteStream: event.stream);
      }),
    );
  }

  Future<void> __onPeerConnectionEventStreamRemoved(
    _PeerConnectionEventStreamRemoved event,
    Emitter<CallState> emit,
  ) async {
    emit(
      state.copyWithMappedActiveCall(event.callId, (activeCall) {
        final prevStream = activeCall.remoteStream;
        if (prevStream != null && prevStream.id == event.stream.id) {
          return activeCall.copyWith(remoteStream: null);
        }
        return activeCall;
      }),
    );
  }

  // procession call screen events

  Future<void> _onCallScreenEvent(CallScreenEvent event, Emitter<CallState> emit) {
    return switch (event) {
      _CallScreenEventDidPush() => __onCallScreenEventDidPush(event, emit),
      _CallScreenEventDidPop() => __onCallScreenEventDidPop(event, emit),
    };
  }

  Future<void> __onCallScreenEventDidPush(_CallScreenEventDidPush event, Emitter<CallState> emit) async {
    final hasActiveCalls = state.activeCalls.isNotEmpty;
    var newState = state.copyWith(minimized: false);

    if (hasActiveCalls) {
      newState = newState.copyWithMappedActiveCalls((activeCall) {
        final transfer = activeCall.transfer;
        if (transfer != null && transfer is BlindTransferInitiated) {
          return activeCall.copyWith(transfer: null);
        } else {
          return activeCall;
        }
      });

      emit(newState);

      final currentCall = state.activeCalls.current;

      await callkeep.reportUpdateCall(currentCall.callId, proximityEnabled: state.shouldListenToProximity);

      if (currentCall.speakerOnBeforeMinimize == true) {
        final speakerDevice = state.availableAudioDevices.getSpeaker;
        if (speakerDevice != null) {
          add(CallControlEvent.audioDeviceSet(currentCall.callId, speakerDevice));
        } else {
          _logger.warning(
            '_onCallControlEventBlindTransferSubmitted: speaker was on before minimize but its not available now',
          );
        }
      }
    } else {
      _logger.warning('__onCallScreenEventDidPush: activeCalls is empty');
    }
  }

  Future<void> __onCallScreenEventDidPop(_CallScreenEventDidPop event, Emitter<CallState> emit) async {
    final shouldMinimize = state.activeCalls.isNotEmpty;
    _logger.info('__onCallScreenEventDidPop: shouldMinimize: $shouldMinimize');

    if (shouldMinimize) {
      final currentCallId = state.activeCalls.current.callId;
      final isSpeakerOn = state.audioDevice?.type == CallAudioDeviceType.speaker;

      emit(
        state
            .copyWithMappedActiveCall(currentCallId, (call) {
              return call.copyWith(speakerOnBeforeMinimize: isSpeakerOn);
            })
            .copyWith(minimized: true),
      );

      await callkeep.reportUpdateCall(currentCallId, proximityEnabled: state.shouldListenToProximity);
    }
  }

  void _onConfigEvent(CallConfigEvent event, Emitter<CallState> emit) {
    switch (event) {
      case _CallConfigEventUpdated(monitorCheckInterval: final interval):
        _logger.info('Updating CallPeerConnectionManager configuration: monitorCheckInterval=$interval');
        _callPeerConnectionManager.updateConfig(monitorCheckInterval: interval);
    }
  }

  // SignalingModule event handlers (called from stream subscription in constructor)

  void _handleHandshakeReceived(StateHandshake stateHandshake) async {
    add(
      _HandshakeSignalingEventState(registration: stateHandshake.registration, linesCount: stateHandshake.lines.length),
    );

    _assignInitialPresence(stateHandshake.presenceInfos);
    _assignInitialDialogs(stateHandshake.dialogInfos);

    // Hang up all active calls that are not associated with any line
    // or guest line, indicating that they are no longer valid.
    //
    // This is needed to drop or retain calls after reconnecting to the signaling server.
    // If you have troubles with line position mismatch replace the activeLineCallIds
    // computation with: https://gist.github.com/digiboridev/f7f1020731e8f247b5891983433bd159
    Set<String> activeLineCallIds = [
      ...stateHandshake.lines,
      stateHandshake.guestLine,
    ].whereType<Line>().map((line) => line.callId).toSet();
    _logger.info('_handleHandshakeReceived: activeLineCallIds=$activeLineCallIds');

    for (final activeCall in state.callsToTerminate(activeLineCallIds)) {
      _callPeerConnectionManager.conditionalCompleteError(activeCall.callId, 'Active call Request Terminated');
      add(
        _CallSignalingEvent.hangup(
          line: activeCall.line,
          callId: activeCall.callId,
          code: 487,
          reason: 'Request Terminated',
        ),
      );
    }

    // The callkeep reads are the only awaits on the way to the plan, and they
    // come first: the plan is then decided in the same turn it is executed,
    // from the state as it stands and from the session as the module knows
    // it now - a call that ended while the reads were in flight is already
    // gone from that handshake, whichever side ended it. What the bloc
    // processed meanwhile is the plan's input, not something it can overtake.
    final handshakeLines = [...stateHandshake.lines, stateHandshake.guestLine].whereType<Line>().toList();
    final lineCallIds = {
      for (final line in handshakeLines) ...[
        line.callId,
        ...line.callLogs.whereType<CallEventLog>().take(1).map((log) => log.callEvent.callId),
      ],
    };
    final connections = await callkeepConnections.getConnections();
    final lineConnections = Map.fromIterables(
      lineCallIds,
      await Future.wait(lineCallIds.map(callkeepConnections.getConnection)),
    );
    final session = _signalingModule.sessionHandshake ?? stateHandshake;
    final actions = _handshakeProcessor.process(
      lines: session.lines,
      guestLine: session.guestLine,
      activeCalls: state.activeCalls,
      connections: connections,
      lineConnections: lineConnections,
      conference: session.conference,
    );

    _logger.warning(
      '_handleHandshakeReceived: HandshakeProcessor actions=${actions.map((a) => a.runtimeType).toList()} '
      'activeCalls=${state.activeCalls.map((c) => '${c.callId}:${c.processingStatus}').toList()}',
    );

    for (final action in actions) {
      switch (action) {
        // The requests below go through the same lifecycle as an end the
        // user makes now - recorded until the server confirms them - and are
        // sent without waiting for their answers: an await between two
        // actions would reopen the window the plan was made to avoid, and
        // each action concerns one call. Where the processor found the
        // session being torn down it has already cut the plan short itself;
        // a hangup replayed from the termination queue says nothing about the
        // other lines, and stopping here once left a live call unanswered
        // while a queued decline kept failing.
        case HangupSignalingAction():
          unawaited(
            _dispatchTerminationRequest(
              request: QueuedTerminationRequest(
                type: QueuedTerminationRequestType.hangup,
                line: action.line,
                callId: action.callId,
              ),
              source: '_handleHandshakeReceived',
            ),
          );
          _logger.info('_handleHandshakeReceived: HangupSignalingAction sent, callId=${action.callId}');

        case DeclineSignalingAction():
          unawaited(
            _dispatchTerminationRequest(
              request: QueuedTerminationRequest(
                type: QueuedTerminationRequestType.decline,
                line: action.line,
                callId: action.callId,
              ),
              source: '_handleHandshakeReceived',
            ),
          );
          _logger.info('_handleHandshakeReceived: DeclineSignalingAction sent, callId=${action.callId}');

        case RestoreCallAction():
          add(
            _RestoreAcceptedCall(
              line: action.line,
              callId: action.callId,
              acceptedEvent: action.acceptedEvent,
              acceptedTime: action.acceptedTime,
              incomingCallEvent: action.incomingCallEvent,
              remoteCameraEnabled: action.mediaState?.video,
            ),
          );

        case HandleIncomingCallAction():
          // The caller's last word on the camera travels with the offer: a
          // media state dispatched after it would run before the mutation that
          // creates the call and find nothing to apply to.
          _dispatchIncomingCall(action.event, remoteVideo: action.mediaState?.video);

        case DeliverOfferAction():
          // The handler is the same as for a live offer: it stores the offer
          // in the waiting call and reports the call to callkeep a second
          // time, which answers callIdAlreadyExists* and is handled there.
          // The state is read once more here - the queued signaling events
          // above may have already answered or removed the call.
          final waiting = state.retrieveActiveCall(action.event.callId);
          if (waiting != null && waiting.awaitsOffer) {
            _logger.info('_handleHandshakeReceived: delivering offer to push-registered call ${action.event.callId}');
            _dispatchIncomingCall(action.event, remoteVideo: action.mediaState?.video);
          } else {
            _logger.info('_handleHandshakeReceived: offer for ${action.event.callId} no longer needed, skipping');
          }

        case EndLocalCallAction():
          unawaited(callkeep.endCall(action.callId));

        case HangupStaleConferenceAction():
          // Never refused, a no-op without a room; the calls in it carry on.
          _logger.info('_handleHandshakeReceived: hanging up conference room ${action.room} this client cannot rejoin');
          unawaited(
            _signalingModule
                .execute(ConferenceHangupRequest(transaction: WebtritSignalingClient.generateTransactionId()))
                ?.catchError(
                  (e, s) => callErrorReporter.handle(e, s, '_handleHandshakeReceived conferenceHangup error'),
                ),
          );
      }
    }
  }

  Future<void> _onRestoreAcceptedCall(_RestoreAcceptedCall event, Emitter<CallState> emit) async {
    final CallkeepHandle handle;
    final String? callerDisplayName;
    final bool video;
    final JsepValue? incomingOffer;
    final CallDirection direction;

    if (event.incomingCallEvent != null) {
      final incoming = event.incomingCallEvent!;
      final jsep = JsepValue.fromOptional(incoming.jsep);
      handle = CallkeepHandle.number(incoming.caller);
      callerDisplayName = incoming.callerDisplayName;
      video = jsep?.hasVideo ?? false;
      incomingOffer = jsep;
      direction = CallDirection.incoming;
    } else {
      final callee = event.acceptedEvent.callee ?? '';
      final number = callee.replaceFirst(RegExp(r'^sips?:'), '').split('@').first;
      final jsep = JsepValue.fromOptional(event.acceptedEvent.jsep);
      handle = CallkeepHandle.number(number);
      callerDisplayName = null;
      video = jsep?.hasVideo ?? false;
      incomingOffer = null;
      direction = CallDirection.outgoing;
    }

    final contactName = (await contactResolver.resolve(handle.value))?.maybeName;
    final displayName = contactName ?? callerDisplayName;

    if (state.activeCalls.any((c) => c.callId == event.callId)) {
      _logger.warning('_onRestoreAcceptedCall: callId=${event.callId} already active, skipping');
      return;
    }

    final activeCall = ActiveCall(
      direction: direction,
      line: event.line,
      callId: event.callId,
      handle: handle,
      displayName: displayName,
      video: video,
      remoteCameraEnabled: event.remoteCameraEnabled,
      createdTime: clock.now(),
      incomingOffer: incomingOffer,
      processingStatus: direction == CallDirection.incoming
          ? CallProcessingStatus.incomingRestoringMedia
          : CallProcessingStatus.outgoingRestoringMedia,
    );
    emit(state.copyWithPushActiveCall(activeCall));

    add(
      _CallMutationEvent.restoreCall(
        callId: event.callId,
        line: event.line,
        acceptedTime: event.acceptedTime,
        incomingCallEvent: event.incomingCallEvent,
        acceptedEvent: event.acceptedEvent,
      ),
    );
  }

  /// Turns an [IncomingCallEvent] into the bloc's incoming event, heard live
  /// or restored from a log; [remoteVideo] is the caller's camera as the log
  /// last reported it, which only a restored call has.
  void _dispatchIncomingCall(IncomingCallEvent event, {bool? remoteVideo}) {
    _logger.warning('[SIG] IncomingCallEvent: callId=${event.callId} caller=${event.caller} callee=${event.callee}');
    add(
      _CallSignalingEvent.incoming(
        line: event.line,
        callId: event.callId,
        callee: event.callee,
        caller: event.caller,
        callerDisplayName: event.callerDisplayName,
        referredBy: event.referredBy,
        replaceCallId: event.replaceCallId,
        isFocus: event.isFocus,
        jsep: JsepValue.fromOptional(event.jsep),
        remoteVideo: remoteVideo,
      ),
    );
  }

  void _handleSignalingEvent(Event event) {
    _logger.info('[SIG] ${event.runtimeType}');
    if (event is IncomingCallEvent) {
      _dispatchIncomingCall(event);
    } else if (event is RingingEvent) {
      add(_CallSignalingEvent.ringing(line: event.line, callId: event.callId));
    } else if (event is ProceedingEvent) {
      add(_CallSignalingEvent.proceeding(line: event.line, callId: event.callId, code: event.code));
    } else if (event is ProgressEvent) {
      add(
        _CallSignalingEvent.progress(
          line: event.line,
          callId: event.callId,
          callee: event.callee,
          jsep: JsepValue.fromOptional(event.jsep),
        ),
      );
    } else if (event is AcceptedEvent) {
      add(
        _CallSignalingEvent.accepted(
          line: event.line,
          callId: event.callId,
          callee: event.callee,
          jsep: JsepValue.fromOptional(event.jsep),
        ),
      );
    } else if (event is HangupEvent) {
      _logger.warning('[SIG] HangupEvent: callId=${event.callId} code=${event.code} reason="${event.reason}"');
      add(_CallSignalingEvent.hangup(line: event.line, callId: event.callId, code: event.code, reason: event.reason));
    } else if (event is UpdatingCallEvent) {
      add(
        _CallSignalingEvent.callUpdating(
          line: event.line,
          callId: event.callId,
          callee: event.callee,
          caller: event.caller,
          callerDisplayName: event.callerDisplayName,
          referredBy: event.referredBy,
          replaceCallId: event.replaceCallId,
          isFocus: event.isFocus,
          jsep: JsepValue.fromOptional(event.jsep),
        ),
      );
    } else if (event is UpdatingEvent) {
      add(_CallSignalingEvent.updating(line: event.line, callId: event.callId));
    } else if (event is UpdatedEvent) {
      add(_CallSignalingEvent.updated(line: event.line, callId: event.callId));
    } else if (event is PeerMessageEvent) {
      switch (event) {
        case MediaStatePeerMessageEvent e:
          add(_CallSignalingEvent.peerMediaState(line: e.line, callId: e.callId, video: e.video));
        case UnknownPeerMessageEvent e:
          _logger.info('[SIG] PeerMessageEvent: ignoring unknown type "${e.type}"');
      }
    } else if (event is TransferEvent) {
      add(
        _CallSignalingEvent.transfer(
          line: event.line,
          referId: event.referId,
          referTo: event.referTo,
          referredBy: event.referredBy,
          replaceCallId: event.replaceCallId,
        ),
      );
    } else if (event is NotifyEvent) {
      add(switch (event) {
        ReferNotifyEvent event => _CallSignalingEvent.notifyRefer(
          line: event.line,
          callId: event.callId,
          notify: event.notify,
          subscriptionState: event.subscriptionState,
          state: event.state,
        ),
        UnknownNotifyEvent event => _CallSignalingEvent.notifyUnknown(
          line: event.line,
          callId: event.callId,
          notify: event.notify,
          subscriptionState: event.subscriptionState,
          contentType: event.contentType,
          content: event.content,
        ),
      });
    } else if (event is RegisteringEvent) {
      add(const _CallSignalingEvent.registration(RegistrationStatus.registering));
    } else if (event is RegisteredEvent) {
      add(const _CallSignalingEvent.registration(RegistrationStatus.registered));
    } else if (event is RegistrationFailedEvent) {
      final registrationFailedEvent = _CallSignalingEvent.registration(
        RegistrationStatus.registration_failed,
        code: event.code,
        reason: event.reason,
      );
      add(registrationFailedEvent);
    } else if (event is UnregisteringEvent) {
      add(const _CallSignalingEvent.registration(RegistrationStatus.unregistering));
    } else if (event is UnregisteredEvent) {
      add(const _CallSignalingEvent.registration(RegistrationStatus.unregistered));
    } else if (event is TransferringEvent) {
      add(_CallSignalingEvent.transferring(line: event.line, callId: event.callId));
    } else if (event is TransferAcceptedEvent) {
      add(_CallSignalingEvent.transferAccepted(line: event.line, callId: event.callId));
    } else if (event is TransferFailedEvent) {
      add(_CallSignalingEvent.transferFailed(line: event.line, callId: event.callId, code: event.code));
    } else if (event is GlobalEvent) {
      add(switch (event) {
        NumberPresenceUpdate event => _GlobalEvent.numberPresenceUpdate(
          number: event.number,
          presenceInfo: event.presenceInfo,
        ),
        NumberDialogsUpdate event => _GlobalEvent.numberDialogsUpdate(
          number: event.number,
          dialogInfos: event.dialogInfos,
        ),
      });
    } else if (event is CallingEvent) {
      _logger.info('[SIG] CallingEvent: callId=${event.callId} line=${event.line} - remote is ringing');
    } else if (event is HangingupEvent) {
      _logger.info('[SIG] HangingupEvent: callId=${event.callId} line=${event.line} - hangup in progress');
    } else if (event is IceHangupEvent) {
      _logger.info('[SIG] IceHangupEvent: line=${event.line} reason="${event.reason}"');
    } else if (event is IceSlowLinkEvent) {
      final activeCall = state.activeCalls.firstWhereOrNull((c) => c.line == event.line);
      if (activeCall != null) {
        add(
          _CallMutationEvent.slowlinkDetected(
            callId: activeCall.callId,
            uplink: event.uplink,
            media: CallMediaKind.values.byName(event.media.name),
            lost: event.lost,
          ),
        );
      } else {
        _logger.fine('[SIG] IceSlowLinkEvent: no active call on line=${event.line}');
      }
    } else if (event is CallErrorEvent) {
      add(
        _CallSignalingEvent.callError(line: event.line, callId: event.callId, code: event.code, reason: event.reason),
      );
    } else if (event is ConferenceOfferEvent) {
      add(
        _CallMutationEvent.conferenceOffer(
          room: event.room,
          jsep: JsepValue(event.jsep),
          participants: event.participants,
        ),
      );
    } else if (event is ConferenceIceTrickleEvent) {
      add(_CallMutationEvent.conferenceRemoteCandidate(event.candidate?.toIceCandidate()));
    } else if (event is ConferenceUpdatedEvent) {
      add(_CallMutationEvent.conferenceUpdated(room: event.room, participants: event.participants));
    } else if (event is ConferenceFailedEvent) {
      add(_CallMutationEvent.conferenceFailed(room: event.room, reason: event.reason, detail: event.detail));
    } else if (event is ConferenceTerminatedEvent) {
      add(_CallMutationEvent.conferenceTerminated(room: event.room));
    } else {
      _logger.warning('unhandled signaling event $event');
    }
  }

  // WidgetsBindingObserver

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.finer('didChangeAppLifecycleState: $state');
    add(_AppLifecycleStateChanged(state));
  }

  // CallkeepDelegate

  @override
  void continueStartCallIntent(CallkeepHandle handle, String? displayName, bool video) {
    _logger.fine(() => 'continueStartCallIntent handle: $handle displayName: $displayName video: $video');

    _continueStartCallIntent(handle, displayName, video);
  }

  Future<void> _continueStartCallIntent(CallkeepHandle handle, String? displayName, bool video) async {
    _logger.fine(
      () => StringBuffer()
        ..write('_continueStartCallIntent - Attempting to start call')
        ..write(' handle: $handle')
        ..write(' displayName: $displayName')
        ..write(' video: $video')
        ..write(' isHandshakeActive: ${state.isHandshakeEstablished}')
        ..write(' isSignalingActive: ${state.isSignalingEstablished}'),
    );

    try {
      // Wait until both signaling and handshake are active.
      // If the desired state is not reached within kSignalingClientConnectionTimeout, a TimeoutException will be thrown.
      final resolvedState = await stream
          .firstWhere((state) => state.isHandshakeEstablished && state.isSignalingEstablished)
          .timeout(kSignalingClientConnectionTimeout);

      if (isClosed) return;

      _logger.fine(
        () => StringBuffer()
          ..write('_continueStartCallIntent - Signaling and handshake are now active for')
          ..write(' handle: $handle')
          ..write(' displayName: $displayName')
          ..write(' video: $video')
          ..write(' isHandshakeActive: ${resolvedState.isHandshakeEstablished}')
          ..write(' isSignalingActive: ${resolvedState.isSignalingEstablished}'),
      );

      final event = CallControlEvent.started(
        generic: handle.isGeneric ? handle.value : null,
        number: handle.isNumber ? handle.value : null,
        email: handle.isEmail ? handle.value : null,
        displayName: displayName,
        video: video,
      );

      add(event);
    } on TimeoutException {
      if (isClosed) return;

      _logger.warning(
        () => StringBuffer()
          ..write('_continueStartCallIntent - Failed to start call')
          ..write(' handle: $handle')
          ..write(' (Signaling/handshake connection timed out after ${kSignalingClientConnectionTimeout.inSeconds}s)')
          ..write(' isHandshakeActive: ${state.isHandshakeEstablished}')
          ..write(' isSignalingActive: ${state.isSignalingEstablished}'),
      );

      submitNotification(const GeneralUnableToCallNotification());
    } catch (e, s) {
      if (isClosed) return;

      final severeMessage = StringBuffer()
        ..write('_continueStartCallIntent - An unexpected error occurred while waiting for signaling')
        ..write(' handle: $handle');
      _logger.severe(() => severeMessage, e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: severeMessage.toString());
    }
  }

  @override
  // Handles incoming call notifications from the native side.
  // On iOS, this is triggered via PushKit when a push is received.
  //
  // On Android, this method is currently not used. Call state synchronization
  // from the background is handled by `CallkeepConnections`. A future refactoring
  // could unify this logic so that both platforms use this delegate method.
  //
  // On Android, this is now fully feasible because after the recent callback
  // improvement we can reliably detect when the bloc is ready.
  //
  // PDelegateFlutterApi.setUp(null);
  // _api.onDelegateSet();
  //
  // TODO: Unify incoming-call handling for both iOS and Android so that
  // this method becomes the shared entry point. This may require removing
  // `CallkeepConnections` and adjusting the method signature.
  void didPushIncomingCall(
    CallkeepHandle handle,
    String? displayName,
    bool video,
    String callId,
    CallkeepIncomingCallError? error,
  ) {
    _logger.fine(
      () =>
          'didPushIncomingCall handle: $handle displayName: $displayName video: $video'
          ' callId: $callId error: $error',
    );

    add(_CallPushEventIncoming(callId: callId, handle: handle, displayName: displayName, video: video, error: error));
  }

  @override
  Future<bool> performStartCall(
    String callId,
    CallkeepHandle handle,
    String? displayNameOrContactIdentifier,
    bool video,
  ) {
    return _perform(
      _CallPerformEvent.started(callId, handle: handle, displayName: displayNameOrContactIdentifier, video: video),
    );
  }

  @override
  Future<bool> performAnswerCall(String callId) {
    return _perform(_CallPerformEvent.answered(callId));
  }

  @override
  Future<bool> performEndCall(String callId) {
    return _perform(_CallPerformEvent.ended(callId));
  }

  @override
  Future<bool> performSetHeld(String callId, bool onHold) {
    return _perform(_CallPerformEvent.setHeld(callId, onHold));
  }

  @override
  Future<bool> performSetMuted(String callId, bool muted) {
    return _perform(_CallPerformEvent.setMuted(callId, muted));
  }

  @override
  Future<bool> performSendDTMF(String callId, String key) {
    return _perform(_CallPerformEvent.sentDTMF(callId, key));
  }

  @override
  Future<bool> performSetCallGroup(String callId, String? groupWithCallId) {
    // Refused until the bloc keeps conference state. Accepting would let the OS
    // present a group the application does not know about, and every later
    // decision here - which calls to hold, which to hang up - reads that state.
    _logger.info('performSetCallGroup refused: callId=$callId groupWith=$groupWithCallId');
    return Future.value(false);
  }

  @override
  Future<bool> performAudioDeviceSet(String callId, CallkeepAudioDevice device) {
    final callDevice = CallAudioDevice.fromCallkeep(device);
    return _perform(_CallPerformEvent.audioDeviceSet(callId, callDevice));
  }

  @override
  Future<bool> performAudioDevicesUpdate(String callId, List<CallkeepAudioDevice> devices) {
    final callDevices = devices.map(CallAudioDevice.fromCallkeep).toList();
    return _perform(_CallPerformEvent.audioDevicesUpdate(callId, callDevices));
  }

  @override
  void didActivateAudioSession() {
    _mediaManager.didActivateAudioSession();
  }

  @override
  void didDeactivateAudioSession() {
    _mediaManager.didDeactivateAudioSession();
  }

  @override
  void didReset() {
    _logger.warning('didReset');
  }

  // conference
  //
  // The room is the server's: the host asks for it with `merge`, the server
  // wires the legs and hands over the mixer's offer, and every change of
  // membership arrives as its participant list. What the client owns is the
  // record of which calls it put in (state.conference.legs) - the legs are
  // quiet from the merge's ack, and that record is what a failure undoes.
  // The wire format and the obligations followed here are in
  // packages/signaling/docs/conference_protocol.md.

  Future<void> __onMutationControlMerge(_CallMutationEventControlMerge e, Emitter<CallState> emit) async {
    if (!state.canMerge(isConferenceEnabled: capabilities.isConferenceEnabled)) {
      _logger.warning('__onMutationControlMerge: nothing to merge now, ignoring');
      return;
    }
    final legs = state.mergeableLegs(e.callIds);
    if (legs.length < 2) {
      _logger.warning('__onMutationControlMerge: fewer than two mergeable calls in ${e.callIds}, ignoring');
      return;
    }
    final taken = await _executeConferenceRequest(
      MergeRequest(transaction: WebtritSignalingClient.generateTransactionId(), lines: legs.values.toList()),
      source: '__onMutationControlMerge',
      notifyRefusal: true,
    );
    if (!taken) return;
    // From the ack on the legs are the server's: quiet now, not at the offer,
    // so that a failure between the two undoes exactly what was recorded.
    legs.removeWhere((callId, _) => state.retrieveActiveCall(callId) == null);
    await _quietLegs(legs.keys);
    if (state.conference.isPresent) {
      _logger.warning('__onMutationControlMerge: a room appeared while this merge was being acknowledged');
      return;
    }
    _conferenceAttempt++;
    emit(
      state.copyWith(
        conference: ConferenceState(phase: ConferencePhase.assembling, legs: legs),
      ),
    );
    _armConferenceAssembly();
  }

  Future<void> __onMutationControlConferenceAdd(
    _CallMutationEventControlConferenceAdd e,
    Emitter<CallState> emit,
  ) async {
    final line = state.mergeableLegs([e.callId])[e.callId];
    if (!state.conference.isPresent || line == null) {
      _logger.warning('__onMutationControlConferenceAdd: ${e.callId} cannot join now, ignoring');
      return;
    }
    final taken = await _executeConferenceRequest(
      ConferenceAddRequest(transaction: WebtritSignalingClient.generateTransactionId(), line: line),
      source: '__onMutationControlConferenceAdd',
      notifyRefusal: true,
    );
    if (!taken || !state.conference.isPresent || state.retrieveActiveCall(e.callId) == null) return;
    await _quietLegs([e.callId]);
    if (!state.conference.isPresent) return;
    emit(state.copyWith(conference: state.conference.copyWith(legs: {...state.conference.legs, e.callId: line})));
  }

  /// A room-wide mute of one participant. Accepted by the server only once
  /// it has listed the participant; the outcome comes back as the next list,
  /// nothing is guessed here.
  Future<void> __onMutationControlConferenceMute(
    _CallMutationEventControlConferenceMute e,
    Emitter<CallState> emit,
  ) async {
    final participant = state.conference.participants.firstWhereOrNull((p) => p.callId == e.callId);
    if (participant == null) {
      _logger.warning('__onMutationControlConferenceMute: ${e.callId} is not a listed participant, ignoring');
      return;
    }
    await _executeConferenceRequest(
      ConferenceMuteRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        line: participant.line,
        muted: e.muted,
      ),
      source: '__onMutationControlConferenceMute',
    );
  }

  Future<void> __onMutationControlConferenceSelfMute(
    _CallMutationEventControlConferenceSelfMute e,
    Emitter<CallState> emit,
  ) async {
    await _setRoomMuted(e.muted, emit);
  }

  /// Mutes the host towards the room, from whichever control asked.
  ///
  /// The room's microphone and what the screen says about it are one thing,
  /// so they are set in one place: a mute the operating system reports for a
  /// leg and the room's own control must not be able to disagree.
  Future<void> _setRoomMuted(bool muted, Emitter<CallState> emit) async {
    if (!state.conference.isPresent) return;
    await _conferencePeerConnection.setSelfMuted(muted);
    emit(state.copyWith(conference: state.conference.copyWith(selfMuted: muted)));
    await _legMutes.apply(state.conference.legIds, muted);
  }

  /// The host ends the conference, and with it every leg: a room is not
  /// unwound into separate calls. The room is dropped here rather than at
  /// the server's confirmation, so the legs end as ordinary calls and the
  /// confirmation, when it comes, finds nothing to bring back.
  Future<void> __onMutationControlConferenceEnd(
    _CallMutationEventControlConferenceEnd e,
    Emitter<CallState> emit,
  ) async {
    if (!state.conference.isPresent) return;
    final legIds = state.conference.legIds.toList();
    await _leaveRoom(emit, restoreLegs: false);
    _hangUpRoom('__onMutationControlConferenceEnd');
    for (final callId in legIds) {
      add(CallControlEvent.ended(callId));
    }
  }

  /// The mixer's offer: the room is built. The list it carries is the
  /// membership - a leg the server could not mix is not in it - and the
  /// answer is what makes the host part of the room.
  Future<void> __onMutationConferenceOffer(_CallMutationEventConferenceOffer e, Emitter<CallState> emit) async {
    if (!state.conference.isPresent) {
      // Nothing here wants it any more: the room was given up while the
      // server was still building it. Never refused, and it ends the room.
      _logger.warning('__onMutationConferenceOffer: no room here for ${e.room}, hanging it up');
      _hangUpRoom('__onMutationConferenceOffer');
      return;
    }
    // Recorded before anything is awaited: the handshake handler runs outside
    // every queue and decides what this client holds by the room id in the
    // state, so a handshake arriving while a participant is being taken off
    // hold - a native round trip - would hang up the room being joined.
    emit(state.copyWith(conference: state.conference.copyWith(room: e.room)));
    await _adoptParticipants(e.participants, emit);
    // Answering is a media round trip and then a request, and neither may
    // hold the mutation queue: while it does, the deadline that gives the
    // calls back cannot run, and neither can the host's own End - the legs
    // would stay silent for as long as the answer takes.
    unawaited(_answerRoom(e.room, e.jsep, _conferenceAttempt));
  }

  /// Builds the connection to the mixer and sends the answer, off the queue.
  ///
  /// Every step is checked against the attempt it was started for: a room
  /// given up while this was in flight must not be raised from the dead by
  /// its own answer arriving late.
  Future<void> _answerRoom(int room, JsepValue jsep, int attempt) async {
    try {
      final answer = await _conferencePeerConnection.answer(room: room, offer: jsep.toDescription());
      if (attempt != _conferenceAttempt) return;
      final sent = await _executeConferenceRequest(
        ConferenceAnswerRequest(transaction: WebtritSignalingClient.generateTransactionId(), jsep: answer.toMap()),
        source: '_answerRoom',
      );
      if (attempt != _conferenceAttempt) return;
      // An answer the session could not carry leaves the server waiting and
      // this client silent: it is a failure to join, not a room.
      add(sent ? _CallMutationEvent.conferenceAnswered(room) : const _CallMutationEvent.conferenceAnswerFailed());
    } catch (error, stackTrace) {
      callErrorReporter.handle(error, stackTrace, '_answerRoom error');
      if (attempt == _conferenceAttempt) add(const _CallMutationEvent.conferenceAnswerFailed());
    }
  }

  /// The answer reached the server: the host is in the room.
  Future<void> __onMutationConferenceAnswered(_CallMutationEventConferenceAnswered e, Emitter<CallState> emit) async {
    if (!state.conference.concerns(e.room) || !state.conference.isPresent) {
      _logger.warning('__onMutationConferenceAnswered: ${e.room} is not the room here');
      return;
    }
    _conferenceAssemblyTimer?.cancel();
    emit(state.copyWith(conference: state.conference.copyWith(phase: ConferencePhase.active)));
  }

  /// Without a way into the room the host would hear nothing of it: give it
  /// up and bring the legs back.
  Future<void> __onMutationConferenceAnswerFailed(
    _CallMutationEventConferenceAnswerFailed e,
    Emitter<CallState> emit,
  ) async {
    if (!state.conference.isPresent) return;
    _hangUpRoom('__onMutationConferenceAnswerFailed');
    await _leaveRoom(emit, restoreLegs: true);
    submitNotification(const ConferenceFailedNotification(reason: 'answer_failed'));
  }

  Future<void> __onMutationConferenceRemoteCandidate(
    _CallMutationEventConferenceRemoteCandidate e,
    Emitter<CallState> emit,
  ) async {
    if (!state.conference.isPresent) return;
    try {
      await _conferencePeerConnection.addRemoteCandidate(e.candidate);
    } catch (error, stackTrace) {
      callErrorReporter.handle(error, stackTrace, '__onMutationConferenceRemoteCandidate error');
    }
  }

  Future<void> __onMutationConferenceLocalCandidate(
    _CallMutationEventConferenceLocalCandidate e,
    Emitter<CallState> emit,
  ) async {
    if (!state.conference.isPresent || !_conferencePeerConnection.isUp) return;
    await _executeConferenceRequest(
      ConferenceIceTrickleRequest(
        transaction: WebtritSignalingClient.generateTransactionId(),
        candidate: e.candidate?.toMap(),
      ),
      source: '__onMutationConferenceLocalCandidate',
    );
  }

  Future<void> __onMutationConferenceUpdated(_CallMutationEventConferenceUpdated e, Emitter<CallState> emit) async {
    if (!state.conference.isPresent) return;
    if (e.room != state.conference.room) {
      // Section 5.1: a list for another room describes another room. A late
      // one from a room already left would otherwise replace this room's
      // membership and put its legs on hold.
      _logger.warning('__onMutationConferenceUpdated: room ${e.room} is not the room here (${state.conference.room})');
      return;
    }
    await _adoptParticipants(e.participants, emit);
  }

  /// The room could not be built - a leg turned out to be a video call.
  /// Terminal: nothing else about this room follows.
  Future<void> __onMutationConferenceFailed(_CallMutationEventConferenceFailed e, Emitter<CallState> emit) async {
    if (!state.conference.isPresent) return;
    if (!state.conference.concerns(e.room)) {
      _logger.warning('__onMutationConferenceFailed: room ${e.room} is not the room here');
      return;
    }
    _logger.warning('__onMutationConferenceFailed: ${e.reason} ${e.detail ?? ''}');
    await _leaveRoom(emit, restoreLegs: true);
    submitNotification(ConferenceFailedNotification(reason: e.reason));
  }

  /// The room is over, for whichever of its reasons: the host's own hangup
  /// has already dropped it here and finds nothing; the rest leave the
  /// calls that are still up as ordinary calls, all active at once on the
  /// server, so all but the focused one go on hold. After a lost mixer the
  /// legs have no media and their hangups follow; they are left alone.
  Future<void> __onMutationConferenceTerminated(
    _CallMutationEventConferenceTerminated e,
    Emitter<CallState> emit,
  ) async {
    if (!state.conference.isPresent) return;
    if (!state.conference.concerns(e.room)) {
      _logger.warning('__onMutationConferenceTerminated: room ${e.room} is not the room here');
      return;
    }
    final restored = await _leaveRoom(emit, restoreLegs: true);
    if (restored.isNotEmpty) submitNotification(const ConferenceEndedNotification());
  }

  /// The room is gone without the server saying so: its media connection
  /// failed, or it never finished being built. The calls in it are still
  /// calls, so they are handed back the way a termination hands them back,
  /// and the room is ended on the server too in case it still stands.
  Future<void> __onMutationConferenceLost(_CallMutationEventConferenceLost e, Emitter<CallState> emit) async {
    if (!state.conference.isPresent) return;
    _logger.warning('__onMutationConferenceLost: giving up conference room ${state.conference.room}');
    _hangUpRoom('__onMutationConferenceLost');
    await _leaveRoom(emit, restoreLegs: true);
    submitNotification(const ConferenceEndedNotification());
  }

  /// Gives the merge a deadline of this client's own.
  ///
  /// The legs go quiet at the acknowledgement and stay quiet until the room's
  /// offer arrives. The server has a deadline of its own and announces it,
  /// but it announces it as an event, and events are not replayed - so a
  /// socket that drops in between takes that word with it and would leave
  /// both calls silent in both directions until it comes back.
  void _armConferenceAssembly() {
    _conferenceAssemblyTimer?.cancel();
    _conferenceAssemblyTimer = Timer(conferenceAssemblyTimeout, () {
      if (state.conference.phase != ConferencePhase.assembling || isClosed) return;
      _logger.warning('the conference room never arrived, giving the calls back');
      add(const _CallMutationEvent.conferenceLost());
    });
  }

  /// Ends the room on the server. Sent and not waited on: this client has
  /// already let the room go by the time it asks.
  void _hangUpRoom(String source) {
    unawaited(
      _executeConferenceRequest(
        ConferenceHangupRequest(transaction: WebtritSignalingClient.generateTransactionId()),
        source: source,
      ),
    );
  }

  /// Sends a conference request and says whether the server took it. A
  /// refusal is the server's answer and, when [notifyRefusal], the host's to
  /// see; a transport failure is a request that never got there.
  Future<bool> _executeConferenceRequest(Request request, {required String source, bool notifyRefusal = false}) async {
    try {
      // A module with nowhere to send answers with nothing at all, and an
      // awaited null completes like an acknowledgement would. Quieting the
      // legs for a room the server was never asked for would leave two live
      // calls silent in both directions.
      final pending = _signalingModule.execute(request);
      if (pending == null) {
        _logger.warning('$source: not sent, the session is not connected');
        return false;
      }
      await pending;
      return true;
    } on WebtritSignalingErrorException catch (e) {
      _logger.warning('$source: refused by the server: ${e.reason}');
      if (notifyRefusal) submitNotification(ConferenceRefusedNotification(e.reason));
      return false;
    } on NotConnectedException {
      _logger.warning('$source: not connected');
      return false;
    } on WebtritSignalingTransactionTimeoutException {
      _logger.warning('$source: transaction timeout');
      return false;
    } catch (e, stackTrace) {
      callErrorReporter.handle(e, stackTrace, '$source error');
      return false;
    }
  }

  /// Silences a leg both ways for the room: the microphone leaves the leg's
  /// own connection and the far end's audio stops playing.
  Future<void> _quietLegs(Iterable<String> callIds) async {
    for (final callId in callIds) {
      final call = state.retrieveActiveCall(callId);
      if (call == null) continue;
      await _setMicrophoneAttached(callId, attached: false);
      _setInboundAudioEnabled(call, false);
    }
    // A call joining a room the host has already muted starts out of step
    // with it; see [LegMuteSync].
    if (state.conference.selfMuted) await _legMutes.apply(callIds, true);
  }

  /// Gives a leg its audio back once it is a call again: the far end to the
  /// speaker, and the microphone to the leg's connection unless the user had
  /// muted that call. Returns whether there was a call to restore - nothing
  /// is done for one that is gone or going.
  Future<bool> _restoreLegAudio(String callId) async {
    final call = state.retrieveActiveCall(callId);
    if (call == null || call.wasHungUp || call.processingStatus == CallProcessingStatus.disconnecting) return false;
    // Hearing the far end again is independent of talking to them: a failure
    // to re-attach the microphone must not leave the call deaf as well.
    _setInboundAudioEnabled(call, true);
    await _setMicrophoneAttached(callId, attached: !call.muted);
    return true;
  }

  void _setInboundAudioEnabled(ActiveCall call, bool enabled) {
    for (final track in call.remoteStream?.getAudioTracks() ?? const <MediaStreamTrack>[]) {
      track.enabled = enabled;
    }
  }

  /// Takes the server's list as the room's membership. A leg not in it that
  /// is still up is an ordinary call again: audio back and on hold, since
  /// the room is what the host hears. A listed call is off hold on the
  /// server's side - it un-holds a leg as it joins, with no event - so the
  /// local flag follows; the operating system is told the group instead, and
  /// takes the legs as active from that. A vanished leg is held only after
  /// the membership is re-declared, which is what lets it leave the group.
  Future<void> _adoptParticipants(List<ConferenceParticipant> participants, Emitter<CallState> emit) async {
    final listed = {for (final participant in participants) participant.callId};
    final vanished = state.conference.legIds.where((callId) => !listed.contains(callId)).toList();
    // The server un-holds a leg as it joins, so the flag on the call follows
    // it; nothing is asked of the operating system for this - see below.
    final unheld = [
      for (final call in state.activeCalls)
        if (listed.contains(call.callId) && call.held) call.callId,
    ];
    // The list is the server's account of the room; the legs are this
    // client's own record, and it records only calls it has. A participant
    // whose call this client no longer holds would otherwise become a leg
    // with nothing behind it: a nameless row whose controls do nothing, and
    // a call id the OS does not know in the group this client declares,
    // which fails the grouping for every other leg with it.
    final legs = {
      for (final entry in state.conference.legs.entries)
        if (listed.contains(entry.key)) entry.key: entry.value,
      for (final participant in participants)
        if (state.retrieveActiveCall(participant.callId) != null) participant.callId: participant.line,
    };
    // A leg this client did not record itself: an add whose acknowledgement
    // was lost or timed out, or a list that arrives after a reconnect. The
    // server counts it in the mix, so its own connection must go quiet -
    // membership and where its audio actually goes cannot disagree.
    final adopted = legs.keys.where((callId) => !state.conference.legs.containsKey(callId)).toList();
    emit(
      state
          .copyWithMappedActiveCalls((call) => unheld.contains(call.callId) ? call.copyWith(held: false) : call)
          .copyWith(
            conference: state.conference.copyWith(legs: legs, participants: participants),
          ),
    );
    await _quietLegs(adopted);
    // The group is the first thing the operating system is told about these
    // calls, and the hold the server took them off is not published at all.
    // CallKit does not keep two ungrouped calls active at once - it ends one -
    // and legs of a room are exactly that the moment the server un-holds them.
    // A member of a group is active by virtue of the group, so there is
    // nothing left for a hold change to say, and the plugin refuses one on a
    // member anyway.
    await _groupLegs();
    for (final callId in vanished) {
      if (await _restoreLegAudio(callId)) add(CallControlEvent.setHeld(callId, true));
    }
  }

  /// Puts the microphone on [callId]'s own connection, or takes it off.
  ///
  /// Mute is a property of one connection, not of the microphone: the app
  /// captures one pooled track and hands the same one to every call and to
  /// the conference room, so disabling that track would silence all of them
  /// at once. Detaching it from a sender stops only what that connection
  /// sends.
  Future<void> _setMicrophoneAttached(String callId, {required bool attached}) async {
    try {
      final peerConnection = await _callPeerConnectionManager.retrieve(callId, allowWaiting: false);
      if (peerConnection == null) return;
      final sender = await peerConnection.audioSender();
      if (sender == null) {
        _logger.warning('_setMicrophoneAttached: $callId has no audio sender, the microphone is unchanged');
        return;
      }
      if (!attached) {
        await sender.detachMicrophone();
        _logger.info('_setMicrophoneAttached: $callId detached');
        return;
      }
      final audioTrack = state.retrieveActiveCall(callId)?.localStream?.getAudioTracks().firstOrNull;
      if (audioTrack != null) await sender.attachMicrophone(audioTrack);
      _logger.info('_setMicrophoneAttached: $callId attached (track=${audioTrack?.id})');
    } catch (e, stackTrace) {
      callErrorReporter.handle(e, stackTrace, '_setMicrophoneAttached error');
    }
  }

  /// Tells the OS the legs are one grouped call. A platform that cannot
  /// group answers with an error that is not the app's; it is logged.
  Future<void> _groupLegs() async {
    final conference = state.conference;
    final room = conference.room;
    if (room == null || conference.legs.isEmpty) return;
    final error = await callkeep.setCallGroup('room-$room', conference.legIds.toList());
    if (error != null) _logger.warning('_groupLegs: setCallGroup error: $error');
  }

  /// Drops the room: its connection, the OS grouping and the state. With
  /// [restoreLegs] the legs still up become ordinary calls again - audio
  /// back on each, and all but the focused one on hold, since the server
  /// leaves them all active. Returns the ids of the legs restored.
  Future<List<String>> _leaveRoom(Emitter<CallState> emit, {required bool restoreLegs}) async {
    _conferenceAssemblyTimer?.cancel();
    _conferenceAttempt++;
    _legMutes.forgetAll();
    final legIds = state.conference.legIds.toList();
    final focused = state.focusedCall?.callId;
    // Not waited on: the mixer's connection serialises its own work, so a
    // teardown asked for while it is still opening runs after that and
    // closes it - but waiting here would hold the queue for exactly as long
    // as the operation this teardown exists to cut short. Giving the legs
    // their audio back touches their own connections, not this one.
    unawaited(_conferencePeerConnection.teardown());
    if (legIds.isNotEmpty) {
      final error = await callkeep.unsetCallGroup(legIds);
      if (error != null) _logger.warning('_leaveRoom: unsetCallGroup error: $error');
    }
    emit(state.copyWith(conference: const ConferenceState()));
    if (!restoreLegs) return const [];
    final restored = <String>[];
    for (final callId in legIds) {
      if (await _restoreLegAudio(callId)) restored.add(callId);
    }
    if (restored.isEmpty) return restored;
    // One of them carries on, the rest go on hold. Which one is the focused
    // call when that is one of these, and otherwise the first: the calls
    // leave the room all active on the server, so a client that only ever
    // added holds would leave every one of them held and the user in
    // silence. A leg merged while it was held is resumed the same way.
    final live = restored.contains(focused) ? focused! : restored.first;
    for (final callId in restored) {
      add(CallControlEvent.setHeld(callId, callId != live));
    }
    return restored;
  }

  // helpers

  Future<bool> _perform(_CallPerformEvent callPerformEvent) {
    add(callPerformEvent);
    return callPerformEvent.future;
  }

  Future<RTCPeerConnection> _createPeerConnection(String callId, int? lineId) {
    return _callPeerConnectionManager.createPeerConnection(
      callId,
      observer: PeerConnectionObserver(
        onSignalingState: (state) => add(_PeerConnectionEvent.signalingStateChanged(callId, state)),
        onConnectionState: (state) => add(_PeerConnectionEvent.connectionStateChanged(callId, state)),
        onIceGatheringState: (state) => add(_PeerConnectionEvent.iceGatheringStateChanged(callId, state)),
        onIceConnectionState: (state) => add(_PeerConnectionEvent.iceConnectionStateChanged(callId, state)),
        onIceCandidate: (candidate) => add(_PeerConnectionEvent.iceCandidateIdentified(callId, candidate)),
        onAddStream: (stream) => add(_PeerConnectionEvent.streamAdded(callId, stream)),
        onRemoveStream: (stream) => add(_PeerConnectionEvent.streamRemoved(callId, stream)),
        // onAddTrack fires during renegotiation when a new track is added to an
        // existing stream. In that case onAddStream does NOT re-fire (only fired
        // once per unique stream ID). Forwarding the stream here ensures the BLoC
        // state is updated with the latest stream reference when video is added
        // mid-call (e.g. after a glare-resolution rollback).
        onAddTrack: (stream, track) => add(_PeerConnectionEvent.streamAdded(callId, stream)),
        onTrack: (event) {
          // Typically fired on upgrade to video, without firing onAddStream.
          // The event may contain multiple streams but in practice we only handle the first one since our use case is limited to a single audio/video stream per call.
          final stream = event.streams.isNotEmpty ? event.streams.first : null;
          if (stream != null) {
            add(_PeerConnectionEvent.streamAdded(callId, stream));
          } else {
            _logger.warning('PeerConnectionObserver.onTrack fired with empty streams for callId=$callId');
          }
        },
        onRenegotiationNeeded: (pc) {
          // Skips initial triggering that happens during peer connection setup
          if (pc.signalingState != null) add(_PeerConnectionEvent.renegotiationNeeded(callId, lineId));
        },
      ),
    );
  }

  /// Attempts to execute a termination request immediately.
  /// If it fails due to connectivity issues, the request is queued for later retry.
  ///
  /// The [source] parameter is used for logging to indicate where the request originated.
  Future<void> _dispatchTerminationRequest({required QueuedTerminationRequest request, required String source}) async {
    /// Put upfront in the repository to ensure it's recorded even if the app is killed before the async operation completes.
    queuedTerminationRequestsRepository.put(request);
    try {
      await _executeTerminationRequest(request);
      // Acknowledged, not yet done: the entry stays until the server's hangup
      // for the call confirms it, so a handshake planned in between still
      // sees the call as one being ended rather than as one to bring back.
    } on WebtritSignalingErrorException catch (e, s) {
      // The server received the request and refused it - the call is gone
      // already, or the request is not applicable to it. Sending the same
      // request again on the next handshake would get the same answer, and a
      // queued entry would only end up in that handshake's plan.
      queuedTerminationRequestsRepository.remove(request);
      _logger.warning('_dispatchTerminationRequest refused by the server, not retried. source=$source', e, s);
    } catch (e, s) {
      // The request did not reach the server (socket down, timeout): it is
      // replayed from the repository by the next handshake.
      _logger.warning('_dispatchTerminationRequest failed, request queued for retry. source=$source', e, s);
    }
  }

  Future<void> _executeTerminationRequest(QueuedTerminationRequest request) async {
    switch (request.type) {
      case QueuedTerminationRequestType.hangup:
        await _signalingModule.execute(
          HangupRequest(
            transaction: WebtritSignalingClient.generateTransactionId(),
            line: request.line,
            callId: request.callId,
          ),
        );
      case QueuedTerminationRequestType.decline:
        await _signalingModule.execute(
          DeclineRequest(
            transaction: WebtritSignalingClient.generateTransactionId(),
            line: request.line,
            callId: request.callId,
          ),
        );
    }
  }

  void _addToRecents(ActiveCall activeCall) {
    final number = activeCall.handle.value;
    final username = activeCall.displayName;

    _logger.info(
      '[Recents:store] '
      'direction=${activeCall.direction.name} '
      'number.hash=${number.hashCode} '
      'username.hash=${username?.hashCode} '
      'numberEqualsUsername=${number == username} '
      'usernameIsNull=${username == null}',
    );

    NewCall call = (
      direction: activeCall.direction,
      number: number,
      video: activeCall.video,
      username: username,
      createdTime: activeCall.createdTime,
      acceptedTime: activeCall.acceptedTime,
      hungUpTime: activeCall.hungUpTime,
    );
    callLogsRepository.add(call);
  }

  Future<void> _releaseLocalStream(MediaStream? stream) async {
    if (stream == null) return;
    await userMediaBuilder.release(stream);
  }

  Future<void> _assignInitialPresence(List<SignalingPresenceInfo> data) async {
    _logger.info('Received initial presence info: ${data.length} entries');

    final presenceInfo = data.map(SignalingPresenceInfoMapper.fromSignaling).toList();
    presenceInfoRepository.setInitialPresenceInfo(presenceInfo);
  }

  Future<void> _assignNumberPresence(String number, List<SignalingPresenceInfo> data) async {
    _logger.info('Received presence update for number $number: ${data.length} entries');

    final presenceInfo = data.map(SignalingPresenceInfoMapper.fromSignaling).toList();
    presenceInfoRepository.setNumberPresence(number, presenceInfo);
  }

  Future<void> _assignInitialDialogs(List<SignalingDialogInfo> data) async {
    _logger.info('Received initial dialogs: ${data.length} dialogs');

    final dialogInfos = data.map(SignalingDialogInfoMapper.fromSignaling).toList();
    dialogInfoRepository.setInitialDialogInfo(dialogInfos);
  }

  Future<void> _assignNumberDialogs(String number, List<SignalingDialogInfo> data) async {
    _logger.info('Received dialogs update for number $number: ${data.length} dialogs');

    final dialogInfos = data.map(SignalingDialogInfoMapper.fromSignaling).toList();
    dialogInfoRepository.setNumberDialogs(number, dialogInfos);
  }

  Future<void> syncPresenceSettings() async {
    final now = DateTime.now();
    final lastSync = presenceSettingsRepository.lastSettingsSync;
    final presenceSettings = presenceSettingsRepository.presenceSettings;

    final canUpdate = state.callServiceState.status == CallStatus.ready;
    bool shouldUpdate = false;
    if (lastSync == null) {
      shouldUpdate = true;
    } else if (presenceSettings.timestamp.difference(lastSync).inSeconds > 0) {
      shouldUpdate = true;
    } else if (now.difference(lastSync).inMinutes >= 30) {
      shouldUpdate = true;
    }

    if (shouldUpdate && canUpdate) {
      _logger.fine('_presenceInfoSyncTimer: updating presence settings');
      try {
        await _signalingModule.execute(
          PresenceSettingsUpdateRequest(
            transaction: clock.now().millisecondsSinceEpoch.toString(),
            settings: SignalingPresenceSettingsMapper.toSignaling(presenceSettings),
          ),
        );
        presenceSettingsRepository.updateLastSettingsSync(now);
        _logger.fine('Presence settings updated at $now');
      } on Exception catch (e, s) {
        _logger.warning('Failed to update presence settings', e, s);
      }
    }
  }

  void _checkSenderResult(RTCRtpSender? senderResult, String kind) {
    if (senderResult == null) {
      _logger.warning('safeAddTrack for $kind returned null: track not added, possibly due to closed connection');
    }
  }

  /// Schedules an ICE restart for [callId] after a short delay to allow a newly created
  /// network interface (e.g. VPN tunnel) to finish initializing before ICE probing starts.
  /// Any pending restart for the same call is cancelled and rescheduled on each call, so
  /// rapid consecutive connectivity events result in a single restart.
  void _scheduleIceRestart(String callId) {
    if (isClosed) return;
    _iceRestartDebounce.schedule(callId, () => add(_IceRestartTriggered(callId)));
  }

  Future<void> _onIceRestartTriggered(_IceRestartTriggered event, Emitter<CallState> emit) async {
    add(_CallMutationEvent.restartIce(event.callId));
  }

  Never _onGetUserMediaPushKitTimeout() {
    _logger.warning(
      'getUserMedia blocked for ${_getUserMediaPushKitTimeout.inSeconds}s — aborting to stay within PushKit deadline',
    );
    throw TimeoutException('getUserMedia timeout', _getUserMediaPushKitTimeout);
  }
}
