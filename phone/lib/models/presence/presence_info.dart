import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

import 'presence_activity.dart';

enum PresenceInfoSource { sip, direct, unknown }

class PresenceInfo extends Equatable {
  const PresenceInfo({
    required this.id,
    required this.number,
    required this.available,
    required this.note,
    required this.statusIcon,
    required this.device,
    required this.timeOffsetMin,
    required this.timestamp,
    required this.activities,
    required this.source,
    required this.arrivalTime,
  });

  final String id;
  final String number;
  final bool available;
  final String note;
  final String? statusIcon;
  final String? device;
  final int? timeOffsetMin;
  final DateTime? timestamp;
  final List<PresenceActivity> activities;
  final PresenceInfoSource source;
  final DateTime arrivalTime;

  /// When the state this record describes began.
  ///
  /// That is the publisher's [timestamp]: Core keeps it through the periodic
  /// re-announcements, and it survives a Core restart, which [arrivalTime]
  /// does not - after a restart every record "arrives" again in whatever
  /// order the devices happen to re-announce.
  ///
  /// The timestamp comes from the device's own clock, so it is not taken
  /// beyond what is possible: a state cannot have begun after Core heard of
  /// it, and a time later than the arrival is cut back to the arrival. A
  /// record without a timestamp is placed by its arrival. A device whose
  /// clock runs slow is not corrected by this and can lose to an older state
  /// of another device.
  DateTime get stateBeganAt {
    final claimed = timestamp;
    return claimed == null || claimed.isAfter(arrivalTime) ? arrivalTime : claimed;
  }

  @override
  List<Object?> get props => [
    id,
    number,
    available,
    note,
    statusIcon,
    device,
    timeOffsetMin,
    timestamp,
    activities,
    source,
    arrivalTime,
  ];

  @override
  String toString() {
    return 'PresenceInfo{id: $id, number: $number, available: $available, note: $note, statusIcon: $statusIcon, device: $device, '
        'timeOffsetMin: $timeOffsetMin, timestamp: $timestamp, activities: $activities, source: $source, arrivalTime: $arrivalTime}';
  }
}

extension PresenceInfoListExtension on Iterable<PresenceInfo> {
  /// The records of the first source that has any: direct, then SIP.
  ///
  /// A direct record is what the contact's own app said about them. A SIP
  /// record is what the PBX last heard from one of their devices, and for
  /// somebody who uses this app it is at best an echo of the direct one.
  /// Reading both as equals let an old publication on the PBX outvote what the
  /// person had just set in the app.
  ///
  /// A number nobody publishes for has no SIP record at all - Core does not
  /// pass on the empty `closed` a PBX answers a subscription with - so for it
  /// this is empty and the caller falls back to registration.
  List<PresenceInfo> get leadingSource {
    final direct = where((p) => p.source == PresenceInfoSource.direct).toList();
    return direct.isNotEmpty ? direct : toList();
  }

  /// Whether the contact can be reached, by the first source that says so:
  /// the direct records, then the SIP ones, then [registered] - whether their
  /// phone is registered on the PBX, as the contact list reports it.
  ///
  /// Among several records of one source it is what [primary] says, not "any
  /// of them": a device left on its default would otherwise keep a person
  /// green after they had set themselves unavailable on another.
  ///
  /// The last step is for the many devices that take calls without ever
  /// publishing a status. A published `closed` is not second-guessed by it: a
  /// device that said so meant it, registered or not. With nothing published
  /// and [registered] unknown the answer is no, and the caller is expected not
  /// to show a status at all.
  bool reachable({required bool? registered}) => primary?.available ?? registered ?? false;

  /// The record a contact is described by: among the records of the
  /// [leadingSource], the one whose state began last.
  ///
  /// A person with several devices has a record per device, and each keeps
  /// saying what was last set on it. What they set most recently is their
  /// status; picking the "best" record instead let an old `available` on one
  /// device hide a `do not disturb` just set on another.
  ///
  /// One exception: a record that is on the phone wins whenever it began. A
  /// call is a fact about the person, not a status they chose, and it holds
  /// whichever device they last touched.
  PresenceInfo? get primary => leadingSource._mostRelevant;

  PresenceInfo? get _mostRelevant {
    if (isEmpty) return null;

    final firstInCall = firstWhereOrNull((p) => p.activities.contains(PresenceActivity.onThePhone));
    if (firstInCall != null) return firstInCall;

    return sortedByUpdate.first;
  }

  PresenceActivity? get primaryActivity {
    if (isEmpty) return null;

    final primaryPresence = primary;
    final inCall = primaryPresence?.activities.contains(PresenceActivity.onThePhone) ?? false;
    if (inCall) return PresenceActivity.onThePhone;
    return primaryPresence?.activities.firstOrNull;
  }

  String? get primaryStatusIcon {
    if (isEmpty) return null;
    final primaryPresence = primary;
    return primaryPresence?.statusIcon;
  }

  String? get primaryNote {
    if (isEmpty) return null;
    final primaryPresence = primary;
    return primaryPresence?.note;
  }

  /// Newest first, by [PresenceInfo.stateBeganAt]; a tie goes to the record
  /// Core heard of later.
  List<PresenceInfo> get sortedByUpdate {
    return sorted((a, b) {
      final byStart = b.stateBeganAt.compareTo(a.stateBeganAt);
      return byStart != 0 ? byStart : b.arrivalTime.compareTo(a.arrivalTime);
    });
  }
}
