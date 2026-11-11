import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/semantics.dart';
import 'fake_call_queues_repository.dart';

void main() {
  late FakeCallQueuesRepository repository;

  setUp(() => repository = FakeCallQueuesRepository());
  tearDown(() => repository.dispose());

  Future<void> pumpScreen(WidgetTester tester, CallQueuesSnapshot snapshot, Widget screen) async {
    // The one setUp made is replaced, so it is closed here rather than left
    // open behind the test.
    await repository.dispose();
    repository = FakeCallQueuesRepository(initial: snapshot);
    await tester.pumpWidget(
      ThemeProvider(
        settings: const ThemeSettings(),
        lightDynamic: null,
        darkDynamic: null,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider(create: (context) => CallQueuesCubit(repository), child: screen),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> pumpBody(WidgetTester tester, CallQueuesSnapshot snapshot) =>
      pumpScreen(tester, snapshot, const Scaffold(body: CallCenterWatchBody(title: 'My queues')));

  final queues = CallQueuesSnapshot(
    known: true,
    queues: [
      testQueue('0111', name: 'Sales', callersWaiting: 3),
      testQueue('0222', name: 'Support', loggedIn: false, callersWaiting: null),
    ],
  );

  for (final preset in watchPresets) {
    testWidgets('on $preset All queues and a pill per queue, saying online and how many wait', (tester) async {
      preset.apply(tester);
      await pumpBody(tester, queues);
      expect(tester.takeException(), isNull);

      expect(find.text('My queues'), findsOneWidget);
      expect(find.text('All queues'), findsOneWidget);
      expect(find.text('Taking calls from 1 of 2 queues'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Support'), 40, scrollable: find.byType(Scrollable).last);
      expect(find.textContaining('Offline'), findsOneWidget);
    });
  }

  testWidgets('a queue\'s line is read with a pause, not the dot drawn in it', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await pumpBody(tester, queues);
    await tester.scrollUntilVisible(find.text('Support'), 40, scrollable: find.byType(Scrollable).last);

    expect(find.bySemanticsLabel(RegExp(r'Offline, ')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('\u00B7')), findsNothing);
    handle.dispose();
  });

  testWidgets('a queue pill logs in or out of it; mixed All queues reads off and logs into all', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await pumpBody(tester, queues);

    final all = tester.widget<WatchToggleChip>(find.widgetWithText(WatchToggleChip, 'All queues'));
    expect(all.value, isFalse);
    // The phone's keys are on the watch's pills too, so a finder by key works on both.
    expect(find.byKey(callCenterMasterSwitchKey), findsOneWidget);
    expect(find.byKey(callCenterQueueSwitchKey('0111')), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(callCenterMasterSwitchId));
    await tester.pump();
    expect(repository.writes, ['all:true']);

    await tester.scrollUntilVisible(find.text('Sales'), 40, scrollable: find.byType(Scrollable).last);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(callCenterQueueSwitchId('0111')));
    await tester.pump();
    expect(repository.writes.last, '0111:false');
    handle.dispose();
  });

  testWidgets('the settings screen draws no app bar, the queues under its name', (tester) async {
    watchPresets.first.apply(tester);
    await pumpScreen(tester, queues, const CallCenterScreen());

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('My queues'), findsOneWidget);
    expect(find.byType(WatchToggleChip), findsWidgets);
  });

  testWidgets('the bottom-menu section is headed by its own name', (tester) async {
    watchPresets.first.apply(tester);
    await pumpScreen(tester, queues, const CallCenterTabScreen(watchTitle: 'Agents'));

    expect(find.byType(AppBar), findsNothing);
    expect(find.text('Agents'), findsOneWidget);
    expect(find.byType(WatchToggleChip), findsWidgets);
  });

  testWidgets('a queue whose change is on its way offers nothing', (tester) async {
    watchPresets.last.apply(tester);
    await pumpBody(
      tester,
      CallQueuesSnapshot(
        known: true,
        queues: [testQueue('0111', name: 'Sales')],
        pendingIds: const {'0111'},
      ),
    );

    expect(tester.widget<WatchToggleChip>(find.widgetWithText(WatchToggleChip, 'Sales')).onChanged, isNull);
    expect(tester.widget<WatchToggleChip>(find.widgetWithText(WatchToggleChip, 'All queues')).onChanged, isNull);
  });

  testWidgets('on its way a loading page', (tester) async {
    watchPresets.first.apply(tester);
    await pumpBody(tester, const CallQueuesSnapshot(known: false));
    expect(find.byType(WatchSpinner), findsOneWidget);
  });

  testWidgets('failed: the reason and Try again on the edge', (tester) async {
    watchPresets.first.apply(tester);
    await pumpBody(tester, const CallQueuesSnapshot(known: false, readFailed: true));
    expect(find.text('Could not load your queues.'), findsOneWidget);
    expect(find.byType(WatchEdgeButton), findsOneWidget);
  });

  testWidgets('no queues is a state page', (tester) async {
    watchPresets.first.apply(tester);
    await pumpBody(tester, const CallQueuesSnapshot(known: true, queues: []));
    expect(find.text('You are not an agent of any call queue.'), findsOneWidget);
  });
}
