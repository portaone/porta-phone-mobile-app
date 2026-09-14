import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

/// A real [CallBloc] with every collaborator that reaches outside the process
/// replaced by a fake the test controls: signaling answers when and how the
/// test says, callkeep and the peer connection record what they were asked,
/// and nothing else is mocked. The production event handlers, the mutation
/// queue and `onChange` run unchanged, so a test drives the bloc through its
/// public surface - the delegate callbacks and [CallBloc.add] - and reads the
/// outcome from [CallBloc.state] and the fakes.
///
/// Seeding goes through the bloc's test seam ([CallBloc.emit]) rather than
/// through a whole incoming-call sequence: a test about hold should not have
/// to negotiate an offer first.
///
/// Usage:
///
/// ```dart
/// late CallBlocHarness h;
/// setUp(() => h = CallBlocHarness());
/// tearDown(() => h.close());
///
/// test('...', () async {
///   h.seedEstablishedCall('a');
///   h.signaling.failure = NotConnectedException();
///   await h.bloc.performSetHeld('a', true);
///   await pumpEventQueue();
///   expect(h.bloc.state.activeCalls.single.held, isFalse);
/// });
/// ```
class CallBlocHarness {
  CallBlocHarness({
    bool sendPresenceSettings = false,
    UserMediaBuilder? userMediaBuilder,
    CallkeepConnections? callkeepConnections,
    CallCapabilitiesConfig capabilities = const CallCapabilitiesConfig(),
  }) {
    TestWidgetsFlutterBinding.ensureInitialized();
    _installPlatformStubs();
    bloc = CallBloc(
      callLogsRepository: _FakeCallLogsRepository(),
      onMissedCall: (_, _) {},
      linesStateRepository: LinesStateRepositoryInMemoryImpl(),
      presenceInfoRepository: _FakePresenceInfoRepository(),
      dialogInfoRepository: _FakeDialogInfoRepository(),
      presenceSettingsRepository: _FakePresenceSettingsRepository(),
      queuedTerminationRequestsRepository: _FakeQueuedTerminationRequestsRepository(),
      resolveOutgoingFromNumber: (from, _) => from,
      onSessionMissedReported: () async {},
      submitNotification: notifications.add,
      callkeep: callkeep,
      callkeepConnections: callkeepConnections ?? _FakeCallkeepConnections(),
      userMediaBuilder: userMediaBuilder ?? _FakeUserMediaBuilder(),
      contactResolver: _FakeContactResolver(),
      callErrorReporter: errors,
      sendPresenceSettings: sendPresenceSettings,
      capabilities: capabilities,
      onDiagnosticReportRequested: (_, _) {},
      signalingModule: signaling,
      peerConnectionManager: peers,
      connectivityService: _FakeConnectivityService(),
    );
  }

  late final CallBloc bloc;
  final FakeSignalingModule signaling = FakeSignalingModule();
  final FakeCallkeep callkeep = FakeCallkeep();
  final RecordingCallErrorReporter errors = RecordingCallErrorReporter();
  final PeerConnectionManager peers = PeerConnectionManager();

  /// Everything the bloc asked the user to see, in order.
  final List<Notification> notifications = [];

  /// Puts an answered call into the state with a peer connection the manager
  /// already holds for it, the way the bloc leaves a call once it is up.
  /// Returns the fake peer connection so the test can check it was, or was
  /// not, closed.
  FakePeerConnection seedEstablishedCall(
    String callId, {
    int line = 0,
    bool held = false,
    CallDirection direction = CallDirection.outgoing,
    String number = '100',
  }) {
    final peer = FakePeerConnection();
    final call = ActiveCall(
      direction: direction,
      line: line,
      callId: callId,
      handle: CallkeepHandle.number(number),
      createdTime: DateTime(2026),
      video: false,
      held: held,
      processingStatus: CallProcessingStatus.connected,
      acceptedTime: DateTime(2026),
    );
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    bloc.emit(bloc.state.copyWithPushActiveCall(call));
    peers.complete(callId, peer);
    return peer;
  }

  Future<void> close() async {
    await bloc.close();
    await signaling.close();
  }

  static bool _stubsInstalled = false;

  /// flutter_webrtc and callkeep reach for platform channels the moment the
  /// bloc touches media or the native call UI; in a test there is nobody on
  /// the other side, so the calls are answered with nothing.
  static void _installPlatformStubs() {
    if (_stubsInstalled) return;
    _stubsInstalled = true;
    WebtritCallkeepPlatform.instance = _FakeCallkeepPlatform();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in const ['FlutterWebRTC.Method', 'FlutterWebRTC.Event']) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), (_) async => null);
    }
  }
}

