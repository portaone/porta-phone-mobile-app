import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' show EndpointNotSupportedException;
import 'package:webtrit_phone/features/cdrs/cdrs.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

class _MockCdrsRemoteRepository extends Mock implements CdrsRemoteRepository {}

class _MockCdrsLocalRepository extends Mock implements CdrsLocalRepository {}

class _MockPollingTaskRunner extends Mock implements PollingTaskRunner {}

void main() {
  late _MockCdrsRemoteRepository remote;
  late _MockCdrsLocalRepository local;
  late _MockPollingTaskRunner sync;
  late CdrsHistoryClearCubit cubit;

  setUp(() {
    remote = _MockCdrsRemoteRepository();
    local = _MockCdrsLocalRepository();
    sync = _MockPollingTaskRunner();
    when(() => remote.clearHistory()).thenAnswer((_) async {});
    when(() => local.replaceAfterClear(any(), syncedAt: any(named: 'syncedAt'))).thenAnswer((_) async {});
    when(() => sync.runNow()).thenAnswer((_) async {});
    cubit = CdrsHistoryClearCubit(remote, local, sync);
  });

  tearDown(() => cubit.close());

  test('clears on the backend, lets a running sync end, drops the local copy and syncs again', () async {
    final states = <CdrsHistoryClearState>[];
    final sub = cubit.stream.listen(states.add);

    await cubit.clear();
    await sub.cancel();

    expect(states, [CdrsHistoryClearState.clearing, CdrsHistoryClearState.cleared]);
    // The sync before the drop is the one a cycle already running is joined
    // through: what it fetched before the clear is stored before the drop.
    verifyInOrder([
      () => remote.clearHistory(),
      () => sync.runNow(),
      () => local.replaceAfterClear(const [], syncedAt: any(named: 'syncedAt')),
      () => sync.runNow(),
    ]);
  });

  test('a failed local drop still reports the clear and leaves the copy to the next cycle', () async {
    // Asking the backend again would clear the calls made in between; the
    // next cycle finds the newest stored record gone and drops the copy.
    when(() => local.replaceAfterClear(any(), syncedAt: any(named: 'syncedAt'))).thenThrow(Exception('disk'));

    await cubit.clear();

    expect(cubit.state, CdrsHistoryClearState.cleared);
    verify(() => remote.clearHistory()).called(1);
    verify(() => sync.runNow()).called(2);
  });

  test('a backend that cannot clear keeps the local copy and says so', () async {
    when(() => remote.clearHistory()).thenThrow(
      EndpointNotSupportedException(
        url: Uri.parse('https://core.test/api/v1/user/history/clear'),
        requestId: 'request-1',
        statusCode: 404,
        recognizedNotSupportedCodes: const [],
      ),
    );

    await cubit.clear();

    expect(cubit.state, CdrsHistoryClearState.unsupported);
    verifyNever(() => local.replaceAfterClear(any(), syncedAt: any(named: 'syncedAt')));
  });

  test('a failed request keeps the local copy', () async {
    when(() => remote.clearHistory()).thenThrow(Exception('offline'));

    await cubit.clear();

    expect(cubit.state, CdrsHistoryClearState.failed);
    verifyNever(() => local.replaceAfterClear(any(), syncedAt: any(named: 'syncedAt')));
    verifyNever(() => sync.runNow());
  });

  test('a failed sync afterwards does not undo a done clear', () async {
    when(() => sync.runNow()).thenThrow(Exception('offline'));

    await cubit.clear();

    expect(cubit.state, CdrsHistoryClearState.cleared);
  });

  test('a second press while clearing sends nothing more', () async {
    final pending = Completer<void>();
    when(() => remote.clearHistory()).thenAnswer((_) => pending.future);

    final first = cubit.clear();
    await cubit.clear();
    pending.complete();
    await first;

    verify(() => remote.clearHistory()).called(1);
  });
}
