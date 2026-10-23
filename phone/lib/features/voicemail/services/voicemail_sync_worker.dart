import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

/// Owns the mailbox worker and its polling registration.
///
/// The standard owner is the whole of it for now: one lifecycle, one
/// single-flight boundary, one backoff policy, and a place for a domain
/// trigger to ask for a read through the same task.
final class VoicemailSync extends PollingWorkerOwner<VoicemailSyncWorker> {
  VoicemailSync({required super.worker, required super.pollingService, required super.interval});
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
