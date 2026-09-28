part of 'local_contacts_sync_bloc.dart';

sealed class LocalContactsSyncEvent extends Equatable {
  const LocalContactsSyncEvent();

  @override
  List<Object?> get props => [];
}

class LocalContactsSyncStarted extends LocalContactsSyncEvent {
  const LocalContactsSyncStarted();
}

class LocalContactsSyncRefreshed extends LocalContactsSyncEvent {
  LocalContactsSyncRefreshed();

  final _completed = Completer<void>();

  Future<void> get completed => _completed.future;

  void complete() {
    if (!_completed.isCompleted) _completed.complete();
  }

  @override
  List<Object?> get props => [_completed];
}

class _LocalContactsSyncUpdated extends LocalContactsSyncEvent {
  final List<LocalContact> contacts;

  const _LocalContactsSyncUpdated({required this.contacts});

  @override
  List<Object?> get props => [EquatablePropToString.list(contacts)];
}
