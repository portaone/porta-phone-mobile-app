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
import 'package:webtrit_phone/features/keypad/keypad.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';

class _MockCallLogBloc extends MockBloc<CallLogEvent, CallLogState> implements CallLogBloc {}

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _MockStackRouter extends Mock implements StackRouter {}

CallLogEntry _entry(int id, {CallDirection direction = CallDirection.outgoing, bool answered = true}) {
  final created = DateTime(2026, 1, 1, 9, id);
  return CallLogEntry(
    id: id,
    direction: direction,
    number: '1001',
    video: id == 3,
    createdTime: created,
    acceptedTime: answered ? created : null,
    hungUpTime: answered ? created.add(const Duration(minutes: 3, seconds: 14)) : null,
  );
}

final _contact = Contact(
  id: 1,
  sourceType: ContactSourceType.external,
  kind: ContactKind.visible,
  firstName: 'Anna',
  lastName: 'Marchenko',
);

void main() {
  late _MockCallLogBloc callLogBloc;
  late _MockCallBloc callBloc;
  late _MockStackRouter router;

  setUpAll(() => registerFallbackValue(const CallControlEvent.started(video: false)));

  setUp(() {
    callLogBloc = _MockCallLogBloc();
    callBloc = _MockCallBloc();
    router = _MockStackRouter();
    whenListen(callBloc, const Stream<CallState>.empty(), initialState: const CallState());
    when(() => router.maybePop<Object?>(any())).thenAnswer((_) async => true);
  });

  void stateIs(CallLogState state) {
    whenListen(callLogBloc, const Stream<CallLogState>.empty(), initialState: state);
  }

  Widget app({bool videoVisible = true}) {
    return ThemeProvider(
      settings: const ThemeSettings(),
      lightDynamic: null,
      darkDynamic: null,
      child: Builder(
        builder: (context) => MaterialApp(
          theme: ThemeProvider.of(context).light(),
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
                    BlocProvider<CallLogBloc>.value(value: callLogBloc),
                    BlocProvider<CallBloc>.value(value: callBloc),
                  ],
                  child: CallLogScreen(videoVisible: videoVisible),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final calls = [
    _entry(1, direction: CallDirection.incoming, answered: false),
    _entry(2, direction: CallDirection.incoming),
    _entry(3),
    for (var i = 4; i < 20; i++) _entry(i),
  ];

  for (final preset in watchPresets) {
    testWidgets('on $preset the name, the number, a row per call, then the video call, all above the call', (
      tester,
    ) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      stateIs(CallLogState(number: '1001', contact: _contact, callLog: calls));

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(LeadingAvatar), findsNothing);
      final title = tester.getRect(find.text('Anna Marchenko'));
      final number = tester.getRect(find.text('1001'));
      final first = tester.getRect(find.byType(CallLogWatchRow).first);
      final call = tester.getRect(find.byKey(callLogWatchCallKey));
      expect(title.bottom, lessThanOrEqualTo(number.top));
      expect(number.bottom, lessThanOrEqualTo(first.top));
      // The first call is in view at rest, above the call button.
      expect(first.bottom, lessThanOrEqualTo(call.top));
      expect(call.top, greaterThan(tester.getRect(find.byType(Scaffold)).center.dy));

      expect(find.bySemanticsLabel(RegExp(r'^Incoming, Missed, ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Incoming, 03:14, ')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Outgoing, Video call, 03:14, ')), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(callLogWatchCallId)).getSemanticsData().label,
        'Audio call',
      );

      // The video call closes the list and scrolls clear of the call button.
      final list = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(find.byKey(callLogWatchVideoCallKey), 40, scrollable: list);
      await tester.drag(list, const Offset(0, -400));
      await tester.pumpAndSettle();
      final video = tester.getRect(find.byKey(callLogWatchVideoCallKey));
      expect(tester.getRect(find.byKey(ObjectKey(calls.last))).bottom, lessThanOrEqualTo(video.top));
      expect(video.bottom, lessThanOrEqualTo(call.top));
      handle.dispose();
    });

    testWidgets('on $preset the edge button calls the number and the page closes', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      stateIs(CallLogState(number: '1001', contact: _contact, callLog: calls));
      await pumpCollectingOverflows(tester, app());

      await tapViaSemantics(tester, find.bySemanticsIdentifier(callLogWatchCallId));

      verify(
        () => callBloc.add(const CallControlEvent.started(number: '1001', displayName: 'Anna Marchenko', video: false)),
      ).called(1);
      verify(() => router.maybePop<Object?>(any())).called(1);
      handle.dispose();
    });

    testWidgets('on $preset the calls on their way are a spinner under a call already there', (tester) async {
      preset.apply(tester);
      stateIs(const CallLogState(number: '1001'));

      expect(await pumpCollectingOverflows(tester, app()), isEmpty);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byKey(callLogWatchCallKey), findsOneWidget);
    });
  }

  testWidgets('a number with no calls left says so above the call', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(const CallLogState(number: '1001', callLog: []));

    expect(await pumpCollectingOverflows(tester, app()), isEmpty);

    expect(find.text('No recent calls'), findsOneWidget);
    expect(find.byKey(callLogWatchCallKey), findsOneWidget);
  });

  testWidgets('the call button is the keypad\'s call, filled', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(CallLogState(number: '1001', contact: _contact, callLog: calls));
    await pumpCollectingOverflows(tester, app());

    final context = tester.element(find.byKey(callLogWatchCallKey));
    final keypad = Theme.of(context).extension<KeypadScreenStyles>()?.primary?.actionpadStyle?.primary?.style;
    final button = tester.widget<TextButton>(find.byKey(callLogWatchCallKey));
    final fill = button.style?.backgroundColor?.resolve({});
    expect(fill, isNotNull);
    expect(fill!.a, 1);
    expect(fill, keypad?.backgroundColor?.resolve({}));
  });

  testWidgets('an outgoing call that never connected says Missed, as the phone row does, but is not red', (
    tester,
  ) async {
    watchPresets.first.apply(tester);
    final handle = tester.ensureSemantics();
    stateIs(CallLogState(number: '1001', contact: _contact, callLog: [_entry(1, answered: false)]));
    await pumpCollectingOverflows(tester, app());

    expect(find.bySemanticsLabel(RegExp(r'^Outgoing, Missed, ')), findsOneWidget);
    final text = tester.widget<Text>(find.text('Missed'));
    expect(text.style?.color, isNot(Theme.of(tester.element(find.text('Missed'))).colorScheme.error));
    handle.dispose();
  });

  testWidgets('the video call starts a video call', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(CallLogState(number: '1001', contact: _contact, callLog: calls));
    await pumpCollectingOverflows(tester, app());

    await tester.scrollUntilVisible(find.byKey(callLogWatchVideoCallKey), 40, scrollable: find.byType(Scrollable).last);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(callLogWatchVideoCallKey));
    await tester.pump();

    verify(
      () => callBloc.add(const CallControlEvent.started(number: '1001', displayName: 'Anna Marchenko', video: true)),
    ).called(1);
  });

  testWidgets('a number that is nobody\'s is the title once, and no video call when video is off', (tester) async {
    watchPresets.first.apply(tester);
    stateIs(CallLogState(number: '1001', callLog: calls));

    await pumpCollectingOverflows(tester, app(videoVisible: false));

    expect(find.text('1001'), findsOneWidget);
    expect(find.byKey(callLogWatchVideoCallKey), findsNothing);
  });
}
