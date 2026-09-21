import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'package:api/api.dart';

void main() {
  test('getCdrHistory sends filters and page parameters', () async {
    late Request captured;
    final httpClient = MockClient((request) async {
      captured = request;
      return Response('{"items": []}', 200, request: request, headers: const {'content-type': 'application/json'});
    });
    final apiClient = WebtritApiClient.inner(Uri.https('core.webtrit.com'), '', httpClient: httpClient);
    final timeFrom = DateTime.utc(2026, 1, 2, 3, 4, 5);
    final timeTo = DateTime.utc(2026, 2, 3, 4, 5, 6);

    await apiClient.getCdrHistory('token', timeFrom: timeFrom, timeTo: timeTo, page: 3, limit: 50);

    expect(captured.method, equalsIgnoringCase('GET'));
    expect(captured.url.path, '/api/v1/user/history');
    expect(captured.url.queryParameters, {
      'time_from': timeFrom.toIso8601String(),
      'time_to': timeTo.toIso8601String(),
      'page': '3',
      'items_per_page': '50',
    });
    expect(captured.headers['Authorization'], 'Bearer token');
  });

  test('getCdrHistory reads the pagination of the filtered range', () async {
    final httpClient = MockClient((request) async {
      return Response(
        '{"items": [], "pagination": {"page": 2, "items_per_page": 50, "items_total": 137}}',
        200,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    });
    final apiClient = WebtritApiClient.inner(Uri.https('core.webtrit.com'), '', httpClient: httpClient);

    final response = await apiClient.getCdrHistory('token', page: 2, limit: 50);

    expect(response.pagination?.page, 2);
    expect(response.pagination?.itemsPerPage, 50);
    expect(response.pagination?.itemsTotal, 137);
  });

  test('getCdrHistory accepts a response that carries no pagination', () async {
    // Whether the object is filled in at all is the adapter's business, so an
    // answer without it must decode rather than throw.
    final httpClient = MockClient((request) async {
      return Response(
        '{"items": [{"call_id": "1", "callee": "1000", "caller": "2000", '
        '"connect_time": "2026-01-02T03:04:05Z", "direction": "incoming", '
        '"disconnect_reason": "normal", "disconnect_time": "2026-01-02T03:05:05Z", '
        '"duration": 60, "status": "accepted"}]}',
        200,
        request: request,
        headers: const {'content-type': 'application/json'},
      );
    });
    final apiClient = WebtritApiClient.inner(Uri.https('core.webtrit.com'), '', httpClient: httpClient);

    final response = await apiClient.getCdrHistory('token');

    expect(response.items, hasLength(1));
    expect(response.pagination, isNull);
  });
}
