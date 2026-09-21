import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;
import 'package:webtrit_phone/app/session/session.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/mocks.dart';

api.CdrRecord _apiRecord(String callId) => api.CdrRecord(
  callId: callId,
  callee: '1000',
  caller: '2000',
  connectTime: DateTime.utc(2026, 9, 21, 10),
  direction: api.CdrDirection.incoming,
  disconnectReason: 'normal',
  disconnectTime: DateTime.utc(2026, 9, 21, 10, 1),
  duration: 60,
  status: api.CdrStatus.accepted,
);

void main() {
  late MockWebtritApiClient apiClient;
  late CdrsRemoteRepository repository;

  setUp(() {
    apiClient = MockWebtritApiClient();
    repository = CdrsRemoteRepositoryApiImpl(apiClient, 'user_token', const EmptySessionGuard());
  });

  void stub(api.CdrHistoryResponse response) {
    when(
      () => apiClient.getCdrHistory(
        any(),
        timeFrom: any(named: 'timeFrom'),
        timeTo: any(named: 'timeTo'),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => response);
  }

  test('carries the total the backend reported for the requested range', () async {
    stub(
      api.CdrHistoryResponse(
        items: [_apiRecord('1'), _apiRecord('2')],
        pagination: const api.Pagination(page: 1, itemsPerPage: 2, itemsTotal: 137),
      ),
    );

    final page = await repository.getHistory(page: 1, limit: 2);

    expect(page.records.map((cdr) => cdr.callId), ['1', '2']);
    expect(page.itemsTotal, 137);
  });

  test('reports no total when the backend sent no pagination', () async {
    stub(api.CdrHistoryResponse(items: [_apiRecord('1')]));

    final page = await repository.getHistory(limit: 50);

    expect(page.records, hasLength(1));
    expect(page.itemsTotal, isNull);
  });

  test('passes the range straight through under the names the wire uses', () async {
    stub(const api.CdrHistoryResponse(items: []));
    final timeFrom = DateTime.utc(2026, 9, 14, 12);
    final timeTo = DateTime.utc(2026, 9, 21, 12);

    await repository.getHistory(timeFrom: timeFrom, timeTo: timeTo, page: 2, limit: 50);

    verify(() => apiClient.getCdrHistory('user_token', timeFrom: timeFrom, timeTo: timeTo, page: 2, limit: 50))
        .called(1);
  });
}
