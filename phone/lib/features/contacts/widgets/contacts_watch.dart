import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'package:webtrit_phone/features/favorites/favorites.dart';

import '../contacts.dart';

/// The lists of a contacts screen on a watch - its address books and, where
/// the section offers them, the favourites - one at a time, as on the phone,
/// the shown one remembered by the contacts bloc. Every list stays mounted
/// and only one is shown, so changing it keeps each list's place and its
/// bloc; the shown list draws the whole face under the heading it gets
/// through [ContactsWatchScope].
///
/// Both contacts screens, tabbed and unified, are this on a watch; they
/// differ in what they offer, how a choice is filed and which list is shown.
class ContactsWatchSources extends StatelessWidget {
  const ContactsWatchSources({
    super.key,
    required this.style,
    required this.title,
    required this.selections,
    required this.shown,
    required this.onSelected,
    required this.listBuilder,
  });

  final ContactsScreenStyle? style;

  /// The section's name, the one the hub shows for it.
  final String title;

  /// The lists the section offers, in their order.
  final List<ContactsListSelection> selections;

  /// The list shown, given what the bloc remembers; null for none.
  final ContactsListSelection? Function(ContactsState state) shown;

  /// Files the choice of another list.
  final ValueChanged<ContactsListSelection> onSelected;

