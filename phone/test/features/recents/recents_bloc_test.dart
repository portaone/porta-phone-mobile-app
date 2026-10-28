import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/recents/recents.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockRecentsRepository extends Mock implements RecentsRepository {}

class _MockActiveRecentsVisibilityFilterRepository extends Mock implements ActiveRecentsVisibilityFilterRepository {}

void main() {
  late _MockRecentsRepository recentsRepository;
  late _MockActiveRecentsVisibilityFilterRepository filterRepository;

  setUp(() {
    recentsRepository = _MockRecentsRepository();
    filterRepository = _MockActiveRecentsVisibilityFilterRepository();
    when(() => filterRepository.getActiveRecentsVisibilityFilter()).thenReturn(RecentsVisibilityFilter.all);
    when(() => recentsRepository.deleteAll()).thenAnswer((_) async {});
  });

  RecentsBloc build() => RecentsBloc(
    recentsRepository: recentsRepository,
    activeRecentsVisibilityFilterRepository: filterRepository,
    dateFormat: DateFormat(),
  );

  blocTest<RecentsBloc, RecentsState>(
    'clearing deletes the whole call log and says it is done only once it is',
    build: build,
    act: (bloc) => bloc.add(const RecentsCleared()),
    expect: () => [
      isA<RecentsState>().having((s) => s.clearStatus, 'clearStatus', RecentsClearStatus.clearing),
      isA<RecentsState>().having((s) => s.clearStatus, 'clearStatus', RecentsClearStatus.cleared),
    ],
    verify: (_) => verify(() => recentsRepository.deleteAll()).called(1),
  );

  blocTest<RecentsBloc, RecentsState>(
    'a failed delete is reported, not announced as done',
    build: build,
    setUp: () => when(() => recentsRepository.deleteAll()).thenThrow(Exception('disk')),
    act: (bloc) => bloc.add(const RecentsCleared()),
    expect: () => [
      isA<RecentsState>().having((s) => s.clearStatus, 'clearStatus', RecentsClearStatus.clearing),
      isA<RecentsState>().having((s) => s.clearStatus, 'clearStatus', RecentsClearStatus.failed),
    ],
  );
}
