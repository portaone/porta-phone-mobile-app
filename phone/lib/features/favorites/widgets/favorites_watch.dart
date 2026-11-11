import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../favorites.dart';

/// Draws the favourites on a watch from what [FavoritesWatchList] hands it:
/// the favourites, null while on their way, and the row of one of them.
///
/// Each screen heads the list its own way: the favourites section draws it
/// with [FavoritesWatchBody]; the contacts section, where the favourites are
/// one step of its chip, with its own header, search and state pages.
typedef FavoritesWatchBodyBuilder = Widget Function(
  BuildContext context,
  List<FavoriteWithContact>? favorites,
  Widget Function(FavoriteWithContact item, int index) tileBuilder,
);

/// The favourites on a watch, and what a row of them does: a tap opens the
/// number's calls, a long press removes it after asking. The same bloc as the
/// phone's [FavoritesList]; [body] draws the list around the rows.
class FavoritesWatchList extends StatefulWidget {
  const FavoritesWatchList({super.key, required this.cdrsEnabled, required this.body});

  /// Whether a row opens the account's call history rather than the
  /// device's call log.
  final bool cdrsEnabled;

  final FavoritesWatchBodyBuilder body;

  @override
  State<FavoritesWatchList> createState() => _FavoritesWatchListState();
}

class _FavoritesWatchListState extends State<FavoritesWatchList> {
  /// On a watch a favourite goes after a question of its own: the phone asks
  /// on the swipe, and a watch has no swipe to ask on.
  Future<void> confirmDelete({required FavoriteWithContact item}) async {
    final number = item.favorite.number;
    final name = item.contact?.maybeName;
    final confirmed = await ConfirmDialog.showDangerous(
      context,
      title: context.l10n.favorites_Watch_removeQuestion,
      content: name == null || name == number ? number : '$name, $number',
    );
    if (confirmed != true || !mounted) return;
    // No snack bar: the row going is the answer, and a bar at the foot of a
    // round face is cut off.
    context.read<FavoritesBloc>().add(FavoritesRemoved(favorite: item.favorite));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (context, state) {
        Widget tile(FavoriteWithContact item, int index) {
          final favorite = item.favorite;
          return FavoritesWatchTile(
            key: ValueKey('${favorite.number}_${favorite.sourceType.name}_$index'),
            item: item,
            onOpen: () => openFavoriteCallLog(context, number: favorite.number, cdrsEnabled: widget.cdrsEnabled),
            onRemove: () => confirmDelete(item: item),
          );
        }

        return widget.body(context, state.favorites, tile);
      },
    );
  }
}

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
