import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/main/main.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/screen_presets.dart';
import '../../helpers/stack_router.dart';

void main() {
  const tabs = <BottomMenuTab>[
    KeypadBottomMenuTab(
      enabled: true,
      initial: true,
      titleL10n: 'main_BottomNavigationBarItemLabel_keypad',
      icon: Icons.dialpad,
    ),
    RecentsBottomMenuTab(
      supportsCallHistory: false,
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_recents',
      icon: Icons.history,
    ),
    FavoritesBottomMenuTab(
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_favorites',
      icon: Icons.star,
    ),
    MessagingBottomMenuTab(
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_chats',
      icon: Icons.chat,
    ),
    VoicemailBottomMenuTab(
      enabled: true,
      initial: false,
      titleL10n: 'main_BottomNavigationBarItemLabel_voicemail',
      icon: Icons.voicemail,
    ),
  ];

  int? selected;
  late _MockSessionStatusCubit sessionStatus;

  setUp(() {
    sessionStatus = _MockSessionStatusCubit();
    when(() => sessionStatus.state).thenReturn(const SessionStatusState());
  });

  Widget shell({
    Widget? body,
    int? currentIndex,
    bool wired = true,
    DestinationPickPurpose? pickPurpose,
    VoidCallback? onCancelPick,
  }) {
    selected = null;
    // The counts the bar shows travel with the decorator; the hub shows them
    // the same way.
    Widget decorate(BottomMenuTab tab, Widget icon) =>
        tab is MessagingBottomMenuTab ? Badge(label: const Text('3'), child: icon) : icon;

    return MaterialApp(
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: BlocProvider<SessionStatusCubit>.value(
        value: sessionStatus,
        child: withRootStackRouter(
          Builder(
            builder: (context) => MainScreen(
              body:
                  body ??
                  MainHub(
                    tabs: tabs,
                    decorateTabIcon: decorate,
                    pick: MainScreenPick.of(context, pickPurpose, onCancelPick),
                    onChosen: wired ? (index) => selected = index : null,
                  ),
              tabs: tabs,
              currentIndex: currentIndex,
              onTabSelected: wired ? (index) => selected = index : null,
              decorateTabIcon: decorate,
              pickPurpose: pickPurpose,
              onCancelPick: onCancelPick,
            ),
          ),
        ),
      ),
    );
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset the hub fits: every section, its count, and settings, with no tab bar', (tester) async {
      final handle = tester.ensureSemantics();
      preset.apply(tester);

      expect(await pumpCollectingOverflows(tester, shell()), isEmpty);
      expect(find.byType(BottomNavigationBar), findsNothing);
      for (final tab in tabs) {
        expect(find.bySemanticsIdentifier(tab.navBarId), findsOneWidget, reason: tab.titleL10n);
      }
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsIdentifier(mainAppBarId), findsOneWidget);
      expect(find.bySemanticsIdentifier(mainAppBarConnectionStatusConnectingId), findsOneWidget);

      handle.dispose();
    });
  }

  testWidgets('choosing a section hands it on', (tester) async {
    watchPresets.first.apply(tester);
    await pumpCollectingOverflows(tester, shell());

    await tester.tap(find.byKey(tabs[3].navBarKey));
    await tester.pump();

    expect(selected, 3);
  });

  for (final preset in watchPresets) {
    testWidgets('on $preset a choice that starts on the hub is said there, within the face, with its way out', (
      tester,
    ) async {
      preset.apply(tester);
      var cancelled = 0;
      expect(
        await pumpCollectingOverflows(tester, shell(pickPurpose: _Purpose(), onCancelPick: () => cancelled++)),
        isEmpty,
      );

      // The grid lays an invisible copy of its header out below, for its own
      // centring; the one in view is the first.
      final banner = tester.getRect(find.text('Pick somebody').first);
      final face = Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio;
      expect(face.contains(banner.topLeft) && face.contains(banner.bottomRight), isTrue);
      await tester.tap(find.byIcon(Icons.close));
      expect(cancelled, 1);
    });
  }

  testWidgets('without a handler the hub is inert, as the bar is', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.first.apply(tester);
    await pumpCollectingOverflows(tester, shell(wired: false));

    expect(
      tester.getSemantics(find.bySemanticsIdentifier(tabs.first.navBarId)),
      isSemantics(identifier: tabs.first.navBarId, hasTapAction: false),
    );
    handle.dispose();
  });

  testWidgets('a phone keeps its tab bar', (tester) async {
    handsetPresets.first.apply(tester);
    await pumpCollectingOverflows(tester, shell());

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}

class _MockSessionStatusCubit extends MockCubit<SessionStatusState> implements SessionStatusCubit {}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  var _taps = 0;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () => setState(() => _taps++), child: Text('taps $_taps'));
}

class _Purpose implements DestinationPickPurpose {
  @override
  String get announcement => 'Pick somebody';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => true;

  @override
  bool get closedByChoice => true;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get cancellable => true;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Transfer to ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) {}
}
