import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/features/cdrs/cdrs.dart';
import 'package:webtrit_phone/features/recents/recents.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockFullCubit extends MockCubit<CdrsListState> implements FullRecentCdrsCubit {}

class _MockMissedCubit extends MockCubit<CdrsListState> implements MissedRecentCdrsCubit {}

class _MockClearCubit extends MockCubit<CdrsHistoryClearState> implements CdrsHistoryClearCubit {}

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _MockCallRoutingCubit extends MockCubit<CallRoutingState?> implements CallRoutingCubit {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockStackRouter extends Mock implements StackRouter {}

CdrRecord _cdr(int id, {CallDirection direction = CallDirection.outgoing, CdrStatus? status, bool number = true}) {
  final time = DateTime(2026, 1, 1, 9, id);
  return CdrRecord(
    callId: 'call-$id',
    direction: direction,
    status: status ?? CdrStatus.accepted,
    callee: 'callee $id',
    calleeNumber: number ? '200$id' : null,
    caller: 'caller $id',
    callerNumber: number ? '300$id' : null,
    connectTime: time,
    disconnectTime: time,
    disconnectReason: '',
    duration: const Duration(minutes: 1),
  );
}

void main() {
  late _MockFullCubit full;
  late _MockMissedCubit missed;
  late _MockClearCubit clear;
  late _MockCallBloc callBloc;
  late _MockCallRoutingCubit callRoutingCubit;
  late _MockContactsRepository contacts;
  late _MockStackRouter router;

  setUpAll(() => registerFallbackValue(NumberCdrsScreenPageRoute(number: '')));

  setUp(() {
    full = _MockFullCubit();
    missed = _MockMissedCubit();
    clear = _MockClearCubit();
    callBloc = _MockCallBloc();
    callRoutingCubit = _MockCallRoutingCubit();
    contacts = _MockContactsRepository();
    router = _MockStackRouter();
    whenListen(clear, const Stream<CdrsHistoryClearState>.empty(), initialState: CdrsHistoryClearState.idle);
    whenListen(callBloc, const Stream<CallState>.empty(), initialState: const CallState());
    whenListen(callRoutingCubit, const Stream<CallRoutingState?>.empty(), initialState: null);
    when(() => contacts.watchContactByPhoneNumber(any())).thenAnswer((_) => Stream.value(null));
    when(() => router.navigate(any())).thenAnswer((_) async {});
    when(() => full.fetchHistory()).thenAnswer((_) async {});
  });

  void statesAre(CdrsListState fullState, CdrsListState missedState) {
    whenListen(full, const Stream<CdrsListState>.empty(), initialState: fullState);
    whenListen(missed, const Stream<CdrsListState>.empty(), initialState: missedState);
  }

  Widget app() {
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RouterScope(
          controller: router,
          inheritableObserversBuilder: () => const [],
          stateHash: 0,
          navigatorObservers: const [],
          child: StackRouterScope(
            controller: router,
            stateHash: 0,
            child: RepositoryProvider<AppTime>.value(
              value: AppTime(is24HourFormat: true),
              child: RepositoryProvider<ContactsRepository>.value(
                value: contacts,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider<FullRecentCdrsCubit>.value(value: full),
                    BlocProvider<MissedRecentCdrsCubit>.value(value: missed),
                    BlocProvider<CdrsHistoryClearCubit>.value(value: clear),
                    BlocProvider<CallBloc>.value(value: callBloc),
                    BlocProvider<CallRoutingCubit>.value(value: callRoutingCubit),
                  ],
                  child: CallControllerScope(
                    controller: CallController(callBloc: callBloc),
                    child: const RecentCdrsScreen(
                      watchTitle: 'Recents',
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
        ),
      ),
    );
  }

  final records = [
    _cdr(1),
    _cdr(2, direction: CallDirection.incoming, status: CdrStatus.missed),
    _cdr(3, number: false),
    for (var i = 4; i < 30; i++) _cdr(i),
  ];
  final missedRecords = [_cdr(2, direction: CallDirection.incoming, status: CdrStatus.missed)];

  for (final preset in watchPresets) {
    testWidgets('on $preset the history is a list under the title and the filter, no tabs or bar', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      statesAre(CdrsListState(records: records, isLoading: false), CdrsListState(records: missedRecords));

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(TabBar), findsNothing);
      final title = tester.getRect(find.text('Recents'));
      final chip = tester.getRect(find.byKey(recentsWatchFilterKey));
      expect(title.bottom, lessThanOrEqualTo(chip.top));
      expect(chip.bottom, lessThanOrEqualTo(tester.getRect(find.byType(RecentsWatchTile).first).top));
      final separator = tester.getRect(find.byType(WatchSeparator));
      expect(chip.bottom, lessThanOrEqualTo(separator.top));
      expect(separator.bottom, lessThanOrEqualTo(tester.getRect(find.byType(RecentsWatchTile).first).top));
      expect(find.text('callee 1'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.bySemanticsLabel(RegExp(r'^caller 2, Missed, ')),
        40,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.bySemanticsLabel(RegExp(r'^caller 2, Missed, ')));
      handle.dispose();
      await tester.pump();
    });

    testWidgets('on $preset a tap opens the calls with the number; a record without one does nothing', (tester) async {
      preset.apply(tester);
      statesAre(CdrsListState(records: records, isLoading: false), CdrsListState(records: missedRecords));
      await pumpCollectingOverflows(tester, app());

      await tester.tap(find.text('callee 1'));
      await tester.pump();
      final route = verify(() => router.navigate(captureAny())).captured.single as NumberCdrsScreenPageRoute;
      expect(route.args?.number, '2001');

      await tester.scrollUntilVisible(find.text('callee 3'), 40, scrollable: find.byType(Scrollable).last);
      await tester.ensureVisible(find.text('callee 3'));
      await tester.pump();
      await tester.tap(find.text('callee 3'));
      await tester.pump();
      verifyNever(() => router.navigate(any()));
    });

    testWidgets('on $preset the chip shows the missed list, and back', (tester) async {
      preset.apply(tester);
      statesAre(
        CdrsListState(records: records, isLoading: false),
        CdrsListState(records: missedRecords, isLoading: false),
      );
      await pumpCollectingOverflows(tester, app());

      await tester.tap(find.byKey(recentsWatchFilterKey));
      await tester.pumpAndSettle();
      expect(find.byType(RecentsWatchTile), findsOneWidget);
      expect(find.text('caller 2'), findsOneWidget);

      await tester.tap(find.byKey(recentsWatchFilterKey));
      await tester.pumpAndSettle();
      expect(find.text('callee 1'), findsOneWidget);
    });

    testWidgets('on $preset the history on its way is a loading page', (tester) async {
      preset.apply(tester);
      statesAre(const CdrsListState(), const CdrsListState());

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);
      expect(find.byType(WatchStatePage), findsOneWidget);
    });

    testWidgets('on $preset no missed calls says so and leads back to all of them', (tester) async {
      preset.apply(tester);
      statesAre(CdrsListState(records: records, isLoading: false), const CdrsListState(isLoading: false));
      await pumpCollectingOverflows(tester, app());
      await tester.tap(find.byKey(recentsWatchFilterKey));
      await tester.pumpAndSettle();

      expect(find.text('No missed calls'), findsOneWidget);
      await tester.tap(find.byType(WatchEdgeButton));
      await tester.pumpAndSettle();
      expect(find.text('callee 1'), findsOneWidget);
    });
  }

  testWidgets('only a call the Missed list holds is read out as missed', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    statesAre(
      CdrsListState(
        records: [
          _cdr(1, direction: CallDirection.incoming, status: CdrStatus.completedElsewhere),
          _cdr(2, direction: CallDirection.incoming, status: CdrStatus.missed),
        ],
        isLoading: false,
      ),
      const CdrsListState(isLoading: false),
    );

    await pumpCollectingOverflows(tester, app());

    expect(find.bySemanticsLabel(RegExp(r'^caller 1, Missed, ')), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^caller 1, ')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^caller 2, Missed, ')), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an empty history offers to fetch it again, and says so when that fails', (tester) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    statesAre(const CdrsListState(isLoading: false), const CdrsListState(isLoading: false));
    var refreshes = 0;
    when(() => full.refresh()).thenAnswer((_) async {
      refreshes++;
      throw Exception('offline');
    });
    await pumpCollectingOverflows(tester, app());

    expect(find.text('No recent calls'), findsOneWidget);
    final refresh = find.bySemanticsIdentifier(recentsWatchRefreshId);
    expect(tester.getSemantics(refresh).getSemanticsData().label, 'Refresh');
    await tapViaSemantics(tester, refresh);
    await tester.pump();

    expect(refreshes, 1);
    expect(find.text('Could not refresh call history - please try again'), findsOneWidget);
    handle.dispose();
  });
}
