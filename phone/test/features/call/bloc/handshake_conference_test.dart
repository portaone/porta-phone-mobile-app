import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'call_bloc_harness.dart';

/// A conference room the server reports on (re)connect is one this client
/// cannot rejoin, so the bloc hangs the room up; the calls in it are left to
/// the ordinary restoration.
void main() {
  late CallBlocHarness h;

  setUp(() => h = CallBlocHarness());
  tearDown(() => h.close());

  StateHandshake handshake({ConferenceInfo? conference}) => StateHandshake(
    keepaliveInterval: const Duration(seconds: 30),
    timestamp: 0,
    registration: const Registration(status: RegistrationStatus.registered),
    lines: const [],
    presenceInfos: const [],
    dialogInfos: const [],
    guestLine: null,
    conference: conference,
  );

  test('a room in the handshake is hung up', () async {
    h.signaling.emitHandshake(handshake(conference: const ConferenceInfo(room: 4242)));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
    expect(h.errors.errors, isEmpty);
  });

  test('a handshake without a room asks for nothing', () async {
    h.signaling.emitHandshake(handshake());
    await pumpEventQueue();

    expect(h.signaling.requests, isEmpty);
  });

  test('a refused hangup is reported, not thrown', () async {
    h.signaling.failure = const WebtritSignalingErrorException(1, 0, 'no_conference');

    h.signaling.emitHandshake(handshake(conference: const ConferenceInfo(room: 4242)));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<ConferenceHangupRequest>(), hasLength(1));
    expect(h.errors.errors, hasLength(1));
  });
}
