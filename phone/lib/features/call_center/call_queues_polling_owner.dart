import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

/// Owns the queue polling task for however many screens are showing the
/// queues at once.
///
/// Both placements read one repository, and [PollingService] keys a task by
/// its listener: registering twice returns the same handle, and unregistering
/// removes it for everyone. Without counting the readers, closing the settings
/// screen would stop the reads for the bottom-menu section that is still
/// mounted behind it - and that section, having already run its initState,
/// would never start them again.
class CallQueuesPollingOwner implements Disposable {
  CallQueuesPollingOwner({
    required PollingService pollingService,
    required CallQueuesRepository repository,
    required Duration interval,
  }) : _pollingService = pollingService,
       _repository = repository,
       _interval = interval;

  final PollingService _pollingService;
  final CallQueuesRepository _repository;
  final Duration _interval;

  int _readers = 0;
  PollingTaskHandle? _task;

  /// A screen showing the queues has opened.
  ///
  /// A repository that has stopped - the deployment does not offer the feature
  /// - is not worth a task the service would unregister on its first tick.
  void acquire() {
    _readers++;
    if (_task != null || !_repository.isActive) return;

    _task = _pollingService.register(PollingRegistration(listener: _repository, interval: _interval));
  }

  /// A screen showing them has gone; the reads stop with the last one.
  void release() {
    if (_readers == 0) return;

    _readers--;
    if (_readers > 0) return;

    _task?.unregister();
    _task = null;
  }

  @override
  Future<void> dispose() async {
    _readers = 0;
    _task?.unregister();
    _task = null;
  }
}
