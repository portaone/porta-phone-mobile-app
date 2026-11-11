import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/models.dart';

import '../../favorites/favorites.dart';
import '../contacts.dart';

/// The unified contacts screen on a watch. One list on the face at a time -
/// an address book or the favourites - and a chip in place of the chooser.
class ContactsFilterScreenWatch extends StatelessWidget {
  const ContactsFilterScreenWatch({
    super.key,
    required this.style,
    required this.title,
    required this.selections,
    required this.shown,
    required this.onSelected,
    required this.sourceTypeWidgetBuilder,
    required this.favoritesWidgetBuilder,
  });

  final ContactsScreenStyle? style;

  /// The section's name over the list, as the hub shows it.
  final String title;

  /// What this deployment offers to pick between, in the order it offers it.
  final List<ContactsListSelection> selections;

  /// The list shown, given what the bloc remembers.
  final ContactsListSelection Function(ContactsState state) shown;

  /// Files the choice of another list.
  final ValueChanged<ContactsListSelection> onSelected;

  /// Mounts the list of one address book on a watch.
  final ContactSourceTypeWidgetBuilder sourceTypeWidgetBuilder;

  /// Mounts the favourites section's list on a watch, drawn by the body it
  /// is given as one more list of this section.
  final Widget Function(BuildContext context, FavoritesWatchBodyBuilder body) favoritesWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    return ContactsWatchSources(
      style: style ?? Theme.of(context).extension<ContactsScreenStyles>()?.primary,
      title: title,
      selections: selections,
      shown: shown,
      onSelected: onSelected,
      listBuilder: (context, selection) => switch (selection) {
        ContactsSourceSelection(:final sourceType) => sourceTypeWidgetBuilder(context, sourceType),
        // Drawn like a book: the same search narrows them by name and number.
        ContactsFavoritesSelection() => favoritesWidgetBuilder(
          context,
          (context, favorites, tileBuilder) => ContactsWatchFavorites(favorites: favorites, tileBuilder: tileBuilder),
        ),
      },
    );
  }
}
