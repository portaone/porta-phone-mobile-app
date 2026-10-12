import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/system_notification.dart';
import 'package:webtrit_phone/models/system_notification_event.dart';
import 'package:webtrit_phone/models/system_notification_outbox_entry.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../services/system_notifications_outbox_worker.dart';
import '../services/system_notifications_reconciler.dart';

part 'system_notifications_screen_state.dart';

final _logger = Logger('SystemNotificationsCubit');

class SystemNotificationsScreenCubit extends Cubit<SystemNotificationScreenState> {
  SystemNotificationsScreenCubit(
    this._systemNotificationsLocalRepository,
    this._systemNotificationsRemoteRepository, {
    required SystemNotificationsOutbox outbox,
    this.pageSize = 50,
  }) : _outbox = outbox,
       super(const SystemNotificationScreenState(notifications: [], isLoading: true));

  final SystemNotificationsLocalRepository _systemNotificationsLocalRepository;
  final SystemNotificationsRemoteRepository _systemNotificationsRemoteRepository;
  final SystemNotificationsOutbox _outbox;
  final int pageSize;
  late final StreamSubscription _eventsSub;
  late final _reconciler = SystemNotificationsReconciler(
    _systemNotificationsLocalRepository,
    _systemNotificationsRemoteRepository,
  );

  Future<void> markAsSeen(SystemNotification notification) async {
    final seenOutboxEntry = SystemNotificationOutboxEntry(
      notificationId: notification.id,
      actionType: SnOutboxActionType.seen,
    );
    await _systemNotificationsLocalRepository.upsertOutboxNotification(seenOutboxEntry);
    // Queued first, so the mark survives a failed send; asking now only
    // saves it from waiting out the safety-net interval.
    _outbox.requestFlush();
  }

  /// Deletes one notification. It leaves the list at once, so the swipe that
  /// asked for it can always finish.
  Future<bool> deleteNotification(SystemNotification notification) async {
    await deleteNotifications([notification.id]);
    return true;
  }

  /// The ids "delete all" is over: every notification stored on this device,
  /// including history read on an earlier visit and no longer on screen.
  ///
  /// Only what the device holds. Older notifications the backend still has are
  /// not counted and not deleted. They come back, silently, the next time the
  /// app starts with an empty store and reads the history again - not by
  /// scrolling, since an emptied list has nothing to scroll.
  Future<List<int>> storedNotificationIds() => _systemNotificationsLocalRepository.getNotificationIds();

  /// Deletes the notifications with [ids] the way a seen receipt is sent.
  ///
  /// Queued first, so the delete survives being offline and the app being
  /// killed, and the notifications leave the list and the unseen count at
  /// once; asking for the flush only saves it from waiting out the interval.
  /// A delete the backend refuses is retried by the outbox, and the
  /// notifications stay hidden meanwhile - there is nothing to tell the
  /// person, as there is nothing for a receipt.
  Future<void> deleteNotifications(List<int> ids) async {
    if (ids.isEmpty) return;

    await _systemNotificationsLocalRepository.queueDeletes(ids);
    _outbox.requestFlush();
  }

  Future<void> fetchHistory() async {
    if (state.fetchingHistory || state.historyEndReached) return;

    emit(state.copyWith(fetchingHistory: true));
    try {
      final oldestDate = state.notifications.last.createdAt;
      var history = await _systemNotificationsLocalRepository.getNotifications(from: oldestDate, limit: pageSize);
      final shownFromStore = history.isNotEmpty;
      if (history.isEmpty) {
        history = await _systemNotificationsRemoteRepository.getHistory(since: oldestDate, limit: pageSize);
        await _systemNotificationsLocalRepository.upsertNotifications(history, silent: true);
      }
      if (history.isEmpty) {
        emit(state.copyWith(fetchingHistory: false, historyEndReached: true));
      } else {
        final notifications = state.notifications.mergeWithHistory(history).toList();
        emit(state.copyWith(notifications: notifications, fetchingHistory: false, historyEndReached: false));
      }
      // A page shown from the store may hold what was deleted elsewhere since
      // it was stored. It is shown at once all the same, and compared with the
      // backend behind the person's back; what is gone leaves the list through
      // the remove event. A page just read from the backend needs none of it.
      if (shownFromStore) unawaited(_reconcileShown(before: oldestDate, downTo: history.last.createdAt));
    } catch (e) {
      _logger.severe('Failed to load notifications', e);
      emit(state.copyWith(fetchingHistory: false));
    }
  }

  Future<void> _reconcileShown({required DateTime before, required DateTime downTo}) async {
    try {
      await _reconciler.reconcileBelow(before: before, downTo: downTo, limit: pageSize, stillWanted: _stillOpen);
    } catch (e, s) {
      // Offline, the backend refusing, or the screen closed on the way: the
      // page stays as the store has it. It is compared again the next time the
      // screen scrolls this far.
      _logger.warning('Failed to reconcile the shown notifications', e, s);
    }
  }

  // The comparison outlives the screen that asked for it - a sign-out may
  // have wiped the store by the time the page arrives - so it stops rather
  // than judge another session's store by this one's snapshot.
  void _stillOpen() {
    if (isClosed) throw StateError('The notifications screen was closed.');
  }

  Future<void> init() async {
    final outboxEntries = await _systemNotificationsLocalRepository.getOutboxNotifications();
    final notifications = await _systemNotificationsLocalRepository.getNotifications(limit: pageSize);
    emit(state.copyWith(notifications: notifications, outboxEntries: outboxEntries, isLoading: false));
    _eventsSub = _systemNotificationsLocalRepository.eventBus.listen(_handleLocalEvent);
  }

  void _handleLocalEvent(SystemNotificationEvent event) {
    _logger.info('Received event: $event');
    final _ = switch (event) {
      SystemNotificationUpdate() => _onSystemNotificationUpdate(event),
      SystemNotificationRemove() => _onSystemNotificationRemove(event),
      SystemNotificationOutboxUpdate() => _onSystemNotificationOutboxUpdate(event),
      SystemNotificationOutboxRemove() => _onSystemNotificationOutboxRemove(event),
    };
  }

  void _onSystemNotificationUpdate(SystemNotificationUpdate update) {
    final notification = update.notification;
    final notifications = state.notifications.mergeWithUpdate(notification);
    emit(state.copyWith(notifications: notifications.toList()));
  }

  void _onSystemNotificationRemove(SystemNotificationRemove remove) {
    final id = remove.id;
    final notifications = state.notifications.mergeWithRemove(id);
    emit(state.copyWith(notifications: notifications.toList()));
  }

  void _onSystemNotificationOutboxUpdate(SystemNotificationOutboxUpdate outboxUpdate) {
    final outboxEntry = outboxUpdate.entry;
    final notifications = state.outboxEntries.mergeWithUpdate(outboxEntry);
    emit(state.copyWith(outboxEntries: notifications.toList()));
  }

  void _onSystemNotificationOutboxRemove(SystemNotificationOutboxRemove outboxRemove) {
    final id = outboxRemove.id;
    var actionType = outboxRemove.actionType;
    final notifications = state.outboxEntries.mergeWithRemove(id, actionType);
    emit(state.copyWith(outboxEntries: notifications.toList()));
  }

  @override
  Future<void> close() async {
    await _eventsSub.cancel();
    return super.close();
  }
}
