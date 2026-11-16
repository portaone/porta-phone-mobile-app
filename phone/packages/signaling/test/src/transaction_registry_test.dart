import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:signaling/src/exceptions.dart';
import 'package:signaling/src/transaction_registry.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

void main() {
  const clientId = 7;
  const timeout = Duration(seconds: 10);

  late MockWebSocketChannel channel;
  late MockWebSocketSink sink;
  late List<Map<String, dynamic>> sent;
  late TransactionRegistry registry;

  setUp(() {
    channel = MockWebSocketChannel();
    sink = MockWebSocketSink();
    sent = [];
    when(() => channel.sink).thenReturn(sink);
    when(() => channel.closeCode).thenReturn(null);
    when(() => sink.add(any())).thenAnswer((invocation) {
      sent.add(jsonDecode(invocation.positionalArguments.single as String) as Map<String, dynamic>);
    });
    registry = TransactionRegistry(channel, clientId: clientId, logger: Logger('TransactionRegistryTest'));
  });

  group('execute', () {
    test('writes the request and returns the answer that names its transaction', () async {
      final answer = registry.execute({'request': 'hangup', 'transaction': 't1'}, timeout);

      expect(sent.single, {'request': 'hangup', 'transaction': 't1'});
      registry.handleAnswer({'response': 'ack', 'transaction': 't1'});

      expect(await answer, {'response': 'ack', 'transaction': 't1'});
    });

    test('a request without a transaction gets one, and the answer comes back without it', () async {
      final answer = registry.execute({'request': 'hangup'}, timeout);

      final id = sent.single['transaction'];
      expect(id, isA<String>());
      registry.handleAnswer({'response': 'ack', 'transaction': id});

      expect(await answer, {'response': 'ack'});
    });

    test('an error answer is returned as it came: the client decides what it means', () async {
      final answer = registry.execute({'request': 'hangup', 'transaction': 't2'}, timeout);
      registry.handleAnswer({'response': 'error', 'transaction': 't2', 'code': 0, 'reason': 'no_conference'});

      expect(await answer, {'response': 'error', 'transaction': 't2', 'code': 0, 'reason': 'no_conference'});
    });

    test('a keepalive echo is paired with its transaction like a response', () async {
      final answer = registry.execute({'handshake': 'keepalive', 'transaction': 'k1'}, timeout);
      registry.handleAnswer({'handshake': 'keepalive', 'transaction': 'k1'});

      expect(await answer, {'handshake': 'keepalive', 'transaction': 'k1'});
    });

    test('answers are paired by transaction, whatever order they come in', () async {
      final first = registry.execute({'request': 'a', 'transaction': 't1'}, timeout);
      final second = registry.execute({'request': 'b', 'transaction': 't2'}, timeout);

      registry.handleAnswer({'response': 'ack', 'transaction': 't2', 'n': 2});
      registry.handleAnswer({'response': 'ack', 'transaction': 't1', 'n': 1});

      expect((await first)['n'], 1);
      expect((await second)['n'], 2);
    });

    test('times out without an answer', () {
      fakeAsync((async) {
        Object? error;
        unawaited(
          registry.execute({'request': 'hangup', 'transaction': 't3'}, timeout).catchError((Object e) {
            error = e;
            return <String, dynamic>{};
          }),
        );

        async.elapse(timeout - const Duration(milliseconds: 1));
        expect(error, isNull);
        async.elapse(const Duration(milliseconds: 1));

        expect(error, isA<SignalingTransactionTimeoutException>().having((e) => e.transactionId, 'id', 't3'));
      });
    });

    test('a write to a closed socket throws at once and leaves no timeout behind', () {
      fakeAsync((async) {
        when(() => channel.closeCode).thenReturn(1000);

        Object? error;
        unawaited(
          registry.execute({'request': 'hangup', 'transaction': 't4'}, timeout).catchError((Object e) {
            error = e;
            return <String, dynamic>{};
          }),
        );
        async.flushMicrotasks();

        expect(error, isA<SignalingBadStateException>());
        expect(sent, isEmpty);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('a sink that refuses the write throws the same way', () async {
      when(() => sink.add(any())).thenThrow(StateError('sink closed'));

      await expectLater(
        registry.execute({'request': 'hangup', 'transaction': 't5'}, timeout),
        throwsA(isA<SignalingBadStateException>().having((e) => e.id, 'id', clientId)),
      );
    });
  });

  // Cases from fixes in the history of the client, each kept here because the
  // registry now holds the code they were made in.
  group('regressions', () {
    test('an answered request leaves no timer to fire later', () {
      fakeAsync((async) {
        unawaited(registry.execute({'request': 'hangup', 'transaction': 't1'}, timeout));
        registry.handleAnswer({'response': 'ack', 'transaction': 't1'});
        async.flushMicrotasks();

        expect(async.pendingTimers, isEmpty);
      });
    });

    test('an answer after the timeout is a warning, not an error and not a second completion', () {
      // A late answer once completed the transaction a second time and threw StateError, and once
      // reached onError as a failed connection, costing a reconnect.
      final warnings = <String>[];
      final previousLevel = Logger.root.level;
      Logger.root.level = Level.WARNING;
      addTearDown(() => Logger.root.level = previousLevel);
      final subscription = Logger.root.onRecord.listen((record) => warnings.add(record.message));
      addTearDown(subscription.cancel);

      final uncaught = <Object>[];
      runZonedGuarded(() {
        fakeAsync((async) {
          unawaited(
            registry
                .execute({'request': 'ice_trickle', 'transaction': 'late'}, timeout)
                .catchError((Object _) => <String, dynamic>{}),
          );
          async.elapse(timeout);
          registry.handleAnswer({'response': 'ack', 'transaction': 'late'});
          async.flushMicrotasks();
        });
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
      expect(warnings.where((message) => message.contains('late')), hasLength(1));
    });

    test('a failed write leaves no timeout to reach the zone later', () {
      // The timer of a request that was never sent once fired 10 s later into a future nobody
      // awaited, and the error was recorded as a fatal crash.
      when(() => channel.closeCode).thenReturn(1000);
      final uncaught = <Object>[];
      runZonedGuarded(() {
        fakeAsync((async) {
          unawaited(
            registry
                .execute({'request': 'hangup', 'transaction': 't2'}, timeout)
                .catchError((Object _) => <String, dynamic>{}),
          );
          async.elapse(timeout * 2);
        });
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
    });

    test('generated transaction ids are unique and digits after the prefix', () {
      // Two isolates once both sent `transaction-0` on one socket and Core paired the second accept
      // with the first call; Core also needs digits only after the prefix.
      final ids = <String>{};
      for (var i = 0; i < 3; i++) {
        unawaited(registry.execute({'request': 'hangup'}, timeout).catchError((Object _) => <String, dynamic>{}));
        ids.add(sent.last['transaction'] as String);
      }

      expect(ids, hasLength(3));
      expect(ids, everyElement(matches(RegExp(r'^transaction-\d+$'))));
      registry.terminateAll(1000, null);
    });
  });

  group('handleAnswer', () {
    test('an answer for a transaction that timed out is ignored, and the next request still works', () {
      fakeAsync((async) {
        unawaited(
          registry
              .execute({'request': 'hangup', 'transaction': 'late'}, timeout)
              .catchError((Object _) => <String, dynamic>{}),
        );
        async.elapse(timeout);

        // The ack after the timeout: dropped, not thrown.
        registry.handleAnswer({'response': 'ack', 'transaction': 'late'});

        Map<String, dynamic>? answer;
        unawaited(registry.execute({'request': 'hangup', 'transaction': 'next'}, timeout).then((a) => answer = a));
        registry.handleAnswer({'response': 'ack', 'transaction': 'next'});
        async.flushMicrotasks();

        expect(answer, {'response': 'ack', 'transaction': 'next'});
      });
    });

    test('an answer nobody sent a request for is ignored', () {
      expect(() => registry.handleAnswer({'response': 'ack', 'transaction': 'never-sent'}), returnsNormally);
    });

    test('a second answer for the same transaction is ignored', () async {
      final answer = registry.execute({'request': 'hangup', 'transaction': 't6'}, timeout);
      registry.handleAnswer({'response': 'ack', 'transaction': 't6', 'n': 1});
      registry.handleAnswer({'response': 'ack', 'transaction': 't6', 'n': 2});

      expect((await answer)['n'], 1);
    });
  });

  group('isAnswer', () {
    test('a response and a keepalive echo are answers', () {
      expect(TransactionRegistry.isAnswer({'response': 'ack', 'transaction': 't'}), isTrue);
      expect(TransactionRegistry.isAnswer({'response': 'error', 'transaction': 't', 'code': 0}), isTrue);
      expect(TransactionRegistry.isAnswer({'handshake': 'keepalive', 'transaction': 'k'}), isTrue);
    });

    test('an event and a state handshake are not', () {
      expect(TransactionRegistry.isAnswer({'event': 'ringing', 'line': 0, 'call_id': 'c'}), isFalse);
      expect(TransactionRegistry.isAnswer({'handshake': 'state', 'keepalive_interval': 30000}), isFalse);
    });
  });

  group('the end of a connection', () {
    test('terminateAll ends every waiting request with the close code and reason', () async {
      final first = registry.execute({'request': 'a', 'transaction': 't1'}, timeout);
      final second = registry.execute({'request': 'b', 'transaction': 't2'}, timeout);

      registry.terminateAll(4441, 'gone');

      for (final (future, id) in [(first, 't1'), (second, 't2')]) {
        await expectLater(
          future,
          throwsA(
            isA<SignalingTransactionTerminateByDisconnectException>()
                .having((e) => e.transactionId, 'id', id)
                .having((e) => e.closeCode, 'code', 4441)
                .having((e) => e.closeReason, 'reason', 'gone'),
          ),
        );
      }
    });

    test('timeOutAll ends every waiting request now, with the timeout it would have got', () {
      fakeAsync((async) {
        final errors = <Object>[];
        for (final id in ['t1', 't2']) {
          unawaited(
            registry.execute({'request': 'a', 'transaction': id}, timeout).catchError((Object e) {
              errors.add(e);
              return <String, dynamic>{};
            }),
          );
        }

        registry.timeOutAll();
        async.flushMicrotasks();

        expect(errors, hasLength(2));
        expect(errors, everyElement(isA<SignalingTransactionTimeoutException>()));
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('an answer after the end is ignored', () async {
      final answer = registry.execute({'request': 'a', 'transaction': 't1'}, timeout);
      registry.terminateAll(1000, null);

      expect(() => registry.handleAnswer({'response': 'ack', 'transaction': 't1'}), returnsNormally);
      await expectLater(answer, throwsA(isA<SignalingTransactionTerminateByDisconnectException>()));
    });
  });

  group('send and isClosed', () {
    test('send writes a frame as it is', () {
      registry.send({'handshake': 'keepalive'});

      expect(sent.single, {'handshake': 'keepalive'});
    });

    test('isClosed follows the close frame of the peer', () {
      expect(registry.isClosed, isFalse);
      when(() => channel.closeCode).thenReturn(1000);
      expect(registry.isClosed, isTrue);
    });
  });
}
