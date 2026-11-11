import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/app_time.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/system_notification.dart';
import 'package:webtrit_phone/models/system_notification_outbox_entry.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../system_notifications.dart';

/// The notices on a watch, as cards, newest at the bottom as on the phone, an
/// unseen one tinted and marked seen as it shows. A tap opens the whole notice
/// on the text page; a long press deletes it after the watch confirm, in place
/// of the swipe. Deleting all stays on the phone.
class SystemNotificationsScreenWatch extends StatelessWidget {
  const SystemNotificationsScreenWatch({super.key, required this.scrollController});

  /// The screen's scroll controller, which fetches older notices as the list
  /// nears its end.
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.system_notifications_screen_title;
    final cubit = context.read<SystemNotificationsScreenCubit>();
    final timeOrDateFormat = context.read<AppTime>().timeOrDateFormat(Localizations.localeOf(context));
    return Scaffold(
      body: BlocBuilder<SystemNotificationsScreenCubit, SystemNotificationScreenState>(
        builder: (context, state) {
          if (state.isLoading) {
            return WatchStatePage.loading(title: title, progressLabel: l10n.common_SemanticsLabel_loading);
          }
          if (state.notifications.isEmpty) {
            return WatchStatePage(
              title: title,
              icon: const Icon(Icons.notifications_none),
              message: l10n.system_notifications_screen_list_empty,
            );
          }
          return WatchScrollList.builder(
            title: title,
            reverse: true,
            controller: scrollController,
            spacing: context.adaptiveMetrics.gap,
            itemCount: state.notifications.length,
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return KeyedSubtree(
                key: ValueKey(notification.id),
                child: SystemNotificationWatchCard(
                  notification: notification,
                  time: timeOrDateFormat.format(notification.createdAt),
                  seen: notification.seen || state.outboxEntries.hasSeen(notification.id),
                  onSeen: () => cubit.markAsSeen(notification),
                  onOpen: () => _open(context, notification),
                  onDelete: () => _confirmDelete(context, notification),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// The whole notice on the text page.
  void _open(BuildContext context, SystemNotification notification) {
    unawaited(
      context.router.root.navigate(WatchTextScreenPageRoute(text: '${notification.title}\n\n${notification.content}')),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SystemNotification notification) async {
    final l10n = context.l10n;
    final cubit = context.read<SystemNotificationsScreenCubit>();
    final delete = await ConfirmDialog.showDangerous(
      context,
      title: l10n.system_notifications_Watch_deleteQuestion,
      content: l10n.system_notifications_Watch_deleteContent,
    );
    if (delete == true) await cubit.deleteNotification(notification);
  }
}
