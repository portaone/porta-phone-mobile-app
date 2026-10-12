import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// Deleting notifications. Two answers here are easy to misread: the bulk call
// skips ids it does not have instead of refusing them, so only deleted_ids says
// what is gone, and a single delete of a notification removed elsewhere is a
// 404 that means "already gone" rather than a failed request.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';

  WebtritApiClient clientAnswering(
    Object? responseJson, {
    int statusCode = 200,
    void Function(Request request)? onRequest,
  }) {
    Future<Response> handler(Request request) async {
      onRequest?.call(request);
      return Response(
        responseJson == null ? '' : jsonEncode(responseJson),
        statusCode,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    }

    return WebtritApiClient.inner(Uri.https(authority), '', httpClient: MockClient(handler));
  }

  group('deleting one notification', () {
    test('sends DELETE to the notification route', () async {
      late Request captured;
      final apiClient = clientAnswering(null, statusCode: 204, onRequest: (request) => captured = request);

      await apiClient.deleteSystemNotification(token, 12);

      expect(captured.method, equalsIgnoringCase('DELETE'));
      expect(captured.url.path, '/api/v1/user/notifications/12');
      expect(captured.headers['authorization'], 'Bearer $token');
      expect(captured.body, isEmpty);
    });

    test('a notification the backend no longer has is reported as gone', () async {
      final apiClient = clientAnswering({'code': 'notification_not_found'}, statusCode: 404);

      await expectLater(
        apiClient.deleteSystemNotification(token, 12),
        throwsA(isA<SystemNotificationGoneException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('a 404 without that code stays a plain failure', () async {
      final apiClient = clientAnswering({'code': 'session_not_found'}, statusCode: 404);

      await expectLater(
        apiClient.deleteSystemNotification(token, 12),
        throwsA(isA<RequestFailure>().having((e) => e, 'exception', isNot(isA<SystemNotificationGoneException>()))),
      );
    });
  });

  group('deleting several notifications', () {
    test('sends the ids in the body of a DELETE to the list route', () async {
      late Request captured;
      final apiClient = clientAnswering({
        'deleted_ids': [12, 15],
      }, onRequest: (request) => captured = request);

      await apiClient.deleteSystemNotifications(token, [12, 15]);

      expect(captured.method, equalsIgnoringCase('DELETE'));
      expect(captured.url.path, '/api/v1/user/notifications');
      expect(captured.headers['content-type'], startsWith('application/json'));
      expect(jsonDecode(captured.body), {
        'ids': [12, 15],
      });
    });

    test('returns only what the backend deleted', () async {
      final apiClient = clientAnswering({
        'deleted_ids': [12],
      });

      final response = await apiClient.deleteSystemNotifications(token, [12, 15, 99]);

      expect(response.deletedIds, [12]);
    });

    test('a Core without the bulk route says so instead of failing plainly', () async {
      final apiClient = clientAnswering({'message': 'Not Found'}, statusCode: 404);

      await expectLater(
        apiClient.deleteSystemNotifications(token, [12]),
        throwsA(isA<EndpointNotSupportedException>()),
      );
    });

    test('nothing deleted is an empty list, not a failure', () async {
      final apiClient = clientAnswering({'deleted_ids': <int>[]});

      final response = await apiClient.deleteSystemNotifications(token, [99]);

      expect(response.deletedIds, isEmpty);
    });
  });

  group('marking a notification seen', () {
    test('one the backend no longer has is reported as gone', () async {
      final apiClient = clientAnswering({'code': 'notification_not_found'}, statusCode: 404);

      await expectLater(
        apiClient.markSystemNotificationAsSeen(token, 12),
        throwsA(isA<SystemNotificationGoneException>()),
      );
    });
  });
}
