import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

class _MockCallBloc extends MockBloc<CallEvent, CallState> implements CallBloc {}

class _OrdinaryPurpose implements DestinationPickPurpose {
  const _OrdinaryPurpose();

  @override
  String get announcement => 'Choose who to forward to';

  @override
  bool get closedByChoice => true;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get cancellable => true;

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => true;

  @override
  IconData get pickIcon => Icons.forward_to_inbox;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Forward';

  @override
  void submit(DestinationCandidate candidate) {}
}

// The one thing that knows about both a call and the picking mechanism. The
// call keeps owning whether a transfer is looking for a target - it is one of
// six transfer states, cleared in ten places inside the bloc - and this
// reflects that one slice, in one direction.
void main() {
  late _MockCallBloc callBloc;
  late DestinationPickingCubit picking;
  late StreamController<CallState> callStates;

  CallState transferring({required bool initiated}) => CallState(
    activeCalls: [
      if (initiated)
        ActiveCall(
          callId: 'call-1',
          direction: CallDirection.outgoing,
          line: 0,
          handle: const CallkeepHandle.number('1001'),
          createdTime: DateTime(2024),
          video: false,
          processingStatus: CallProcessingStatus.connected,
          transfer: const Transfer.blindTransferInitiated(),
        ),
    ],
  );

  setUp(() {
    callBloc = _MockCallBloc();
    picking = DestinationPickingCubit();
    callStates = StreamController<CallState>.broadcast(sync: true);
    whenListen(callBloc, callStates.stream, initialState: transferring(initiated: false));
  });

  tearDown(() async {
    await callStates.close();
    await picking.close();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CallBloc>.value(value: callBloc),
            BlocProvider<DestinationPickingCubit>.value(value: picking),
          ],
          child: MultiBlocListener(
            listeners: [BlindTransferPicking(controller: CallController(callBloc: callBloc))],
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  testWidgets('a call looking for somebody to be handed to asks for a choice', (tester) async {
    await pump(tester);

    callStates.add(transferring(initiated: true));
    await tester.pump();

    expect(picking.state.purpose, isA<BlindTransferPurpose>());
  });

  testWidgets('and the request goes when the transfer does', (tester) async {
    // Whatever ended it - the destination submitted, the call gone, signalling
    // refusing - the call says so in the one state this watches.
    await pump(tester);
    callStates.add(transferring(initiated: true));
    await tester.pump();

    callStates.add(transferring(initiated: false));
    await tester.pump();

    expect(picking.state.purpose, isNull);
  });

  testWidgets('a transfer that ends does not take somebody else s request away', (tester) async {
    // The edge can arrive after another feature has the floor: the transfer
    // finished, its request was already closed by the choice, and a message is
    // now looking for a recipient.
    await pump(tester);
    picking.ask(const _OrdinaryPurpose());

    callStates.add(transferring(initiated: false));
    await tester.pump();

    expect(picking.state.purpose, isA<_OrdinaryPurpose>());
  });
}
