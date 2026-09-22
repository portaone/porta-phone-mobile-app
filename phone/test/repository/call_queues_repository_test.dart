import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;
import 'package:webtrit_phone/app/session/session.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/mocks.dart';

api.CallQueue _apiQueue(
  String id, {
  bool loggedIn = true,
  int agentsTotal = 3,
  int agentsLoggedIn = 2,
  int? callersWaiting = 0,
}) => api.CallQueue(
  id: id,
  name: 'Queue $id',
  loggedIn: loggedIn,
  agentsTotal: agentsTotal,
  agentsLoggedIn: agentsLoggedIn,
  callersWaiting: callersWaiting,
);

api.RequestFailure _failure(int statusCode) =>
    api.RequestFailure(url: Uri.https('demo.webtrit.com'), requestId: 'r', statusCode: statusCode);

class _RecordingSessionGuard implements SessionGuard {
  final unauthorized = <Exception>[];

  @override
  void onUnauthorized(Exception e) => unauthorized.add(e);
}

void main() {
  late MockWebtritApiClient apiClient;
  late _RecordingSessionGuard sessionGuard;
  late CallQueuesRepository repository;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
  });

  setUp(() {
    apiClient = MockWebtritApiClient();
    sessionGuard = _RecordingSessionGuard();
    repository = CallQueuesRepositoryApiImpl(apiClient: apiClient, token: 'token_1', sessionGuard: sessionGuard);
  });

  tearDown(() => repository.dispose());

  void stubRead(List<api.CallQueue> queues) {
    when(
      () => apiClient.getUserCallQueues(
        any(),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => api.CallQueueListResponse(items: queues));
  }

  void stubReadFailing(Object error) {
    when(
      () => apiClient.getUserCallQueues(
        any(),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) async => throw error);
  }

  group('reading', () {
    test('an answer becomes the snapshot and marks the queues known', () async {
      stubRead([_apiQueue('0111'), _apiQueue('0222', loggedIn: false)]);

      await repository.refresh();

      expect(repository.snapshot.known, isTrue);
      expect(repository.snapshot.queues.map((queue) => queue.id), ['0111', '0222']);
      expect(repository.snapshot.isAgent, isTrue);
    });

    test('an empty answer is an answer: known, and not an agent', () async {
      stubRead(const []);

      await repository.refresh();

      expect(repository.snapshot.known, isTrue);
      expect(repository.snapshot.isAgent, isFalse);
      expect(repository.isActive, isTrue);
    });

    test('a failed read is thrown on, so polling can back off instead of retrying blind', () async {
      stubReadFailing(_failure(500));

      await expectLater(repository.refresh(), throwsA(isA<api.RequestFailure>()));
      expect(repository.snapshot.known, isFalse);
    });

    test('a deployment without the feature stops the task instead of asking again', () async {
      stubReadFailing(
        api.EndpointNotSupportedException(
          url: Uri.https('demo.webtrit.com'),
          requestId: 'r',
          statusCode: 501,
          recognizedNotSupportedCodes: const ['404', '501'],
        ),
      );

      await repository.refresh();

      expect(repository.isActive, isFalse);
      expect(repository.snapshot.known, isTrue);
      expect(repository.snapshot.isAgent, isFalse);
    });

    test('a bare 404 after the route has answered once is a failure, not the feature going away', () async {
      // The transport reports a 404 with no error code as "not supported",
      // because an absent route answers that way - and so does an ingress in
      // front of a backend that is briefly down. Taking an agent's queues off
      // their screen for the rest of the session over that is the damage this
      // prevents.
      stubRead([_apiQueue('0111')]);
      await repository.refresh();
      stubReadFailing(
        api.EndpointNotSupportedException(
          url: Uri.https('demo.webtrit.com'),
          requestId: 'r',
          statusCode: 404,
          recognizedNotSupportedCodes: const ['404', '501'],
        ),
      );

      await expectLater(repository.refresh(), throwsA(isA<api.EndpointNotSupportedException>()));

      expect(repository.isActive, isTrue);
      expect(repository.snapshot.queues, hasLength(1));
    });

    test('a bare 404 before anything has answered is the route being absent', () async {
      stubReadFailing(
        api.EndpointNotSupportedException(
          url: Uri.https('demo.webtrit.com'),
          requestId: 'r',
          statusCode: 404,
          recognizedNotSupportedCodes: const ['404', '501'],
        ),
      );

      await repository.refresh();

      expect(repository.isActive, isFalse);
    });

    test('two callers arriving together share one request', () async {
      final answer = Completer<api.CallQueueListResponse>();
      when(
        () => apiClient.getUserCallQueues(
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => answer.future);

      final first = repository.refresh();
      final second = repository.refresh();
      answer.complete(api.CallQueueListResponse(items: [_apiQueue('0111')]));
      await Future.wait([first, second]);

      verify(
        () => apiClient.getUserCallQueues(
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('a dead session reaches the guard and is still thrown on', () async {
      final unauthorized = api.UnauthorizedException(
        url: Uri.https('demo.webtrit.com'),
        requestId: 'r',
        statusCode: 401,
      );
      stubReadFailing(unauthorized);

      await expectLater(repository.refresh(), throwsA(same(unauthorized)));
      expect(sessionGuard.unauthorized, [same(unauthorized)]);
    });
  });

  group('a failed read', () {
    test('is published, so a screen waiting on the poll can say so', () async {
      stubReadFailing(_failure(500));

      await expectLater(repository.refresh(), throwsA(isA<api.RequestFailure>()));

      expect(repository.snapshot.readFailed, isTrue);
      expect(repository.snapshot.known, isFalse);
    });

    test('keeps what was read before it, and the next answer clears it', () async {
      stubRead([_apiQueue('0111')]);
      await repository.refresh();
      stubReadFailing(_failure(500));
      await expectLater(repository.refresh(), throwsA(isA<api.RequestFailure>()));

      expect(repository.snapshot.queues, hasLength(1), reason: 'a failure says nothing about what was read');
      expect(repository.snapshot.readFailed, isTrue);

      stubRead([_apiQueue('0111'), _apiQueue('0222')]);
      await repository.refresh();

      expect(repository.snapshot.readFailed, isFalse);
      expect(repository.snapshot.queues, hasLength(2));
    });
  });

  group('writing one queue', () {
    test('renders the state the server returned, counts included', () async {
      stubRead([_apiQueue('0111', loggedIn: true, agentsLoggedIn: 2)]);
      await repository.refresh();
      when(
        () => apiClient.updateUserCallQueue(
          any(),
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _apiQueue('0111', loggedIn: false, agentsLoggedIn: 1));

      await repository.setLoggedIn('0111', loggedIn: false);

      expect(repository.snapshot.queues.single.loggedIn, isFalse);
      expect(repository.snapshot.queues.single.agentsLoggedIn, 1);
    });

    test('a second attempt is ignored while the first is in flight', () async {
      stubRead([_apiQueue('0111')]);
      await repository.refresh();
      final inFlight = Completer<api.CallQueue>();
      when(
        () => apiClient.updateUserCallQueue(
          any(),
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => inFlight.future);

      final first = repository.setLoggedIn('0111', loggedIn: false);
      await repository.setLoggedIn('0111', loggedIn: false);

      inFlight.complete(_apiQueue('0111', loggedIn: false));
      await first;

      verify(
        () => apiClient.updateUserCallQueue(
          any(),
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('a queue the user is no longer an agent of leaves the row alone and asks for the list', () async {
      stubRead([_apiQueue('0111', loggedIn: true)]);
      await repository.refresh();
      when(
        () => apiClient.updateUserCallQueue(
          any(),
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async =>
            throw api.CallQueueNotFoundException(url: Uri.https('demo.webtrit.com'), requestId: 'r', statusCode: 404),
      );
      stubRead([_apiQueue('0222')]);

      await expectLater(
        repository.setLoggedIn('0111', loggedIn: false),
        throwsA(isA<api.CallQueueNotFoundException>()),
      );

      expect(repository.snapshot.queues.map((queue) => queue.id), ['0222']);
    });
  });

  group('a read that raced a write', () {
    test('an answer that started before the write is dropped', () async {
      stubRead([_apiQueue('0111', loggedIn: true)]);
      await repository.refresh();

      // The read is in flight when the write lands, so it carries the state
      // from before it: applying it would flip the switch back under the user.
      final slowRead = Completer<api.CallQueueListResponse>();
      when(
        () => apiClient.getUserCallQueues(
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => slowRead.future);
      final reading = repository.refresh();

      when(
        () => apiClient.updateUserCallQueue(
          any(),
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => _apiQueue('0111', loggedIn: false));
      await repository.setLoggedIn('0111', loggedIn: false);

      slowRead.complete(api.CallQueueListResponse(items: [_apiQueue('0111', loggedIn: true)]));
      await reading;

      expect(repository.snapshot.queues.single.loggedIn, isFalse);
    });

    test('a row with its own write in flight keeps what it shows, the rest of the list does not', () async {
      stubRead([_apiQueue('0111', loggedIn: true), _apiQueue('0222', loggedIn: true)]);
      await repository.refresh();

      final inFlight = Completer<api.CallQueue>();
      when(
        () => apiClient.updateUserCallQueue(
          any(),
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => inFlight.future);
      final writing = repository.setLoggedIn('0111', loggedIn: false);

      stubRead([_apiQueue('0111', loggedIn: true, agentsLoggedIn: 3), _apiQueue('0222', loggedIn: false)]);
      await repository.refresh();

      final held = repository.snapshot.queues.firstWhere((queue) => queue.id == '0111');
      final applied = repository.snapshot.queues.firstWhere((queue) => queue.id == '0222');
      expect(held.agentsLoggedIn, 2, reason: 'the row being written is left as it was');
      expect(applied.loggedIn, isFalse, reason: 'every other row still follows the backend');

      inFlight.complete(_apiQueue('0111', loggedIn: false));
      await writing;
    });

    test('while every queue is being written, a read is dropped whole', () async {
      stubRead([_apiQueue('0111', loggedIn: true), _apiQueue('0222', loggedIn: true)]);
      await repository.refresh();

      final inFlight = Completer<api.CallQueueListResponse>();
      when(
        () => apiClient.updateUserCallQueues(
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => inFlight.future);
      final writing = repository.setAllLoggedIn(loggedIn: false);

      stubRead([_apiQueue('0111', loggedIn: true, agentsLoggedIn: 3), _apiQueue('0222', loggedIn: true)]);
      await repository.refresh();

      expect(repository.snapshot.queues.every((queue) => queue.agentsLoggedIn == 2), isTrue);

      inFlight.complete(
        api.CallQueueListResponse(items: [_apiQueue('0111', loggedIn: false), _apiQueue('0222', loggedIn: false)]),
      );
      await writing;

      expect(repository.snapshot.queues.every((queue) => queue.loggedIn == false), isTrue);
      expect(repository.snapshot.allPending, isFalse);
    });
  });

  group('writing every queue', () {
    test('is ignored while anything else is in flight', () async {
      stubRead([_apiQueue('0111')]);
      await repository.refresh();
      final inFlight = Completer<api.CallQueue>();
      when(
        () => apiClient.updateUserCallQueue(
          any(),
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => inFlight.future);
      final writing = repository.setLoggedIn('0111', loggedIn: false);

      await repository.setAllLoggedIn(loggedIn: true);

      verifyNever(
        () => apiClient.updateUserCallQueues(
          any(),
          loggedIn: any(named: 'loggedIn'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      );

      inFlight.complete(_apiQueue('0111', loggedIn: false));
      await writing;
    });
  });
}
