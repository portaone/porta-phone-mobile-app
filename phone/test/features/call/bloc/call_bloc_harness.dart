import 'dart:async';
import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
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
    Duration conferenceAssemblyTimeout = const Duration(seconds: 20),
  }) {
    TestWidgetsFlutterBinding.ensureInitialized();
    installPlatformStubs();
    bloc = CallBloc(
      callLogsRepository: _FakeCallLogsRepository(),
      onMissedCall: (_, _) {},
      linesStateRepository: LinesStateRepositoryInMemoryImpl(),
      presenceInfoRepository: _FakePresenceInfoRepository(),
      dialogInfoRepository: _FakeDialogInfoRepository(),
      presenceSettingsRepository: _FakePresenceSettingsRepository(),
      queuedTerminationRequestsRepository: terminationQueue,
      resolveOutgoingFromNumber: (from, _) => from,
      onSessionMissedReported: () async {},
      submitNotification: notifications.add,
      callkeep: callkeep,
      callkeepConnections: callkeepConnections ?? _FakeCallkeepConnections(),
      userMediaBuilder: userMediaBuilder ?? media,
      contactResolver: _FakeContactResolver(),
      callErrorReporter: errors,
      sendPresenceSettings: sendPresenceSettings,
      capabilities: capabilities,
      onDiagnosticReportRequested: (_, _) {},
      signalingModule: signaling,
      callPeerConnectionManager: peers,
      connectivityService: _FakeConnectivityService(),
      conferenceAssemblyTimeout: conferenceAssemblyTimeout,
    );
  }

  late final CallBloc bloc;
  final FakeSignalingModule signaling = FakeSignalingModule();
  final FakeCallkeep callkeep = FakeCallkeep();
  final FakeQueuedTerminationRequestsRepository terminationQueue = FakeQueuedTerminationRequestsRepository();
  final RecordingCallErrorReporter errors = RecordingCallErrorReporter();
  final FakePeerConnectionFactory peerFactory = FakePeerConnectionFactory();
  final FakeUserMediaBuilder media = FakeUserMediaBuilder();
  late final CallPeerConnectionManager peers = CallPeerConnectionManager(factory: peerFactory);

  /// Everything the bloc asked the user to see, in order.
  final List<Notification> notifications = [];

  /// Puts an answered call into the state with a peer connection the manager
  /// already holds for it, the way the bloc leaves a call once it is up:
  /// its microphone on the connection's audio sender, the far end's audio
  /// in its remote stream. Returns the fake peer connection so the test can
  /// check what was done to it.
  FakePeerConnection seedEstablishedCall(
    String callId, {
    int line = 0,
    bool held = false,
    CallDirection direction = CallDirection.outgoing,
    String number = '100',
  }) {
    // The microphone comes from the one builder, so a seeded call holds the
    // same track object the room and every other call hold - as in production.
    final localStream = media.buildSync();
    final remoteStream = FakeMediaStream(
      'remote-$callId',
      tracks: [FakeMediaStreamTrack(kind: 'audio', id: 'far-$callId')],
    );
    final peer = FakePeerConnection(audioTrack: localStream.getAudioTracks().single);
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
      localStream: localStream,
      remoteStream: remoteStream,
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
  /// the other side, so the calls are answered with nothing. Installed by
  /// the harness; a test of a part that touches media without the bloc
  /// installs them itself.
  static void installPlatformStubs() {
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
  final _session = SignalingEventBuffer();

  /// Every request the bloc executed, in order.
  final List<Request> requests = [];

  /// Thrown by [execute] instead of an ack while set.
  Object? failure;

  /// While set, [execute] records the request and then waits for this to
  /// complete before answering - to interleave something with a request in
  /// flight.
  Completer<void>? gate;

  bool connected = true;

  /// Whether a request can be handed over at all. A real module answers a
  /// request it cannot send with `null` rather than with a future.
  bool sendable = true;

  @override
  Stream<SignalingModuleEvent> get events => _events.stream;

  @override
  bool get isConnected => connected;

  @override
  Future<void>? execute(Request request) {
    if (!sendable) return null;
    return _execute(request);
  }

  Future<void> _execute(Request request) async {
    requests.add(request);
    await gate?.future;
    final error = failure;
    if (error != null) throw error;
  }

  /// Delivers [event] to the bloc as if the server sent it.
  void emit(Event event) => _add(SignalingProtocolEvent(event: event));

  /// A hangup cancels the call's pending requests; there is no queue here.
  @override
  void cancelRequestsByCallId(String callId) {}

  @override
  void clearTerminatingMark(String callId) {}

  /// Delivers [handshake] to the bloc as if the session had just (re)connected.
  void emitHandshake(StateHandshake handshake) => _add(SignalingHandshakeReceived(handshake: handshake));

  void _add(SignalingModuleEvent event) {
    _session.onEvent(event);
    _events.add(event);
  }

  /// The session as a real module keeps it: the handshake folded with every
  /// event delivered since.
  @override
  StateHandshake? get sessionHandshake => _session.sessionHandshake;

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

  /// What the OS was told about each call's microphone, in order.
  final List<({String callId, bool muted})> muted = [];
  final List<String> endCalls = [];
  final List<({String callId, bool onHold})> held = [];
  final List<({String groupId, List<String> callIds})> groups = [];
  final List<List<String>> ungroups = [];

  CallkeepDelegate? _delegate;

  @override
  void setDelegate(CallkeepDelegate? delegate) => _delegate = delegate;

  @override
  Future<void> reportEndCall(String callId, String displayName, CallkeepEndCallReason reason) async {
    ended.add(callId);
  }

  /// While true the reports are held back instead of being delivered, so a
  /// test can let a command be overtaken by a later one. The command itself
  /// still completes, as it does on the platform, which does not wait for the
  /// report either.
  bool deferMuteReports = false;

  final _heldMuteReports = Queue<({String callId, bool muted})>();

  /// How many reports are still waiting to be delivered.
  int get heldMuteReports => _heldMuteReports.length;

  /// Delivers the held reports in the order they were produced, which is the
  /// order the platform delivers them in.
  Future<void> flushMuteReports({int? count}) async {
    final many = count ?? _heldMuteReports.length;
    for (var i = 0; i < many && _heldMuteReports.isNotEmpty; i++) {
      final report = _heldMuteReports.removeFirst();
      await _delegate?.performSetMuted(report.callId, report.muted);
      await pumpEventQueue();
    }
  }

  /// Records the request and reports the new state back, the way the platform
  /// does: it keeps a mute state per call and publishes every change of it to
  /// the application, including the ones the application asked for.
  @override
  Future<CallkeepCallRequestError?> setMuted(String callId, {required bool muted}) async {
    this.muted.add((callId: callId, muted: muted));
    if (deferMuteReports) {
      _heldMuteReports.add((callId: callId, muted: muted));
    } else {
      unawaited(_delegate?.performSetMuted(callId, muted));
    }
    return null;
  }

  @override
  Future<CallkeepCallRequestError?> endCall(String callId) async {
    endCalls.add(callId);
    return null;
  }

  /// While set, a hold waits for this before answering - the native round
  /// trip a handshake can land inside.
  Completer<void>? holdGate;

  @override
  Future<CallkeepCallRequestError?> setHeld(String callId, {required bool onHold}) async {
    held.add((callId: callId, onHold: onHold));
    await holdGate?.future;
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

/// A peer connection that records what it was asked and answers every
/// negotiation step with a placeholder description.
class FakePeerConnection extends Fake implements RTCPeerConnection {
  FakePeerConnection({MediaStreamTrack? audioTrack}) {
    if (audioTrack != null) {
      final sender = FakeRtpSender(audioTrack);
      _senders.add(sender);
      _kinds[sender] = 'audio';
    }
  }

  /// The kind each sender was created for, so the audio one is still
  /// recognisable once its track has been taken off.
  final Map<FakeRtpSender, String> _kinds = {};

  int closes = 0;
  final List<FakeRtpSender> _senders = [];
  final List<MediaStreamTrack> addedTracks = [];
  final List<RTCSessionDescription> remoteDescriptions = [];
  final List<RTCSessionDescription> localDescriptions = [];
  final List<RTCIceCandidate> candidates = [];

  /// The senders as the bloc sees them; the audio one is first when seeded.
  List<FakeRtpSender> get fakeSenders => List.unmodifiable(_senders);

  @override
  Function(RTCIceCandidate candidate)? onIceCandidate;

  @override
  Function(RTCIceGatheringState state)? onIceGatheringState;

  @override
  Function(RTCPeerConnectionState state)? onConnectionState;

  @override
  RTCPeerConnectionState? connectionState;

  @override
  Future<void> close() async {
    closes++;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<List<RTCRtpSender>> getSenders() async => List.of(_senders);

  @override
  Future<List<RTCRtpTransceiver>> getTransceivers() async => [
    for (final sender in _senders)
      FakeRtpTransceiver(sender: sender, kind: _kinds[sender] ?? sender.track?.kind ?? 'audio'),
  ];

  @override
  Future<List<RTCRtpSender>> get senders => getSenders();

  @override
  Future<RTCRtpSender> addTrack(MediaStreamTrack track, [MediaStream? stream]) async {
    addedTracks.add(track);
    final sender = FakeRtpSender(track);
    _kinds[sender] = track.kind ?? 'audio';
    _senders.add(sender);
    return sender;
  }

  @override
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    remoteDescriptions.add(description);
  }

  @override
  Future<RTCSessionDescription> createAnswer([Map<String, dynamic>? constraints]) async =>
      RTCSessionDescription('v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n', 'answer');

  @override
  Future<void> setLocalDescription(RTCSessionDescription description) async {
    localDescriptions.add(description);
  }

  @override
  Future<void> addCandidate(RTCIceCandidate candidate) async {
    candidates.add(candidate);
  }
}

class FakeRtpTransceiver extends Fake implements RTCRtpTransceiver {
  FakeRtpTransceiver({required this.sender, required String kind}) : receiver = FakeRtpReceiver(kind);

  @override
  final RTCRtpSender sender;

  @override
  final RTCRtpReceiver receiver;
}

class FakeRtpReceiver extends Fake implements RTCRtpReceiver {
  FakeRtpReceiver(String kind) : track = FakeMediaStreamTrack(kind: kind, id: 'remote-$kind');

  @override
  final MediaStreamTrack? track;
}

class FakeRtpSender extends Fake implements RTCRtpSender {
  FakeRtpSender(this._track);

  MediaStreamTrack? _track;

  /// Every track put on the sender since it was created, `null` included.
  final List<MediaStreamTrack?> replaced = [];

  @override
  MediaStreamTrack? get track => _track;

  @override
  Future<void> replaceTrack(MediaStreamTrack? track) async {
    replaced.add(track);
    _track = track;
  }
}

class FakeMediaStreamTrack extends Fake implements MediaStreamTrack {
  FakeMediaStreamTrack({required this.kind, required this.id});

  @override
  final String? kind;

  @override
  final String? id;

  @override
  bool enabled = true;

  bool stopped = false;

  @override
  Future<void> stop() async {
    stopped = true;
  }
}

class FakeMediaStream extends Fake implements MediaStream {
  FakeMediaStream(this.id, {required List<MediaStreamTrack> tracks}) : _tracks = tracks;

  @override
  final String id;

  final List<MediaStreamTrack> _tracks;

  @override
  List<MediaStreamTrack> getTracks() => List.of(_tracks);

  @override
  List<MediaStreamTrack> getAudioTracks() => _tracks.where((track) => track.kind == 'audio').toList();

  @override
  List<MediaStreamTrack> getVideoTracks() => _tracks.where((track) => track.kind == 'video').toList();

  @override
  Future<void> dispose() async {}
}

/// Hands out fake streams the way [DefaultUserMediaBuilder] does: every
/// stream is new, but they all carry the SAME microphone track, reference
/// counted, and the last release stops it.
///
/// Modelling this is the point of the fake. The app captures one microphone
/// and lends it to every call and to the conference room, so anything that
/// mutes or stops that track affects all of them at once - a fake handing out
/// a track per call turns an app-wide defect into correct-looking per-call
/// behaviour.
class FakeUserMediaBuilder extends Fake implements UserMediaBuilder {
  final List<FakeMediaStream> built = [];
  final List<MediaStream> released = [];

  /// The one microphone, as the device has one.
  final FakeMediaStreamTrack microphone = FakeMediaStreamTrack(kind: 'audio', id: 'mic');
  int _references = 0;

  /// Whether the microphone is still captured; the last release stops it.
  bool get microphoneLive => !microphone.stopped;

  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async =>
      buildSync(video: video);

  /// [build] without the await, for seeding a call.
  FakeMediaStream buildSync({bool video = false}) {
    final stream = FakeMediaStream(
      'media-${built.length}',
      tracks: [
        microphone,
        if (video) FakeMediaStreamTrack(kind: 'video', id: 'cam-${built.length}'),
      ],
    );
    _references++;
    built.add(stream);
    return stream;
  }

  @override
  Future<void> release(MediaStream stream) async {
    released.add(stream);
    if (--_references <= 0) microphone.stopped = true;
  }
}

/// Creates [FakePeerConnection]s and keeps them, in order.
class FakePeerConnectionFactory implements PeerConnectionFactory {
  final List<FakePeerConnection> created = [];

  @override
  Future<RTCPeerConnection> create([
    Map<String, dynamic> configuration = const {},
    Map<String, dynamic> constraints = const {},
  ]) async {
    final peerConnection = FakePeerConnection();
    created.add(peerConnection);
    return peerConnection;
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

/// Records the termination requests the bloc queues for a later handshake.
class FakeQueuedTerminationRequestsRepository extends Fake implements QueuedTerminationRequestsRepository {
  final Map<String, QueuedTerminationRequest> requests = {};

  @override
  Map<String, QueuedTerminationRequest> get getAll => Map.unmodifiable(requests);

  @override
  void put(QueuedTerminationRequest request) => requests[request.callId] = request;

  @override
  void remove(QueuedTerminationRequest request) => requests.remove(request.callId);
}

/// No native connections: what the plugin reports on iOS, and on Android
/// while nothing is up.
class _FakeCallkeepConnections extends Fake implements CallkeepConnections {
  @override
  Future<CallkeepConnection?> getConnection(String callId) async => null;

  @override
  Future<List<CallkeepConnection>> getConnections() async => const [];
}

class _FakeContactResolver extends Fake implements ContactResolver {
  @override
  Future<Contact?> resolve(String? number) async => null;
}

class _FakeConnectivityService extends Fake implements ConnectivityService {}
