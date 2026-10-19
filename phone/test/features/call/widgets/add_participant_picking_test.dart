import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

ActiveCall _call(String callId, {int line = 0}) => ActiveCall(
  callId: callId,
  direction: CallDirection.outgoing,
  line: line,
  handle: const CallkeepHandle.number('1001'),
  createdTime: DateTime(2024),
  video: false,
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime(2024),
);

// The request to choose somebody to call in is made where the person asks for
// it; this takes it back when the call it was asked from is gone, or when the person is
// back on the call without choosing.
void main() {
  late _MockCallBloc callBloc;
  late DestinationPickingCubit picking;
  late StreamController<CallState> callStates;
  late CallController controller;

  final onScreen = CallState(activeCalls: [_call('b')], minimized: false);
  final away = CallState(activeCalls: [_call('b')], minimized: true);

  setUp(() {
    callBloc = _MockCallBloc();
    picking = DestinationPickingCubit();
    callStates = StreamController<CallState>.broadcast(sync: true);
    controller = CallController(callBloc: callBloc);
    whenListen(callBloc, callStates.stream, initialState: onScreen);
  });

  tearDown(() async {
    await callStates.close();
    await picking.close();
  });

  AddParticipantPurpose purpose({String anchorCallId = 'b', bool intoRoom = false}) => AddParticipantPurpose(
    announcement: 'Choose who to add to the call',
    pickLabel: (number) => 'Add $number to the call',
    controller: controller,
    anchorCallId: anchorCallId,
    intoRoom: intoRoom,
  );

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CallBloc>.value(value: callBloc),
            BlocProvider<DestinationPickingCubit>.value(value: picking),
          ],
          child: MultiBlocListener(listeners: [AddParticipantPicking()], child: const SizedBox.shrink()),
        ),
      ),
    );
  }

  testWidgets('a call that changes while the screen is still up does not take the request away', (tester) async {
    // The request is made on the screen a moment before it steps aside.
    await pump(tester);
    picking.ask(purpose());

    callStates.add(CallState(activeCalls: [_call('b').copyWith(muted: true)], minimized: false));
    await tester.pump();

    expect(picking.state.purpose, isA<AddParticipantPurpose>());
  });

  testWidgets('the request goes when the call it was for ends', (tester) async {
    await pump(tester);
    picking.ask(purpose());
    callStates.add(away);
    await tester.pump();
    expect(picking.state.purpose, isA<AddParticipantPurpose>());

    callStates.add(const CallState(activeCalls: [], minimized: true));
    await tester.pump();

    expect(picking.state.purpose, isNull);
  });

  testWidgets('the request goes when the leg it was asked from leaves the room', (tester) async {
    // The room stays, but the request names a leg the bloc no longer knows;
    // the person asks again from the room as it is now.
    final room = CallState(
      activeCalls: [_call('a'), _call('b', line: 1)],
      minimized: true,
      conference: const ConferenceState(phase: ConferencePhase.active, legs: {'a': 0, 'b': 1}),
    );
    whenListen(callBloc, callStates.stream, initialState: room);
    await pump(tester);
    picking.ask(purpose(anchorCallId: 'a'));

    callStates.add(
      room.copyWith(
        activeCalls: [_call('b', line: 1)],
        conference: const ConferenceState(phase: ConferencePhase.active, legs: {'b': 1}),
      ),
    );
    await tester.pump();

    expect(picking.state.purpose, isNull);
  });

  testWidgets('a request for the room goes when the room ends, though its call stays', (tester) async {
    // The legs come back as ordinary calls; a choice then would merge somebody
    // with one former participant instead of bringing them into the room.
    final room = CallState(
      activeCalls: [_call('a'), _call('b', line: 1)],
      minimized: true,
      conference: const ConferenceState(phase: ConferencePhase.active, legs: {'a': 0, 'b': 1}),
    );
    whenListen(callBloc, callStates.stream, initialState: room);
    await pump(tester);
    picking.ask(purpose(anchorCallId: 'a', intoRoom: true));

    callStates.add(room.copyWith(conference: const ConferenceState()));
    await tester.pump();

    expect(picking.state.purpose, isNull);
  });

  testWidgets('the request goes when the person comes back to the call without choosing', (tester) async {
    await pump(tester);
    picking.ask(purpose());
    callStates.add(away);
    await tester.pump();

    callStates.add(onScreen);
    await tester.pump();

    expect(picking.state.purpose, isNull);
  });
}
