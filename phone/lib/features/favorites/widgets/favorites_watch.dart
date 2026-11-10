import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// Draws the favourites on a watch from what the list hands it: the
/// favourites, null while on their way, and the row of one of them.
///
/// A screen that heads its lists its own way - the contacts section, where
/// the favourites are one step of its chip - passes one, so the favourites
/// get that screen's header, search and state pages; the favourites section
/// draws them with [FavoritesWatchBody].
typedef FavoritesWatchBodyBuilder = Widget Function(
  BuildContext context,
  List<FavoriteWithContact>? favorites,
  Widget Function(FavoriteWithContact item, int index) tileBuilder,
);

/// The favourites section on a watch: the section's title and a row per
/// favourite number - no app bar, no reorder button, no swipe, and no search,
/// as on the phone. On its way a loading page, with nothing kept a state page
/// saying how a favourite is added.
class FavoritesWatchBody extends StatelessWidget {
  const FavoritesWatchBody({super.key, required this.title, required this.favorites, required this.tileBuilder});

  final String title;

  /// Null while the list is on its way.
  final List<FavoriteWithContact>? favorites;

  final Widget Function(FavoriteWithContact item, int index) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final favorites = this.favorites;
    final l10n = context.l10n;

    if (favorites == null) {
      return WatchStatePage.loading(title: title, progressLabel: l10n.common_SemanticsLabel_loading);
    }

    if (favorites.isEmpty) {
      return WatchStatePage(
        title: title,
        icon: const Icon(Icons.star_outline),
        message: l10n.favorites_Watch_empty,
        hint: l10n.favorites_Watch_emptyHint,
      );
    }

    return WatchScrollList.builder(
      title: title,
      spacing: context.adaptiveMetrics.gap,
      itemCount: favorites.length,
      itemBuilder: (context, index) => tileBuilder(favorites[index], index),
    );
  }
}

/// One favourite number in a list on a watch, the contact row's shape: the
/// avatar and the name, the number under it where the name is not the number
/// itself. A tap opens the number's call page, where Call is the edge button,
/// so a tap on a small face never dials by accident; a long press removes it
/// after asking. While somebody is being chosen a tap chooses the number, or
/// does nothing where it cannot be chosen, and nothing is removed.
class FavoritesWatchTile extends StatelessWidget {
  const FavoritesWatchTile({super.key, required this.item, required this.onOpen, required this.onRemove});

  final FavoriteWithContact item;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final favorite = item.favorite;
    final contact = item.contact;
    final name = contact?.maybeName ?? favorite.number;
    final pick = context.pickOfferFor(DestinationCandidate(number: favorite.number, contact: contact));

    return WatchListTile(
      title: name,
      subtitle: name == favorite.number ? null : favorite.number,
      leading: WatchContactAvatar(contact: contact, name: name),
      onTap: pick != null ? pick.onPressed : onOpen,
      onLongPress: pick == null ? onRemove : null,
      longPressHint: context.l10n.favorites_Watch_remove,
    );
  }
}

extension FavoriteWithContactSearch on FavoriteWithContact {
  /// Whether a search for [query] finds this favourite: by the contact's
  /// name or by the number, ignoring case.
  bool matches(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    final name = contact?.maybeName?.toLowerCase() ?? '';
    return name.contains(needle) || favorite.number.toLowerCase().contains(needle);
  }
}