  /// Mounts one list, under the scope that heads it.
  final Widget Function(BuildContext context, ContactsListSelection selection) listBuilder;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    return ThemedScaffold(
      background: style?.background,
      contentThemeOverride: style?.contentThemeOverride ?? ThemeMode.system,
      body: BlocBuilder<ContactsBloc, ContactsState>(
        buildWhen: (previous, current) => shown(previous) != shown(current),
        builder: (context, state) {
          final selected = shown(state);
          if (selected == null || !selections.contains(selected)) return const SizedBox.shrink();
          return ContactsWatchScope(
            section: WatchSection(title: title, options: selections, selected: selected, onSelected: onSelected),
            child: IndexedStack(
              index: selections.indexOf(selected),
              sizing: StackFit.expand,
              // Built under the scope, so a list can read its heading.
              children: [
                for (final selection in selections) Builder(builder: (context) => listBuilder(context, selection)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Hands the section's heading to the list of the address book shown, which
/// draws the whole face on a watch - its rows or its state - with the
/// heading on top.
class ContactsWatchScope extends InheritedWidget {
  const ContactsWatchScope({super.key, required this.section, required super.child});

  final WatchSection<ContactsListSelection> section;

  static WatchSection<ContactsListSelection> of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ContactsWatchScope>();
    assert(scope != null, 'a contacts list on a watch is mounted by a contacts screen');
    return scope!.section;
  }

  @override
  // A section is built anew with its callback on every build of the screen,
  // so there is nothing cheaper to compare: the book's list rebuilds.
  bool updateShouldNotify(ContactsWatchScope oldWidget) => true;
}

/// What an address book's list says when it has no rows: the message, and
/// what can be done about it on the edge button.
class ContactsWatchEmpty {
  const ContactsWatchEmpty({required this.message, this.icon = Icons.person_off_outlined, this.hint, this.action});

  final String message;

  /// A short second line: how the list gets filled.
  final String? hint;
  final IconData icon;
  final WatchAction? action;
}

/// One list of a contacts section on a watch - an address book, or the
/// favourites - : the section's title, the search, the chip that shows
/// another list, and a row per entry - no tabs, no app bar. On its way it is a loading page; with nothing to list, a state page
/// that keeps the chip, so another book is a tap away - and a search that
/// finds nothing stays the list, so the query can be changed.
class ContactsWatchBody extends StatelessWidget {
  const ContactsWatchBody({
    super.key,
    required this.loading,
    required this.itemCount,
    required this.itemBuilder,
    required this.searching,
    required this.empty,
    this.footer,
  });

  final bool loading;

  /// How many rows [itemBuilder] builds.
  final int itemCount;

  /// Builds the row at an index: a [ContactsWatchTile], or a favourite's.
  final IndexedWidgetBuilder itemBuilder;

  /// Whether a search is applied to the list.
  final bool searching;

  /// What the page says with no rows.
  final ContactsWatchEmpty empty;

  /// What closes a list with rows - a note that it is not the whole book.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final section = ContactsWatchScope.of(context);
    final chip = section.choosable ? ContactsWatchSourceChip(section: section) : null;

    // Keyed by the book shown: every book in the stack keeps a field of its
    // own, and one built before a search in another book would show the old
    // query over rows filtered by the new one. Changing the book rebuilds it
    // from the query the screen holds; typing in it does not.
    final header = [ContactsWatchToolbar(key: ValueKey(section.selected), section: section), const WatchSeparator()];

    // A search that finds nothing stays the list, its rows saying so: a
    // state page would rebuild the field being typed in, and the watch
    // keyboard would close after the letter that emptied the list. Asked
    // before the loading page, which a book still syncing would otherwise
    // show for the same letter.
    if (itemCount == 0 && searching) {
      return WatchScrollList.builder(
        title: section.title,
        header: header,
        itemCount: 1,
        itemBuilder: (context, _) => WatchListNote(empty.message),
      );
    }

    if (loading) {
      return WatchStatePage.loading(
        title: section.title,
        footer: [?chip],
        progressLabel: context.l10n.common_SemanticsLabel_loading,
      );
    }

    if (itemCount == 0) {
      return WatchStatePage(
        title: section.title,
        footer: [?chip],
        icon: Icon(empty.icon),
        message: empty.message,
        hint: empty.hint,
        action: empty.action,
      );
    }

    return WatchScrollList.builder(
      title: section.title,
      header: header,
      spacing: context.adaptiveMetrics.gap,
      itemCount: itemCount + (footer == null ? 0 : 1),
      itemBuilder: (context, index) => index == itemCount ? footer! : itemBuilder(context, index),
    );
  }
}

/// The favourites as one list of a contacts section on a watch, drawn like
/// an address book: the same title, search and chip, a row per favourite,
/// and the search narrowing them by name and number.
class ContactsWatchFavorites extends StatelessWidget {
  const ContactsWatchFavorites({super.key, required this.favorites, required this.tileBuilder});

  /// Null while on their way.
  final List<FavoriteWithContact>? favorites;

  final Widget Function(FavoriteWithContact item, int index) tileBuilder;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final search = context.select((ContactsBloc bloc) => bloc.state.search);
    final shown = favorites?.where((item) => item.matches(search)).toList() ?? const <FavoriteWithContact>[];
    final searching = search.isNotEmpty;

    return ContactsWatchBody(
      loading: favorites == null,
      itemCount: shown.length,
      itemBuilder: (context, index) => tileBuilder(shown[index], index),
      searching: searching,
      empty: searching
          ? ContactsWatchEmpty(message: l10n.favorites_Watch_notFound)
          : ContactsWatchEmpty(
              message: l10n.favorites_Watch_empty,
              hint: l10n.favorites_Watch_emptyHint,
              icon: Icons.star_outline,
            ),
    );
  }
}

/// The list chip of a contacts section on a watch, in place of the tabs or
/// the chooser: one pill naming the address book shown, or the favourites; a
/// tap moves to the next one.
class ContactsWatchSourceChip extends StatelessWidget {
  const ContactsWatchSourceChip({super.key, required this.section, this.round = false});

  final WatchSection<ContactsListSelection> section;

  /// Only the book's icon, in a round button: beside a query, which takes the
  /// rest of the row.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final label = section.selected.l10n(context);
    final name = '${context.l10n.contacts_ContactsScreen_sourceSemanticsLabel}: $label';
    final icon = section.selected.icon;
    void showNext() => section.onSelected(section.next);

    if (round) {
      return WatchRoundButton(
        buttonKey: contactsWatchSourceKey,
        identifier: contactsWatchSourceId,
        label: name,
        icon: Icon(icon),
        size: WatchPill.height,
        width: WatchPill.height,
        onPressed: showNext,
      );
    }
    return WatchPillButton(
      buttonKey: contactsWatchSourceKey,
      identifier: contactsWatchSourceId,
      icon: icon,
      label: label,
      semanticsLabel: name,
      onPressed: showNext,
    );
  }
}

/// The row over a contacts list on a watch: the search and the address book
/// side by side, so the first contact is in view on a small face. With no
/// query, a round search button and the book as a pill; with one, the query
/// takes the row as a pill with its cross and the book shrinks to a round
/// button. With one book there is nothing to choose, and the search takes the
/// row as a pill.
///
/// The search is a button, not a field: a watch's keyboard takes the whole
/// face with a line of its own to type in, so a box on the list to type into
/// would never be seen. Under the row is a field nobody sees, the one the
/// keyboard types into - without it the app cannot ask for a keyboard. It is
/// the same field whichever shape the row takes, so the keyboard stays open
/// while the query appears; what it holds shows in the row as it is typed,
/// for a watch whose keyboard leaves the face in view. Same keys and ids as
/// the phone's box.
class ContactsWatchToolbar extends StatefulWidget {
  const ContactsWatchToolbar({super.key, required this.section});

  final WatchSection<ContactsListSelection> section;

  @override
  State<ContactsWatchToolbar> createState() => _ContactsWatchToolbarState();
}

class _ContactsWatchToolbarState extends State<ContactsWatchToolbar> {
  late final _controller = TextEditingController(text: context.read<ContactsBloc>().state.search);
  final _focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A page or a dialog over the list: the field may not take focus back
    // when it closes. The keyboard closed with Back leaves the field focused,
    // and the route handing focus back would bring the keyboard up again over
    // a list nobody is searching. The search button lets it again.
    if (ModalRoute.isCurrentOf(context) == false) _focus.canRequestFocus = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    _focus.canRequestFocus = true;
    if (_focus.hasFocus) {
      // Focused already, the keyboard may have been closed with Back: ask
      // for it again.
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focus.requestFocus();
    }
  }

  void _clear() {
    _controller.clear();
    context.read<ContactsBloc>().add(const ContactsSearchChanged(''));
  }

  @override
  Widget build(BuildContext context) {
    final contactsBloc = context.read<ContactsBloc>();
    final section = widget.section;
    final books = section.choosable;

    return Stack(
      children: [
        // Out of sight and out of reach: the keyboard's target only.
        Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  key: contactsSearchInputKey,
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => contactsBloc.add(ContactsSearchChanged(value)),
                  onSubmitted: (value) {
                    contactsBloc.add(ContactsSearchSubmitted(value));
                    _focus.unfocus();
                  },
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final query = value.text;
            final search = _SearchPill(query: query, onOpen: _open, onClear: _clear);
            if (!books) return search;
            return Row(
              spacing: 8,
              children: query.isEmpty
                  ? [_RoundSearch(onOpen: _open), Expanded(child: ContactsWatchSourceChip(section: section))]
                  : [Expanded(child: search), ContactsWatchSourceChip(section: section, round: true)],
            );
          },
        ),
      ],
    );
  }
}

/// The search as a round button, beside the book's pill while nothing is
/// searched for.
class _RoundSearch extends StatelessWidget {
  const _RoundSearch({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return WatchRoundButton(
      identifier: contactsSearchInputId,
      label: context.l10n.contacts_ContactsScreen_searchSemanticsLabel,
      icon: const Icon(Icons.search),
      size: WatchPill.height,
      width: WatchPill.height,
      onPressed: onOpen,
    );
  }
}

/// The search as a pill: its name, or the query with a cross to clear it.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.query, required this.onOpen, required this.onClear});

