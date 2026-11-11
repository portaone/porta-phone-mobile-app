import 'package:flutter/widgets.dart';

import '../cubit/cdrs_list_cubit.dart';

/// Asks [cubit] for an older page of the history once [position] is near the
/// end of what is loaded, on either arrangement's list.
void fetchCdrsHistoryNearEnd(ScrollPosition position, CdrsListCubit cubit) {
  final pixels = position.pixels;
  final scrollRemaining = position.maxScrollExtent - pixels;

  const historyFetchScrollThreshold = 500.0;
  // A leading-edge bounce is the pull-to-refresh gesture, not pagination.
  final isPastLeadingEdge = pixels > position.minScrollExtent;
  final shouldFetch = isPastLeadingEdge && scrollRemaining < historyFetchScrollThreshold;
  final canFetch = !cubit.state.historyEndReached && !cubit.state.fetchingHistory;
  if (shouldFetch && canFetch) cubit.fetchHistory();
}
