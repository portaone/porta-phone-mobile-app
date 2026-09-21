import 'package:freezed_annotation/freezed_annotation.dart';

import 'balance_type.dart';

part 'common.freezed.dart';

part 'common.g.dart';

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Numbers with _$Numbers {
  const Numbers({this.main, this.ext, this.additional, this.sms});

  @override
  final String? main;

  @override
  final String? ext;

  @override
  final List<String>? additional;

  @override
  final List<String>? sms;

  factory Numbers.fromJson(Map<String, Object?> json) => _$NumbersFromJson(json);

  Map<String, Object?> toJson() => _$NumbersToJson(this);
}

@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Balance with _$Balance {
  const Balance({this.balanceType, this.amount, this.creditLimit, this.currency});

  @override
  final BalanceType? balanceType;

  @override
  final double? amount;

  @override
  final double? creditLimit;

  @override
  final String? currency;

  factory Balance.fromJson(Map<String, Object?> json) => _$BalanceFromJson(json);

  Map<String, Object?> toJson() => _$BalanceToJson(this);
}

/// Pagination of a filtered list result.
///
/// Every field is optional on purpose: the object is filled in by whichever
/// adapter served the request, and one that pages differently - or not at all -
/// is free to leave it out. A reader that needs a number must decide what an
/// absent one means for it; there is no safe default to invent here.
@freezed
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class Pagination with _$Pagination {
  const Pagination({this.page, this.itemsPerPage, this.itemsTotal});

  @override
  final int? page;

  @override
  final int? itemsPerPage;

  /// How many records the FILTERED result set holds - the whole of it, not the
  /// page. With a time range in the request that is the count within the range.
  @override
  final int? itemsTotal;

  factory Pagination.fromJson(Map<String, Object?> json) => _$PaginationFromJson(json);

  Map<String, Object?> toJson() => _$PaginationToJson(this);
}
