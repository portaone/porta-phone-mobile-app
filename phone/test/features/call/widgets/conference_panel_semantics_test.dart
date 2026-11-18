import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../../helpers/helpers.dart';

/// The room's controls through assistive technology. Each of them acts on
/// somebody - the host, one participant, the whole room - and a glyph alone
/// does not say which, so every one carries a name that does.
ActiveCall _call(String callId, {int line = 0, String? displayName}) => ActiveCall(
  callId: callId,
  direction: CallDirection.incoming,
  line: line,
  handle: const CallkeepHandle.number('+380991234567'),
  createdTime: DateTime(2024),
  video: false,
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime(2024),
  displayName: displayName,
);

void main() {
  late List<String> acted;
  late List<String> switched;

  setUp(() {
    acted = [];
    switched = [];
  });

  Widget subject({bool borisMuted = false, bool ready = true, bool parked = false}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ConferencePanel(
        conference: ConferenceState(
          room: 7,
          phase: ConferencePhase.active,
          legs: const {'a': 0, 'b': 1},
          participants: ready
              ? [
                  const ConferenceParticipant(line: 0, callId: 'a'),
                  ConferenceParticipant(line: 1, callId: 'b', muted: borisMuted),
                ]
              : const [],
        ),
        calls: [
          _call('a', displayName: 'Anna Marchenko'),
          _call('b', line: 1, displayName: 'Boris Klein'),
        ],
        roomParked: parked,
        onSwitchToConference: switched.add,
        onParticipantMutedChanged: (callId, muted) => acted.add('mute:$callId:$muted'),
        onParticipantHangup: (callId) => acted.add('hangup:$callId'),
      ),
    ),
  );

  group('ConferencePanel - what a screen reader gets', () {
    testWidgets('every control is one named button, and says who it acts on', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject());

      // Named, because there is one of these per row and they act on
      // different people.
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(conferenceParticipantMuteId),
        label: 'Mute Anna Marchenko for everyone',
        identifier: conferenceParticipantMuteId,
        isButton: true,
      );
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)),
        label: 'Mute Boris Klein for everyone',
        identifier: numberedId(conferenceParticipantMuteId, 1),
        isButton: true,
      );
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(conferenceParticipantMenuId),
        label: 'More for Anna Marchenko',
        identifier: conferenceParticipantMenuId,
        isButton: true,
      );
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1)),
        label: 'More for Boris Klein',
        identifier: numberedId(conferenceParticipantMenuId, 1),
        isButton: true,
      );

      // End, one tap further, is named for the person as well.
      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1)));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)),
        findsOneWidget,
        reason: 'the entry carries its own id',
      );
      expect(find.bySemanticsLabel(RegExp('End the call with Boris Klein')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('every control activates through semantics, not only by pointer', (tester) async {
      // A pointer tap passes while the semantics path is broken, which is
      // what docs/guides/accessibility.md asks these tests to catch.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject());

      await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)));
      await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1)));
      await tester.pumpAndSettle();
      await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
      await tester.pumpAndSettle();

      expect(acted, ['mute:b:true', 'hangup:b']);

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('a participant the server has not listed offers no mute to press', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject(ready: false));

      final mute = tester.getSemantics(find.bySemanticsIdentifier(conferenceParticipantMuteId));
      expect(
        mute.getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the server would answer line_not_ready',
      );

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('a muted microphone offers to unmute, not to mute again', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject(borisMuted: true));

      expect(
        tester
            .getSemantics(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)))
            .getSemanticsData()
            .label,
        'Unmute Boris Klein for everyone',
      );

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('no control of the room offers a press without saying what it is', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject());

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('a room standing aside keeps every control named, its note read once and in order', (tester) async {
      // The state the panel changes most when the host steps out: a note joins
      // the header and the participants' controls step back, dimmed but alive.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject(parked: true));

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      expect(find.bySemanticsIdentifier(conferenceParkedNoteId), findsOneWidget);
      expect(
        tester.getSemantics(find.bySemanticsIdentifier(conferenceParkedNoteId)).getSemanticsData().label,
        'You are on another call',
      );
      final header = tester.getTopLeft(find.textContaining('PARTICIPANTS')).dy;
      final note = tester.getTopLeft(find.bySemanticsIdentifier(conferenceParkedNoteId)).dy;
      final firstRow = tester.getTopLeft(find.text('Anna Marchenko')).dy;
      expect(header < note && note < firstRow, isTrue, reason: 'header, then the note, then the rows');

      await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1)));
      await tester.pumpAndSettle();
      await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
      await tester.pumpAndSettle();
      expect(acted, ['hangup:b'], reason: 'dimmed, not disabled');

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });
  });
}
