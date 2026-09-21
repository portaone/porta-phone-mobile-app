import 'package:equatable/equatable.dart';

import 'record.dart';

/// One page of call records, with what the server said about the set it was
/// taken from.
class CdrHistoryPage extends Equatable {
  const CdrHistoryPage({required this.records, this.itemsTotal});

  const CdrHistoryPage.empty() : records = const [], itemsTotal = null;

  final List<CdrRecord> records;

  /// How many records the requested range holds altogether, as the server
  /// reported it; null when it reported nothing. Whether that number is there
  /// at all is the backend's business, so nothing may depend on having it.
  final int? itemsTotal;

  /// Whether the range this page came from may still hold records beyond the
  /// [taken] already collected from it.
  ///
  /// The reported total answers it outright. Without one, any page that holds
  /// records says "ask again", and only an empty page ends the range. Comparing
  /// against the size that was ASKED for would be wrong here: a backend is free
  /// to serve fewer per page than requested, and a page that came back shorter
  /// for that reason is not the last one.
  bool hasMoreAfter(int taken) {
    final total = itemsTotal;
    if (total != null) return taken < total;
    return records.isNotEmpty;
  }

  @override
  List<Object?> get props => [records, itemsTotal];
}
