import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

const _offer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};
const _incoming = IncomingCallEvent(line: 0, callId: 'call', caller: '100', callee: '200', jsep: _offer);

/// Where an answer that has begun arrives first: it asks for the microphone. The request is the
/// boundary of these tests - it is counted and refused, nothing native runs.
class _CountingMediaBuilder extends Fake implements UserMediaBuilder {
  int requests = 0;

  @override
  Future<MediaStream> build({required bool video, bool? frontCamera, bool allowAudioFallback = false}) async {
    requests++;
    throw const SignalingTransactionTerminateByDisconnectException(1, 'test', null, 'media boundary');
  }
}

const _ringingStatuses = {CallProcessingStatus.incomingFromPush, CallProcessingStatus.incomingFromOffer};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingMediaBuilder media;
  setUp(() => media = _CountingMediaBuilder());

  /// A call that came by its offer and rings.
  Future<CallBlocHarness> ringing() async {
    final h = CallBlocHarness(userMediaBuilder: media);
    addTearDown(h.close);
    h.signaling.emit(_incoming);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.single.processingStatus, CallProcessingStatus.incomingFromOffer);
    return h;
  }

  /// A call that came by its push and rings, its offer not here yet.
  Future<CallBlocHarness> ringingFromPush() async {
    final h = CallBlocHarness(userMediaBuilder: media);
    addTearDown(h.close);
    h.bloc.didPresentIncomingCall(const CallkeepHandle.number('100'), null, false, 'call', null);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.single.processingStatus, CallProcessingStatus.incomingFromPush);
    return h;
  }

  Future<void> accept(CallBlocHarness h) async {
    h.bloc.add(const CallControlEvent.answered('call'));
    await pumpEventQueue();
  }

  ActiveCall call(CallBlocHarness h) => h.bloc.state.activeCalls.single;

  /// The platform says the answer has begun.
  Future<void> platformBeginsAnswer(CallBlocHarness h) async {
    await h.bloc.performAnswerCall('call');
    await pumpEventQueue();
  }

  /// Whether the call is still an unanswered one the user could press Accept on.
  bool rings(CallBlocHarness h) => _ringingStatuses.contains(h.bloc.state.retrieveActiveCall('call')?.processingStatus);

  test('Accept submits the answer to the platform, and the platform beginning it moves the call on', () async {
    final h = await ringing();

    await accept(h);

    expect(h.callkeep.answers, ['call']);
    expect(call(h).processingStatus, CallProcessingStatus.incomingSubmittedAnswer);

    await platformBeginsAnswer(h);

    expect(media.requests, 1);
    expect(rings(h), isFalse);
  });

  test('a second Accept while the platform is asked is a double tap', () async {
    final h = await ringing();
    final gate = h.callkeep.answerGate = Completer();
    addTearDown(() => gate.complete(null));

    await accept(h);
    await accept(h);

    expect(h.callkeep.answers, ['call']);
  });

  test('a successful request keeps Accept closed until the platform begins the answer', () async {
    final h = await ringing();

    await accept(h);
    await accept(h);

    expect(h.callkeep.answers, ['call'], reason: 'the platform said yes and has not begun yet');
    expect(call(h).processingStatus, CallProcessingStatus.incomingSubmittedAnswer);
  });

  for (final (name, fail, heal) in <(String, void Function(FakeCallkeep), void Function(FakeCallkeep))>[
    (
      'refuses',
      (callkeep) => callkeep.answerError = CallkeepCallRequestError.unknown,
      (callkeep) => callkeep.answerError = null,
    ),
    (
      'throws on',
      (callkeep) => callkeep.answerException = PlatformException(code: 'answer'),
      (callkeep) => callkeep.answerException = null,
    ),
  ]) {
    test('an answer the platform $name leaves the call ringing, and Accept works again', () async {
      final h = await ringing();

      fail(h.callkeep);
      await accept(h);

      expect(h.callkeep.answers, ['call']);
      expect(call(h).processingStatus, CallProcessingStatus.incomingFromOffer);

      heal(h.callkeep);
      await accept(h);

      expect(h.callkeep.answers, ['call', 'call'], reason: 'the second Accept must reach the platform');
      expect(call(h).processingStatus, CallProcessingStatus.incomingSubmittedAnswer);
    });
  }

  test('an offer that comes while the platform is asked is kept, and a retry answers with it', () async {
    final h = await ringingFromPush();
    final gate = h.callkeep.answerGate = Completer();

    await accept(h);
    h.signaling.emit(_incoming);
    await pumpEventQueue();
    expect(call(h).incomingOffer, isNotNull);

    gate.complete(CallkeepCallRequestError.unknown);
    await pumpEventQueue();
    expect(call(h).processingStatus, CallProcessingStatus.incomingFromOffer, reason: 'it rings, and has its offer');
    expect(call(h).awaitsOffer, isFalse);

    h.callkeep.answerGate = null;
    await accept(h);
    expect(h.callkeep.answers, ['call', 'call']);

    await platformBeginsAnswer(h);
    expect(media.requests, 1);
  });

  test(
    'a call known by its push alone rings as such again after a failed answer, and still awaits its offer',
    () async {
      final h = await ringingFromPush();
      h.callkeep.answerError = CallkeepCallRequestError.unknown;

      await accept(h);

      expect(call(h).processingStatus, CallProcessingStatus.incomingFromPush);
      expect(call(h).awaitsOffer, isTrue);
    },
  );

  test('the platform beginning the answer before the request fails is not undone by the failure', () async {
    final h = await ringing();
    final gate = h.callkeep.answerGate = Completer();

    await accept(h);
    await platformBeginsAnswer(h);

    gate.complete(CallkeepCallRequestError.unknown);
    await pumpEventQueue();

    expect(media.requests, 1);
    expect(rings(h), isFalse, reason: 'the answer has begun: the call is not offered for Accept again');
  });

  test('the platform beginning the answer after the request failed answers once', () async {
    final h = await ringing();
    h.callkeep.answerError = CallkeepCallRequestError.unknown;

    await accept(h);
    await platformBeginsAnswer(h);
    await platformBeginsAnswer(h);

    expect(media.requests, 1);
  });

  test('an answer made on the system screen needs no Accept in the app', () async {
    final h = await ringing();

    await platformBeginsAnswer(h);

    expect(h.callkeep.answers, isEmpty);
    expect(media.requests, 1);
    expect(rings(h), isFalse);
  });

  test('a call ended while the platform is asked is not brought back by the failure', () async {
    final h = await ringing();
    final gate = h.callkeep.answerGate = Completer();

    await accept(h);
    h.bloc.add(const CallControlEvent.ended('call'));
    await pumpEventQueue();
    expect(call(h).processingStatus, CallProcessingStatus.disconnecting);

    gate.complete(CallkeepCallRequestError.unknown);
    await pumpEventQueue();

    expect(call(h).processingStatus, CallProcessingStatus.disconnecting);
  });
}
