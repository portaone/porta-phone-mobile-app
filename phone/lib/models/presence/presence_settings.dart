import 'package:equatable/equatable.dart';

import 'presence_activity.dart';

class PresenceSettings extends Equatable {
  const PresenceSettings({
    required this.available,
    required this.note,
    required this.statusIcon,
    required this.device,
    required this.timeOffsetMin,
    required this.timestamp,
    required this.activity,
    required this.dndMode,
  });

  final bool available;
  final String note;
  final String? statusIcon;
  final String device;

  /// Minutes east of UTC of the zone the phone was in when the status was set.
  final int timeOffsetMin;

  /// When the status was set. What the app sets and stores is in UTC; a local
  /// time is read as the wall clock of [timeOffsetMin].
  final DateTime timestamp;
  final PresenceActivity? activity;
  final bool dndMode;

  bool isBlank() {
    return this == PresenceSettings.blank(device: device);
  }

  factory PresenceSettings.blank({required String device}) {
    final setAt = _now();
    return PresenceSettings(
      available: true,
      note: '',
      statusIcon: null,
      device: device,
      timeOffsetMin: setAt.timeOffsetMin,
      timestamp: setAt.timestamp,
      activity: null,
      dndMode: false,
    );
  }

  PresenceSettings copyWithAvailable(bool available) {
    final setAt = _now();
    return PresenceSettings(
      available: available,
      note: note,
      statusIcon: statusIcon,
      device: device,
      timeOffsetMin: setAt.timeOffsetMin,
      timestamp: setAt.timestamp,
      activity: activity,
      dndMode: dndMode,
    );
  }

  PresenceSettings copyWithNote(String note) {
    final setAt = _now();
    return PresenceSettings(
      available: available,
      note: note,
      statusIcon: statusIcon,
      device: device,
      timeOffsetMin: setAt.timeOffsetMin,
      timestamp: setAt.timestamp,
      activity: activity,
      dndMode: dndMode,
    );
  }

  PresenceSettings copyWithStatusIcon(String? statusIcon) {
    final setAt = _now();
    return PresenceSettings(
      available: available,
      note: note,
      statusIcon: statusIcon,
      device: device,
      timeOffsetMin: setAt.timeOffsetMin,
      timestamp: setAt.timestamp,
      activity: activity,
      dndMode: dndMode,
    );
  }

  PresenceSettings copyWithActivity(PresenceActivity? activity) {
    final setAt = _now();
    return PresenceSettings(
      available: available,
      note: note,
      statusIcon: statusIcon,
      device: device,
      timeOffsetMin: setAt.timeOffsetMin,
      timestamp: setAt.timestamp,
      activity: activity,
      dndMode: dndMode,
    );
  }

  PresenceSettings copyWithDndMode(bool dndMode) {
    final setAt = _now();
    return PresenceSettings(
      available: available,
      note: note,
      statusIcon: statusIcon,
      device: device,
      timeOffsetMin: setAt.timeOffsetMin,
      timestamp: setAt.timestamp,
      activity: activity,
      dndMode: dndMode,
    );
  }

  @override
  List<Object?> get props => [available, note, statusIcon, device, timeOffsetMin, timestamp, activity, dndMode];

  @override
  String toString() {
    return 'PresenceSettings{available: $available, note: $note, statusIcon: $statusIcon, device: $device, '
        'timeOffsetMin: $timeOffsetMin, timestamp: $timestamp, activity: $activity, dndMode: $dndMode}';
  }

  /// The moment a status is set and the offset of the zone the phone is in at
  /// that moment, from one reading of the clock.
  ///
  /// Taken apart, the two could straddle a change of zone and no longer
  /// describe each other. The moment is kept in UTC: a local time is turned
  /// into its fields by the zone in force when they are first read, which need
  /// not be the zone the offset was taken in.
  static ({DateTime timestamp, int timeOffsetMin}) _now() {
    final now = DateTime.now();
    return (timestamp: now.toUtc(), timeOffsetMin: now.timeZoneOffset.inMinutes);
  }
}
