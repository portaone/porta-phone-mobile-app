import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/styles/styles.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

void main() {
  const registeredColor = Color(0xFF00AA00);
  const unregisteredColor = Color(0xFF888888);
  const availableColor = Color(0xFF11AA11);
  const unavailableColor = Color(0xFF999999);
  const busyColor = Color(0xFFCC2222);
  const diameter = 40.0;

  /// The share of the avatar a presence mark takes, as the app sets it in
  /// `LeadingAvatarStyle`. Named rather than spelled out at each expectation:
  /// the four copies of it went stale together the last time it changed.
  const markFactor = 0.4;

  Widget wrap(Widget badge, {required bool hybridPresenceSupport}) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        extensions: [
          RegisteredStatusStyles(
            primary: RegisteredStatusStyle(registered: registeredColor, unregistered: unregisteredColor),
          ),
          const LeadingAvatarStyles(
            primary: LeadingAvatarStyle(
              presenceBadge: PresenceBadgeStyle(
                availableColor: availableColor,
                unavailableColor: unavailableColor,
                busyColor: busyColor,
              ),
            ),
          ),
        ],
      ),
      home: Scaffold(
        body: PresenceViewParams(
          hybridPresenceSupport: hybridPresenceSupport,
          blfViaSipSupport: false,
          presenceViaSipSupport: false,
          child: Center(
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Stack(children: [Positioned.fill(child: badge)]),
            ),
          ),
        ),
      ),
    );
  }

  PresenceInfo presence({
    required bool available,
    List<PresenceActivity> activities = const [],
    PresenceInfoSource source = PresenceInfoSource.sip,
  }) {
    return PresenceInfo(
      id: 'id',
      number: 'number',
      available: available,
      note: '',
      statusIcon: null,
      device: null,
      timeOffsetMin: null,
      timestamp: null,
      activities: activities,
      source: source,
      arrivalTime: DateTime(2026),
    );
  }

  DialogInfo dialog(DialogState state) => DialogInfo(
    id: 'dlg-${state.name}',
    entityNumber: 'number',
    state: state,
    callId: 'call',
    direction: DialogDirection.recipient,
    localTag: 'lt',
    localNumber: 'number',
    localDisplayName: null,
    remoteTag: 'rt',
    remoteNumber: 'other',
    remoteDisplayName: null,
    arrivalVersion: '1',
    arrivalTime: DateTime(2026),
  );

  Color? markColor(WidgetTester tester) {
    final container = tester.widget<Container>(
      find.descendant(of: find.byType(SipPresenceIndicator), matching: find.byType(Container)),
    );
    return (container.decoration! as BoxDecoration).color;
  }

  Container dotOf(WidgetTester tester) {
    return tester.widget<Container>(
      find.descendant(of: find.byType(AvatarStatusBadge), matching: find.byType(Container)),
    );
  }

  group('AvatarStatusBadge without hybrid presence', () {
    testWidgets('draws the registration dot at the presence-mark size, ringed', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(registered: true), hybridPresenceSupport: false));

      final dot = dotOf(tester);
      final decoration = dot.decoration! as BoxDecoration;
      expect(decoration.color, registeredColor);
      expect(tester.getSize(find.byWidget(dot)), const Size(diameter * markFactor, diameter * markFactor));
      // The ring is what lets the dot straddle the avatar edge: without it,
      // the half hanging over the row background reads as a partial dot.
      expect(decoration.border!.top.width, diameter * markFactor * 0.1);
      expect(find.byType(SipPresenceIndicator), findsNothing);
    });

    testWidgets('sits the registration dot on the avatar edge', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(registered: true), hybridPresenceSupport: false));

      final dot = tester.getRect(find.byWidget(dotOf(tester)));
      final avatar = tester.getRect(find.byType(AvatarStatusBadge));

      expect((dot.center - avatar.center).distance, closeTo(avatar.width / 2, 0.01));
      expect(dot.right, greaterThan(avatar.right));
    });

    testWidgets('colors the dot by registration state', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(registered: false), hybridPresenceSupport: false));

      expect((dotOf(tester).decoration! as BoxDecoration).color, unregisteredColor);
    });

    testWidgets('shows nothing without registration data', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(), hybridPresenceSupport: false));

      expect(find.descendant(of: find.byType(AvatarStatusBadge), matching: find.byType(Container)), findsNothing);
      expect(find.byType(SipPresenceIndicator), findsNothing);
    });
  });

  group('AvatarStatusBadge.maybe', () {
    test('is null when there is no status data', () {
      expect(AvatarStatusBadge.maybe(), isNull);
    });

    test('is a badge when any input is present', () {
      expect(AvatarStatusBadge.maybe(registered: false), isA<AvatarStatusBadge>());
      expect(AvatarStatusBadge.maybe(presenceInfo: const []), isA<AvatarStatusBadge>());
      expect(AvatarStatusBadge.maybe(dialogInfo: const []), isA<AvatarStatusBadge>());
    });
  });

  group('AvatarStatusBadge with hybrid presence', () {
    testWidgets('shows the presence indicator at the hybrid size', (tester) async {
      await tester.pumpWidget(
        wrap(AvatarStatusBadge(presenceInfo: [presence(available: true)]), hybridPresenceSupport: true),
      );

      expect(find.byType(SipPresenceIndicator), findsOneWidget);
      expect(
        tester.getSize(find.byType(SipPresenceIndicator)),
        const Size(diameter * markFactor, diameter * markFactor),
      );
    });

    testWidgets('sits the mark on the avatar edge with the glyph inside it', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.busy]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      final avatar = tester.getRect(find.byType(AvatarStatusBadge));
      final dot = tester.getRect(find.byType(SipPresenceIndicator));
      final icon = tester.getRect(find.descendant(of: find.byType(SipPresenceIndicator), matching: find.byType(Icon)));

      // The mark's centre sits ON the avatar's edge, so half of it hangs
      // outside the silhouette instead of covering the face; the glyph lives
      // inside the mark, because an icon laid over it would cut into the
      // outline and make the mark read smaller than it is.
      final avatarCentre = avatar.center;
      final radius = avatar.width / 2;
      final reach = (dot.center - avatarCentre).distance;
      expect(reach, closeTo(radius, 0.01));
      expect(dot.width, avatar.width * markFactor);
      expect(dot.right, greaterThan(avatar.right));
      expect(icon.left, greaterThanOrEqualTo(dot.left));
      expect(icon.top, greaterThanOrEqualTo(dot.top));
      expect(icon.right, lessThanOrEqualTo(dot.right));
      expect(icon.bottom, lessThanOrEqualTo(dot.bottom));
    });
  });

  group('with hybrid presence the sources answer in order: direct, SIP, registration', () {
    testWidgets('a registered contact nobody publishes for is drawn as available', (tester) async {
      // A desk phone registers and takes calls without ever publishing a
      // status. Nothing published must not read as "cannot be reached".
      await tester.pumpWidget(
        wrap(const AvatarStatusBadge(registered: true, presenceInfo: []), hybridPresenceSupport: true),
      );

      expect(markColor(tester), availableColor);
      expect(
        tester.getSize(find.byType(SipPresenceIndicator)),
        const Size(diameter * markFactor, diameter * markFactor),
      );
      // Named for what is known - the phone is registered - not for the
      // conclusion the colour draws from it.
      expect(find.bySemanticsLabel('Registered'), findsOneWidget);
      expect(find.bySemanticsLabel('Available'), findsNothing);
    });

    testWidgets('an unregistered contact nobody publishes for is drawn as unavailable', (tester) async {
      await tester.pumpWidget(
        wrap(const AvatarStatusBadge(registered: false, presenceInfo: []), hybridPresenceSupport: true),
      );

      expect(markColor(tester), unavailableColor);
      expect(find.bySemanticsLabel('Not registered'), findsOneWidget);
      expect(find.bySemanticsLabel('Unavailable'), findsNothing);
    });

    testWidgets('registration answers for an avatar that is given no presence at all', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(registered: true), hybridPresenceSupport: true));

      expect(markColor(tester), availableColor);
      expect(find.bySemanticsLabel('Registered'), findsOneWidget);
      expect(find.descendant(of: find.byType(SipPresenceIndicator), matching: find.byType(Icon)), findsNothing);
    });

    testWidgets('an avatar built from a contact asks all three sources, not the registration alone', (tester) async {
      // A picker or a call log that passed only the registration showed a
      // registered phone as reachable while its owner had published do not
      // disturb, contradicting the contact list beside it.
      final contact = Contact(
        id: 1,
        sourceType: ContactSourceType.external,
        kind: ContactKind.visible,
        registered: true,
        presenceInfo: [
          presence(available: false, activities: const [PresenceActivity.doNotDisturb]),
        ],
      );

      await tester.pumpWidget(wrap(AvatarStatusBadge.ofContact(contact)!, hybridPresenceSupport: true));

      expect(markColor(tester), busyColor);
      expect(find.bySemanticsLabel('Do not disturb'), findsOneWidget);
      expect(find.bySemanticsLabel('Registered'), findsNothing);
    });

    test('no contact, no badge', () {
      expect(AvatarStatusBadge.ofContact(null), isNull);
    });

    test('a contact nothing is known about gets no badge at all', () {
      // No registration, no presence, no calls: nothing for a badge to say.
      final contact = Contact(id: 1, sourceType: ContactSourceType.local, kind: ContactKind.visible);

      expect(AvatarStatusBadge.ofContact(contact), isNull);
    });

    test('a phone that is only ringing is not something known about its owner', () {
      // The badge draws nothing for a call that is not established, so a
      // badge mounted for it would be an empty one.
      final contact = Contact(
        id: 1,
        sourceType: ContactSourceType.external,
        kind: ContactKind.visible,
        dialogInfo: [dialog(DialogState.early)],
      );

      expect(AvatarStatusBadge.ofContact(contact), isNull);
    });

    testWidgets('nothing known, nothing drawn', (tester) async {
      // No status, no call, no registration data: a mark here would paint
      // every such contact as offline, which nobody has said.
      await tester.pumpWidget(wrap(const AvatarStatusBadge(presenceInfo: []), hybridPresenceSupport: true));

      expect(find.byType(SipPresenceIndicator), findsNothing);
      expect(find.descendant(of: find.byType(AvatarStatusBadge), matching: find.byType(Container)), findsNothing);
      expect(find.bySemanticsLabel('Unavailable'), findsNothing);
    });

    testWidgets('a status the device published is not overruled by its registration', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(registered: true, presenceInfo: [presence(available: false)]),
          hybridPresenceSupport: true,
        ),
      );

      expect(markColor(tester), unavailableColor);
    });

    testWidgets('the direct record outranks a SIP record that says otherwise', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            registered: true,
            presenceInfo: [
              presence(available: true),
              presence(available: false, source: PresenceInfoSource.direct),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(markColor(tester), unavailableColor);
      expect(find.bySemanticsLabel('Unavailable'), findsOneWidget);
    });

    testWidgets('an established call is drawn for a contact nothing else is known about', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(presenceInfo: const [], dialogInfo: [dialog(DialogState.confirmed)]),
          hybridPresenceSupport: true,
        ),
      );

      expect(
        find.descendant(of: find.byType(SipPresenceIndicator), matching: find.byIcon(Icons.phone_in_talk_rounded)),
        findsOneWidget,
      );
    });
  });

  group('the mark shows how much is known', () {
    Finder inMark(Finder what) => find.descendant(of: find.byType(SipPresenceIndicator), matching: what);

    testWidgets('a published available carries a tick', (tester) async {
      await tester.pumpWidget(
        wrap(AvatarStatusBadge(presenceInfo: [presence(available: true)]), hybridPresenceSupport: true),
      );

      expect(inMark(find.byIcon(Icons.check_rounded)), findsOneWidget);
    });

    testWidgets('a published unavailable carries a cross', (tester) async {
      await tester.pumpWidget(
        wrap(AvatarStatusBadge(presenceInfo: [presence(available: false)]), hybridPresenceSupport: true),
      );

      expect(inMark(find.byIcon(Icons.close_rounded)), findsOneWidget);
    });

    testWidgets('a published activity keeps its own glyph instead', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.vacation]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(inMark(find.byType(Icon)), findsOneWidget);
      expect(inMark(find.byIcon(Icons.check_rounded)), findsNothing);
    });

    testWidgets('a registered phone is the colour alone', (tester) async {
      // Less is known, so less is drawn: nobody said "available", the
      // contact list said "registered".
      await tester.pumpWidget(
        wrap(const AvatarStatusBadge(registered: true, presenceInfo: []), hybridPresenceSupport: true),
      );

      expect(markColor(tester), availableColor);
      expect(inMark(find.byType(Icon)), findsNothing);
      expect(tester.widget<Container>(inMark(find.byType(Container))).child, isNull);
    });

    testWidgets('a phone that is not registered is the other colour alone, with nothing inside', (tester) async {
      await tester.pumpWidget(
        wrap(const AvatarStatusBadge(registered: false, presenceInfo: []), hybridPresenceSupport: true),
      );

      expect(markColor(tester), unavailableColor);
      expect(inMark(find.byType(Icon)), findsNothing);
      // A solid disc: nothing is cut out of it or laid over it.
      expect(tester.widget<Container>(inMark(find.byType(Container))).child, isNull);
    });

    testWidgets('a call seen on a phone that is not registered is still drawn as a call', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(registered: false, presenceInfo: const [], dialogInfo: [dialog(DialogState.confirmed)]),
          hybridPresenceSupport: true,
        ),
      );

      expect(inMark(find.byIcon(Icons.phone_in_talk_rounded)), findsOneWidget);
    });
  });

  group('the mark colours whether the contact can be called now', () {
    testWidgets('do not disturb paints it busy', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.doNotDisturb]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(markColor(tester), busyColor);
    });

    testWidgets('a published busy paints it busy as well', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.busy]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(markColor(tester), busyColor);
    });

    testWidgets('an activity that is merely elsewhere stays available', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.vacation]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(markColor(tester), availableColor);
    });

    testWidgets('a reported call leaves the colour alone, established or ringing', (tester) async {
      for (final state in [DialogState.confirmed, DialogState.early]) {
        await tester.pumpWidget(
          wrap(
            AvatarStatusBadge(presenceInfo: [presence(available: true)], dialogInfo: [dialog(state)]),
            hybridPresenceSupport: true,
          ),
        );

        expect(markColor(tester), availableColor, reason: 'dialog state ${state.name}');
      }
    });

    testWidgets('a contact publishing on-the-phone keeps the reachable colour', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.onThePhone]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(markColor(tester), availableColor);
    });

    testWidgets('an unreachable contact stays unavailable', (tester) async {
      await tester.pumpWidget(
        wrap(AvatarStatusBadge(presenceInfo: [presence(available: false)]), hybridPresenceSupport: true),
      );

      expect(markColor(tester), unavailableColor);
    });

    testWidgets('do not disturb outranks being unreachable', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: false, activities: const [PresenceActivity.doNotDisturb]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(markColor(tester), busyColor);
    });
  });

  group('the mark says its state out loud', () {
    testWidgets('an established call is announced as a call', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(presenceInfo: [presence(available: true)], dialogInfo: [dialog(DialogState.confirmed)]),
          hybridPresenceSupport: true,
        ),
      );

      expect(find.bySemanticsLabel('On a call'), findsOneWidget);
    });

    testWidgets('a phone that is only ringing is not announced as a call', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(presenceInfo: [presence(available: true)], dialogInfo: [dialog(DialogState.early)]),
          hybridPresenceSupport: true,
        ),
      );

      expect(find.bySemanticsLabel('On a call'), findsNothing);
      expect(find.bySemanticsLabel('Available'), findsOneWidget);
    });

    testWidgets('a published activity is announced instead of the plain state', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.vacation]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(find.bySemanticsLabel('On vacation'), findsOneWidget);
    });

    testWidgets('do not disturb is announced even though it only changes the colour', (tester) async {
      await tester.pumpWidget(
        wrap(
          AvatarStatusBadge(
            presenceInfo: [
              presence(available: true, activities: const [PresenceActivity.doNotDisturb]),
            ],
          ),
          hybridPresenceSupport: true,
        ),
      );

      expect(find.bySemanticsLabel('Do not disturb'), findsOneWidget);
      expect(find.bySemanticsLabel('Available'), findsNothing);
    });

    testWidgets('a plain contact is announced as available or not', (tester) async {
      await tester.pumpWidget(
        wrap(AvatarStatusBadge(presenceInfo: [presence(available: true)]), hybridPresenceSupport: true),
      );
      expect(find.bySemanticsLabel('Available'), findsOneWidget);

      await tester.pumpWidget(
        wrap(AvatarStatusBadge(presenceInfo: [presence(available: false)]), hybridPresenceSupport: true),
      );
      expect(find.bySemanticsLabel('Unavailable'), findsOneWidget);
    });
  });

  group('the legacy registration dot says its state out loud', () {
    testWidgets('a registered contact is announced as registered', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(registered: true), hybridPresenceSupport: false));

      expect(find.bySemanticsLabel('Registered'), findsOneWidget);
    });

    testWidgets('an unregistered contact is announced as not registered', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(registered: false), hybridPresenceSupport: false));

      expect(find.bySemanticsLabel('Not registered'), findsOneWidget);
    });

    testWidgets('nothing is announced when there is no registration data', (tester) async {
      await tester.pumpWidget(wrap(const AvatarStatusBadge(), hybridPresenceSupport: false));

      expect(find.bySemanticsLabel('Registered'), findsNothing);
      expect(find.bySemanticsLabel('Not registered'), findsNothing);
    });
  });
}
