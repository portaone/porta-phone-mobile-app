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
import 'system_notifications_screen_styles.dart';

class SystemNotificationsScreen extends StatefulWidget {
  const SystemNotificationsScreen({super.key});

  @override
  State<SystemNotificationsScreen> createState() => _SystemNotificationsScreenState();
}

class _SystemNotificationsScreenState extends State<SystemNotificationsScreen> {
  late final scrollController = ScrollController();
  late final cubit = context.read<SystemNotificationsScreenCubit>();

  bool scrolledAway = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      final maxScroll = scrollController.position.maxScrollExtent;
      final position = scrollController.position.pixels;
      final scrollRemaining = maxScroll - position;

      const hystoryFetchScrollThreshold = 500.0;
      final shouldFetch = scrollRemaining < hystoryFetchScrollThreshold;
      final canFetch = !cubit.state.historyEndReached && !cubit.state.fetchingHistory;
      if (shouldFetch && canFetch) cubit.fetchHistory();

      const scrolledThreshold = 1000;
      final scrolledAway = position > scrolledThreshold;
      if (this.scrolledAway != scrolledAway) setState(() => this.scrolledAway = scrolledAway);
    });
  }

  void scrollToBottom() {
    scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutExpo);
  }

  void markAsSeen(SystemNotification notification) {
    cubit.markAsSeen(notification);
  }

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// The notices as cards, newest at the bottom as on the phone, an unseen one
  /// tinted and marked seen as it shows. A tap opens the whole notice on the
  /// text page; a long press deletes it after the watch confirm, in place of
  /// the swipe. Deleting all stays on the phone.
  Widget _watch(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.system_notifications_screen_title;
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
                  onSeen: () => markAsSeen(notification),
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
    final delete = await ConfirmDialog.showDangerous(
      context,
      title: l10n.system_notifications_Watch_deleteQuestion,
      content: l10n.system_notifications_Watch_deleteContent,
    );
    if (delete == true) await cubit.deleteNotification(notification);
  }

  Widget _handset(BuildContext context) {
    final timeOrDateFormat = context.read<AppTime>().timeOrDateFormat(Localizations.localeOf(context));
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(context.l10n.system_notifications_screen_title),
        flexibleSpace: BlurredSurface.fromStyle(
          Theme.of(context).extension<SystemNotificationsScreenStyles>()?.primary?.appBarBlurredSurface,
        ),
        // Themes that configure no bar color keep a translucent bar instead of
        // the opaque framework default.
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Colors.transparent,
        actions: const [SystemNotificationsDeleteAllAction()],
      ),
      body: BlocBuilder<SystemNotificationsScreenCubit, SystemNotificationScreenState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.notifications.isEmpty) {
            return Center(child: Text(context.l10n.system_notifications_screen_list_empty));
          }

          return ScrollToBottomOverlay(
            scrolledAway: scrolledAway,
            onScrollToBottom: scrollToBottom,
            child: ListView.builder(
              controller: scrollController,
              reverse: true,
              scrollCacheExtent: .viewport(2),
              shrinkWrap: true,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              itemCount: state.notifications.length + 1,
              itemBuilder: (context, index) {
                final historyIndicatorPosition = state.notifications.length;
                if (index == historyIndicatorPosition) return HistoryFetchIndicator(state.fetchingHistory);
                final notifiaction = state.notifications[index];
                final pendingSeen = state.outboxEntries.hasSeen(notifiaction.id);

                return SizedBox(
                  key: Key(notifiaction.id.toString()),
                  child: SystemNotificationListTile(
                    notifiaction,
                    timeOrDateFormat: timeOrDateFormat,
                    seenPending: pendingSeen,
                    onSeen: () => markAsSeen(notifiaction),
                    onDelete: () => cubit.deleteNotification(notifiaction),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
