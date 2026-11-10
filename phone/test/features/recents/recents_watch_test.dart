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
import 'package:webtrit_phone/features/recents/recents.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockRecentsBloc extends MockBloc<RecentsEvent, RecentsState> implements RecentsBloc {}

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _MockCallRoutingCubit extends MockCubit<CallRoutingState?> implements CallRoutingCubit {}

class _MockStackRouter extends Mock implements StackRouter {}

Recent _recent(int id, {CallDirection direction = CallDirection.outgoing, bool answered = true}) {
  final created = DateTime(2026, 1, 1, 9, id);
  return Recent(
    callLogEntry: CallLogEntry(
      id: id,
      direction: direction,
      number: '100$id',
      video: false,
      createdTime: created,
      acceptedTime: answered ? created : null,
    ),
    contact: null,
  );
}

void main() {
  late _MockRecentsBloc recentsBloc;
  late _MockCallBloc callBloc;
  late _MockCallRoutingCubit callRoutingCubit;
  late _MockStackRouter router;

  setUpAll(() {
    registerFallbackValue(const RecentsFiltered(RecentsVisibilityFilter.all));
    registerFallbackValue(CallLogScreenPageRoute(number: ''));
    registerFallbackValue(CallControlEvent.blindTransferSubmitted(number: ''));
  });

  setUp(() {
    recentsBloc = _MockRecentsBloc();
    callBloc = _MockCallBloc();
    callRoutingCubit = _MockCallRoutingCubit();
    router = _MockStackRouter();
    whenListen(callBloc, const Stream<CallState>.empty(), initialState: const CallState());
    whenListen(callRoutingCubit, const Stream<CallRoutingState?>.empty(), initialState: null);
    when(() => router.navigate(any())).thenAnswer((_) async {});
  });

  void stateIs(RecentsState state) {
    whenListen(recentsBloc, const Stream<RecentsState>.empty(), initialState: state);
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
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<RecentsBloc>.value(value: recentsBloc),
                  BlocProvider<CallBloc>.value(value: callBloc),
                  BlocProvider<CallRoutingCubit>.value(value: callRoutingCubit),
                ],
                child: CallControllerScope(
                  controller: CallController(callBloc: callBloc),
                  child: const RecentsScreen(
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
    );
  }

  final calls = [
    _recent(1),
    _recent(2, direction: CallDirection.incoming, answered: false),
    for (var i = 3; i < 30; i++) _recent(i),
  ];

  for (final preset in watchPresets) {
    testWidgets('on $preset the calls are a list under the title and the filter, no tabs or bar', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      stateIs(RecentsState(recents: calls, filter: RecentsVisibilityFilter.all));

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(RecentsActionsFab), findsNothing);
      final title = tester.getRect(find.text('Recents'));
      final chip = tester.getRect(find.byKey(recentsWatchFilterKey));
      final first = tester.getRect(find.byType(RecentsWatchTile).first);
      expect(title.bottom, lessThanOrEqualTo(chip.top));
      expect(chip.bottom, lessThanOrEqualTo(first.top));
      final separator = tester.getRect(find.byType(WatchSeparator));
      expect(chip.bottom, lessThanOrEqualTo(separator.top));
      expect(separator.bottom, lessThanOrEqualTo(tester.getRect(find.byType(RecentsWatchTile).first).top));
      expect(find.text('1001'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^1002, Missed, ')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('on $preset a tap opens the calls with that number and dials nothing', (tester) async {
      preset.apply(tester);
      stateIs(RecentsState(recents: calls, filter: RecentsVisibilityFilter.all));
      await pumpCollectingOverflows(tester, app());

      await tester.tap(find.text('1001'));
      await tester.pump();

      final route = verify(() => router.navigate(captureAny())).captured.single as CallLogScreenPageRoute;
      expect(route.args?.number, '1001');
      verifyNever(() => callBloc.add(any()));
    });

    testWidgets('on $preset the chip names the filter and a tap moves to the next', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      stateIs(RecentsState(recents: calls, filter: RecentsVisibilityFilter.all));
      await pumpCollectingOverflows(tester, app());

      final chip = find.bySemanticsIdentifier(recentsWatchFilterId);
      expect(tester.getSemantics(chip).getSemanticsData().label, 'Show calls: All');
      await tapViaSemantics(tester, chip);

      verify(() => recentsBloc.add(const RecentsFiltered(RecentsVisibilityFilter.missed))).called(1);
      handle.dispose();
    });

    testWidgets('on $preset the list on its way is a loading page', (tester) async {
      preset.apply(tester);
      stateIs(const RecentsState(filter: RecentsVisibilityFilter.all));

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(WatchStatePage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Recents'), findsOneWidget);
    });

    testWidgets('on $preset no missed calls says so and leads back to all of them', (tester) async {
      preset.apply(tester);
      stateIs(RecentsState(recents: [_recent(1)], filter: RecentsVisibilityFilter.missed));

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(WatchStatePage), findsOneWidget);
      expect(find.textContaining('no missed recent calls'), findsOneWidget);
      await tester.tap(find.byType(WatchEdgeButton));
      await tester.pump();

      verify(() => recentsBloc.add(const RecentsFiltered(RecentsVisibilityFilter.all))).called(1);
    });
  }

  testWidgets('no calls at all has no button to go anywhere', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(const RecentsState(recents: [], filter: RecentsVisibilityFilter.all));

    await pumpCollectingOverflows(tester, app());

    expect(find.byType(WatchStatePage), findsOneWidget);
    expect(find.byType(WatchEdgeButton), findsNothing);
  });
}
