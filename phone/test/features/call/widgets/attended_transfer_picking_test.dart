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

ActiveCall _call(String callId) => ActiveCall(
  callId: callId,
  direction: CallDirection.outgoing,
  line: 0,
  handle: const CallkeepHandle.number('1001'),
  createdTime: DateTime(2024),
  video: false,
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime(2024),
);

// The request to choose whom to call before a transfer is made where the
// person asks for it; this takes it back when the call it was for is gone, or
// when the person is back on the call without choosing.
void main() {
  late _MockCallBloc callBloc;
  late DestinationPickingCubit picking;
  late StreamController<CallState> callStates;

  final onScreen = CallState(activeCalls: [_call('b')], minimized: false);
  final away = CallState(activeCalls: [_call('b')], minimized: true);

  setUp(() {
    callBloc = _MockCallBloc();
    picking = DestinationPickingCubit();
    callStates = StreamController<CallState>.broadcast(sync: true);
    whenListen(callBloc, callStates.stream, initialState: onScreen);
  });

  tearDown(() async {
    await callStates.close();
    await picking.close();
  });

  AttendedTransferPurpose purpose() => AttendedTransferPurpose(
    announcement: 'Choose who to consult before transferring',
    pickLabel: (number) => number,
    controller: CallController(callBloc: callBloc),
    anchorCallId: 'b',
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
          child: MultiBlocListener(listeners: [AttendedTransferPicking()], child: const SizedBox.shrink()),
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

    expect(picking.state.purpose, isA<AttendedTransferPurpose>());
  });

  testWidgets('the request goes when the call it was for ends', (tester) async {
    await pump(tester);
    picking.ask(purpose());
    callStates.add(away);
    await tester.pump();
    expect(picking.state.purpose, isA<AttendedTransferPurpose>());

    callStates.add(const CallState(activeCalls: [], minimized: true));
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
