import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../helpers/helpers.dart';
import 'fake_call_queues_repository.dart';

void main() {
  late FakeCallQueuesRepository repository;

  tearDown(() => repository.dispose());

  Future<void> pumpScreen(WidgetTester tester, CallQueuesSnapshot snapshot) async {
    repository = FakeCallQueuesRepository(initial: snapshot);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(create: (context) => CallQueuesCubit(repository), child: const CallCenterScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('every control is named and carries its id on the node that acts', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      CallQueuesSnapshot(
        known: true,
        queues: [
          testQueue('0111', name: 'Support'),
          testQueue('0222', name: 'Sales', loggedIn: false),
        ],
      ),
    );

    // The caption of each row is its name - a label of its own would be
    // announced on top of it - so what is asserted is that the name, the id
    // and the action land on ONE node.
    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(callCenterMasterSwitchId),
      label: 'All queues\nTaking calls from 1 of 2 queues',
      identifier: callCenterMasterSwitchId,
    );
    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(callCenterQueueSwitchId('0111')),
      label: 'Support\nOnline \u00b7 0111 \u00b7 0 waiting \u00b7 2 of 3 agents',
      identifier: callCenterQueueSwitchId('0111'),
    );

    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('a control is reached the way a screen reader reaches it', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      CallQueuesSnapshot(known: true, queues: [testQueue('0111', name: 'Support', loggedIn: false)]),
    );

    await tapViaSemantics(tester, find.bySemanticsIdentifier(callCenterQueueSwitchId('0111')));
    await tester.pumpAndSettle();

    expect(repository.writes, ['0111:true']);
    handle.dispose();
  });

  testWidgets('a row waiting for the backend keeps its name and its id', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      CallQueuesSnapshot(
        known: true,
        queues: [testQueue('0111', name: 'Support')],
        pendingIds: const {'0111'},
      ),
    );

    // The control gives way to a progress indicator, and the row has to stay
    // findable by the same id - a reader that lost it would have nothing to
    // announce where the switch used to be. It is an anchor now, not an
    // action: there is nothing to activate until the backend answers.
    expect(find.bySemanticsIdentifier(callCenterQueueSwitchId('0111')), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    handle.dispose();
  });
}
