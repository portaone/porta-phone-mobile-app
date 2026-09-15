import 'package:equatable/equatable.dart';

import 'contact_source_type.dart';

/// What the contacts list of the unified arrangement is drawn from: one
/// address book, or the favourites a person has kept.
///
/// A type of its own rather than one more value on [ContactSourceType],
/// because that enum is stored against every contact row in the database and
/// is what a sync writes. Favourites are not a place a row comes from - they
/// are the list the favourites section keeps, spanning every address book - so
/// an enum value for them would have to be excluded by hand everywhere a
/// source type is persisted.
sealed class ContactsListSelection extends Equatable {
  const ContactsListSelection();

  @override
  bool get stringify => true;
}

/// One address book.
final class ContactsSourceSelection extends ContactsListSelection {
  const ContactsSourceSelection(this.sourceType);

  final ContactSourceType sourceType;

  @override
  List<Object?> get props => [sourceType];
}

/// The favourites section's own list.
final class ContactsFavoritesSelection extends ContactsListSelection {
  const ContactsFavoritesSelection();

  @override
  List<Object?> get props => const [];
}

extension ContactSourceTypesShown on List<ContactSourceType> {
  /// The address book to draw the list from, out of the books this deployment
  /// offers, or null where it offers none.
  ///
  /// What was remembered is not always still on offer: the choice outlives a
  /// change of configuration, and it starts out as a default nobody made. The
  /// first book is what is left in that case - the arrangements differ in
  /// what else they show, but not in this.
  ContactSourceType? shown(ContactSourceType remembered) {
    if (contains(remembered)) return remembered;
    return isEmpty ? null : first;
  }
}

extension ContactsListSelectionsShown on List<ContactsListSelection> {
  /// The address books among these entries, in the order they are offered.
  List<ContactSourceType> get sourceTypes =>
      whereType<ContactsSourceSelection>().map((selection) => selection.sourceType).toList();

  /// Whether the favourites are one of the entries.
  bool get offersFavorites => any((selection) => selection is ContactsFavoritesSelection);

  /// The list actually shown, given what was remembered.
  ///
  /// The favourites are checked against what is offered, not only against what
  /// was picked: the pick outlives a change of configuration, and a section
  /// that no longer carries favourites falls back to an address book rather
  /// than showing a list it does not offer.
  ///
  /// [favorites] is a pick, never a default: a section nobody has chosen
  /// anything in opens on an address book, because favourites hold only the
  /// people someone has starred and a new account would be greeted by an empty
  /// screen. Favourites are shown without a pick only when there is no book to
  /// show instead - a tab configured for an address book its core does not
  /// carry ends up there, and so does one configured with nothing at all.
  ContactsListSelection shown({required ContactSourceType remembered, required bool favorites}) {
    if (favorites && offersFavorites) return const ContactsFavoritesSelection();

    final sourceType = sourceTypes.shown(remembered);
    if (sourceType != null) return ContactsSourceSelection(sourceType);

    return const ContactsFavoritesSelection();
  }
}
