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

  /// The other party in the call, depending on the call direction
  late final String participant = direction == CallDirection.outgoing ? callee : caller;

  /// The other party's number in the call, depending on the call direction
  late final String? participantNumber = direction == CallDirection.outgoing ? calleeNumber : callerNumber;

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
  Iterable<CdrRecord> mergeWithUpdate(CdrRecord v) {
    final isNew = !any((n) => n.callId == v.callId);
    if (isNew) {
      return [v, ...this];
    } else {
      return map((n) => n.callId == v.callId ? v : n);
    }
  }

  Iterable<CdrRecord> mergeWithRemove(String callId) {
    return where((n) => n.callId != callId);
  }

  /// Appends older records, and replaces in place a call id the list already
  /// holds rather than showing it twice.
  ///
  /// A record can arrive twice: the boundary of one history range overlaps the
  /// next, and a range boundary on the wire is only as precise as the backend's
  /// own resolution. The copy that arrived LAST wins, which is what the store
  /// does with the same pair - one call can be reported under one id with
  /// different data, and a list left holding the older copy would disagree with
  /// the database it was read from.
  Iterable<CdrRecord> mergeWithHistory(Iterable<CdrRecord> history) {
    final byId = {for (final cdr in history) cdr.callId: cdr};
    final merged = [for (final cdr in this) byId.remove(cdr.callId) ?? cdr];
    return [...merged, ...history.where((cdr) => byId.containsKey(cdr.callId))];
  }
}
