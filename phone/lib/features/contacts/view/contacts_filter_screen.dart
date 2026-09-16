import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../favorites/favorites.dart';
import '../contacts.dart';

/// The contacts screen of a deployment where favourites live inside the
/// contacts section rather than in a section of their own.
///
/// Everything the list can be drawn from is stated in one control on the line
/// under the title: each address book, and the favourites. One control rather
/// than a chooser plus a switch on the title row, because the question a
/// person is answering is the same either way - which list do I want - and two
/// controls asking it invite the combination nobody meant: the favourites of
/// one address book, under a header still naming that book.
class ContactsFilterScreen extends StatefulWidget {
  const ContactsFilterScreen({
    super.key,
    required this.selections,
    required this.sourceTypeWidgetBuilder,
    required this.favoritesWidgetBuilder,
    this.title,
    this.style,
  });

  /// What this deployment offers to pick between, in the order it offers it.
  final List<ContactsListSelection> selections;

  /// Mounts the list of one address book.
  final Widget Function(BuildContext context, ContactSourceType sourceType, {bool markFavorites})
  sourceTypeWidgetBuilder;

  /// Mounts the favourites section's own list, rearrangeable when asked.
  final Widget Function(
    BuildContext context, {
    bool reorderMode,
    void Function(int index)? onReorderStart,
    void Function(int index)? onReorderEnd,
  })
  favoritesWidgetBuilder;

  final Widget? title;
  final ContactsScreenStyle? style;

  @override
  State<ContactsFilterScreen> createState() => _ContactsFilterScreenState();
}

class _ContactsFilterScreenState extends State<ContactsFilterScreen> {
  bool _searching = false;

  final _reorder = FavoritesReorderController();

  @override
  void dispose() {
    _reorder.dispose();
    super.dispose();
  }

  /// The list actually shown. The rule is stated once, beside the entries it
  /// reads, and the tabbed arrangement asks the same question of it.
  ContactsListSelection _shown(ContactsState state) =>
      widget.selections.shown(remembered: state.sourceType, favorites: state.favorites);