  final String query;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;
    final l10n = context.l10n;
    final name = l10n.contacts_ContactsScreen_searchSemanticsLabel;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: SemanticAction(
              label: query.isEmpty ? name : query,
              identifier: contactsSearchInputId,
              child: InkWell(
                onTap: onOpen,
                // The pill's name is the label above; its words are for the eye.
                child: ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: WatchPill.height),
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: query.isEmpty ? 12 : 14, end: query.isEmpty ? 16 : 0),
                      child: Row(
                        spacing: 8,
                        children: [
                          // With a query the pill sits beside the book's button and the
                          // cross needs its room; the query and the cross say what it is.
                          if (query.isEmpty) Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                          Expanded(
                            child: Text(
                              query.isEmpty ? name : query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: query.isEmpty
                                  ? textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)
                                  : textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (query.isNotEmpty)
            SemanticAction(
              label: l10n.contacts_SemanticsLabel_clearSearch,
              identifier: contactsSearchInputClearId,
              // Narrow, full height: beside the book's button the query
              // needs the width more than the cross does.
              child: IconButton(
                key: contactsSearchInputClearKey,
                icon: const Icon(Icons.close, size: 18),
                color: colorScheme.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 36, height: WatchPill.height),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: onClear,
              ),
            ),
        ],
      ),
    );
  }
}

/// One contact in a list on a watch: the avatar and the name. A tap opens
/// the contact's page, where its numbers are called from - or, while
/// somebody is being chosen, chooses the contact.
class ContactsWatchTile extends StatelessWidget {
  const ContactsWatchTile({super.key, required this.contact, this.tileKey});

  final Contact contact;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    final pick = contactPickOffer(context, contact);
    return WatchListTile(
      key: tileKey,
      title: contact.displayTitle,
      leading: WatchContactAvatar(contact: contact),
      onTap: pick != null
          ? pick.onPressed
          : () => context.router.navigate(ContactScreenPageRoute(contactId: contact.id)),
    );
  }
}
