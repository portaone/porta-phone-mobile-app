import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_log/call_log.dart';
import 'package:webtrit_phone/features/cdrs/cdrs.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/theme/theme.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockNumberCdrsLogCubit extends MockCubit<CdrsListState> implements NumberCdrsLogCubit {}

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _MockContactsRepository extends Mock implements ContactsRepository {}

class _MockStackRouter extends Mock implements StackRouter {}

CdrRecord _cdr(int id, {CallDirection direction = CallDirection.outgoing, CdrStatus status = CdrStatus.accepted}) {
  final time = DateTime(2026, 1, 1, 9, id);
  return CdrRecord(
    callId: 'call-$id',
    direction: direction,
    status: status,
    callee: 'callee',
    calleeNumber: '2001',
    caller: 'caller',
    callerNumber: '3001',
    connectTime: time,
    disconnectTime: time,
    disconnectReason: '',
    duration: const Duration(seconds: 48),
  );
}

void main() {
  late _MockNumberCdrsLogCubit cubit;
  late _MockCallBloc callBloc;
  late _MockContactsRepository contacts;
  late _MockStackRouter router;

  setUpAll(() => registerFallbackValue(const CallControlEvent.started(video: false)));

  setUp(() {
    cubit = _MockNumberCdrsLogCubit();
    callBloc = _MockCallBloc();
    contacts = _MockContactsRepository();
    router = _MockStackRouter();
    when(() => cubit.number).thenReturn('2001');
    when(() => cubit.fetchHistory()).thenAnswer((_) async {});
    whenListen(callBloc, const Stream<CallState>.empty(), initialState: const CallState());
    when(() => contacts.watchContactByPhoneNumber(any())).thenAnswer((_) => Stream.value(null));
    when(() => router.maybePop<Object?>(any())).thenAnswer((_) async => true);
  });

  void stateIs(CdrsListState state) {
    whenListen(cubit, const Stream<CdrsListState>.empty(), initialState: state);
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
                    BlocProvider<NumberCdrsLogCubit>.value(value: cubit),
                    BlocProvider<CallBloc>.value(value: callBloc),
                  ],
                  child: const NumberCdrsScreen(title: Text('App'), videoVisible: false),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final records = [
    _cdr(1, direction: CallDirection.incoming, status: CdrStatus.missed),
    _cdr(2, direction: CallDirection.incoming, status: CdrStatus.completedElsewhere),
    for (var i = 3; i < 60; i++) _cdr(i),
  ];

  for (final preset in watchPresets) {
    testWidgets('on $preset the number, then a row per call above the call', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      stateIs(CdrsListState(records: records, isLoading: false));

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(AppBar), findsNothing);
      expect(find.text('2001'), findsOneWidget);
      expect(find.byKey(callLogWatchVideoCallKey), findsNothing);
      expect(
        tester.getRect(find.text('2001')).bottom,
        lessThanOrEqualTo(tester.getRect(find.byType(CallLogWatchRow).first).top),
      );
      // Only a call nobody answered is missed; one taken on another device is not.
      expect(find.bySemanticsLabel(RegExp(r'^Incoming, Missed, ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Incoming, 00:48, ')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('on $preset the edge button calls the number', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      stateIs(CdrsListState(records: records, isLoading: false));
      await pumpCollectingOverflows(tester, app());

      await tapViaSemantics(tester, find.bySemanticsIdentifier(callLogWatchCallId));

      verify(() => callBloc.add(const CallControlEvent.started(number: '2001', video: false))).called(1);
      handle.dispose();
    });

    testWidgets('on $preset the history on its way is a spinner under the call', (tester) async {
      preset.apply(tester);
      stateIs(const CdrsListState());

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(callLogWatchCallKey), findsOneWidget);
    });
  }

  testWidgets('an empty list walking the history further back is a spinner', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(const CdrsListState(isLoading: false, fetchingHistory: true));

    expect(await pumpCollectingOverflows(tester, app()), isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('No recent calls'), findsNothing);
  });

  testWidgets('a number with no calls says so above the call', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(const CdrsListState(isLoading: false));

    expect(await pumpCollectingOverflows(tester, app()), isEmpty);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('No recent calls'), findsOneWidget);
    expect(find.byKey(callLogWatchCallKey), findsOneWidget);
  });

  testWidgets('scrolling near the end fetches older calls', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(CdrsListState(records: records, isLoading: false));
    await pumpCollectingOverflows(tester, app());

    await tester.drag(find.byType(Scrollable).last, const Offset(0, -3000));
    await tester.pump();

    verify(() => cubit.fetchHistory()).called(greaterThan(0));
  });
}
