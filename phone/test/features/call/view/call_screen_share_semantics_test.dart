import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';

import '../../../helpers/semantics.dart';
import 'call_active_scaffold_harness.dart';

/// The screen share on the call screen: the toolbar menu's entry that starts and stops it - in an
/// audio call too, where it is the menu's one entry, and only where the call can share, which the
/// state says for the phone and the call alike - and the camera control standing aside while the
/// screen is shown. Everything is reached through semantics, as the QA stand reaches it.
void main() {
  late MockCallBloc callBloc;

  setUp(() {
    callBloc = newCallBloc();
    pinPortraitSurface();
  });

  final audio = makeCall(callId: 'active', acceptedTime: DateTime(2024), displayName: 'Boris Klein');

  Future<void> openMenu(WidgetTester tester) async {
    await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsOptionsId));
    await tester.pumpAndSettle();
  }

  Future<void> pumpOn(
    WidgetTester tester, {
    required ActiveCall call,
    bool canShareScreen = true,
    ScreenShareStatus? sharing,
  }) async {
    await pumpCallScaffold(
      tester,
      buildCallScaffold(
        callBloc,
        activeCalls: [call],
        focusedCall: call,
        canShareScreen: canShareScreen,
        screenShare: sharing == null
            ? null
            : ScreenShareState(target: CallScreenShareTarget(call.callId), status: sharing),
      ),
    );
  }

  Future<void> tearDownOn(WidgetTester tester) => teardownCallScaffold(tester);

  testWidgets('an audio call that can share has the menu, with Share screen as its one entry', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOn(tester, call: audio);

    await openMenu(tester);

    expect(find.bySemanticsIdentifier(callActionsScreenShareId), findsOneWidget);
    expect(find.text('Share screen'), findsOneWidget);
    expect(find.text('Fit'), findsNothing, reason: 'the picture\'s entries stay video-only');
    expect(find.text('Cover'), findsNothing);

    await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsScreenShareId));
    await tester.pumpAndSettle();
    verify(() => callBloc.add(const CallControlEvent.screenShareStarted('active'))).called(1);

    await tearDownOn(tester);
    semantics.dispose();
  });

  testWidgets('an audio call that cannot share - on a phone that cannot, or held - has no menu', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOn(tester, call: audio, canShareScreen: false);

    expect(find.bySemanticsIdentifier(callActionsOptionsId), findsNothing);

    await tearDownOn(tester);
    semantics.dispose();
  });

  testWidgets('a video call keeps its picture\'s entries, with Share screen after them', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOn(tester, call: VideoCall());

    await openMenu(tester);

    final fit = tester.getTopLeft(find.text('Fit').hitTestable().first);
    final share = tester.getTopLeft(find.text('Share screen'));
    expect(share.dy, greaterThan(fit.dy));

    await tearDownOn(tester);
    semantics.dispose();
  });

  testWidgets('while the screen is shown the entry stops it, and the camera stands aside', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOn(tester, call: audio, canShareScreen: true, sharing: ScreenShareStatus.sharing);

    final camera = tester.getSemantics(find.bySemanticsIdentifier(callActionsVideoCallId));
    expect(camera.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);

    await openMenu(tester);
    expect(find.text('Stop sharing'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(callActionsScreenShareId));
    await tester.pumpAndSettle();
    verify(() => callBloc.add(const CallControlEvent.screenShareStopped('active'))).called(1);

    await tearDownOn(tester);
    semantics.dispose();
  });

  testWidgets('a share under way can be stopped even where a new one could not start', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpOn(tester, call: audio, canShareScreen: false, sharing: ScreenShareStatus.starting);

    await openMenu(tester);

    expect(find.text('Stop sharing'), findsOneWidget);

    await tearDownOn(tester);
    semantics.dispose();
  });
}
