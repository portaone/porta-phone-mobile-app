part of 'recents_bloc.dart';

/// Where clearing the call log stands; the screen says how it went.
enum RecentsClearStatus { idle, clearing, cleared, failed }

@freezed
class RecentsState with _$RecentsState {
  const RecentsState({this.recents, required this.filter, this.clearStatus = RecentsClearStatus.idle});

  final List<Recent>? recents;

  final RecentsVisibilityFilter filter;

  final RecentsClearStatus clearStatus;

  List<Recent>? get recentsFiltered {
    return recents?.where((recent) {
      final callLogEntry = recent.callLogEntry;

      if (filter == RecentsVisibilityFilter.missed) {
        return !callLogEntry.isComplete && callLogEntry.direction == CallDirection.incoming;
      } else if (filter == RecentsVisibilityFilter.incoming) {
        return callLogEntry.direction == CallDirection.incoming;
      } else if (filter == RecentsVisibilityFilter.outgoing) {
        return callLogEntry.direction == CallDirection.outgoing;
      } else {
        return true;
      }
    }).toList();
  }

  @override
  String toString() {
    return 'RecentsState { recents: ${recents?.length ?? 0} items, filter: $filter, clearStatus: $clearStatus }';
  }
}
