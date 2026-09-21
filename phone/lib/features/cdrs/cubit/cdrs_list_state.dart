part of 'cdrs_list_cubit.dart';

class CdrsListState extends Equatable {
  final List<CdrRecord> records;
  final bool isLoading;
  final bool fetchingHistory;

  /// Whether the history has been walked as far back as it may go. It is the
  /// horizon that ends a list, never an answer that came back empty: a stretch
  /// of days without a call is a quiet week, not the end of the archive.
  final bool historyEndReached;

  /// How far back the remote history has been walked, and where the next walk
  /// resumes. Null until the first walk; it is not derived from [records],
  /// because a filtered list can walk through days that contribute nothing to
  /// it and must not start over when it does.
  final DateTime? historyCursor;

  const CdrsListState({
    this.records = const [],
    this.isLoading = true,
    this.fetchingHistory = false,
    this.historyEndReached = false,
    this.historyCursor,
  });

  CdrsListState copyWith({
    bool? isLoading,
    List<CdrRecord>? records,
    bool? fetchingHistory,
    bool? historyEndReached,
    DateTime? historyCursor,
  }) {
    return CdrsListState(
      isLoading: isLoading ?? this.isLoading,
      records: records ?? this.records,
      fetchingHistory: fetchingHistory ?? this.fetchingHistory,
      historyEndReached: historyEndReached ?? this.historyEndReached,
      historyCursor: historyCursor ?? this.historyCursor,
    );
  }

  @override
  List<Object?> get props => [records, isLoading, fetchingHistory, historyEndReached, historyCursor];

  @override
  String toString() {
    return 'CdrsListState(records: $records, isLoading: $isLoading, fetchingHistory: $fetchingHistory, '
        'historyEndReached: $historyEndReached, historyCursor: $historyCursor)';
  }
}
