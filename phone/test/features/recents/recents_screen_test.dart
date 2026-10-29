import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/features/recents/recents.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';

class MockRecentsBloc extends MockBloc<RecentsEvent, RecentsState> implements RecentsBloc {}

class MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class MockCallRoutingCubit extends MockCubit<CallRoutingState?> implements CallRoutingCubit {}

class MockSessionStatusCubit extends MockCubit<SessionStatusState> implements SessionStatusCubit {}

class MockUserInfoCubit extends MockCubit<UserInfoState> implements UserInfoCubit {}

class MockSmsRepository extends Mock implements SmsRepository {}

Recent recent(int id) => Recent(
  callLogEntry: CallLogEntry(
    id: id,
    direction: CallDirection.outgoing,
    number: '100$id',
    video: false,
    createdTime: DateTime.utc(2026, 1, 1, 0, id),
  ),
  contact: null,
);

void main() {
  late MockRecentsBloc recentsBloc;
  late MockCallBloc callBloc;
  late MockCallRoutingCubit callRoutingCubit;
  late MockSmsRepository smsRepository;
  late MockSessionStatusCubit sessionStatusCubit;
  late MockUserInfoCubit userInfoCubit;

  setUpAll(() => registerFallbackValue(const RecentsFiltered(RecentsVisibilityFilter.all)));

  setUp(() {
    recentsBloc = MockRecentsBloc();
    callBloc = MockCallBloc();
    callRoutingCubit = MockCallRoutingCubit();
    smsRepository = MockSmsRepository();
    sessionStatusCubit = MockSessionStatusCubit();
    userInfoCubit = MockUserInfoCubit();
    whenListen(sessionStatusCubit, const Stream<SessionStatusState>.empty(), initialState: const SessionStatusState());
    whenListen(userInfoCubit, const Stream<UserInfoState>.empty(), initialState: const UserInfoState());
    when(() => recentsBloc.dateFormat).thenReturn(DateFormat.Hm());
    whenListen(callBloc, const Stream<CallState>.empty(), initialState: const CallState());
    whenListen(callRoutingCubit, const Stream<CallRoutingState?>.empty(), initialState: null);
    when(() => smsRepository.watchUserSmsNumbers()).thenAnswer((_) => Stream.value(const []));
  });

  void stateIs(RecentsState state) {
    whenListen(recentsBloc, const Stream<RecentsState>.empty(), initialState: state);
  }

  Widget app({
    List<RecentsVisibilityFilter> filters = const [RecentsVisibilityFilter.all, RecentsVisibilityFilter.missed],
  }) {
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepositoryProvider<SmsRepository>.value(
          value: smsRepository,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<RecentsBloc>.value(value: recentsBloc),
              BlocProvider<CallBloc>.value(value: callBloc),
              BlocProvider<CallRoutingCubit>.value(value: callRoutingCubit),
              BlocProvider<SessionStatusCubit>.value(value: sessionStatusCubit),
              BlocProvider<UserInfoCubit>.value(value: userInfoCubit),
            ],
            child: CallControllerScope(
              controller: CallController(callBloc: callBloc),
              child: PresenceViewParams(
                hybridPresenceSupport: false,
                blfViaSipSupport: false,
                presenceViaSipSupport: false,
                child: RecentsScreen(
                  recentsFilters: filters,
                  transferEnabled: false,
                  videoEnabled: false,
                  chatsEnabled: false,
                  smssEnabled: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a remembered filter the screen does not offer gives way to the first one it does', (tester) async {
    stateIs(RecentsState(recents: [recent(1)], filter: RecentsVisibilityFilter.missed));

    await tester.pumpWidget(app(filters: const [RecentsVisibilityFilter.all]));

    verify(() => recentsBloc.add(const RecentsFiltered(RecentsVisibilityFilter.all))).called(1);
  });

  testWidgets('a remembered filter the screen offers stays', (tester) async {
    stateIs(RecentsState(recents: [recent(1)], filter: RecentsVisibilityFilter.missed));

    await tester.pumpWidget(app());

    verifyNever(() => recentsBloc.add(any(that: isA<RecentsFiltered>())));
  });

  testWidgets('the end of the list scrolls out from under the actions button', (tester) async {
    stateIs(RecentsState(recents: [for (var i = 0; i < 30; i++) recent(i)], filter: RecentsVisibilityFilter.all));
    await tester.pumpWidget(app());

    final list = find.byType(Scrollable).last;
    // The extent is an estimate until the rows near the end are laid out.
    for (var i = 0; i < 3; i++) {
      final position = tester.state<ScrollableState>(list).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
    }

    final lastRow = tester.getRect(find.byType(RecentTile).last);
    final button = tester.getRect(find.byType(RecentsActionsFab));
    expect(lastRow.bottom, lessThanOrEqualTo(button.top));
  });
}
