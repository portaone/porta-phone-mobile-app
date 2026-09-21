import 'package:webtrit_phone/features/cdrs/cubit/cdrs_list_cubit.dart';
import 'package:webtrit_phone/models/models.dart';

class NumberCdrsLogCubit extends CdrsListCubit {
  NumberCdrsLogCubit(
    this.number,
    super.localRepository,
    super.remoteRepository,
    super.syncStateSource, {
    super.pageSize,
    super.historyWindows,
    super.walkQueue,
  });

  final String number;

  @override
  Future<List<CdrRecord>> queryLocal({DateTime? olderThan}) =>
      localRepository.getHistory(number: number, olderThan: olderThan, limit: pageSize);

  @override
  bool matches(CdrRecord cdr) => cdr.callerNumber == number || cdr.calleeNumber == number;
}
