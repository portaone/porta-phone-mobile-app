part of 'local_contacts_sync_cubit.dart';

@immutable
abstract class LocalContactsSyncState extends Equatable {
  const LocalContactsSyncState();

  @override
  List<Object?> get props => [];
}

class LocalContactsSyncInitial extends LocalContactsSyncState {
  const LocalContactsSyncInitial();
}

class LocalContactsSyncRefreshInProgress extends LocalContactsSyncInitial {
  const LocalContactsSyncRefreshInProgress();
}

class LocalContactsSyncSuccess extends LocalContactsSyncState {
  const LocalContactsSyncSuccess({required this.access});

  /// What the device let the app read for this pass. With a selection the
  /// stored list is complete as far as the app can see, yet not the whole
  /// address book.
  final ContactsAccess access;

  @override
  List<Object?> get props => [access];
}

abstract class LocalContactsSyncFailure extends LocalContactsSyncState {
  const LocalContactsSyncFailure();

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => identityHashCode(this);
}

class LocalContactsSyncRefreshFailure extends LocalContactsSyncFailure {
  const LocalContactsSyncRefreshFailure();
}

class LocalContactsSyncPermissionFailure extends LocalContactsSyncFailure {
  const LocalContactsSyncPermissionFailure();
}

class LocalContactsSyncUpdateFailure extends LocalContactsSyncFailure {
  const LocalContactsSyncUpdateFailure();
}

class ContactsAgreementMissingException extends LocalContactsSyncFailure {
  const ContactsAgreementMissingException();

  @override
  String toString() => 'Local contacts sync is not allowed agreement.';
}

class ContactsFeatureDisabledException extends LocalContactsSyncFailure {
  const ContactsFeatureDisabledException();

  @override
  String toString() => 'Local contacts sync is not allowed due to settings.';
}
