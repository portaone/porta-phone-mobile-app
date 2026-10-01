import 'dart:async';

import 'package:logging/logging.dart';
import 'package:webtrit_callkeep_platform_interface/webtrit_callkeep_platform_interface.dart';

// TODO
// - convert to static abstract

/// Represents the status stages of the Callkeep setup process.
enum CallkeepStatus {
  /// The initial state when Callkeep is not yet set up.
  uninitialized,

  /// The state indicating Callkeep is in the process of configuring.
  configuring,

  /// The active state when Callkeep is fully set up and ready.
  active,

  /// The state when Callkeep is in the process of shutting down.
  terminating,
}

/// The [Callkeep] main class for managing platform specific callkeep operations.
/// e.g reporting incoming calls, handling outgoing calls, setting up platform VOIP integration etc.
/// The delegate is used to receive events from the native side.
class Callkeep {
  /// The singleton constructor of [Callkeep].
  factory Callkeep() => _instance;

  Callkeep._();

  static final _instance = Callkeep._();

  final StreamController<CallkeepStatus> _statusController = StreamController<CallkeepStatus>.broadcast();
  CallkeepStatus _currentStatus = CallkeepStatus.uninitialized;

  /// Getter for the current status
  CallkeepStatus get currentStatus => _currentStatus;

  /// Stream to subscribe to status updates
  Stream<CallkeepStatus> get statusStream => _statusController.stream;

