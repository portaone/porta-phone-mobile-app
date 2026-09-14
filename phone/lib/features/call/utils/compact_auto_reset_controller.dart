import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final _logger = Logger('CompactAutoResetController');

/// Manages a state that automatically reverts from an expanded state to a
/// compact state after a specified duration of inactivity.
///
/// The compact state exists only while the controller is active: deactivating
/// expands, and an inactive controller refuses to compact. So "compact with no
/// timer to undo it" cannot be reached from any caller.
class CompactAutoResetController extends ChangeNotifier {
  static const int defaultAutoResetSeconds = 5;

  CompactAutoResetController({
    this.autoResetSeconds = defaultAutoResetSeconds,
    bool initialCompact = false,
    bool initiallyActive = false,
  }) : assert(autoResetSeconds > 0, 'autoResetSeconds must be > 0'),
       _compact = initialCompact,
       _active = initiallyActive {
    if (_active && !_compact) {
      _startTimer(reason: 'init');
    }
  }

  /// The duration in seconds to wait before automatically switching to compact mode.
  final int autoResetSeconds;

  /// Internal timer used to track the auto-reset duration.
  Timer? _timer;

  /// Tracks whether the auto-reset functionality is currently enabled.
  bool _active;

  /// Tracks the current visual state (compact vs expanded).
  bool _compact;

  /// Whether the controller allows auto-reset behavior.
  bool get active => _active;

  /// Whether the UI is currently in compact mode.
  bool get compact => _compact;

  /// Returns true if the countdown timer is currently running.
  @visibleForTesting
  bool get isRunning => _timer?.isActive ?? false;

  /// Toggles the active state of the controller.
  ///
  /// When set to `true`, the timer starts, and the state expands.
  /// When set to `false`, the timer stops, and the state remains expanded.
  void setActive(bool value, {String reason = 'setActive'}) {
    if (_active == value) return;

    _active = value;
    _logger.info('$reason: active changed to $_active');

    // Always expand (show controls) when activity state changes.
    _compact = false;

    if (_active) {
      _startTimer(reason: 'became active');
    } else {
      _cancelTimer(reason: 'became inactive');
    }

    notifyListeners();
  }

  /// Convenience method to enable the controller.
  void activate() => setActive(true, reason: 'activate()');

  /// Convenience method to disable the controller.
  void deactivate() => setActive(false, reason: 'deactivate()');

  /// Toggles the compact state.
  ///
  /// If currently compact, it expands and starts the timer.
  /// If currently expanded, it compacts and stops the timer - while the
  /// controller is active; an inactive one stays expanded, see [setCompact].
  void toggle() {
    if (_compact) {
      setCompact(false, reason: 'toggle(expand)');
    } else {
      setCompact(true, reason: 'toggle(hide)');
    }
  }

  /// Manually sets the compact state.
  ///
  /// Compacting is refused while the controller is inactive. Inactive means
  /// nothing wants the UI out of the way, and a compact state reached without
  /// the timer would be one nothing reverts: the timer is the only thing that
  /// ever expands on its own. So an inactive controller is always expanded,
  /// whoever asks - a tap, a key, a future caller.
  void setCompact(bool value, {String reason = 'setCompact'}) {
    if (value && !_active) {
      _logger.fine('$reason: compacting refused, the controller is inactive');
      return;
    }
    if (_compact == value) return;

    _compact = value;
    _logger.info('$reason: compact changed to $_compact');

    if (_compact) {
      _cancelTimer(reason: 'compacted');
    } else {
      _startTimer(reason: 'expanded');
    }

    notifyListeners();
  }

  void _startTimer({required String reason}) {
    _cancelTimer(reason: 'restart');
    _timer = Timer(Duration(seconds: autoResetSeconds), _handleTimeout);
  }

  /// Handles the timeout event and switches to compact mode.
  void _handleTimeout() {
    if (!_active) return;
    _logger.info('timeout: auto-compacting');
    _compact = true;
    notifyListeners();
  }

  /// Cancels the current timer if it exists.
  void _cancelTimer({required String reason}) {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes the controller by canceling the timer and resetting state.
  @override
  void dispose() {
    _cancelTimer(reason: 'dispose');
    super.dispose();
  }
}
