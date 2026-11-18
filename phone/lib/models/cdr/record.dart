import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/extensions/iterable.dart';
import 'package:webtrit_phone/models/models.dart';

/// Call status of a record, mirroring `api.CdrStatus`.
///
/// [error] is a status of its own and never a catch-all: what this build does
/// not model becomes [unrecognized]. [failed] and [completedElsewhere] were
/// reported as [error] for as long as this enum stopped short of the contract
/// and the fallback swallowed the difference.
enum CdrStatus { accepted, declined, missed, failed, completedElsewhere, error, unrecognized }

class CdrRecord extends Equatable {
  CdrRecord({
    required this.callId,
    required this.direction,
    required this.status,
    required this.callee,
    required this.calleeNumber,
    required this.caller,
    required this.callerNumber,
    required this.connectTime,
    required this.disconnectTime,
    required this.disconnectReason,
    required this.duration,
    this.recordingId,
  });

  final String callId;
  final CallDirection direction;
  final CdrStatus status;
  final String callee;
  final String? calleeNumber;
  final String caller;
  final String? callerNumber;
  final DateTime connectTime;
  final DateTime disconnectTime;
  final String disconnectReason;
  final Duration duration;
  final dynamic recordingId;

  /// What tells this record from the others of its call id: the backend reports several records
  /// under one Call-ID (a transfer back, a retried transfer, the legs of an IVR call), the store
  /// keeps one per call id, connect time and direction, and a list keys its rows by the same.
  late final String recordKey = '$callId|${connectTime.microsecondsSinceEpoch}|${direction.name}';

  /// The unattributed copy of an IVR call: the same call id and moment as [other], no direction
  /// of its own while [other] has one. Not shown beside it.
  bool isUnattributedCopyOf(CdrRecord other) =>
      direction == CallDirection.unknown &&
      other.direction != CallDirection.unknown &&
      callId == other.callId &&
      connectTime == other.connectTime;

  /// The other party in the call, depending on the call direction
  late final String participant = direction == CallDirection.outgoing ? callee : caller;

  /// The other party's number in the call, depending on the call direction
  late final String? participantNumber = direction == CallDirection.outgoing ? calleeNumber : callerNumber;

  /// An incoming call nobody answered - declined, failed or taken on another
  /// device is not one: what the Missed list keeps, and what a list marks as
  /// missed.
  bool get isMissedIncoming => status == CdrStatus.missed && direction == CallDirection.incoming;

  /// Tries to parse the [disconnectReason] string into a known [CdrDisconnectReason] enum value.
  /// Returns null if no match is found, so consumer can decide to use the raw string instead.
  late final CdrDisconnectReason? disconnectReasonEnum = CdrDisconnectReason.values.firstWhereOrNull(
    (r) => r.rawValue.toLowerCase().trim() == disconnectReason.toLowerCase().trim(),
  );

  @override
  List<Object?> get props => [
    callId,
    direction,
    status,
    callee,
    calleeNumber,
    caller,
    callerNumber,
    connectTime,
    disconnectTime,
    disconnectReason,
    duration,
    recordingId,
  ];
  @override
  String toString() =>
      'CdrRecord(callId: $callId, direction: $direction, status: $status, callee: $callee, calleeNumber: $calleeNumber, caller: $caller, callerNumber: $callerNumber, connectTime: $connectTime, disconnectTime: $disconnectTime, disconnectReason: $disconnectReason, duration: $duration, recordingId: $recordingId)';
}

extension CdrRecordIterableExtension on Iterable<CdrRecord> {
  /// Puts [v] in its place: a record the list holds already (by [CdrRecord.recordKey]) is
  /// replaced, a new one goes first. The unattributed copy of an IVR call the list holds attributed
  /// is left out, and an attributed one replaces the unattributed copy the list holds.
  Iterable<CdrRecord> mergeWithUpdate(CdrRecord v) {
    if (any((n) => v.isUnattributedCopyOf(n))) return this;
    final copy = firstWhereOrNull((n) => n.isUnattributedCopyOf(v));
    if (copy != null) return map((n) => identical(n, copy) ? v : n);
    final isNew = !any((n) => n.recordKey == v.recordKey);
    if (isNew) {
      return [v, ...this];
    } else {
      return map((n) => n.recordKey == v.recordKey ? v : n);
    }
  }

  Iterable<CdrRecord> mergeWithRemove(String callId) {
    return where((n) => n.callId != callId);
  }

  /// Appends older records, and replaces in place a record ([CdrRecord.recordKey]) the list
  /// already holds rather than showing it twice.
  ///
  /// A record can arrive twice: the boundary of one history range overlaps the
  /// next, and a range boundary on the wire is only as precise as the backend's
  /// own resolution. The copy that arrived LAST wins, which is what the store
  /// does with the same pair - one call can be reported under one id with
  /// different data, and a list left holding the older copy would disagree with
  /// the database it was read from.
  Iterable<CdrRecord> mergeWithHistory(Iterable<CdrRecord> history) {
    final byKey = {for (final cdr in history) cdr.recordKey: cdr};
    final merged = [for (final cdr in this) byKey.remove(cdr.recordKey) ?? cdr];
    return [...merged, ...history.where((cdr) => byKey.containsKey(cdr.recordKey))];
  }
}
