import 'package:equatable/equatable.dart';

import 'active_session.dart';

/// When the core ends the account's idle sessions.
///
/// The core answers with the period in force rather than with the user's own
/// choice: [inactivityTimeoutDays] is the shorter of that choice and
/// [installationMaxDays]. A choice equal to the installation's period is
/// therefore the same thing as no choice, and a choice an administrator has
/// since overtaken by a shorter limit is never seen at all.
class SessionAutoTerminate extends Equatable {
  const SessionAutoTerminate({this.inactivityTimeoutDays, this.installationMaxDays});

  /// The ready-made periods offered: one week, one month, three months.
  static const presetDays = [7, 30, 90];

  /// The longest period the core accepts where the installation sets none.
  static const maxDaysWithoutInstallationLimit = 365;

  /// Idle days after which the account's sessions end; null - they never do.
  final int? inactivityTimeoutDays;

  /// The installation's own period, set by its administrator; null - none.
  final int? installationMaxDays;

  /// The longest period the user may choose.
  int get maxDays => installationMaxDays ?? maxDaysWithoutInstallationLimit;

  /// Whether the period in force is the one the user gets by choosing nothing.
  bool get isInstallationDefault => inactivityTimeoutDays == installationMaxDays;

  /// The presets that are a choice of their own: shorter than the installation's
  /// period (one equal to it is the default, a longer one the core refuses).
  List<int> get presets => [
    for (final days in presetDays)
      if (installationMaxDays == null ? days <= maxDays : days < installationMaxDays!) days,
  ];

  @override
  List<Object?> get props => [inactivityTimeoutDays, installationMaxDays];
}

/// The account's sessions together with when idle ones end - one answer of the
/// core. [autoTerminate] is null where the core does not end idle sessions.
class SessionList extends Equatable {
  const SessionList({this.sessions = const [], this.autoTerminate});

  final List<ActiveSession> sessions;

  final SessionAutoTerminate? autoTerminate;

  @override
  List<Object?> get props => [sessions, autoTerminate];
}

/// Why the core refused a period the user chose.
enum SessionAutoTerminateRefusal {
  /// Longer than the installation allows - its administrator lowered the limit
  /// after the screen read it.
  exceedsInstallationLimit,

  /// The adapter no longer lets users choose.
  notSupported,
}

class SessionAutoTerminateRefusedException implements Exception {
  const SessionAutoTerminateRefusedException(this.reason);

  final SessionAutoTerminateRefusal reason;

  @override
  String toString() => 'SessionAutoTerminateRefusedException($reason)';
}
