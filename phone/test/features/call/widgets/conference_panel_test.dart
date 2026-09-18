import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

ActiveCall _call(String callId, {int line = 0, String? displayName}) => ActiveCall(
  callId: callId,
  direction: CallDirection.incoming,
  line: line,
  handle: const CallkeepHandle.number('+380991234567'),
  createdTime: DateTime(2024),
  video: false,
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime.now().subtract(const Duration(seconds: 65)),
  displayName: displayName,
);

/// A room of two, both wired by the server unless [participants] says
/// otherwise.
ConferenceState _room({
  List<ConferenceParticipant> participants = const [
    ConferenceParticipant(line: 0, callId: 'a'),
    ConferenceParticipant(line: 1, callId: 'b'),
  ],
  bool selfMuted = false,
}) => ConferenceState(
  room: 7,
  phase: ConferencePhase.active,
  legs: const {'a': 0, 'b': 1},
  participants: participants,
  selfMuted: selfMuted,
);

Widget _maybeScroll(bool scrollable, Widget child) => scrollable ? SingleChildScrollView(child: child) : child;

void main() {
  late List<bool> selfMutes;
  late List<({String callId, bool muted})> participantMutes;
  late List<String> hangups;

  setUp(() {
    selfMutes = [];
    participantMutes = [];
    hangups = [];
  });

  Widget subject({ConferenceState? conference, List<ActiveCall>? calls, bool scrollable = false}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      // The screen gives the block a scrollable slot of its own, so only the
      // row's own width is in question here.
      body: _maybeScroll(
        scrollable,
        ConferencePanel(
          conference: conference ?? _room(),
          calls: calls ?? [_call('a', displayName: 'Anna Marchenko'), _call('b', line: 1, displayName: 'Boris Klein')],
          onSelfMutedChanged: selfMutes.add,
          onParticipantMutedChanged: (callId, muted) => participantMutes.add((callId: callId, muted: muted)),
          onParticipantHangup: hangups.add,
        ),
      ),
    ),
  );

  group('ConferencePanel', () {
    testWidgets('lists the host and every leg, by line', (tester) async {
      await tester.pumpWidget(subject());
      final context = tester.element(find.byType(ConferencePanel));

      expect(find.text(context.l10n.call_ConferencePanel_you), findsOneWidget);
      expect(find.text('Anna Marchenko'), findsOneWidget);
      expect(find.text('Boris Klein'), findsOneWidget);
      expect(find.text(context.l10n.call_ConferencePanel_header(2).toUpperCase()), findsOneWidget);

      // Ordered by line, whatever order the legs were recorded in.
      final names = tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).toList();
      expect(names.indexOf('Anna Marchenko'), lessThan(names.indexOf('Boris Klein')));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('every row leads with a picture, the host included', (tester) async {
      // The panel and the roster are the same kind of list, so a leg says who
      // it is with the same way a call outside the room does. The host has no
      // contact of their own, and a row without a picture would start its
      // name at a different place down the list.
      await tester.pumpWidget(subject());

      expect(find.byType(CallRowAvatar), findsNWidgets(2), reason: 'one per leg');
      expect(find.byType(CallRowSelfAvatar), findsOneWidget, reason: 'and one standing for the host');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a leg falls back to its number, and to its id before the call is known', (tester) async {
      await tester.pumpWidget(subject(calls: [_call('a')]));

      expect(find.text('+380991234567'), findsOneWidget);
      expect(find.text('b'), findsOneWidget, reason: 'the call is gone but the server still lists the leg');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('the host mic reports the opposite of what the room says', (tester) async {
      await tester.pumpWidget(subject());
      await tester.tap(find.bySemanticsIdentifier(conferenceSelfMuteId));
      expect(selfMutes, [true]);

      await tester.pumpWidget(subject(conference: _room(selfMuted: true)));
      await tester.tap(find.bySemanticsIdentifier(conferenceSelfMuteId));
      expect(selfMutes, [true, false]);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a participant is muted for everyone, and said to be', (tester) async {
      await tester.pumpWidget(
        subject(
          conference: _room(
            participants: const [
              ConferenceParticipant(line: 0, callId: 'a'),
              ConferenceParticipant(line: 1, callId: 'b', muted: true),
            ],
          ),
        ),
      );
      final context = tester.element(find.byType(ConferencePanel));

      // The status line carries the duration beside it now.
      expect(find.textContaining(context.l10n.call_ConferencePanel_participantMuted), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 0)));
      expect(participantMutes, [(callId: 'a', muted: true)]);

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)));
      expect(participantMutes.last, (callId: 'b', muted: false), reason: 'a muted one is unmuted');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a leg the server has not listed cannot be muted yet', (tester) async {
      // Core answers line_not_ready until the participant appears in a list,
      // so the control waits rather than asking and failing.
      await tester.pumpWidget(
        subject(
          conference: _room(participants: const [ConferenceParticipant(line: 0, callId: 'a')]),
        ),
      );

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)));
      expect(participantMutes, isEmpty);

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 0)));
      expect(participantMutes, hasLength(1), reason: 'the listed one is ready');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a participant is dropped by ending their call', (tester) async {
      await tester.pumpWidget(subject());

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
      expect(hangups, ['b']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a long call does not push the controls off a narrow row', (tester) async {
      // Past an hour the duration grows to HH:MM:SS; beside two tap targets
      // on a small screen at a large text scale there was nowhere to put it.
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: subject(
            scrollable: true,
            calls: [
              _call(
                'a',
                displayName: 'Oleksandr Marchenko',
              ).copyWith(acceptedTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 5))),
              _call('b', line: 1, displayName: 'Kateryna Bondarenko'),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
