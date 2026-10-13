import 'dart:convert';

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

// The notification updates. They are the only place a delete made elsewhere is
// heard of: the backend lists a deleted notification here, marked, when asked
// to.
void main() {
  const authority = 'demo.webtrit.com';
  const token = 'token_1';
  final since = DateTime.utc(2026, 10, 1, 12);

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

  Map<String, Object?> item(int id, {String? deletedAt}) => {
    'id': id,
    'title': deletedAt == null ? 'Title $id' : '-',
    'content': deletedAt == null ? 'Content $id' : '-',
    'seen': false,
    'type': 'system',
    'created_at': '2026-10-01T10:00:00.000000Z',
    'updated_at': '2026-10-02T10:00:00.000000Z',
    'deleted_at': deletedAt,
  };

  test('asks for deleted notifications only when told to', () async {
    final queries = <Map<String, String>>[];
    final apiClient = clientAnswering({'items': []}, onRequest: (request) => queries.add(request.url.queryParameters));

    await apiClient.getSystemNotificationsUpdates(token, since: since, limit: 50);
    await apiClient.getSystemNotificationsUpdates(token, since: since, limit: 50, includeDeleted: true);

    expect(queries.first, {'updated_after': '2026-10-01T12:00:00.000Z', 'limit': '50'});
    expect(queries.last, {'updated_after': '2026-10-01T12:00:00.000Z', 'limit': '50', 'include_deleted': 'true'});
  });

  test('a deleted notification is told apart from one that exists', () async {
    final apiClient = clientAnswering({
      'items': [item(1), item(2, deletedAt: '2026-10-02T10:00:00.000000Z')],
    });

    final response = await apiClient.getSystemNotificationsUpdates(token, since: since, includeDeleted: true);

    expect(response.items.first.deletedAt, isNull);
    expect(response.items.last.deletedAt, DateTime.utc(2026, 10, 2, 10));
  });

  test('a backend that does not send deleted_at at all means none is deleted', () async {
    final apiClient = clientAnswering({
      'items': [item(1)..remove('deleted_at')],
    });

    final response = await apiClient.getSystemNotificationsUpdates(token, since: since);

    expect(response.items.single.deletedAt, isNull);
  });
}
