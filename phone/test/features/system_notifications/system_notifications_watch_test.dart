import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/app_time.dart';
import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../helpers/helpers.dart';
import '../../helpers/screen_presets.dart';
import 'idle_outbox.dart';

class _Local extends Mock implements SystemNotificationsLocalRepository {}

class _Remote extends Mock implements SystemNotificationsRemoteRepository {}

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

  setUpAll(() {
    registerFallbackValue(<int>[]);
    registerFallbackValue(SystemNotificationOutboxEntry(notificationId: 0, actionType: SnOutboxActionType.seen));
  });

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
        events.add(SystemNotificationRemove(notification(id)));
      }
    });
  });

  tearDown(() => events.close());

  Future<void> pumpScreen(WidgetTester tester, List<SystemNotification> stored) async {
    when(() => local.getNotifications(limit: any(named: 'limit'))).thenAnswer((_) async => stored);
    when(() => local.getNotificationIds()).thenAnswer((_) async => stored.map((n) => n.id).toList());

    await tester.pumpWidget(
      RepositoryProvider<AppTime>.value(
        value: AppTime(is24HourFormat: true),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider(
            create: (_) => SystemNotificationsScreenCubit(local, remote, outbox: idleOutbox())..init(),
            child: const SystemNotificationsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final preset in watchPresets) {
    testWidgets('on $preset the notices as cards under the title, the newest at the bottom; no app bar', (
      tester,
    ) async {
      preset.apply(tester);
      await pumpScreen(tester, [notification(2), notification(1)]);
      expect(tester.takeException(), isNull);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(WatchNoticeCard), findsWidgets);
      final newest = tester.getRect(find.text('Notification 2'));
      final older = tester.getRect(find.text('Notification 1', skipOffstage: false));
      expect(newest.top, greaterThan(older.top));
    });
  }

  testWidgets('a long press asks on the watch confirm; yes deletes that notice', (tester) async {
    final handle = tester.ensureSemantics();
    watchPresets.last.apply(tester);
    await pumpScreen(tester, [notification(2), notification(1)]);

    await longPressViaSemantics(tester, find.bySemanticsLabel(RegExp('^Notification 2')));
    await tester.pumpAndSettle();
    expect(find.byType(WatchConfirm), findsOneWidget);
    expect(find.text('Delete this notification?'), findsOneWidget);
    await tapViaSemantics(tester, find.bySemanticsIdentifier(confirmDialogYesButtonId));
    await tester.pumpAndSettle();

    verify(() => local.queueDeletes([2])).called(1);
    handle.dispose();
  });

  testWidgets('an unseen notice is marked seen as it shows and stays tinted while on the face', (tester) async {
    watchPresets.last.apply(tester);
    // What the real store does: the queued mark is announced at once.
    when(() => local.upsertOutboxNotification(any())).thenAnswer((invocation) async {
      events.add(
        SystemNotificationOutboxUpdate(invocation.positionalArguments.single as SystemNotificationOutboxEntry),
      );
    });
    final unseen = SystemNotification(
      id: 3,
      title: 'Notification 3',
      content: 'Content 3',
      type: SystemNotificationType.security,
      seen: false,
      createdAt: DateTime.utc(2026, 10, 3),
      updatedAt: DateTime.utc(2026, 10, 3),
    );
    await pumpScreen(tester, [unseen]);

    await tester.pumpAndSettle();
    verify(() => local.upsertOutboxNotification(any())).called(1);
    expect(tester.widget<WatchNoticeCard>(find.byType(WatchNoticeCard)).unread, isTrue);
  });

  testWidgets('nothing yet is a state page', (tester) async {
    watchPresets.first.apply(tester);
    await pumpScreen(tester, const []);

    expect(find.byType(WatchStatePage), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
  });
}
