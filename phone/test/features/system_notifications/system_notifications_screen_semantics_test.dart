import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../../helpers/helpers.dart';
import 'idle_outbox.dart';

class _Local extends Mock implements SystemNotificationsLocalRepository {}

class _Remote extends Mock implements SystemNotificationsRemoteRepository {}

// The two ways to delete on the notifications screen, reached the way a screen
// reader reaches them: the header action that deletes everything on the
// device, and the delete a row offers in place of the swipe.
void main() {
  late _Local local;
  late _Remote remote;
  late StreamController<SystemNotificationEvent> events;

  SystemNotification notification(int id) => SystemNotification(
    id: id,
    title: 'Notification $id',
    content: 'Content $id',
    type: SystemNotificationType.system,
    // Seen, so the row does not queue a receipt the moment it is drawn.
    seen: true,
    createdAt: DateTime.utc(2026, 10, id),
    updatedAt: DateTime.utc(2026, 10, id),
  );

  setUpAll(() => registerFallbackValue(<int>[]));

  setUp(() {
    local = _Local();
    remote = _Remote();
    events = StreamController.broadcast();
    when(() => local.eventBus).thenAnswer((_) => events.stream);
    when(() => local.getOutboxNotifications()).thenAnswer((_) async => []);
    when(() => local.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => []);
    // What the real store does: the queued notifications leave the list.
    when(() => local.queueDeletes(any())).thenAnswer((invocation) async {
      for (final id in invocation.positionalArguments.single as List<int>) {
        events.add(SystemNotificationRemove(id));
      }
    });
  });

  tearDown(() => events.close());

  Future<void> pumpScreen(WidgetTester tester, List<SystemNotification> stored) async {
    when(() => local.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => stored);
    when(() => local.getNotificationIds()).thenAnswer((_) async => stored.map((n) => n.id).toList());

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider(
          create: (_) => SystemNotificationsScreenCubit(local, remote, outbox: idleOutbox())..init(),
          child: const SystemNotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('delete all is named, asks with the count and deletes what the device holds', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, [notification(2), notification(1)]);

    final finder = find.bySemanticsIdentifier(systemNotificationsDeleteAllId);
    expectTapTargetSemantics(
      tester,
      finder,
      label: 'Delete all notifications',
      identifier: systemNotificationsDeleteAllId,
      isButton: true,
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tapViaSemantics(tester, finder);
    await tester.pumpAndSettle();
    expect(find.text('Delete 2 notifications?'), findsOneWidget);

    await tester.tap(find.byKey(confirmDialogYesButtonKey));
    await tester.pumpAndSettle();

    verify(() => local.queueDeletes([2, 1])).called(1);
    verifyZeroInteractions(remote);
    handle.dispose();
  });

  testWidgets('delete all is off while there is nothing to delete', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, []);

    final data = tester.getSemantics(find.bySemanticsIdentifier(systemNotificationsDeleteAllId)).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('a row offers delete as an action of its own', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, [notification(1)]);

    final row = tester.getSemantics(find.text('Notification 1'));
    final node = _withCustomActions(row);
    final delete = node
        .getSemanticsData()
        .customSemanticsActionIds!
        .map(CustomSemanticsAction.getAction)
        .firstWhere((action) => action!.label == 'Delete')!;

    node.owner!.performAction(node.id, SemanticsAction.customAction, CustomSemanticsAction.getIdentifier(delete));
    await tester.pumpAndSettle();

    verify(() => local.queueDeletes([1])).called(1);
    expect(find.text('Notification 1'), findsNothing);
    handle.dispose();
  });

  testWidgets('a swipe deletes the card without asking the backend', (tester) async {
    await pumpScreen(tester, [notification(1)]);

    await tester.drag(find.text('Notification 1'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    verify(() => local.queueDeletes([1])).called(1);
    verifyZeroInteractions(remote);
    expect(find.text('Notification 1'), findsNothing);
  });
}

/// The row's node or the nearest one above it that carries custom actions.
SemanticsNode _withCustomActions(SemanticsNode node) {
  SemanticsNode? current = node;
  while (current != null) {
    if (current.getSemanticsData().customSemanticsActionIds?.isNotEmpty ?? false) return current;
    current = current.parent;
  }
  fail('no node with custom actions above $node');
}
