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

import '../contacts.dart';

/// The address books of a contacts screen on a watch: one at a time, as on
/// the phone, the shown one remembered by the contacts bloc. Every book stays
/// mounted and only one is shown, so changing the book keeps each list's
/// place and its bloc; the shown book's list draws the whole face under the
/// heading it gets through [ContactsWatchScope].
///
/// Both contacts screens, tabbed and unified, are this on a watch; they
/// differ in how a choice is filed and in what a section with no book left
/// shows.
class ContactsWatchSources extends StatelessWidget {
  const ContactsWatchSources({
    super.key,
    required this.style,
    required this.title,
    required this.sources,
    required this.onSelected,
    required this.bookBuilder,
    this.noBookBuilder,
  });

  final ContactsScreenStyle? style;

  /// The section's name, the one the hub shows for it.
  final String title;

  final List<ContactSourceType> sources;

  /// Files the choice of another book.
  final ValueChanged<ContactSourceType> onSelected;

  /// Mounts the list of one book.
  final Widget Function(BuildContext context, ContactSourceType sourceType) bookBuilder;

  /// What a section with no book left shows; nothing when null.
  final WidgetBuilder? noBookBuilder;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    return ThemedScaffold(
      background: style?.background,
      contentThemeOverride: style?.contentThemeOverride ?? ThemeMode.system,
      body: BlocBuilder<ContactsBloc, ContactsState>(
        buildWhen: (previous, current) => previous.sourceType != current.sourceType,
        builder: (context, state) {
          final selected = sources.shown(state.sourceType);
          if (selected == null) return noBookBuilder?.call(context) ?? const SizedBox.shrink();
          return ContactsWatchScope(
            section: WatchSection(title: title, options: sources, selected: selected, onSelected: onSelected),
            child: IndexedStack(
              index: sources.indexOf(selected),
              sizing: StackFit.expand,
              children: [for (final sourceType in sources) bookBuilder(context, sourceType)],
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

  final WatchSection<ContactSourceType> section;

  static WatchSection<ContactSourceType> of(BuildContext context) {
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
  const ContactsWatchEmpty({required this.message, this.icon = Icons.person_off_outlined, this.action});

  final String message;
  final IconData icon;
  final WatchAction? action;
}

/// One address book's list on a watch: the section's title, the search, the
/// chip that shows another book, and a row per contact - no tabs, no app
/// bar. On its way it is a loading page; with nothing to list, a state page
/// that keeps the chip, so another book is a tap away - and a search that
/// finds nothing stays the list, so the query can be changed.
class ContactsWatchBody extends StatelessWidget {
  const ContactsWatchBody({
    super.key,
    required this.loading,
    required this.contacts,
    required this.searching,
    required this.empty,
    this.tileKey,
    this.footer,
  });

  final bool loading;
  final List<Contact> contacts;

  /// Whether a search is applied to the list.
  final bool searching;

  /// What the page says with no rows.
  final ContactsWatchEmpty empty;

  /// The key every row carries, as on the phone.
  final Key? tileKey;

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
    if (contacts.isEmpty && searching) {
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

    if (contacts.isEmpty) {
      return WatchStatePage(
        title: section.title,
        footer: [?chip],
        icon: Icon(empty.icon),
        message: empty.message,
        action: empty.action,
      );
    }

    return WatchScrollList.builder(
      title: section.title,
      header: header,
      spacing: context.adaptiveMetrics.gap,
      itemCount: contacts.length + (footer == null ? 0 : 1),
      itemBuilder: (context, index) {
        if (index == contacts.length) return footer!;
        final contact = contacts[index];
        return ContactsWatchTile(key: ValueKey(contact.id), tileKey: tileKey, contact: contact);
      },
    );
  }
}

/// The address book chip of a contacts list on a watch, in place of the
/// tabs: one pill naming the book shown; a tap moves to the next one.
class ContactsWatchSourceChip extends StatelessWidget {
  const ContactsWatchSourceChip({super.key, required this.section, this.round = false});

  final WatchSection<ContactSourceType> section;

  /// Only the book's icon, in a round button: beside a query, which takes the
  /// rest of the row.
  final bool round;

  @override
  Widget build(BuildContext context) {
    final label = section.selected.l10n(context);
    final name = '${context.l10n.contacts_ContactsScreen_sourceSemanticsLabel}: $label';
    final icon = section.selected == ContactSourceType.local ? Icons.smartphone_outlined : Icons.cloud_outlined;
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

  final WatchSection<ContactSourceType> section;

  @override
  State<ContactsWatchToolbar> createState() => _ContactsWatchToolbarState();
}

class _ContactsWatchToolbarState extends State<ContactsWatchToolbar> {
  late final _controller = TextEditingController(text: context.read<ContactsBloc>().state.search);
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
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
      leading: LeadingAvatar(
        username: contact.displayTitle,
        thumbnail: contact.thumbnail,
        thumbnailUrl: contact.thumbnailUrl,
        badge: AvatarStatusBadge.maybe(registered: contact.registered),
        radius: 12,
      ),
      onTap: pick != null
          ? pick.onPressed
          : () => context.router.navigate(ContactScreenPageRoute(contactId: contact.id)),
    );
  }
}
