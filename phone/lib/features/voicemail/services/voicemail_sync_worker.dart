import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

/// Core pushes as soon as the mailbox reports the message, so a short wait is
/// enough; it is there to fold the pushes of one burst into one read.
const _newMessageRefreshDelay = Duration(seconds: 1);

/// Owns the mailbox worker and its polling registration.
///
/// Scheduled refreshes and new-message pushes use the same polling task, so
/// they share one lifecycle, single-flight boundary, and backoff policy.
final class VoicemailSync extends PollingWorkerOwner<VoicemailSyncWorker> {
  VoicemailSync({
    required super.worker,
    required super.pollingService,
    required super.interval,
    this.newMessageRefreshDelay = _newMessageRefreshDelay,
  });

  final Duration newMessageRefreshDelay;

  /// Requests one read of the mailbox after a push said a message arrived.
  ///
  /// A burst of pushes - the backend reports every change of the mailbox -
  /// becomes one read through the task's trailing-edge debounce, and a push
  /// that comes while offline or in the background waits for the connection
  /// or the resume instead of failing.
  void requestRefresh() {
    invalidatePollingTask(after: newMessageRefreshDelay);
  }
}

/// Reads the mailbox into the local store.
///
/// [VoicemailRepository] does the reading and stays owned by the session's
/// repositories; this worker only puts it under [PollingService], so disposing
/// the worker leaves the repository alone.
class VoicemailSyncWorker implements PollingWorker {
  VoicemailSyncWorker(this._repository);

  final VoicemailRepository _repository;

  bool _disposed = false;

  /// Inactive also once the backend has said the session has no voicemail.
  @override
  bool get isActive => !_disposed && _repository.isActive;

  @override
  Future<void> refresh() async {
    if (_disposed) {
      throw StateError('Cannot refresh a disposed voicemail sync worker.');
    }
    await _repository.refresh();
  }

  @override
  Future<void> dispose() {
    _disposed = true;
    return Future<void>.value();
  }
}
