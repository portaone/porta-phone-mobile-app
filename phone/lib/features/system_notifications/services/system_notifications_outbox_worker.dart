import 'dart:async';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/system_notification_event.dart';
import 'package:webtrit_phone/models/system_notification_outbox_entry.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_local_repository.dart';
import 'package:webtrit_phone/repositories/system_notifications/system_notifications_remote_repository.dart';
import 'package:webtrit_phone/services/services.dart';

final _logger = Logger('SystemNotificationsOutboxWorker');

/// How long a requested flush waits for the taps that may follow it.
const _flushDebounce = Duration(seconds: 1);

/// Owns the outbox worker and its polling registration.
///
/// The queue is filled by a tap, so the interval is only a safety net for what
/// a previous session left behind; [requestFlush] carries the ordinary case.
final class SystemNotificationsOutbox extends PollingWorkerOwner<SystemNotificationsOutboxWorker> {
  SystemNotificationsOutbox({
    required super.worker,
    required super.pollingService,
    required super.interval,
    this.flushDebounce = _flushDebounce,
  });

  /// How long a flush waits before running, so that reading a list of
  /// notifications is one send rather than one per tap.
  final Duration flushDebounce;

  /// Sends what the queue holds soon, instead of waiting for the next tick.
  ///
  /// The wait is the task's trailing-edge debounce, so reading through a
  /// screenful of notifications collapses into a single cycle rather than
  /// becoming one cycle per tap.
  ///
  /// A flush that would jump the queue while the backend is refusing it is
  /// dropped instead. Every cycle attempts the whole queue, so once sends are
  /// failing, one flush per tap is one request per tap per queued entry at a
  /// backend that is already failing - which is the herd backoff exists to
  /// prevent. The receipt is on disk either way; the retry the task has
  /// already scheduled is the right moment for it.
  ///
  /// Being offline is deliberately not this case: the task then reports
  /// [PollingTaskPhase.waitingForConnectivity], the service defers the cycle
  /// without a request of its own, and the queue leaves on the leading refresh
  /// that reconnecting runs.
  void requestFlush() {
    if (state.phase == PollingTaskPhase.failed) return;

    invalidatePollingTask(after: flushDebounce);
  }
}

/// Sends the locally queued system notification actions to the backend.
///
/// Marking a notification as seen, and deleting one, is written to the outbox
/// rather than sent from the screen, so the action survives being offline and
/// being killed. One [refresh] is one attempt at every pending entry;
/// [PollingService] owns scheduling, connectivity, single-flight, and the
/// delay between attempts.
class SystemNotificationsOutboxWorker implements PollingWorker {
  SystemNotificationsOutboxWorker(this.localRepo, this.remoteRepo) {
    // The queue is reconciled against what the backend confirms, so the
    // subscription belongs to the worker's own lifetime rather than to a
    // separate init() a caller has to remember.
    _confirmationsSub = localRepo.eventBus.listen(_onLocalEvent);
  }

  final SystemNotificationsLocalRepository localRepo;
  final SystemNotificationsRemoteRepository remoteRepo;

  late final StreamSubscription<SystemNotificationEvent> _confirmationsSub;

  @override
  bool get isActive => !_disposed;

  /// Attempts every pending entry once and returns when the queue has been
  /// walked.
  ///
  /// A failing entry does not stop the others: the cycle keeps going and then
  /// rethrows the first failure with its original stack trace, so polling
  /// applies backoff to a real error while the rest of the queue still drains.
  /// A failed entry is left exactly as it was, so the next cycle retries it.
  @override
  Future<void> refresh() async {
    _ensureActive();

    Object? firstError;
    StackTrace? firstStackTrace;

    // Deletes first: a receipt for a notification that is about to go is a
    // request for nothing, and the delete takes the receipt with it.
    try {
      await _sendDeletes();
    } catch (e, s) {
      _logger.warning('Sending queued deletes failed', e, s);
      firstError = e;
      firstStackTrace = s;
    }
    _ensureActive();

    final pending = await localRepo.getOutboxNotifications(
      actionType: SnOutboxActionType.seen,
      states: const [SnOutboxState.pending],
    );
    _ensureActive();

    if (pending.isNotEmpty) _logger.fine('Pending seen entries: ${pending.length}');

    for (final entry in pending) {
      _ensureActive();

      try {
        await remoteRepo.markSystemNotificationAsSeen(entry.notificationId);
      } catch (e, s) {
        // The entry stays pending and untouched. Giving up belongs to nobody
        // here: a receipt is worth retrying for as long as polling is willing
        // to retry, and a per-entry attempt count would be spent by whatever
        // happens to trigger a cycle - a burst of taps would abandon an entry
        // in seconds, which is the failure this migration set out to remove.
        _logger.warning('Sending seen notification ${entry.notificationId} failed', e, s);
        firstError ??= e;
        firstStackTrace ??= s;
        continue;
      }

      _ensureActive();
      // Deleted while the receipt was out: its outbox row went with it, and
      // writing it back would point at a row that is no longer there - the
      // foreign key refuses that and the whole cycle would fail on it.
      if (await localRepo.getNotificationById(entry.notificationId) == null) continue;
      _ensureActive();
      await localRepo.upsertOutboxNotification(entry.toSent());
      _logger.fine('Seen notification sent: ${entry.notificationId}');
    }

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  /// Sends every queued delete in one request and, once the backend has
  /// answered, drops the notifications for good.
  ///
  /// Every id sent is gone from the backend after the answer - deleted now, or
  /// already gone - so all of them go, not only those it reports. A failure
  /// leaves the queue as it was for the next cycle; the notifications stay
  /// hidden meanwhile.
  Future<void> _sendDeletes() async {
    final queued = await localRepo.getOutboxNotifications(
      actionType: SnOutboxActionType.delete,
      states: const [SnOutboxState.pending],
    );
    _ensureActive();
    if (queued.isEmpty) return;

    final ids = queued.map((entry) => entry.notificationId).toList();
    _logger.fine('Queued deletes: ${ids.length}');
    await remoteRepo.deleteNotifications(ids);
    _ensureActive();
    await localRepo.deleteNotifications(ids);
  }

  /// Drops an entry the backend has confirmed.
  ///
  /// Confirmation arrives through the sync worker: the notification comes back
  /// with `seen` set, which means the queued action no longer has anything to
  /// carry - including when another device sent it.
  void _onLocalEvent(SystemNotificationEvent event) {
    if (_disposed) return;
    if (event is SystemNotificationUpdate && event.notification.seen) {
      localRepo.deleteOutboxNotification(event.notification.id, SnOutboxActionType.seen);
    }
  }

  // In-flight I/O cannot be cancelled, but a retired worker must not start
  // another request or write after an async boundary.
  void _ensureActive() {
    if (_disposed) {
      throw StateError('Cannot refresh a disposed system notifications outbox worker.');
    }
  }

  bool _disposed = false;

  @override
  Future<void> dispose() async {
    if (_disposed) return;

    _logger.info('Disposing');
    _disposed = true;
    await _confirmationsSub.cancel();
  }
}
