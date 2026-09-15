part of 'contacts_bloc.dart';

@freezed
class ContactsState with _$ContactsState {
  const ContactsState({this.search = '', required this.sourceType, this.favorites = false});

  @override
  final String search;

  @override
  final ContactSourceType sourceType;

  /// Whether the favourites entry of the chooser is the one picked.
  ///
  /// Kept here beside the address book rather than in the screen's own state:
  /// one control asks one question, so all of its answers are remembered the
  /// same way, and a person who left the section on their favourites comes
  /// back to them. The book is remembered too, so leaving the favourites
  /// lands on the book that was left behind rather than on a default.
  ///
  /// Not a default, though: a section nobody has chosen anything in still
  /// opens on an address book, since favourites hold only what someone has
  /// starred (see `ContactsFilterScreen._shownSource`).
  @override
  final bool favorites;
}
