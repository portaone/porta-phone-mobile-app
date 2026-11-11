import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:signaling/signaling.dart';

class MockWebSocketChannel extends Mock implements WebSocketChannel {}

class MockWebSocketSink extends Mock implements WebSocketSink {}

// Keepalive interval used by _handshakeJson() - drives all timing calculations below.
const _kKeepaliveIntervalMs = 100;
const _kKeepaliveInterval = Duration(milliseconds: _kKeepaliveIntervalMs);

/// Helper to create a valid handshake state JSON string.
String _handshakeJson({int keepaliveInterval = _kKeepaliveIntervalMs}) {
  return jsonEncode({
    'handshake': 'state',
    'timestamp': 1705322000000,
    'keepalive_interval': keepaliveInterval,
    'registration': {'status': 'registered'},
    'lines': [],
    'dialog_infos': [],
    'presence_infos': [],
    'guest_line': null,
  });
}

void main() {
  late MockWebSocketChannel mockChannel;
  late MockWebSocketSink mockSink;
  late StreamController<dynamic> streamController;

  setUp(() {
    mockChannel = MockWebSocketChannel();
    mockSink = MockWebSocketSink();
    streamController = StreamController<dynamic>();

    when(() => mockChannel.sink).thenReturn(mockSink);
    when(() => mockChannel.stream).thenAnswer((_) => streamController.stream);
    when(() => mockChannel.closeCode).thenReturn(null);
    when(() => mockChannel.closeReason).thenReturn(null);
    when(() => mockSink.close(any(), any())).thenAnswer((_) => Future.value());
  });

  tearDown(() async {
    await streamController.close();
  });

  group('Keepalive race condition', () {
    test('should gracefully stop keepalive loop when timer fires on a closed socket', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);

        var errorReported = false;
        Object? reportedError;

        client.listen(
          onStateHandshake: (_) {},
          onEvent: (_) {},
          onError: (e, s) {
            errorReported = true;
            reportedError = e;
          },
          onDisconnect: (_, _) {},
        );

        var isPhysicalSocketClosed = false;

        when(() => mockSink.add(any())).thenAnswer((_) {
          if (isPhysicalSocketClosed) {
            throw StateError('Cannot add event after closing.');
          }
        });

        streamController.add(_handshakeJson());
        async.flushMicrotasks();

        // Simulate physical connection drop.
        isPhysicalSocketClosed = true;

        // Advance past the keepalive interval.
        async.elapse(_kKeepaliveInterval * 2);

        verify(() => mockSink.add(any())).called(1);
        expect(errorReported, isFalse, reason: 'Race condition leaked to onError: $reportedError');
      });
    });

    test('leaves no timeout behind when the keepalive could not be sent', () {
      final uncaught = <Object>[];
      runZonedGuarded(() {
        fakeAsync((async) {
          final errors = <Object>[];
          final client = WebtritSignalingClient.inner(mockChannel);
          client.listen(
            onStateHandshake: (_) {},
            onEvent: (_) {},
            onError: (error, _) => errors.add(error),
            onDisconnect: (_, _) {},
          );

          var isPhysicalSocketClosed = false;
          when(() => mockSink.add(any())).thenAnswer((_) {
            if (isPhysicalSocketClosed) throw StateError('Cannot add event after closing.');
          });

          streamController.add(_handshakeJson());
          async.flushMicrotasks();

          isPhysicalSocketClosed = true;
          async.elapse(_kKeepaliveInterval);
          async.elapse(WebtritSignalingClient.defaultExecuteTransactionTimeoutDuration * 2);
          async.flushMicrotasks();

          expect(errors, isEmpty, reason: 'a write to a closed socket only ends the keepalive loop');
        });
      }, (error, _) => uncaught.add(error));

      expect(uncaught, isEmpty);
    });

    test('keeps one keepalive timer when a request goes out during a keepalive', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);
        client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

        final sent = <Map<String, dynamic>>[];
        when(() => mockSink.add(any())).thenAnswer((invocation) {
          sent.add(jsonDecode(invocation.positionalArguments.first as String) as Map<String, dynamic>);
        });

        streamController.add(_handshakeJson());
        async.flushMicrotasks();

        // The keepalive is out, its answer has not come.
        async.elapse(_kKeepaliveInterval);
        final keepalive = sent.single;

        unawaited(client.execute(HangupRequest(transaction: 'hangup', line: 0, callId: 'call')));
        async.flushMicrotasks();

        streamController
          ..add(jsonEncode({'handshake': 'keepalive', 'transaction': keepalive['transaction']}))
          ..add(jsonEncode({'response': 'ack', 'transaction': 'hangup'}));
        async.flushMicrotasks();

        unawaited(client.disconnect());
        async.flushMicrotasks();
        sent.clear();

        async.elapse(_kKeepaliveInterval * 3);

        expect(sent, isEmpty, reason: 'a keepalive timer outlived disconnect');
      });
    });

    test('schedules no keepalive after a disconnect that follows the keepalive answer', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);
        client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

        final sent = <Map<String, dynamic>>[];
        when(() => mockSink.add(any())).thenAnswer((invocation) {
          sent.add(jsonDecode(invocation.positionalArguments.first as String) as Map<String, dynamic>);
        });

        streamController.add(_handshakeJson());
        async.flushMicrotasks();

        async.elapse(_kKeepaliveInterval);
        final keepalive = sent.single;

        // The answer is handled, then the client disconnects before the keepalive loop resumes.
        // The socket has no close code yet: the peer's close frame has not come back.
        streamController.add(jsonEncode({'handshake': 'keepalive', 'transaction': keepalive['transaction']}));
        scheduleMicrotask(() => unawaited(client.disconnect()));
        async.flushMicrotasks();
        sent.clear();

        async.elapse(_kKeepaliveInterval * 3);

        expect(sent, isEmpty, reason: 'a keepalive timer outlived disconnect');
      });
    });

    test('should not restart keepalive timer when closeCode is set after successful keepalive', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);

        String? capturedTransactionId;
        var keepaliveRequestCount = 0;

        // Capture the transaction ID from outgoing keepalive requests.
        when(() => mockSink.add(any())).thenAnswer((invocation) {
          final data = invocation.positionalArguments[0] as String;
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (json['handshake'] == 'keepalive') {
            capturedTransactionId = json['transaction'] as String?;
            keepaliveRequestCount++;
          }
        });

        client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

        // Start keepalive timer via handshake (100ms interval).
        streamController.add(_handshakeJson());
        async.flushMicrotasks();

        // First keepalive fires.
        async.elapse(const Duration(milliseconds: 110));
        async.flushMicrotasks();
        expect(keepaliveRequestCount, equals(1));

        // Respond to first keepalive with matching transaction ID.
        streamController.add(jsonEncode({'handshake': 'keepalive', 'transaction': capturedTransactionId}));

        // Set closeCode BEFORE flushing so _onKeepalive sees it when it resumes.
        when(() => mockChannel.closeCode).thenReturn(1000);
        async.flushMicrotasks();

        // Wait well beyond second keepalive interval — timer should not restart.
        async.elapse(const Duration(milliseconds: 500));
        async.flushMicrotasks();

        // Only one keepalive request should have been sent.
        expect(keepaliveRequestCount, equals(1));

        // Verify closeCode was checked exactly twice: once in _addData (before write),
        // once in _onKeepalive (after response, as the 'no restart' guard).
        // If the timer restarted, closeCode would be accessed a third time.
        verify(() => mockChannel.closeCode).called(2);
      });
    });
  });

  group('Keepalive timeout', () {
    test('should report SignalingKeepaliveTimeoutException when server does not respond', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);

        Object? capturedError;
        when(() => mockSink.add(any())).thenAnswer((_) {});

        client.listen(
          onStateHandshake: (_) {},
          onEvent: (_) {},
          onError: (e, _) => capturedError = e,
          onDisconnect: (_, _) {},
        );

        streamController.add(_handshakeJson());
        async.flushMicrotasks();

        // Keepalive fires after _kKeepaliveInterval, then waits defaultExecuteTransactionTimeoutDuration for a response.
        async.elapse(
          _kKeepaliveInterval +
              WebtritSignalingClient.defaultExecuteTransactionTimeoutDuration +
              const Duration(milliseconds: 100),
        );
        async.flushMicrotasks();

        expect(capturedError, isA<SignalingKeepaliveTimeoutException>());
      });
    });
  });

  group('Keepalive normal flow', () {
    test('should restart keepalive timer after successful echo and send second keepalive', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);

        var keepaliveCount = 0;
        String? lastTransactionId;

        when(() => mockSink.add(any())).thenAnswer((invocation) {
          final data = invocation.positionalArguments[0] as String;
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          if (decoded['handshake'] == 'keepalive') {
            keepaliveCount++;
            lastTransactionId = decoded['transaction'] as String?;
          }
        });

        client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

        streamController.add(_handshakeJson());
        async.flushMicrotasks();

        // First keepalive fires.
        async.elapse(const Duration(milliseconds: 110));
        async.flushMicrotasks();
        expect(keepaliveCount, equals(1));

        // Echo the first keepalive.
        streamController.add(jsonEncode({'handshake': 'keepalive', 'transaction': lastTransactionId}));
        async.flushMicrotasks();

        // Second keepalive fires.
        async.elapse(const Duration(milliseconds: 110));
        async.flushMicrotasks();
        expect(keepaliveCount, equals(2));
      });
    });

    test('should complete three keepalive cycles without error', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);

        var keepaliveCount = 0;
        var errorCount = 0;
        final transactionIds = <String?>[];

        when(() => mockSink.add(any())).thenAnswer((invocation) {
          final data = invocation.positionalArguments[0] as String;
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          if (decoded['handshake'] == 'keepalive') {
            keepaliveCount++;
            transactionIds.add(decoded['transaction'] as String?);
          }
        });

        client.listen(
          onStateHandshake: (_) {},
          onEvent: (_) {},
          onError: (_, _) => errorCount++,
          onDisconnect: (_, _) {},
        );

        streamController.add(_handshakeJson());
        async.flushMicrotasks();

        for (var i = 0; i < 3; i++) {
          async.elapse(const Duration(milliseconds: 110));
          async.flushMicrotasks();
          expect(keepaliveCount, equals(i + 1));
          streamController.add(jsonEncode({'handshake': 'keepalive', 'transaction': transactionIds.last}));
          async.flushMicrotasks();
        }

        expect(errorCount, equals(0));
      });
    });
  });

  group('Disconnect handling', () {
    test('should call onDisconnect with code and reason when stream closes gracefully', () async {
      final client = WebtritSignalingClient.inner(mockChannel);

      int? disconnectCode;
      String? disconnectReason;

      client.listen(
        onStateHandshake: (_) {},
        onEvent: (_) {},
        onError: (_, _) {},
        onDisconnect: (code, reason) {
          disconnectCode = code;
          disconnectReason = reason;
        },
      );

      when(() => mockChannel.closeCode).thenReturn(1000);
      when(() => mockChannel.closeReason).thenReturn('normal closure');

      await streamController.close();
      await Future.delayed(Duration.zero);

      expect(disconnectCode, equals(1000));
      expect(disconnectReason, equals('normal closure'));
    });

    test('should call onError when stream emits an error', () async {
      final client = WebtritSignalingClient.inner(mockChannel);

      Object? capturedError;

      client.listen(
        onStateHandshake: (_) {},
        onEvent: (_) {},
        onError: (e, _) => capturedError = e,
        onDisconnect: (_, _) {},
      );

      final networkError = Exception('network dropped');
      streamController.addError(networkError);
      await Future.delayed(Duration.zero);

      expect(capturedError, equals(networkError));
    });

    test('should throw SignalingDisconnectedException when execute called after stream closes', () async {
      final client = WebtritSignalingClient.inner(mockChannel);

      client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

      await streamController.close();
      await Future.delayed(Duration.zero);

      final request = HangupRequest(transaction: 'test-tx', line: 0, callId: 'test-call-id');
      await expectLater(client.execute(request), throwsA(isA<SignalingDisconnectedException>()));
    });
  });

  group('Silent connection', () {
    const interval = Duration(seconds: 30);
    final wait = WebtritSignalingClient.defaultExecuteTransactionTimeoutDuration;

    late List<Object> errors;
    late List<String> sent;
    late int disconnects;

    WebtritSignalingClient listening() {
      errors = [];
      sent = [];
      disconnects = 0;
      final client = WebtritSignalingClient.inner(mockChannel);
      client.listen(
        onStateHandshake: (_) {},
        onEvent: (_) {},
        onError: (e, _) => errors.add(e),
        onDisconnect: (_, _) => disconnects++,
      );
      return client;
    }

    int keepalives() => sent.where((frame) => frame.contains('"keepalive"')).length;

    /// The same request again every time it times out, as the request queue retries it.
    void retry(WebtritSignalingClient client) {
      client
          .execute(HangupRequest(transaction: 'retried', line: 0, callId: 'call'))
          .then<void>(
            (_) {},
            onError: (Object e, _) {
              if (e is SignalingTransactionTimeoutException) retry(client);
            },
          );
    }

    test('gets a keepalive while requests keep going out, and is given up when it is not answered', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) => sent.add(call.positionalArguments.single as String));
        final client = listening();
        streamController.add(_handshakeJson(keepaliveInterval: interval.inMilliseconds));
        async.flushMicrotasks();

        retry(client);
        async.elapse(interval - const Duration(milliseconds: 1));
        expect(keepalives(), 0);

        async.elapse(const Duration(milliseconds: 1));
        expect(keepalives(), 1, reason: 'nothing received for the interval, whatever was sent');
        expect(errors, isEmpty);

        async.elapse(wait);
        async.flushMicrotasks();
        expect(errors.single, isA<SignalingKeepaliveTimeoutException>());

        async.elapse(const Duration(minutes: 10));
        expect(errors, hasLength(1), reason: 'a connection given up tells nothing more');
        expect(disconnects, 0);
      });
    });

    test('with its keepalive answered, an unanswered request costs only its own timeout', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) {
          final frame = call.positionalArguments.single as String;
          sent.add(frame);
          if (frame.contains('"keepalive"')) streamController.add(frame);
        });
        final client = listening();
        streamController.add(_handshakeJson(keepaliveInterval: interval.inMilliseconds));
        async.flushMicrotasks();
        Object? requestError;

        async.elapse(const Duration(seconds: 15));
        client
            .execute(HangupRequest(transaction: 'ignored', line: 0, callId: 'call'))
            .then<void>((_) {}, onError: (Object e, _) => requestError = e);
        async.elapse(const Duration(minutes: 10));

        expect(requestError, isA<SignalingTransactionTimeoutException>());
        expect(errors, isEmpty);
      });
    });

    test('is watched by the interval the server names', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) {
          final frame = call.positionalArguments.single as String;
          sent.add(frame);
          if (frame.contains('"keepalive"')) streamController.add(frame);
        });
        listening();
        streamController.add(_handshakeJson(keepaliveInterval: 60000));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 59));
        expect(keepalives(), 0);

        async.elapse(const Duration(minutes: 10));
        expect(errors, isEmpty);
        expect(keepalives(), 10, reason: 'one per interval, the timer and the watch never both');
      });
    });

    test('that never gets its state is asked a keepalive and given up', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) => sent.add(call.positionalArguments.single as String));
        listening();

        async.elapse(interval);
        expect(keepalives(), 1);
        expect(errors, isEmpty);

        async.elapse(wait);
        async.flushMicrotasks();
        expect(errors.single, isA<SignalingKeepaliveTimeoutException>());
      });
    });

    test('that answers its keepalive before the state is given up at the answer', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) {
          final frame = call.positionalArguments.single as String;
          sent.add(frame);
          if (frame.contains('"keepalive"')) streamController.add(frame);
        });
        when(() => mockSink.close(any(), any())).thenAnswer((_) async {});
        listening();

        async.elapse(interval);
        async.flushMicrotasks();
        expect(keepalives(), 1);
        final keepalive = jsonDecode(sent.single) as Map<String, dynamic>;
        expect(
          errors.single,
          isA<SignalingStateHandshakeMissingException>().having(
            (e) => e.transactionId,
            'transactionId',
            keepalive['transaction'],
          ),
        );
        verify(() => mockSink.close(any(), any())).called(1);

        streamController.add(_handshakeJson(keepaliveInterval: interval.inMilliseconds));
        async.elapse(const Duration(minutes: 10));
        expect(errors, hasLength(1), reason: 'a connection given up tells nothing more');
        expect(keepalives(), 1);
      });
    });

    test('whose state comes late but before the keepalive answer is kept', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) => sent.add(call.positionalArguments.single as String));
        listening();

        async.elapse(interval);
        expect(keepalives(), 1);

        streamController.add(_handshakeJson(keepaliveInterval: interval.inMilliseconds));
        async.elapse(const Duration(seconds: 5));
        streamController.add(sent.single);
        async.flushMicrotasks();

        expect(errors, isEmpty, reason: 'the order of the frames counts, not how long the state took');
      });
    });

    test('given up: waiting requests time out at once, the socket is closed, nothing more is taken', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) => sent.add(call.positionalArguments.single as String));
        final client = listening();
        streamController.add(_handshakeJson(keepaliveInterval: interval.inMilliseconds));
        async.flushMicrotasks();
        Object? waitingError;
        async.elapse(interval);
        client
            .execute(HangupRequest(transaction: 'waiting', line: 0, callId: 'call'), const Duration(minutes: 5))
            .then<void>((_) {}, onError: (Object e, _) => waitingError = e);

        async.elapse(wait);
        async.flushMicrotasks();

        expect(errors, hasLength(1));
        expect(waitingError, isA<SignalingTransactionTimeoutException>());
        expect(waitingError, isNot(isA<SignalingKeepaliveTimeoutException>()));
        verify(() => mockSink.close()).called(1);
        Object? lateError;
        client
            .execute(HangupRequest(transaction: 'late', line: 0, callId: 'call'))
            .then<void>((_) {}, onError: (Object e, _) => lateError = e);
        async.flushMicrotasks();
        expect(lateError, isA<SignalingDisconnectedException>());
      });
    });

    test('given up even when the error handler throws: the socket is closed first', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((_) {});
        final thrown = <Object>[];
        runZonedGuarded(() {
          WebtritSignalingClient.inner(mockChannel).listen(
            onStateHandshake: (_) {},
            onEvent: (_) {},
            onError: (_, _) => throw StateError('handler'),
            onDisconnect: (_, _) {},
          );
        }, (error, _) => thrown.add(error));

        async.elapse(interval + wait);
        async.flushMicrotasks();

        expect(thrown.single, isStateError);

        verify(() => mockSink.close()).called(1);
      });
    });

    test('is not watched after a disconnect', () {
      fakeAsync((async) {
        when(() => mockSink.add(any())).thenAnswer((call) => sent.add(call.positionalArguments.single as String));
        final client = listening();

        client.disconnect();
        async.elapse(const Duration(minutes: 10));

        expect(errors, isEmpty);
        expect(keepalives(), 0);
      });
    });
  });

  group('Request transaction timeout', () {
    test('should throw SignalingTransactionTimeoutException (not keepalive variant) when server ignores request', () {
      fakeAsync((async) {
        final client = WebtritSignalingClient.inner(mockChannel);

        Object? executeError;
        when(() => mockSink.add(any())).thenAnswer((_) {});

        client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

        // Long keepalive interval to prevent interference with the request timeout.
        streamController.add(_handshakeJson(keepaliveInterval: 100000));
        async.flushMicrotasks();

        client
            .execute(HangupRequest(transaction: 'test-tx', line: 0, callId: 'test-call-id'))
            .then<void>(
              (_) {},
              onError: (Object e, _) {
                executeError = e;
              },
            );

        async.flushMicrotasks();

        // Advance past transaction timeout.
        async.elapse(
          WebtritSignalingClient.defaultExecuteTransactionTimeoutDuration + const Duration(milliseconds: 100),
        );
        async.flushMicrotasks();

        expect(executeError, isA<SignalingTransactionTimeoutException>());
        expect(executeError, isNot(isA<SignalingKeepaliveTimeoutException>()));
      });
    });
  });

  group('Transaction cleanup on send failure', () {
    test('should throw SignalingBadStateException when sink.add throws StateError', () async {
      final client = WebtritSignalingClient.inner(mockChannel);

      client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

      // Initialize client with handshake.
      streamController.add(_handshakeJson());
      await Future.delayed(Duration.zero);

      // Any sink.add throws StateError (socket broken).
      when(() => mockSink.add(any())).thenThrow(StateError('Cannot add event after closing.'));

      final request = HangupRequest(transaction: 'test-tx', line: 0, callId: 'test-call-id');

      await expectLater(client.execute(request), throwsA(isA<SignalingBadStateException>()));
    });

    test('should throw SignalingBadStateException when closeCode is already set', () async {
      final client = WebtritSignalingClient.inner(mockChannel);

      client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

      // Initialize client with handshake.
      streamController.add(_handshakeJson());
      await Future.delayed(Duration.zero);

      // Socket already closed.
      when(() => mockChannel.closeCode).thenReturn(1000);

      final request = HangupRequest(transaction: 'test-tx', line: 0, callId: 'test-call-id');

      await expectLater(client.execute(request), throwsA(isA<SignalingBadStateException>()));
    });

    test('should not call sink.add when closeCode is detected before write', () async {
      final client = WebtritSignalingClient.inner(mockChannel);

      client.listen(onStateHandshake: (_) {}, onEvent: (_) {}, onError: (_, _) {}, onDisconnect: (_, _) {});

      // Initialize client with handshake.
      streamController.add(_handshakeJson());
      await Future.delayed(Duration.zero);

      // closeCode set — socket already closed.
      when(() => mockChannel.closeCode).thenReturn(1000);

      final request = HangupRequest(transaction: 'test-tx', line: 0, callId: 'test-call-id');

      try {
        await client.execute(request);
      } on SignalingBadStateException {
        // Expected.
      }

      // sink.add should NOT have been called — pre-check caught it.
      verifyNever(() => mockSink.add(any()));
    });
  });
}