  void _onSelected(ContactsListSelection selection) {
    // Rearranging belongs to the favourites list; picking another one ends it
    // rather than leaving a mode on a list that cannot use it.
    if (selection is! ContactsFavoritesSelection) _reorder.stop();

    // The whole answer in one event, and the bloc is what remembers it:
    // picking a book also leaves the favourites, and the book it names is
    // kept so that leaving the favourites lands on the one left behind.
    context.read<ContactsBloc>().add(ContactsListSelectionChanged(selection));
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final effectiveStyle = widget.style ?? themeData.extension<ContactsScreenStyles>()?.primary;
    final mediaQueryData = MediaQuery.of(context);

    // The line lines up with the title above it rather than with the screen
    // edge, and the figure is taken from the bar itself so the two cannot
    // drift apart.
    final titleInset = themeData.appBarTheme.titleSpacing ?? NavigationToolbar.kMiddleSpacing;

    // One line under the title, not two: the filter took a strip of its own
    // here and now sits on the title row, which is what lets the list start
    // this much sooner.
    //
    // The line takes exactly what a row of tabs takes on every other screen,
    // so a person moving between sections sees the list start in the same
    // place rather than a header that grows and shrinks under them.

    return Unfocuser(
      // One builder for the whole screen, so the question "which list is
      // shown" is asked once and every part of the screen is given the same
      // answer. Three builders with the same condition is how the rearrange
      // button came to ask about the pick while the body drew what was shown,
      // and a fourth thing depending on the list would have had to remember a
      // fourth builder.
      child: BlocBuilder<ContactsBloc, ContactsState>(
        buildWhen: (previous, current) =>
            previous.sourceType != current.sourceType || previous.favorites != current.favorites,
        builder: (context, state) {
          final shown = _shown(state);
          final showingFavorites = shown is ContactsFavoritesSelection;

          return ThemedScaffold(
            background: effectiveStyle?.background,
            contentThemeOverride: effectiveStyle?.contentThemeOverride ?? ThemeMode.system,
            applyToAppBar: effectiveStyle?.applyToAppBar ?? true,
            appBarTheme: effectiveStyle?.appBarTheme,
            extendBodyBehindAppBar: true,
            // Asked against the list SHOWN rather than against the pick - a
            // section left with nothing but favourites shows them without
            // anyone having picked them, and the button belongs there too.
            //
            // Both branches carry a key of their own, and the key now reaches
            // the scaffold itself: the slot used to hold one keyless builder
            // for both, which is how the scaffold saw no change and skipped
            // the animation that brings the button in.
            floatingActionButton: !widget.selections.offersFavorites
                ? null
                : !showingFavorites
                ? const SizedBox.shrink(key: ValueKey('contacts-no-reorder'))
                // While somebody is being chosen every row is a choice, and the
                // bar announcing it takes the bottom of the screen.
                : FavoritesReorderButton(
                    key: const ValueKey('contacts-reorder'),
                    controller: _reorder,
                    identifier: contactsFavoritesReorderId,
                    bottomPadding: mediaQueryData.padding.bottom,
                    hidden: context.isPickingDestination,
                  ),
            appBar: MainAppBar(
              title: widget.title,
              context: context,
              flexibleSpace: BlurredSurface.fromStyle(effectiveStyle?.appBarBlurredSurface),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(ContactsSearchRow.height),
                child: ContactsSearchRow(
                  inset: titleInset,
                  // Half the gap above, half below: the row is the whole
                  // header here, and its controls would otherwise sit against
                  // the avatar in the title row above them.
                  gapAbove: kMainAppBarBottomPaddingGap / 2,
                  searching: _searching,
                  // The favourites section has never offered a search, and a
                  // box that takes text and changes nothing is worse than none.
                  searchable: !showingFavorites,
                  onSearchOpened: () => setState(() => _searching = true),
                  onSearchClosed: () => setState(() => _searching = false),
                  // With one list there is nothing to pick, so the search box
                  // takes the whole line, exactly as on the tabbed screen.
                  leading: widget.selections.length <= 1
                      ? null
                      : ContactsSourcePicker(selections: widget.selections, selected: shown, onSelected: _onSelected),
                ),
              ),
            ),
            // No inset of its own: the body runs behind the bar, and Scaffold
            // already hands it a MediaQuery whose top padding is the bar plus
            // the status bar. A list with no padding of its own takes that
            // figure, and so does the refresh indicator. Computing it here a
            // second time is what let the two disagree - it read kToolbarHeight
            // where MainAppBar is built from kMinInteractiveDimension, eight
            // points apart.
            //
            // Favourites are not this screen's list narrowed down - they are
            // the favourites section's own list, drawn by the widget that
            // section draws it with. Deriving them a second time from the
            // contacts table is what made two answers to one question, and they
            // disagree the moment either side changes.
            //
            // Both are kept alive and only one is shown, because each is
            // watched by a bloc of its own: swapped in and out instead, every
            // tap of the control would tear a list down, build the other from
            // nothing and flash a spinner where a list already stood.
            //
            // A tab can be configured with nothing to show at all.
            body: widget.selections.isEmpty
                ? const SizedBox.shrink()
                // A slot per list, not one per kind of list. Sharing a slot
                // between the address books tears one down and builds the other
                // from nothing whenever someone changes book: a spinner where a
                // list already stood, and the place they had in it lost.
                : IndexedStack(
                    index: widget.selections.indexOf(shown).clamp(0, widget.selections.length - 1),
                    sizing: StackFit.expand,
                    children: [
                      for (final selection in widget.selections)
                        switch (selection) {
                          ContactsSourceSelection(:final sourceType) => widget.sourceTypeWidgetBuilder(
                            context,
                            sourceType,
                            markFavorites: true,
                          ),
                          // Listened to here as well as by the button: the two
                          // sit in different parts of the tree, and a button
                          // that changes its icon while the rows stay put is
                          // the whole thing not working.
                          ContactsFavoritesSelection() => ListenableBuilder(
                            listenable: _reorder,
                            builder: (context, _) => widget.favoritesWidgetBuilder(
                              context,
                              reorderMode: _reorder.active,
                              onReorderStart: _reorder.dragStarted,
                              onReorderEnd: _reorder.dragEnded,
                            ),
                          ),
                        },
                    ],
                  ),
          );
        },
      ),
    );
  }
}