  /// Method to update the status, ensuring status updates go through the stream
  void _updateStatus(CallkeepStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      _statusController.add(newStatus);
    }
  }

  /// The [WebtritCallkeepPlatform] instance used to perform platform specific operations.
  static WebtritCallkeepPlatform get platform => WebtritCallkeepPlatform.instance;

  /// Calls whose end the app reported before it ever held them, by call id, each with the
  /// version of its report; the most recent report is last.
  ///
  /// The platform can still present such a call to the delegate afterwards - Android replays
  /// a ringing connection to a delegate that attaches, iOS confirms a push registration - while
  /// the report itself travels to the native side through a queue the app's own start keeps
  /// busy. The knowledge that the call is over lives here, in the isolate that reported it, so
  /// the delegate is never handed the call (see [setDelegate]) and the app can ask before it
  /// applies a presentation it already received (see [wasEndedBeforePresented]).
  ///
  /// Only ends reported with [CallkeepEndCallReason.missedWhileConnecting] are kept: the end
  /// of a call the app held is its own knowledge, and that call's id stays free for a transfer
  /// back, as the platforms keep it. The map is bounded; the oldest report is forgotten first.
  final Map<String, int> _endsReportedUnseen = <String, int>{};
  int _endReportVersion = 0;
  static const _kEndsReportedUnseenLimit = 32;

  /// Whether the app reported the end of [callId] before it ever held that call, and nothing
  /// has reopened the id since.
  ///
  /// True after `reportEndCall(callId, ..., missedWhileConnecting)` until
  /// [reportNewIncomingCall] registers [callId] anew (returns null with no newer such report
  /// made meanwhile), [tearDown] runs, or 32 newer such reports push the entry out. A local,
  /// bounded fact of this [Callkeep] instance: false does not mean the call is alive, and the
  /// end of a call the app held (any other reason) is never recorded here.
  ///
  /// Ask this before applying a [CallkeepDelegate.didPresentIncomingCall] that was received
  /// earlier and waited on something asynchronous: the end may have been reported meanwhile.
  bool wasEndedBeforePresented(String callId) => _endsReportedUnseen.containsKey(callId);

  void _recordEndReportedUnseen(String callId) {
    _endsReportedUnseen.remove(callId);
    _endsReportedUnseen[callId] = ++_endReportVersion;
    while (_endsReportedUnseen.length > _kEndsReportedUnseenLimit) {
      _endsReportedUnseen.remove(_endsReportedUnseen.keys.first);
    }
  }

  /// Sets the delegate for receiving calkeep events from the native side.
  /// [CallkeepDelegate] needs to be implemented to receive callkeep events.
  ///
  /// The platform receives the delegate behind a gate: a
  /// [CallkeepDelegate.didPresentIncomingCall] for a call the app reported ended before it
  /// held it ([wasEndedBeforePresented]) is dropped here and never reaches [delegate].
  void setDelegate(CallkeepDelegate? delegate) {
    platform.setDelegate(delegate == null ? null : _EndAwareDelegate(delegate, this));
  }

  /// Sets the delegate for receiving push registry events from the native side.
  /// [PushRegistryDelegate] needs to be implemented to receive push registry events.
  void setPushRegistryDelegate(PushRegistryDelegate? delegate) {
    return platform.setPushRegistryDelegate(delegate);
  }

  /// Push token for push type VOIP.
  // TODO: unused, need clarification
  Future<String?> pushTokenForPushTypeVoIP() {
    return platform.pushTokenForPushTypeVoIP();
  }

  /// Check if CallKeep has been set up.
  /// Returns [Future] that completes with a [bool] value.
  Future<bool> isSetUp() {
    return platform.isSetUp();
  }

  /// Perform setup with the given [options].
  /// Returns [Future] that completes when the setup is done.
  Future<void> setUp(CallkeepOptions options) {
    _updateStatus(CallkeepStatus.configuring);
    return platform.setUp(options).then((_) => _updateStatus(CallkeepStatus.active));
  }

  /// Report the teardown state
  Future<void> tearDown() {
    _updateStatus(CallkeepStatus.terminating);
    _endsReportedUnseen.clear();
    return platform.tearDown().then((_) => _updateStatus(CallkeepStatus.uninitialized));
  }

  /// Report a new incoming call with the given [callId], [handle], [displayName] and [hasVideo] flag.
  /// Returns [CallkeepIncomingCallError] if there is an error.
  ///
  /// A registration the platform accepts as new (null) reopens [callId] for presentation after
  /// an end reported before the call was held ([wasEndedBeforePresented]) - unless a newer such
  /// report was made while this call was in flight. Any other outcome leaves that fact as it
  /// is, an adoption of a call the platform already holds included: the Android core answers
  /// [CallkeepIncomingCallError.callIdAlreadyExists] for a call it holds, and CallKit refuses a
  /// known UUID the same way, so a registration cannot reopen an id behind the old call's back.
  Future<CallkeepIncomingCallError?> reportNewIncomingCall(
    String callId,
    CallkeepHandle handle, {
    String? displayName,
    bool hasVideo = false,
  }) async {
    final reportedAs = _endsReportedUnseen[callId];
    final result = await platform.reportNewIncomingCall(callId, handle, displayName, hasVideo);
    if (reportedAs != null && result == null && _endsReportedUnseen[callId] == reportedAs) {
      _endsReportedUnseen.remove(callId);
    }
    return result;
  }

  /// Report that an outgoing call with given [callId] is connecting.
  /// Returns [Future] that completes when the operation is done.
  Future<void> reportConnectingOutgoingCall(String callId) {
    return platform.reportConnectingOutgoingCall(callId);
  }

  /// Report that an outgoing call with given [callId] has been connected.
  /// Returns [Future] that completes when the operation is done.
  Future<void> reportConnectedOutgoingCall(String callId) {
    return platform.reportConnectedOutgoingCall(callId);
  }

  /// Report an update to the call metadata.
  /// The [displayName] and [hasVideo] flag can be updated.
  /// Returns [Future] that completes when the operation is done.
  Future<void> reportUpdateCall(
    String callId, {
    CallkeepHandle? handle,
    String? displayName,
    bool? hasVideo,
    bool? proximityEnabled,
  }) {
    return platform.reportUpdateCall(callId, handle, displayName, hasVideo, proximityEnabled);
  }

  /// Report the end of call with the given [callId].
  /// The [displayName] of the call is required for reporting miseed call metadata.
  /// The [reason] for ending the call is required.
  /// Returns [Future] that completes when the operation is done.
  ///
  /// With [CallkeepEndCallReason.missedWhileConnecting] - the end of a call the app never held,
  /// learnt from signaling - the fact is kept here before the platform hears of it, so a
  /// presentation of that call the platform still has in flight is dropped
  /// ([wasEndedBeforePresented]).
  Future<void> reportEndCall(String callId, String displayName, CallkeepEndCallReason reason) {
    if (reason == CallkeepEndCallReason.missedWhileConnecting) _recordEndReportedUnseen(callId);
    return platform.reportEndCall(callId, displayName, reason);
  }

  /// Start a call with the given [callId], [handle], [displayNameOrContactIdentifier] and [hasVideo] flag.
  /// Returns [CallkeepCallRequestError] if there is an error.
  Future<CallkeepCallRequestError?> startCall(
    String callId,
    CallkeepHandle handle, {
    String? displayNameOrContactIdentifier,
    bool hasVideo = false,
    bool proximityEnabled = false,
  }) {
    return platform.startCall(callId, handle, displayNameOrContactIdentifier, hasVideo, proximityEnabled);
  }

  /// Answer a call with the given [callId].
  /// Returns [CallkeepCallRequestError] if there is an error.
  Future<CallkeepCallRequestError?> answerCall(String callId) {
    return platform.answerCall(callId);
  }

  /// End a call with the given [callId].
  /// Returns [CallkeepCallRequestError] if there is an error.
  Future<CallkeepCallRequestError?> endCall(String callId) {
    return platform.endCall(callId);
  }

  /// Set the call on hold with the given [callId] and [onHold] flag.
  /// Returns [CallkeepCallRequestError] if there is an error.
  Future<CallkeepCallRequestError?> setHeld(String callId, {required bool onHold}) {
    return platform.setHeld(callId, onHold);
  }

  /// Set the call on mute with the given [callId] and [muted] flag.
  /// Returns [CallkeepCallRequestError] if there is an error.
  Future<CallkeepCallRequestError?> setMuted(String callId, {required bool muted}) {
    return platform.setMuted(callId, muted);
  }

  /// Send DTMF with the given [callId] and [key].
  /// Returns [CallkeepCallRequestError] if there is an error.
  Future<CallkeepCallRequestError?> sendDTMF(String callId, String key) {
    return platform.sendDTMF(callId, key);
  }

  /// Present [callIds] to the operating system as the group of calls [groupId].
  ///
  /// Declarative and idempotent: the list is the whole membership, so adding a
  /// call means calling this again with every member. Every backend holds one
  /// group at a time today; a second [groupId] while another group is live
  /// answers [CallkeepCallRequestError.maximumCallGroupsReached].
  ///
  /// Returns [CallkeepCallRequestError] if there is an error, and
  /// [CallkeepCallRequestError.callGroupingNotSupported] where the active backend
  /// cannot group calls at all. Grouping is presentation: a failure leaves every
  /// call running.
  Future<CallkeepCallRequestError?> setCallGroup(String groupId, List<String> callIds) {
    return platform.setCallGroup(groupId, callIds);
  }

  /// Take [callIds] out of the group they are in, leaving those calls running.
  ///
  /// Passing every member takes the group apart; an empty list does nothing.
  ///
  /// Returns [CallkeepCallRequestError] if there is an error, and
  /// [CallkeepCallRequestError.callGroupingNotSupported] where the active backend
  /// cannot group calls at all.
  Future<CallkeepCallRequestError?> unsetCallGroup(List<String> callIds) {
    return platform.unsetCallGroup(callIds);
  }

  /// Set the speaker with the given [callId] and [enabled] flag.
  /// Returns [CallkeepCallRequestError] if there is an error.
  @Deprecated('Use setAudioDevice instead. This method will be removed in the next major version.')
  Future<CallkeepCallRequestError?> setSpeaker(String callId, {required bool enabled}) {
    return platform.setSpeaker(callId, enabled);
  }

  /// Set the audio device for the given [callId] and [device] flag.
  /// Returns [CallkeepCallRequestError] if there is an error.
  Future<CallkeepCallRequestError?> setAudioDevice(String callId, CallkeepAudioDevice device) {
    return platform.setAudioDevice(callId, device);
  }
}

