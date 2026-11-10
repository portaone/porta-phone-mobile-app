import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:ssl_certificates/ssl_certificates.dart';

import 'package:webtrit_phone/app/session/signaling_inbound.dart';

/// A client the test speaks for: it hands the module a handshake and events
/// when the test says so.
class _Client extends Fake implements WebtritSignalingClient {
  StateHandshakeHandler? _onStateHandshake;
  EventHandler? _onEvent;
  DisconnectHandler? _onDisconnect;

  @override
  void listen({
    required StateHandshakeHandler onStateHandshake,
    required EventHandler onEvent,
    required ErrorHandler onError,
    required DisconnectHandler onDisconnect,
  }) {
    _onStateHandshake = onStateHandshake;
    _onEvent = onEvent;
    _onDisconnect = onDisconnect;
  }

  void handshake(StateHandshake handshake) => _onStateHandshake!(handshake);

  void event(Event event) => _onEvent!(event);

  @override
  Future<void> disconnect([int? code, String? reason]) async => _onDisconnect?.call(code, reason);

  @override
  Future<void> execute(Request request, [Duration? timeout]) async {}
}

const _handshake = StateHandshake(
  keepaliveInterval: Duration(seconds: 30),
  timestamp: 0,
  registration: Registration(status: RegistrationStatus.registered),
  lines: [null],
  dialogInfos: [],
  presenceInfos: [],
  guestLine: null,
);

// The inbound holds no subscription of its own: what a consumer that listens
// late gets is what the real module replays to a new listener of its events.
void main() {
  late _Client client;
  late SignalingModuleImpl module;
  late SignalingInbound inbound;

  setUp(() async {
    client = _Client();
    module = SignalingModuleImpl(
      coreUrl: 'https://example.com',
      tenantId: 'tenant',
      token: 'token',
      trustedCertificates: TrustedCertificates.empty,
      clientFactory: ({
        required Uri url,
        required String tenantId,
        required String token,
        required Duration connectionTimeout,
        required TrustedCertificates certs,
        required bool force,
      }) async => client,
    );
    inbound = SignalingInbound(() => module.events);
    module.connect();
    await pumpEventQueue();
    client.handshake(_handshake);
  });

  tearDown(() => module.dispose());

  test('a consumer that listens after the session is up gets the connection and the handshake', () async {
    final received = <SignalingModuleEvent>[];
    inbound.call.listen(received.add);
    await pumpEventQueue();

    expect(received.map((event) => event.runtimeType), [
      SignalingConnecting,
      SignalingConnected,
      SignalingHandshakeReceived,
    ]);
    expect((received.last as SignalingHandshakeReceived).handshake.registration.status, RegistrationStatus.registered);
  });

  test(
    'a protocol event heard before a consumer listens is not replayed to it, only folded into the handshake',
    () async {
      client.event(const ConferenceTerminatedEvent(room: 1));
      await pumpEventQueue();

      final received = <SignalingModuleEvent>[];
      inbound.call.listen(received.add);
      await pumpEventQueue();

      expect(received.whereType<SignalingProtocolEvent>(), isEmpty);
    },
  );

  test('a consumer that listens early hears what comes after live, in order', () async {
    final received = <SignalingModuleEvent>[];
    inbound.call.listen(received.add);
    await pumpEventQueue();
    received.clear();

    client.event(const ConferenceTerminatedEvent(room: 1));
    await pumpEventQueue();

    expect(
      received.single,
      isA<SignalingProtocolEvent>().having((e) => e.event, 'event', const ConferenceTerminatedEvent(room: 1)),
    );
  });
}