/// The signaling module as the test wants it: every request is recorded, and
/// answered with an ack unless [failure] is set, after [gate] releases it when
/// one is set. Events reach the bloc through [emit].
class FakeSignalingModule extends Fake implements SignalingModule {
  final _events = StreamController<SignalingModuleEvent>.broadcast();

  /// Every request the bloc executed, in order.
  final List<Request> requests = [];

  /// Thrown by [execute] instead of an ack while set.
  Object? failure;

  /// While set, [execute] records the request and then waits for this to
  /// complete before answering - to interleave something with a request in
  /// flight.
  Completer<void>? gate;

  bool connected = true;

  @override
  Stream<SignalingModuleEvent> get events => _events.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void> execute(Request request) async {
    requests.add(request);
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
  }

  /// Delivers [event] to the bloc as if the server sent it.
  void emit(Event event) => _events.add(SignalingProtocolEvent(event: event));

  /// A hangup cancels the call's pending requests; there is no queue here.
  @override
  void cancelRequestsByCallId(String callId) {}

  @override
  void clearTerminatingMark(String callId) {}

  /// Delivers [handshake] to the bloc as if the session had just (re)connected.
  void emitHandshake(StateHandshake handshake) => _events.add(SignalingHandshakeReceived(handshake: handshake));

  Future<void> close() => _events.close();
}

/// Records what the bloc asked the OS to do; every request is accepted.
class FakeCallkeep extends Fake implements Callkeep {
  @override
  Future<CallkeepIncomingCallError?> reportNewIncomingCall(
    String callId,
    CallkeepHandle handle, {
    String? displayName,
    bool hasVideo = false,
  }) async => null;

  @override
  Future<void> reportUpdateCall(
    String callId, {
    CallkeepHandle? handle,
    String? displayName,
    bool? hasVideo,
    bool? proximityEnabled,
  }) async {}

  final List<String> ended = [];
  final List<({String callId, bool onHold})> held = [];
  final List<({String groupId, List<String> callIds})> groups = [];
  final List<List<String>> ungroups = [];

  @override
  void setDelegate(CallkeepDelegate? delegate) {}

  @override
  Future<void> reportEndCall(String callId, String displayName, CallkeepEndCallReason reason) async {
    ended.add(callId);
  }

  @override
  Future<CallkeepCallRequestError?> setHeld(String callId, {required bool onHold}) async {
    held.add((callId: callId, onHold: onHold));
    return null;
  }

  @override
  Future<CallkeepCallRequestError?> setCallGroup(String groupId, List<String> callIds) async {
    groups.add((groupId: groupId, callIds: List.of(callIds)));
    return null;
  }

  @override
  Future<CallkeepCallRequestError?> unsetCallGroup(List<String> callIds) async {
    ungroups.add(List.of(callIds));
    return null;
  }
}

class FakePeerConnection extends Fake implements RTCPeerConnection {
  int closes = 0;

  @override
  Future<void> close() async {
    closes++;
  }
}

class RecordingCallErrorReporter implements CallErrorReporter {
  final List<Object> errors = [];

  @override
  void handle(Object error, StackTrace? stack, String context) => errors.add(error);
}

class _FakeCallkeepPlatform extends WebtritCallkeepPlatform {
  @override
  Future<void> stopRingbackSound() async {}
}

class _FakeCallLogsRepository extends Fake implements CallLogsRepository {
  @override
  Future<void> add(NewCall call) async {}
}

class _FakePresenceInfoRepository extends Fake implements PresenceInfoRepository {
  @override
  Future<void> setInitialPresenceInfo(List<PresenceInfo> presenceInfos) async {}
}

class _FakeDialogInfoRepository extends Fake implements DialogInfoRepository {
  @override
  Future<void> setInitialDialogInfo(List<DialogInfo> dialogInfo) async {}
}

class _FakePresenceSettingsRepository extends Fake implements PresenceSettingsRepository {}

class _FakeQueuedTerminationRequestsRepository extends Fake implements QueuedTerminationRequestsRepository {
  @override
  Map<String, QueuedTerminationRequest> get getAll => const {};
}

/// No native connections: what the plugin reports on iOS, and on Android
/// while nothing is up.
class _FakeCallkeepConnections extends Fake implements CallkeepConnections {
  @override
  Future<CallkeepConnection?> getConnection(String callId) async => null;

  @override
  Future<List<CallkeepConnection>> getConnections() async => const [];
}

class _FakeUserMediaBuilder extends Fake implements UserMediaBuilder {}

class _FakeContactResolver extends Fake implements ContactResolver {
  @override
  Future<Contact?> resolve(String? number) async => null;
}

class _FakeConnectivityService extends Fake implements ConnectivityService {}
