import 'dart:async';

import 'package:logging/logging.dart';

import 'feature_access.dart';

final _logger = Logger('StartupFeatureAccessCheck');

/// Answers, once for a run of the app, whether the session it started with is
/// already behind what the backend offers.
///
/// A started app builds its configuration from the system info it stored
/// before, and a session keeps the configuration it was mounted with. The
/// backend is asked only once the session runs, so what it answers then would
/// wait in the store for the next start: a capability turned off stayed in the
/// app through one restart, and one turned on stayed away through one.
///
/// The first session of a run asks here; the answer comes when that first read
/// has landed. Later sessions get no answer: they follow a login, which reads
/// the backend before it mounts one, or the restart this answer caused.
class StartupFeatureAccessCheck {
  StartupFeatureAccessCheck({
    required Stream<Object?> systemInfoReads,
    required Future<FeatureAccess> Function() current,
  }) : _systemInfoReads = systemInfoReads,
       _current = current,
       _asked = false;

  /// For a host that supplies the configuration itself: nothing read from the
  /// backend can put its session behind.
  StartupFeatureAccessCheck.never() : _systemInfoReads = null, _current = null, _asked = true;

  /// Emits when a system info answer has been stored.
  final Stream<Object?>? _systemInfoReads;

  /// What a session mounted now would run on.
  final Future<FeatureAccess> Function()? _current;

  bool _asked;

  /// The configuration a session mounted now would get, when the first read of
  /// the backend has left [mounted] behind; null when it has not, and for
  /// every call but the first of the run.
  ///
  /// Does not complete while the backend has not been read.
  Future<FeatureAccess?> changedSince(FeatureAccess mounted) async {
    final systemInfoReads = _systemInfoReads;
    final current = _current;
    if (_asked || systemInfoReads == null || current == null) {
      return null;
    }
    _asked = true;

    try {
      await systemInfoReads.first;
    } on StateError {
      // The app is shutting down: the stream closed before a read landed.
      return null;
    }
    final now = await current();
    if (now == mounted) {
      _logger.info('the session runs on what the backend offers');
      return null;
    }
    _logger.info('the backend offers another configuration than the session was started with');
    return now;
  }
}