/// The delegate as the platform sees it: everything is forwarded to the app's delegate except
/// the presentation of a call whose end the app already reported before holding it.
///
/// Implements the interface directly, without `noSuchMethod`: a method added to
/// [CallkeepDelegate] must be forwarded here too, and the analyzer says so.
class _EndAwareDelegate implements CallkeepDelegate {
  const _EndAwareDelegate(this._delegate, this._callkeep);

  /// Through `package:logging`, so the app's own sinks (logcat, its log file) carry the line:
  /// a drop here is otherwise visible only by the absence of the presentation that follows.
  static final _log = Logger('Callkeep');

  final CallkeepDelegate _delegate;
  final Callkeep _callkeep;

  @override
  void didPresentIncomingCall(
    CallkeepHandle handle,
    String? displayName,
    bool video,
    String callId,
    CallkeepIncomingCallError? error,
  ) {
    if (_callkeep.wasEndedBeforePresented(callId)) {
      _log.info('didPresentIncomingCall dropped: the app reported $callId ended before it held it');
      return;
    }
    _delegate.didPresentIncomingCall(handle, displayName, video, callId, error);
  }

  @override
  void continueStartCallIntent(CallkeepHandle handle, String? displayName, bool video) =>
      _delegate.continueStartCallIntent(handle, displayName, video);

  @override
  Future<bool> performStartCall(
    String callId,
    CallkeepHandle handle,
    String? displayNameOrContactIdentifier,
    bool video,
  ) => _delegate.performStartCall(callId, handle, displayNameOrContactIdentifier, video);

  @override
  Future<bool> performAnswerCall(String callId) => _delegate.performAnswerCall(callId);

  @override
  Future<bool> performEndCall(String callId) => _delegate.performEndCall(callId);

  @override
  Future<bool> performSetHeld(String callId, bool onHold) => _delegate.performSetHeld(callId, onHold);

  @override
  Future<bool> performSetMuted(String callId, bool muted) => _delegate.performSetMuted(callId, muted);

  @override
  Future<bool> performSendDTMF(String callId, String key) => _delegate.performSendDTMF(callId, key);

  @override
  Future<bool> performAudioDeviceSet(String callId, CallkeepAudioDevice device) =>
      _delegate.performAudioDeviceSet(callId, device);

  @override
  Future<bool> performAudioDevicesUpdate(String callId, List<CallkeepAudioDevice> devices) =>
      _delegate.performAudioDevicesUpdate(callId, devices);

  @override
  Future<bool> performSetCallGroup(String callId, String? groupWithCallId) =>
      _delegate.performSetCallGroup(callId, groupWithCallId);

  @override
  void didActivateAudioSession() => _delegate.didActivateAudioSession();

  @override
  void didDeactivateAudioSession() => _delegate.didDeactivateAudioSession();

  @override
  void didReset() => _delegate.didReset();
}
