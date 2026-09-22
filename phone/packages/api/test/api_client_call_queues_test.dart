import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// The queue list is what an agent reads their shift off, and two of its fields
// are easy to get wrong in the transport: a null callers_waiting that must not
// arrive as a zero, and a 404 that means two different things depending on
// whether the backend put a code in it.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';

  Map<String, dynamic> queueJson({
    String id = '0111',
    String name = 'First line support',
    bool loggedIn = true,
    int agentsTotal = 3,
    int agentsLoggedIn = 2,
    Object? callersWaiting = 3,
  }) => {
    'id': id,
    'name': name,
    'logged_in': loggedIn,
    'agents_total': agentsTotal,
    'agents_logged_in': agentsLoggedIn,
    'callers_waiting': callersWaiting,
  };

  WebtritApiClient clientAnswering(
    Object? responseJson, {
    int statusCode = 200,
    void Function(Request request)? onRequest,
  }) {
    Future<Response> handler(Request request) async {
      onRequest?.call(request);
      return Response(
        jsonEncode(responseJson),
        statusCode,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    }

    return WebtritApiClient.inner(Uri.https(authority), '', httpClient: MockClient(handler));
  }

  Map<String, dynamic> bodyOf(Request request) => jsonDecode(request.body) as Map<String, dynamic>;

  group('reading the queues', () {
    test('asks the queues route and parses the list', () async {
      late Request captured;
      final apiClient = clientAnswering({
        'items': [queueJson()],
      }, onRequest: (request) => captured = request);

      final response = await apiClient.getUserCallQueues(token);

      expect(captured.method, equalsIgnoringCase('GET'));
      expect(captured.url.path, '/api/v1/user/queues');
      expect(response.items.single.id, '0111');
      expect(response.items.single.name, 'First line support');
      expect(response.items.single.loggedIn, isTrue);
      expect(response.items.single.agentsTotal, 3);
      expect(response.items.single.agentsLoggedIn, 2);
      expect(response.items.single.callersWaiting, 3);
    });

    test('an unknown callers_waiting stays null instead of becoming zero', () async {
      final apiClient = clientAnswering({
        'items': [queueJson(callersWaiting: null)],
      });

      final response = await apiClient.getUserCallQueues(token);

      expect(response.items.single.callersWaiting, isNull);
    });

    test('a reported zero stays zero', () async {
      final apiClient = clientAnswering({
        'items': [queueJson(callersWaiting: 0)],
      });

      final response = await apiClient.getUserCallQueues(token);

      expect(response.items.single.callersWaiting, 0);
    });

    test('an empty list is an answer, not a failure', () async {
      final apiClient = clientAnswering({'items': <Object?>[]});

      final response = await apiClient.getUserCallQueues(token);

      expect(response.items, isEmpty);
    });
  });

  group('logging in and out', () {
    test('one queue is addressed by its number and carries only the flag', () async {
      late Request captured;
      final apiClient = clientAnswering(queueJson(loggedIn: false), onRequest: (request) => captured = request);

      final queue = await apiClient.updateUserCallQueue(token, '0111', loggedIn: false);

      expect(captured.method, equalsIgnoringCase('PATCH'));
      expect(captured.url.path, '/api/v1/user/queues/0111');
      expect(bodyOf(captured), {'logged_in': false});
      expect(queue.loggedIn, isFalse);
    });

    test('every queue at once is the same body on the collection', () async {
      late Request captured;
      final apiClient = clientAnswering({
        'items': [queueJson(loggedIn: true), queueJson(id: '0222', loggedIn: true)],
      }, onRequest: (request) => captured = request);

      final response = await apiClient.updateUserCallQueues(token, loggedIn: true);

      expect(captured.method, equalsIgnoringCase('PATCH'));
      expect(captured.url.path, '/api/v1/user/queues');
      expect(bodyOf(captured), {'logged_in': true});
      expect(response.items.map((queue) => queue.loggedIn), everyElement(isTrue));
    });

    test('the state the server returned is what comes back, not what was asked for', () async {
      // A queue whose agents moved while the write was in flight: the answer
      // carries the counts, so a caller that renders the response cannot show
      // the pre-change figures.
      final apiClient = clientAnswering(queueJson(loggedIn: false, agentsLoggedIn: 1));

      final queue = await apiClient.updateUserCallQueue(token, '0111', loggedIn: false);

      expect(queue.agentsLoggedIn, 1);
    });

    test('a queue id needing encoding is encoded rather than split into segments', () async {
      late Request captured;
      final apiClient = clientAnswering(queueJson(id: 'a/b'), onRequest: (request) => captured = request);

      await apiClient.updateUserCallQueue(token, 'a/b', loggedIn: true);

      expect(captured.url.pathSegments.last, 'a/b');
      expect(captured.url.path, '/api/v1/user/queues/a%2Fb');
    });
  });

  group('refusals', () {
    WebtritApiClient clientFailing(int statusCode, {String body = ''}) {
      Future<Response> handler(Request request) async => Response(body, statusCode, request: request);
      return WebtritApiClient.inner(Uri.https(authority), '', httpClient: MockClient(handler));
    }

    test('a deployment without the feature answers 501 and reads as unsupported', () {
      final apiClient = clientFailing(501);

      expect(apiClient.getUserCallQueues(token), throwsA(isA<EndpointNotSupportedException>()));
    });

    test('a 404 with no code is an absent route, not a missing queue', () {
      final apiClient = clientFailing(404);

      expect(
        apiClient.updateUserCallQueue(token, '0111', loggedIn: true),
        throwsA(isA<EndpointNotSupportedException>()),
      );
    });

    test('a 404 carrying the code is a queue this user is not an agent of', () {
      final apiClient = clientFailing(
        404,
        body: jsonEncode({'code': 'call_queue_not_found', 'message': 'Call queue not found'}),
      );

      expect(apiClient.updateUserCallQueue(token, '0111', loggedIn: true), throwsA(isA<CallQueueNotFoundException>()));
    });

    test('a dead session is still a dead session on these routes', () {
      // The shared rules keep answering for the session on an optional
      // endpoint: the flag above must not swallow a 401 into "unsupported".
      final apiClient = clientFailing(401, body: jsonEncode({'code': 'session_missing', 'message': 'gone'}));

      expect(apiClient.getUserCallQueues(token), throwsA(isA<SessionMissingException>()));
    });
  });
}
