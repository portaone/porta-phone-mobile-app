import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:api/api.dart' as api;
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import 'fake_call_queues_repository.dart';

void main() {
  late FakeCallQueuesRepository repository;

  setUp(() => repository = FakeCallQueuesRepository());

  tearDown(() => repository.dispose());

  Future<void> pumpScreen(WidgetTester tester, CallQueuesSnapshot snapshot) async {
    repository = FakeCallQueuesRepository(initial: snapshot);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider(create: (context) => CallQueuesCubit(repository), child: const CallCenterBody()),
        ),
      ),
    );
    await tester.pump();
  }

  group('what a row says', () {
    testWidgets('an unknown number of waiting callers is a dash, a reported zero is a zero', (tester) async {
      await pumpScreen(
        tester,
        CallQueuesSnapshot(
          known: true,
          queues: [
            testQueue('0111', name: 'Support', callersWaiting: null),
            testQueue('0222', name: 'Sales', callersWaiting: 0),
          ],
        ),
      );

      final support = tester.widget<ListTile>(find.ancestor(of: find.text('Support'), matching: find.byType(ListTile)));
      final sales = tester.widget<ListTile>(find.ancestor(of: find.text('Sales'), matching: find.byType(ListTile)));

      expect(_subtitleOf(tester, support), contains('— waiting'));
      expect(_subtitleOf(tester, sales), contains('0 waiting'));
    });

    testWidgets('the row carries the queue number and the agent count', (tester) async {
      await pumpScreen(
        tester,
        CallQueuesSnapshot(
          known: true,
          queues: [testQueue('0111', name: 'Support', agentsLoggedIn: 2, agentsTotal: 3)],
        ),
      );

      final row = tester.widget<ListTile>(find.ancestor(of: find.text('Support'), matching: find.byType(ListTile)));

      expect(_subtitleOf(tester, row), contains('0111'));
      expect(_subtitleOf(tester, row), contains('2 of 3 agents'));
      expect(_subtitleOf(tester, row), contains('Online'));
    });

    testWidgets('a row whose write is in flight shows progress instead of a switch', (tester) async {
      await pumpScreen(
        tester,
        CallQueuesSnapshot(known: true, queues: [testQueue('0111')], pendingIds: const {'0111'}),
      );

      expect(find.byKey(callCenterQueueSwitchKey('0111')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(callCenterQueueSwitchKey('0111')),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(callCenterQueueSwitchKey('0111')), matching: find.byType(Switch)),
        findsNothing,
      );
    });
  });

  group('the control for every queue', () {
    testWidgets('is on when every queue is', (tester) async {
      await pumpScreen(tester, CallQueuesSnapshot(known: true, queues: [testQueue('0111'), testQueue('0222')]));

      expect(_masterSwitch(tester).value, isTrue);
    });

    testWidgets('is off when no queue is', (tester) async {
      await pumpScreen(
        tester,
        CallQueuesSnapshot(
          known: true,
          queues: [testQueue('0111', loggedIn: false), testQueue('0222', loggedIn: false)],
        ),
      );

      expect(_masterSwitch(tester).value, isFalse);
    });

    testWidgets('a mixed list reads as off and is marked as mixed', (tester) async {
      await pumpScreen(
        tester,
        CallQueuesSnapshot(known: true, queues: [testQueue('0111'), testQueue('0222', loggedIn: false)]),
      );

      expect(_masterSwitch(tester).value, isFalse);
      expect(_masterSwitch(tester).thumbIcon, isNotNull, reason: 'mixed is a third appearance, not a plain off');
      expect(find.text('Taking calls from 1 of 2 queues'), findsOneWidget);
    });

    testWidgets('from a mixed list it logs into every queue', (tester) async {
      await pumpScreen(
        tester,
        CallQueuesSnapshot(known: true, queues: [testQueue('0111'), testQueue('0222', loggedIn: false)]),
      );

      await tester.tap(find.byKey(callCenterMasterSwitchKey));
      await tester.pumpAndSettle();

      expect(repository.writes, ['all:true']);
    });
  });

  group('the control for every queue', () {
    testWidgets('refuses while a single row is being written', (tester) async {
      // It cannot act then - the repository turns it down - so a control that
      // still looked live would swallow the tap without a word.
      await pumpScreen(
        tester,
        CallQueuesSnapshot(known: true, queues: [testQueue('0111'), testQueue('0222')], pendingIds: const {'0111'}),
      );

      expect(find.descendant(of: find.byKey(callCenterMasterSwitchKey), matching: find.byType(Switch)), findsNothing);
      expect(
        find.descendant(of: find.byKey(callCenterMasterSwitchKey), matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
    });
  });

  group('acting on one queue', () {
    testWidgets('sends the opposite of what the row shows', (tester) async {
      await pumpScreen(tester, CallQueuesSnapshot(known: true, queues: [testQueue('0111', loggedIn: true)]));

      await tester.tap(find.byKey(callCenterQueueSwitchKey('0111')));
      await tester.pumpAndSettle();

      expect(repository.writes, ['0111:false']);
    });

    testWidgets('a refused write is reported and the row is left as it was', (tester) async {
      await pumpScreen(tester, CallQueuesSnapshot(known: true, queues: [testQueue('0111', loggedIn: true)]));
      repository.failWith = api.RequestFailure(url: Uri.https('demo.webtrit.com'), requestId: 'r', statusCode: 500);

      await tester.tap(find.byKey(callCenterQueueSwitchKey('0111')));
      await tester.pumpAndSettle();

      expect(find.text('Could not change your status in the queue. Please try again.'), findsOneWidget);
      expect(_queueSwitch(tester, '0111').value, isTrue);
    });

    testWidgets('a read-only site says so rather than reporting a plain failure', (tester) async {
      await pumpScreen(tester, CallQueuesSnapshot(known: true, queues: [testQueue('0111', loggedIn: true)]));
      repository.failWith = api.RequestFailure(url: Uri.https('demo.webtrit.com'), requestId: 'r', statusCode: 503);

      await tester.tap(find.byKey(callCenterQueueSwitchKey('0111')));
      await tester.pumpAndSettle();

      expect(find.text('The server is read-only right now, so queue status cannot be changed.'), findsOneWidget);
    });

    testWidgets('a queue that is not the agent is any more says the list was refreshed', (tester) async {
      await pumpScreen(tester, CallQueuesSnapshot(known: true, queues: [testQueue('0111', loggedIn: true)]));
      repository.failWith = api.CallQueueNotFoundException(
        url: Uri.https('demo.webtrit.com'),
        requestId: 'r',
        statusCode: 404,
      );

      await tester.tap(find.byKey(callCenterQueueSwitchKey('0111')));
      await tester.pumpAndSettle();

      expect(find.text('That queue is no longer yours. The list has been refreshed.'), findsOneWidget);
    });
  });

  group('when a read fails', () {
    testWidgets('the screen says so instead of spinning forever', (tester) async {
      await pumpScreen(tester, const CallQueuesSnapshot(readFailed: true));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Could not load your queues.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('asking again goes back to the backend', (tester) async {
      await pumpScreen(tester, const CallQueuesSnapshot(readFailed: true));

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(repository.refreshCount, 1);
    });
  });

  group('before anything is known', () {
    testWidgets('waits instead of announcing that there are no queues', (tester) async {
      await pumpScreen(tester, const CallQueuesSnapshot());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('You are not an agent of any call queue.'), findsNothing);
    });

    testWidgets('an answered empty list says the user is not an agent', (tester) async {
      await pumpScreen(tester, const CallQueuesSnapshot(known: true));

      expect(find.text('You are not an agent of any call queue.'), findsOneWidget);
    });
  });
}

String _subtitleOf(WidgetTester tester, ListTile tile) {
  final texts = find.descendant(of: find.byWidget(tile.subtitle!), matching: find.byType(Text));
  return tester.widgetList<Text>(texts).map((text) => text.data ?? '').join(' ');
}

Switch _masterSwitch(WidgetTester tester) =>
    tester.widget<Switch>(find.descendant(of: find.byKey(callCenterMasterSwitchKey), matching: find.byType(Switch)));

Switch _queueSwitch(WidgetTester tester, String queueId) => tester.widget<Switch>(
  find.descendant(of: find.byKey(callCenterQueueSwitchKey(queueId)), matching: find.byType(Switch)),
);
