import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

import 'package:webtrit_phone/features/call/services/call_signaling.dart';

class _Module extends Fake implements SignalingModule {
  final controller = StreamController<SignalingModuleEvent>.broadcast();
  final executed = <Request>[];

  /// What [execute] does with the next request: null hands back nothing, an
  /// error fails it.
  Object? next = 'sent';

  @override
  Stream<SignalingModuleEvent> get events => controller.stream;

  @override
  bool get isConnected => true;

  @override
  Future<void>? execute(Request request) {
    executed.add(request);
    final what = next;
    if (what == null) return null;
    if (what is! String) return Future.error(what);
    return Future.value();
  }
}

void main() {
  late _Module module;
  late ModuleCallSignaling signaling;

  setUp(() {
    module = _Module();
    signaling = ModuleCallSignaling(module, events: module.controller.stream);
  });

  tearDown(() async {
    if (!module.controller.isClosed) await module.controller.close();
  });

  SignalingProtocolEvent hangup(String transaction) => SignalingProtocolEvent(
    event: HangupEvent(transaction: transaction, line: 0, callId: 'a', code: 200, reason: 'ok'),
  );

  test('the answer is the first session event that names the transaction', () async {
    final answer = signaling.response('t2', timeout: const Duration(seconds: 1));

    module.controller
      ..add(SignalingConnected())
      ..add(hangup('t1'))
      ..add(hangup('t2'));

    expect(await answer, hangup('t2').event);
    expect(module.controller.hasListener, isFalse, reason: 'the answer found, the wait lets go of the stream');
  });

  test('no answer within the timeout is a TimeoutException', () async {
    final answer = signaling.response('t1', timeout: const Duration(milliseconds: 10));

    await expectLater(answer, throwsA(isA<TimeoutException>()));
    expect(module.controller.hasListener, isFalse, reason: 'a wait that ran out must not stay subscribed');
  });

  test('a wait given up completes with null and lets go of the stream at once', () async {
    final givenUp = Completer<void>();
    final answer = signaling.responseUntil('t1', timeout: const Duration(seconds: 10), until: givenUp.future);

    givenUp.complete();

    expect(await answer, isNull);
    expect(module.controller.hasListener, isFalse);
  });

  test('a wait whose answer comes first is not given up after', () async {
    final givenUp = Completer<void>();
    final answer = signaling.responseUntil('t1', timeout: const Duration(seconds: 10), until: givenUp.future);

    module.controller.add(hangup('t1'));
    givenUp.complete();

    expect(await answer, hangup('t1').event);
  });

  test('the events ending before an answer is a StateError', () async {
    final answer = signaling.response('t1', timeout: const Duration(seconds: 1));

    await module.controller.close();

    await expectLater(answer, throwsA(isA<StateError>()));
  });

  test('an answer that came before the wait is not found: protocol events are not replayed', () async {
    module.controller.add(hangup('t1'));
    await pumpEventQueue();

    final answer = signaling.response('t1', timeout: const Duration(milliseconds: 10));

    await expectLater(answer, throwsA(isA<TimeoutException>()));
  });

  group('send', () {
    final request = HangupRequest(transaction: 't1', line: 0, callId: 'a');

    test('a request the server took is sent', () async {
      expect(await signaling.send(request), isA<SignalingSent>());
    });

    test('a request nothing could be handed is not sent', () async {
      module.next = null;

      expect(await signaling.send(request), isA<SignalingNotSent>());
    });

    test('a request that went with the connection is lost, with its error', () async {
      final losses = [
        NotConnectedException('not connected'),
        const SignalingDisconnectedException(1),
        const SignalingTransactionTimeoutException(1, 't1'),
        const SignalingTransactionTerminateByDisconnectException(1, 't1', 4502, 'keepalive'),
        TimeoutException('no reply'),
      ];
      for (final loss in losses) {
        module.next = loss;

        final outcome = await signaling.send(request);

        expect(outcome, isA<SignalingLost>().having((o) => o.error, 'error', same(loss)));
      }
    });

    test('any other failure is a refusal, with its error', () async {
      final refusal = StateError('refused');
      module.next = refusal;

      final outcome = await signaling.send(request);

      expect(outcome, isA<SignalingRefused>().having((o) => o.error, 'error', same(refusal)));
    });
  });

  test('requests and the session state are the module\'s', () async {
    final request = HangupRequest(transaction: 't1', line: 0, callId: 'a');

    await signaling.execute(request);

    expect(module.executed, [request]);
    expect(signaling.isConnected, isTrue);
  });
}
