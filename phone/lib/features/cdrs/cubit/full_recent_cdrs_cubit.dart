import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/services/services.dart';

import 'cdrs_list_cubit.dart';

class FullRecentCdrsCubit extends CdrsListCubit {
  FullRecentCdrsCubit(
    super.localRepository,
    super.remoteRepository,
    super.syncStateSource,
    this.syncRunner, {
    super.pageSize,
    super.historyWindows,
  });

  final PollingTaskRunner syncRunner;

  /// Runs the app-owned CDR sync now or joins its in-flight cycle.
  Future<void> refresh() => syncRunner.runNow();

  @override
  Future<List<CdrRecord>> queryLocal({DateTime? olderThan}) =>
      localRepository.getHistory(olderThan: olderThan, limit: pageSize);

  @override
  bool matches(CdrRecord cdr) => true;
}
