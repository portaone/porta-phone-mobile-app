part of 'contacts_bloc.dart';

sealed class ContactsEvent extends Equatable {
  const ContactsEvent();

  @override
  List<Object?> get props => [];
}

class ContactsSourceTypeChanged extends ContactsEvent {
  const ContactsSourceTypeChanged(this.sourceType);

  final ContactSourceType sourceType;

  @override
  List<Object?> get props => [sourceType];
}

/// The whole answer of the chooser that offers one list at a time.
///
/// One event rather than one per kind of entry: the two answers are
/// mutually exclusive, and separate events would be separate pipelines with
/// nothing ordering them against each other - the later pick could land
/// first and be overwritten by the earlier one.
class ContactsListSelectionChanged extends ContactsEvent {
  const ContactsListSelectionChanged(this.selection);

  final ContactsListSelection selection;

  @override
  List<Object?> get props => [selection];
}

class ContactsSearchChanged extends ContactsEvent {
  const ContactsSearchChanged(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}

class ContactsSearchSubmitted extends ContactsEvent {
  const ContactsSearchSubmitted(this.search);

  final String search;

  @override
  List<Object?> get props => [search];
}
