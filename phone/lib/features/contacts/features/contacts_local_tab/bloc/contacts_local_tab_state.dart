part of 'contacts_local_tab_bloc.dart';

enum ContactsLocalTabStatus { initial, inProgress, success, failure, permissionFailure, contactsAgreementFailure }

class ContactsLocalTabState extends Equatable {
  const ContactsLocalTabState({
    this.status = ContactsLocalTabStatus.initial,
    this.contacts = const [],
    this.searching = false,
    this.selectionOnly = false,
  });

  final ContactsLocalTabStatus status;
  final List<Contact> contacts;
  final bool searching;

  /// Whether the device shares only a selection of contacts with the app, so
  /// the list is not the whole address book.
  final bool selectionOnly;

  @override
  List<Object?> get props => [status, EquatablePropToString.list(contacts), searching, selectionOnly];

  ContactsLocalTabState copyWith({
    ContactsLocalTabStatus? status,
    List<Contact>? contacts,
    bool? searching,
    bool? selectionOnly,
  }) {
    return ContactsLocalTabState(
      status: status ?? this.status,
      contacts: contacts ?? this.contacts,
      searching: searching ?? this.searching,
      selectionOnly: selectionOnly ?? this.selectionOnly,
    );
  }
}
