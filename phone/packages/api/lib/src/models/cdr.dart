import 'package:freezed_annotation/freezed_annotation.dart';

import 'common.dart';

part 'cdr.freezed.dart';

part 'cdr.g.dart';

/// Call direction as the backend reports it.
///
/// `unknown` is a value of the contract, not a placeholder: the PortaSwitch
/// adapter reports it for a call leg whose `bit_flags` carry neither the
/// incoming nor the outgoing bit. `unrecognized` is the landing place for a
/// value this build does not know, so a contract that grows cannot break
/// decoding.
@JsonEnum(fieldRename: FieldRename.snake)
enum CdrDirection { incoming, outgoing, forwarded, unknown, unrecognized }

/// Call status as the backend reports it.
///
/// Every value of the contract is modelled; `unrecognized` carries whatever a
/// later contract adds. `error` is a status of its own and must not be used as
/// a catch-all.
@JsonEnum(fieldRename: FieldRename.snake)
enum CdrStatus { accepted, declined, missed, failed, completedElsewhere, error, unrecognized }

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CdrRecord with _$CdrRecord {
  const CdrRecord({
    required this.callId,
    required this.callee,
    required this.caller,
    required this.connectTime,
    required this.direction,
    required this.disconnectReason,
    required this.disconnectTime,
    required this.duration,
    this.recordingId,
    required this.status,
  });

  @override
  final String callId;

  @override
  final String callee;

  @override
  final String caller;

  @override
  final DateTime connectTime;

  @override
  @JsonKey(unknownEnumValue: CdrDirection.unrecognized)
  final CdrDirection direction;

  @override
  final String disconnectReason;

  @override
  final DateTime disconnectTime;

  @override
  final int duration;

  @override
  final dynamic recordingId;

  @override
  @JsonKey(unknownEnumValue: CdrStatus.unrecognized)
  final CdrStatus status;

  factory CdrRecord.fromJson(Map<String, Object?> json) => _$CdrRecordFromJson(json);

  Map<String, Object?> toJson() => _$CdrRecordToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CdrHistoryResponse with _$CdrHistoryResponse {
  const CdrHistoryResponse({required this.items, this.pagination});

  @override
  final List<CdrRecord> items;

  /// Absent when the adapter answered without it; `items` is then all that is
  /// known about the result set.
  @override
  final Pagination? pagination;

  factory CdrHistoryResponse.fromJson(Map<String, Object?> json) => _$CdrHistoryResponseFromJson(json);

  Map<String, Object?> toJson() => _$CdrHistoryResponseToJson(this);
}
