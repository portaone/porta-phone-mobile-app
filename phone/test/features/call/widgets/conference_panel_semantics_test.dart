import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
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

  setUp(() => acted = []);

  Widget subject({bool selfMuted = false, bool ready = true}) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ConferencePanel(
        conference: ConferenceState(
          room: 7,
          phase: ConferencePhase.active,
          legs: const {'a': 0, 'b': 1},
          participants: ready
              ? const [ConferenceParticipant(line: 0, callId: 'a'), ConferenceParticipant(line: 1, callId: 'b')]
              : const [],
          selfMuted: selfMuted,
        ),
        calls: [
          _call('a', displayName: 'Anna Marchenko'),
          _call('b', line: 1, displayName: 'Boris Klein'),
        ],
        onSelfMutedChanged: (muted) => acted.add('self:$muted'),
        onParticipantMutedChanged: (callId, muted) => acted.add('mute:$callId:$muted'),
        onParticipantHangup: (callId) => acted.add('hangup:$callId'),
        onEndPressed: () => acted.add('end'),
      ),
    ),
  );

  group('ConferencePanel - what a screen reader gets', () {
    testWidgets('every control is one named button, and says who it acts on', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject());

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(conferenceSelfMuteId),
        label: 'Mute your microphone',
        identifier: conferenceSelfMuteId,
        isButton: true,
      );
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
        find.bySemanticsIdentifier(conferenceParticipantHangupId),
        label: 'End the call with Anna Marchenko',
        identifier: conferenceParticipantHangupId,
        isButton: true,
      );
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)),
        label: 'End the call with Boris Klein',
        identifier: numberedId(conferenceParticipantHangupId, 1),
        isButton: true,
      );
      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(conferenceEndId),
        label: 'End the conference and every call in it',
        identifier: conferenceEndId,
        isButton: true,
      );

      await tester.pumpWidget(const SizedBox());
      semantics.dispose();
    });

    testWidgets('every control activates through semantics, not only by pointer', (tester) async {
      // A pointer tap passes while the semantics path is broken, which is
      // what docs/accessibility.md asks these tests to catch.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(subject());

      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceSelfMuteId));
      await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)));
      await tapViaSemantics(tester, find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
      await tapViaSemantics(tester, find.bySemanticsIdentifier(conferenceEndId));

      expect(acted, ['self:true', 'mute:b:true', 'hangup:b', 'end']);

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
      await tester.pumpWidget(subject(selfMuted: true));

      expect(
        tester.getSemantics(find.bySemanticsIdentifier(conferenceSelfMuteId)).getSemanticsData().label,
        'Unmute your microphone',
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
  });
}
