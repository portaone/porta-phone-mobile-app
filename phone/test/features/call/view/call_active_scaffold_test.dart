import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call/view/call_active_scaffold.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/keypad_key_button.dart';

import '../../../helpers/semantics.dart';
import 'call_active_scaffold_harness.dart';

void main() {
  late MockCallBloc callBloc;

  setUp(() {
    callBloc = newCallBloc();
    // This suite pins the PORTRAIT arrangement; landscape lives next door in
    // call_active_scaffold_landscape_test.dart.
    pinPortraitSurface();
  });

  final ringing = makeCall(
    callId: 'ringing',
    processingStatus: CallProcessingStatus.incomingFromOffer,
    displayName: 'Anna Marchenko',
  );
  final active = makeCall(callId: 'active', acceptedTime: DateTime(2024), displayName: 'Boris Klein');

  group('CallActiveScaffold - single call (list of 1)', () {
    testWidgets('1 incoming: Decline/Answer only, no list, no hint', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [ringing], focusedCall: ringing));

      expect(find.byType(IncomingCallActions), findsOneWidget);
      expect(find.byType(ActiveCallActions), findsNothing);
      expect(find.byType(CallList), findsNothing);
      expect(find.byType(FocusedActionHint), findsNothing);
      expect(find.byType(CallInfo), findsOneWidget);
      await teardownCallScaffold(tester);
    });

    testWidgets('1 active: control grid, no incoming actions, no list', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active));

      expect(find.byType(ActiveCallActions), findsOneWidget);
      expect(find.byType(IncomingCallActions), findsNothing);
      expect(find.byType(CallList), findsNothing);
      await teardownCallScaffold(tester);
    });

    testWidgets('1 on hold: control grid as well', (tester) async {
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held], focusedCall: held));

      expect(find.byType(ActiveCallActions), findsOneWidget);
      expect(find.byType(IncomingCallActions), findsNothing);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - active + incoming', () {
    testWidgets('ringing focus: list + hint with hold side effect + two buttons', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active, ringing], focusedCall: ringing));
      final context = tester.element(find.byType(CallActiveScaffold));

      expect(find.byType(CallList), findsOneWidget);
      expect(find.byType(CallRow), findsNWidgets(2));
      expect(find.byType(IncomingCallActions), findsOneWidget);
      expect(find.byType(ActiveCallActions), findsNothing);
      // With multiple calls the rows carry the info; no central block.
      expect(find.byType(CallInfo), findsNothing);

      // The hint names the focused call and the answered call to be held.
      expect(
        find.text(context.l10n.call_FocusedActionHint_actingOn('Anna Marchenko'), findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text(context.l10n.call_FocusedActionHint_willBeHeld('Boris Klein'), findRichText: true),
        findsOneWidget,
      );
      await teardownCallScaffold(tester);
    });

    testWidgets('answer dispatches the holding intent for the focused call', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active, ringing], focusedCall: ringing));

      await tester.tap(find.byIcon(Icons.call));
      verify(() => callBloc.add(const CallControlEvent.answeredHoldingOthers('ringing'))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('tapping the active row focuses it', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active, ringing], focusedCall: ringing));

      await tester.tap(find.byKey(const ValueKey('CallRow-active')));
      verify(() => callBloc.add(const CallControlEvent.callSelected('active'))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('active focus: control grid instead of incoming actions', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active, ringing], focusedCall: active));

      expect(find.byType(ActiveCallActions), findsOneWidget);
      expect(find.byType(IncomingCallActions), findsNothing);
      expect(find.byType(CallList), findsOneWidget);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - hold and resume on the focused call', () {
    testWidgets('Hold on an active focus holds just that call', (tester) async {
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held, active], focusedCall: active));

      await tester.tap(find.byIcon(Icons.pause));
      verify(() => callBloc.add(const CallControlEvent.setHeld('active', true))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('Resume on a held focus holds the live call and resumes the focused one', (tester) async {
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held, active], focusedCall: held));

      // The slot is a Resume affordance for a held focus - no swap button.
      expect(find.byIcon(Icons.swap_calls), findsNothing);
      await tester.tap(find.byIcon(Icons.play_arrow));
      verify(() => callBloc.add(const CallControlEvent.resumedHoldingOthers('held'))).called(1);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - merging the calls', () {
    final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
    const conferencing = CallCapabilitiesConfig(isConferenceEnabled: true);

    testWidgets('Merge asks for a conference of the calls that can join one', (tester) async {
      // The set is the bloc's to name at the moment of the press, not the
      // screen's to capture when the frame was built - and it is the calls
      // that can join a room, not every call on the screen.
      final ringing = makeCall(callId: 'ringing', processingStatus: CallProcessingStatus.incomingFromOffer);
      when(() => callBloc.state).thenReturn(CallState(activeCalls: [held, active, ringing]));
      await tester.pumpWidget(
        buildCallScaffold(
          callBloc,
          activeCalls: [held, active, ringing],
          focusedCall: active,
          callConfig: conferencing,
          canMerge: true,
        ),
      );

      await tester.tap(find.bySemanticsIdentifier(callMergeButtonId));
      verify(() => callBloc.add(const CallControlEvent.merged(['held', 'active']))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('the control is absent where the deployment offers no conferences', (tester) async {
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [held, active], focusedCall: active, canMerge: true),
      );

      expect(find.bySemanticsIdentifier(callMergeButtonId), findsNothing);
      await teardownCallScaffold(tester);
    });

    testWidgets('a single call offers nothing to merge', (tester) async {
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active, callConfig: conferencing),
      );

      expect(find.bySemanticsIdentifier(callMergeButtonId), findsNothing);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - the room in place of the focused leg', () {
    final legA = makeCall(callId: 'a', acceptedTime: DateTime(2024), displayName: 'Anna Marchenko');
    final legB = makeCall(callId: 'b', acceptedTime: DateTime(2024), displayName: 'Boris Klein');
    const room = ConferenceState(
      room: 7,
      phase: ConferencePhase.active,
      legs: {'a': 0, 'b': 1},
      participants: [
        ConferenceParticipant(line: 0, callId: 'a'),
        ConferenceParticipant(line: 1, callId: 'b'),
      ],
    );

    testWidgets('the microphone mutes the room, not the leg', (tester) async {
      // The microphone track is one for every call, the room's included, so
      // muting it as a leg's would silence the whole conference.
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [legA, legB], focusedCall: legA, conference: room),
      );

      // The panel carries a microphone per row, so the grid's own control is
      // addressed by its id rather than by its glyph. It sends the ordinary
      // mute of the focused call, which goes through the operating system and
      // comes back to the bloc, where a leg's mute becomes the room's.
      await tester.tap(find.byKey(const Key(callActionsMuteId)));
      verify(() => callBloc.add(const CallControlEvent.setMuted('a', true))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('a leg is not held or transferred on its own', (tester) async {
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [legA, legB], focusedCall: legA, conference: room),
      );

      // The server refuses a hold of a leg, and the plugin answers a hold of
      // a grouped call itself: the control is not offered in the first place.
      expect(tester.widget<CallActionButton>(find.byKey(const Key(callActionsHoldId))).onPressed, isNull);
      await teardownCallScaffold(tester);
    });

    testWidgets('the main hangup ends the room, not one of its participants', (tester) async {
      // The grid acts on the room whenever the focused call is a leg; a room
      // is not ended by silently picking one participant.
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [legA, legB], focusedCall: legA, conference: room),
      );

      await tester.tap(find.byKey(const Key(callActionsHangupId)));
      verify(() => callBloc.add(const CallControlEvent.conferenceEnded())).called(1);
      verifyNever(() => callBloc.add(const CallControlEvent.ended('a')));
      await teardownCallScaffold(tester);
    });

    testWidgets('the main hangup still ends a call standing outside the room', (tester) async {
      final outside = makeCall(callId: 'outside', acceptedTime: DateTime(2024), displayName: 'Dana Ruiz');
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [legA, legB, outside], focusedCall: outside, conference: room),
      );

      await tester.tap(find.byKey(const Key(callActionsHangupId)));
      verify(() => callBloc.add(const CallControlEvent.ended('outside'))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('the hangup ends the room, and says that is what it ends', (tester) async {
      // It is the only control that ends the room - the panel carries none of
      // its own - so a screen reader must not hear it as an ordinary hangup.
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [legA, legB], focusedCall: legA, conference: room),
      );

      expectTapTargetSemantics(
        tester,
        find.bySemanticsIdentifier(callActionsHangupId),
        label: 'End the conference and every call in it',
        identifier: callActionsHangupId,
        isButton: true,
      );
      await tester.tap(find.bySemanticsIdentifier(callActionsHangupId));
      verify(() => callBloc.add(const CallControlEvent.conferenceEnded())).called(1);
      await teardownCallScaffold(tester);
      semantics.dispose();
    });

    testWidgets('a participant is dropped by ending their call', (tester) async {
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [legA, legB], focusedCall: legA, conference: room),
      );

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
      verify(() => callBloc.add(const CallControlEvent.ended('b'))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('a call outside the room is brought into it, one request per call', (tester) async {
      final outside = makeCall(callId: 'outside', acceptedTime: DateTime(2024), displayName: 'Dana Ruiz');
      when(() => callBloc.state).thenReturn(CallState(activeCalls: [legA, legB, outside], conference: room));
      await tester.pumpWidget(
        buildCallScaffold(
          callBloc,
          activeCalls: [legA, legB, outside],
          focusedCall: legA,
          conference: room,
          canAdd: true,
        ),
      );

      await tester.tap(find.bySemanticsIdentifier(callAddToConferenceButtonId));
      // The legs never qualify, so the set is exactly what stands outside.
      verify(() => callBloc.add(const CallControlEvent.conferenceAdded('outside'))).called(1);
      await teardownCallScaffold(tester);
    });

    testWidgets('a participant is muted for everyone', (tester) async {
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [legA, legB], focusedCall: legA, conference: room),
      );

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)));
      verify(() => callBloc.add(const CallControlEvent.conferenceParticipantMuted('b', true))).called(1);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - camera permission denied', () {
    testWidgets('camera button shows the permission-denied tooltip', (tester) async {
      final call = makeCall(callId: 'active', acceptedTime: DateTime(2024), videoPermissionDenied: true);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));
      final context = tester.element(find.byType(CallActiveScaffold));

      expect(find.byTooltip(context.l10n.call_CallActionsTooltip_cameraPermissionDenied), findsOneWidget);
      expect(find.byTooltip(context.l10n.call_CallActionsTooltip_enableCamera), findsNothing);
      await teardownCallScaffold(tester);
    });

    testWidgets('tap enables the camera when permission is now granted', (tester) async {
      final appPermissions = MockAppPermissions();
      when(() => appPermissions.isPermissionGranted(Permission.camera)).thenAnswer((_) async => true);
      final call = makeCall(callId: 'active', acceptedTime: DateTime(2024), videoPermissionDenied: true);
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call, appPermissions: appPermissions),
      );

      await tester.tap(find.byIcon(Icons.videocam_off));
      await tester.pump();

      verify(() => callBloc.add(const CallControlEvent.cameraEnabled('active', true))).called(1);
      verifyNever(() => appPermissions.toAppSettings());
      await teardownCallScaffold(tester);
    });

    testWidgets('tap opens app settings when permission is still denied', (tester) async {
      final appPermissions = MockAppPermissions();
      when(() => appPermissions.isPermissionGranted(Permission.camera)).thenAnswer((_) async => false);
      when(() => appPermissions.toAppSettings()).thenAnswer((_) async {});
      final call = makeCall(callId: 'active', acceptedTime: DateTime(2024), videoPermissionDenied: true);
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call, appPermissions: appPermissions),
      );

      await tester.tap(find.byIcon(Icons.videocam_off));
      await tester.pump();

      verify(() => appPermissions.toAppSettings()).called(1);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - attended transfer submit', () {
    final original = makeCall(callId: 'original', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
    final consultation = makeCall(
      callId: 'consultation',
      direction: CallDirection.outgoing,
      acceptedTime: DateTime(2024),
      displayName: 'Boris Klein',
    );

    Future<void> openTransferMenu(WidgetTester tester) async {
      await tester.tap(find.byKey(callActionsTransferMenuKey));
      await tester.pumpAndSettle();
    }

    // The replace target must always be the consultation call, regardless of
    // which row is focused - an incoming call grabs the selection at ring
    // time and keeps it, so the held original call may stay focused through
    // the whole transfer flow. A self-referential transfer (referor ==
    // replace) is rejected by the backend.
    for (final focused in [consultation, original]) {
      testWidgets('submit targets the consultation call when ${focused.callId} is focused', (tester) async {
        await tester.pumpWidget(
          buildCallScaffold(callBloc, activeCalls: [original, consultation], focusedCall: focused),
        );

        await openTransferMenu(tester);
        await tester.tap(find.byKey(callActionsTransferMenuNumberKey));
        await tester.pumpAndSettle();

        verify(
          () => callBloc.add(
            CallControlEvent.attendedTransferSubmitted(referorCall: original, replaceCall: consultation),
          ),
        ).called(1);
        await teardownCallScaffold(tester);
      });
    }

    testWidgets('attended item is absent while the consultation call is not yet accepted', (tester) async {
      final ringingConsultation = makeCall(
        callId: 'consultation',
        direction: CallDirection.outgoing,
        displayName: 'Boris Klein',
      );
      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [original, ringingConsultation], focusedCall: original),
      );

      await openTransferMenu(tester);

      expect(find.byKey(callActionsTransferMenuNumberKey), findsNothing);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - avatar in the video area', () {
    testWidgets('audio-only call shows the remote avatar instead of the video overlay', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active));

      expect(find.byType(CallRemoteAvatar), findsOneWidget);
      expect(find.byType(RemoteVideoViewOverlay), findsNothing);
      await teardownCallScaffold(tester);
    });

    testWidgets('falls back to the initials of the remote display name', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active));
      await tester.pump();

      expect(find.descendant(of: find.byType(CallRemoteAvatar), matching: find.text('BK')), findsOneWidget);
      await teardownCallScaffold(tester);
    });

    testWidgets('a live picture behind a held focus does not stand in for the held one', (tester) async {
      // The frames are probed on the live (current) call; with the held call
      // focused, the controls describe her, and her avatar must be there.
      final live = VideoCall();
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held, live], focusedCall: held));
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.descendant(of: find.byType(CallRemoteAvatar), matching: find.text('CD')), findsOneWidget);

      // Focus back on the live call: the picture is hers, the avatar stands down.
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held, live], focusedCall: live));
      await tester.pump();
      expect(find.byType(CallRemoteAvatar), findsNothing);
      await teardownCallScaffold(tester);
    });

    testWidgets('a held video call shows its avatar even as the only call', (tester) async {
      // Every call held: the screen keeps the video of a held call off the
      // screen rather than freeze on its last frame, and a blank background
      // must not be left standing in for the person.
      final held = VideoCall(held: true);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held], focusedCall: held));
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byType(CallRemoteAvatar), findsOneWidget);
      await teardownCallScaffold(tester);
    });

    testWidgets('with a held call focused, the avatar shows that call, not the live one', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held, active], focusedCall: held));
      await tester.pump();

      // The roster highlights Clara and the actions act on her - the picture
      // must not show Boris (the derived current call) at the same time.
      expect(find.descendant(of: find.byType(CallRemoteAvatar), matching: find.text('CD')), findsOneWidget);
      await teardownCallScaffold(tester);
    });

    testWidgets('the open in-call keypad hides the avatar and keeps the keys full size', (tester) async {
      // The in-call keypad opens only in portrait orientation.
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active));
      expect(find.byType(CallRemoteAvatar), findsOneWidget);

      await tester.tap(find.byKey(callActionsKeypadKey));
      await tester.pumpAndSettle();

      // The avatar makes way for the keypad, and the keys render at their
      // natural size (screen shortest side / 5) - never scaled down.
      expect(find.byType(CallRemoteAvatar), findsNothing);
      final keySize = tester.getSize(find.byType(KeypadKeyButton).first);
      expect(keySize.width, greaterThanOrEqualTo(360 / 5));

      await tester.tap(find.byKey(callActionsHideKeypadKey));
      await tester.pumpAndSettle();
      expect(find.byType(KeypadKeyButton), findsNothing);
      expect(find.byType(CallRemoteAvatar), findsOneWidget);

      await teardownCallScaffold(tester);
    });

    testWidgets('typed digits are sent as DTMF, shown, and dropped when the keypad closes', (tester) async {
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active));
      await tester.tap(find.byKey(callActionsKeypadKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Every key goes out as DTMF for the focused call, and the display
      // mirrors the screen-owned buffer.
      verify(() => callBloc.add(const CallControlEvent.sentDTMF('active', '5'))).called(1);
      verify(() => callBloc.add(const CallControlEvent.sentDTMF('active', '2'))).called(1);
      expect(find.text('52'), findsOneWidget);

      // Closing the keypad drops the collected digits: reopening starts clean.
      await tester.tap(find.byKey(callActionsHideKeypadKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(callActionsKeypadKey));
      await tester.pumpAndSettle();
      expect(find.text('52'), findsNothing);

      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - legacy landscape fallback', () {
    testWidgets('a turned screen still renders the whole arrangement', (tester) async {
      tester.view.physicalSize = const Size(2622, 1206);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(ActiveCallActions), findsOneWidget);
      expect(find.byType(CallRemoteAvatar), findsOneWidget);

      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - 3 calls (held + active + incoming)', () {
    testWidgets('three rows, ringing focus keeps two buttons and the hint', (tester) async {
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held, active, ringing], focusedCall: ringing));
      final context = tester.element(find.byType(CallActiveScaffold));

      expect(find.byType(CallRow), findsNWidgets(3));
      expect(find.byType(IncomingCallActions), findsOneWidget);
      // Only the still-active call is named in the hold side effect; the
      // already-held one does not change state.
      expect(
        find.text(context.l10n.call_FocusedActionHint_willBeHeld('Boris Klein'), findRichText: true),
        findsOneWidget,
      );
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - hiding the controls in a video call', () {
    // What hiding them costs a screen reader is checked next door, in
    // call_active_scaffold_semantics_test.dart.
    const idleDelay = Duration(seconds: 8);
    // The controls have nothing to hide behind until the far side's picture
    // is on the screen, and the screen only knows that after it has probed a
    // frame. The probe is a zero-delay timer, and a plain pump moves no
    // clock: let a moment pass so it fires.
    Future<void> pumpUntilPictureProbed(WidgetTester tester) => tester.pump(const Duration(milliseconds: 1));

    testWidgets('on their own they hide once the call is left alone', (tester) async {
      final call = VideoCall();
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));

      expect(controlsOpacity(tester), 1);
      await tester.pump(idleDelay);
      expect(controlsOpacity(tester), 0);
      await teardownCallScaffold(tester);
    });

    testWidgets('a tap anywhere shows and hides them again', (tester) async {
      final call = VideoCall();
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));
      await pumpUntilPictureProbed(tester);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 0);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 1);
      await teardownCallScaffold(tester);
    });

    testWidgets('the bare toolbar counts as anywhere too', (tester) async {
      // The toolbar carries the status line and nothing else to press, so a tap
      // on it belongs to the same gesture as a tap on the picture.
      final call = VideoCall();
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));
      await pumpUntilPictureProbed(tester);

      await tester.tapAt(tester.getCenter(find.byType(AppBar)));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 0);
      await teardownCallScaffold(tester);
    });

    testWidgets('the own camera being off changes nothing - the picture is the other person', (tester) async {
      final call = VideoCall(cameraOn: false);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));

      await tester.pump(idleDelay);
      expect(controlsOpacity(tester), 0);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 1);
      await teardownCallScaffold(tester);
    });

    testWidgets('in an audio call they stay, idle or tapped', (tester) async {
      // WT-1832: a stray tap during a voice call used to take away the avatar,
      // the name and every button, leaving a bare screen and no hint that a
      // second tap brings them back. There is no picture to uncover in an
      // audio call, so there is nothing for the tap to do.
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [active], focusedCall: active));

      await tester.pump(idleDelay);
      expect(controlsOpacity(tester), 1);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 1);
      await teardownCallScaffold(tester);
    });

    testWidgets('a ringing call keeps its answer buttons through a tap', (tester) async {
      // The same screen takes the incoming call, and a tap there used to hide
      // the way to answer or decline it.
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [ringing], focusedCall: ringing));

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester, of: find.byType(IncomingCallActions)), 1);
      await teardownCallScaffold(tester);
    });

    testWidgets('a far side that announces video but sends nothing to show keeps them too', (tester) async {
      // Announced video with black or missing frames puts the avatar up in
      // place of the picture, and hiding the controls would take the avatar
      // with them.
      final call = VideoCall(framesArrive: false);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));

      await tester.pump(idleDelay);
      expect(controlsOpacity(tester), 1);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 1);
      await teardownCallScaffold(tester);
    });

    testWidgets('with a held call focused over the live video, they stay as well', (tester) async {
      // The picture of the live call is kept off the screen while a held call
      // is focused (the controls describe the held one), so once more there
      // is nothing to uncover.
      final live = VideoCall();
      final held = makeCall(callId: 'held', acceptedTime: DateTime(2024), held: true, displayName: 'Clara Diaz');
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [held, live], focusedCall: held));

      await tester.pump(idleDelay);
      expect(controlsOpacity(tester), 1);

      await tester.tapAt(const Offset(20, 400));
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 1);
      await teardownCallScaffold(tester);
    });

    testWidgets('the demand arriving over hidden controls brings them back', (tester) async {
      final call = VideoCall();
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));
      await tester.pump(idleDelay);
      expect(controlsOpacity(tester), 0);

      await tester.pumpWidget(
        buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call, keepControlsVisible: true),
      );
      await tester.pump(kThemeAnimationDuration);
      expect(controlsOpacity(tester), 1);
      await teardownCallScaffold(tester);
    });
  });

  group('CallActiveScaffold - the picture belongs to the call it was probed on', () {
    // The screen stays put while the call it shows changes underneath it
    // (CallScreen rebuilds the same scaffold for the life of the call state),
    // and what it learnt about one call's picture must not carry over to the
    // next. From the review of the WT-1832 change.
    const idleDelay = Duration(seconds: 8);

    for (final kind in ['audio', 'held', 'ringing']) {
      testWidgets('controls hidden over the video come back when the call becomes $kind', (tester) async {
        final video = VideoCall();
        await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [video], focusedCall: video));
        await tester.pump(idleDelay);
        expect(controlsOpacity(tester), 0);
        final before = tester.state(find.byType(CallActiveScaffold));

        final next = makeCall(
          callId: 'next',
          held: kind == 'held',
          processingStatus: kind == 'ringing' ? CallProcessingStatus.incomingFromOffer : CallProcessingStatus.connected,
          acceptedTime: kind == 'ringing' ? null : DateTime(2024),
        );
        await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [next], focusedCall: next));
        expect(tester.state(find.byType(CallActiveScaffold)), same(before), reason: 'the same screen, another call');
        await tester.pump(kThemeAnimationDuration);
        expect(controlsOpacity(tester, of: kind == 'ringing' ? find.byType(IncomingCallActions) : null), 1);
        await teardownCallScaffold(tester);
      });
    }

    testWidgets('a replacement one-way video call waits for a frame of its own', (tester) async {
      // The previous call's picture was probed and found renderable; the next
      // call has a track but its first frame is still on its way. The
      // controls have nothing to hide behind yet.
      final previous = VideoCall(cameraOn: false);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [previous], focusedCall: previous));
      await tester.pump(const Duration(milliseconds: 1));
      final before = tester.state(find.byType(CallActiveScaffold));

      final track = _PendingFrameTrack();
      final next = _oneWayVideoCall('next', track);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [next], focusedCall: next));
      expect(tester.state(find.byType(CallActiveScaffold)), same(before));
      await tester.pump(const Duration(seconds: 6));
      expect(track.captures, greaterThan(0), reason: 'the new track is being probed');
      expect(track.frame.isCompleted, isFalse);
      final opacity = controlsOpacity(tester);

      track.frame.completeError(StateError('test finished'));
      await tester.pump();
      await teardownCallScaffold(tester);
      expect(opacity, 1, reason: 'the replacement call has delivered no frame to uncover');
    });

    testWidgets('a track replaced within the same call is probed afresh', (tester) async {
      // A renegotiation hands the same call another remote track. What the
      // old track showed says nothing about the new one.
      final oldTrack = _PendingFrameTrack();
      final call = _oneWayVideoCall('same', oldTrack);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));
      await tester.pump(const Duration(milliseconds: 1));
      oldTrack.frame.completeError(StateError('capture failed, counts as a picture'));
      await tester.pump();
      final before = tester.state(find.byType(CallActiveScaffold));

      final newTrack = _PendingFrameTrack();
      final renegotiated = _oneWayVideoCall('same', newTrack);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [renegotiated], focusedCall: renegotiated));
      expect(tester.state(find.byType(CallActiveScaffold)), same(before));
      await tester.pump(const Duration(seconds: 6));
      expect(newTrack.captures, greaterThan(0));
      expect(newTrack.frame.isCompleted, isFalse);
      final opacity = controlsOpacity(tester);

      newTrack.frame.completeError(StateError('test finished'));
      await tester.pump();
      await teardownCallScaffold(tester);
      expect(opacity, 1, reason: 'the new track has delivered no frame to uncover');
    });

    testWidgets('a track swapped inside the stream, with no new call state, is caught by the next probe', (
      tester,
    ) async {
      // The stream object stays the same and only its track list changes, so
      // nothing rebuilds the screen; the periodic probe notices on its own.
      final oldTrack = _PendingFrameTrack();
      final stream = _RemoteStream(oldTrack);
      final call = _oneWayVideoCall('same', oldTrack, stream: stream);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [call], focusedCall: call));
      await tester.pump(const Duration(milliseconds: 1));
      oldTrack.frame.completeError(StateError('capture failed, counts as a picture'));
      await tester.pump();

      final newTrack = _PendingFrameTrack();
      stream.track = newTrack;
      await tester.pump(const Duration(seconds: 6));
      expect(newTrack.captures, greaterThan(0));
      expect(newTrack.frame.isCompleted, isFalse);
      final opacity = controlsOpacity(tester);

      newTrack.frame.completeError(StateError('test finished'));
      await tester.pump();
      await teardownCallScaffold(tester);
      expect(opacity, 1, reason: 'the swapped-in track has delivered no frame to uncover');
    });

    testWidgets('a capture still pending from the previous call cannot authorise hiding on the next', (tester) async {
      // The old stream closes once the call is gone and its capture fails; a
      // failed capture counts as a renderable frame - for the call it was
      // taken on, which is no longer the one on screen.
      final oldTrack = _PendingFrameTrack();
      final previous = _oneWayVideoCall('previous', oldTrack);
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [previous], focusedCall: previous));
      await tester.pump(const Duration(milliseconds: 1));
      expect(oldTrack.captures, 1);

      final nextTrack = _PendingFrameTrack();
      final next = _oneWayVideoCall('next', nextTrack);
      final before = tester.state(find.byType(CallActiveScaffold));
      await tester.pumpWidget(buildCallScaffold(callBloc, activeCalls: [next], focusedCall: next));
      expect(tester.state(find.byType(CallActiveScaffold)), same(before));
      oldTrack.frame.completeError(StateError('previous stream is closed'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 6));
      expect(nextTrack.captures, greaterThan(0));
      expect(nextTrack.frame.isCompleted, isFalse);
      final opacity = controlsOpacity(tester);

      nextTrack.frame.completeError(StateError('test finished'));
      await tester.pump();
      await teardownCallScaffold(tester);
      expect(opacity, 1, reason: 'the old capture must not activate the new call\'s auto-hide');
    });
  });
}

/// A remote video track whose frame capture stays pending until the test
/// completes it, counting how often it was asked.
class _PendingFrameTrack extends Fake implements MediaStreamTrack {
  final frame = Completer<ByteBuffer>();
  int captures = 0;

  @override
  Future<ByteBuffer> captureFrame() {
    captures++;
    return frame.future;
  }
}

/// A remote stream whose single video track can be swapped, the way a
/// renegotiation replaces a track inside the stream that stays.
class _RemoteStream extends Fake implements MediaStream {
  _RemoteStream(this.track);

  MediaStreamTrack track;

  @override
  List<MediaStreamTrack> getVideoTracks() => [track];
}

/// A connected call with the own camera off and the far side's video track
/// present - a real ActiveCall, so remoteVideo and isCameraActive are the
/// production getters over these streams.
ActiveCall _oneWayVideoCall(String id, MediaStreamTrack track, {MediaStream? stream}) => ActiveCall(
  callId: id,
  direction: CallDirection.incoming,
  line: 0,
  handle: kHandle,
  createdTime: DateTime(2024),
  video: false,
  remoteStream: stream ?? _RemoteStream(track),
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime(2024),
  displayName: id,
);
