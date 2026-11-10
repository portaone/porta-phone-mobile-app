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

/// The row over a contacts list on a watch ([WatchSearchRow]): the search and
/// the address book side by side - a round search button and the book as a
/// pill, or the query as a pill and the book as a round button; with one book
/// the search takes the row. Same keys and ids as the phone's box.
class ContactsWatchToolbar extends StatelessWidget {
  const ContactsWatchToolbar({super.key, required this.section});

  final WatchSection<ContactsListSelection> section;

  @override
  Widget build(BuildContext context) {
    final contactsBloc = context.read<ContactsBloc>();
    final l10n = context.l10n;
    return WatchSearchRow(
      initialQuery: contactsBloc.state.search,
      onChanged: (value) => contactsBloc.add(ContactsSearchChanged(value)),
      onSubmitted: (value) => contactsBloc.add(ContactsSearchSubmitted(value)),
      chooser: section.choosable ? ({required round}) => ContactsWatchSourceChip(section: section, round: round) : null,
      searchLabel: l10n.contacts_ContactsScreen_searchSemanticsLabel,
      clearLabel: l10n.contacts_SemanticsLabel_clearSearch,
      fieldKey: contactsSearchInputKey,
      searchIdentifier: contactsSearchInputId,
      clearKey: contactsSearchInputClearKey,
      clearIdentifier: contactsSearchInputClearId,
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
