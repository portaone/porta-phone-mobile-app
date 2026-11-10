import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../contacts.dart';

class ContactsExternalTab extends StatefulWidget {
  const ContactsExternalTab({this.markFavorites = false, super.key});

  /// Whether a star marks the people with a favourite among their numbers.
  /// Only where favourites are reachable from this screen: a star that leads
  /// nowhere is worse than no star at all.
  final bool markFavorites;

  @override
  State<ContactsExternalTab> createState() => _ContactsExternalTabState();
}

class _ContactsExternalTabState extends State<ContactsExternalTab> {
  int? _expandedContactId;

  void _toggleExpanded(int contactId) {
    setState(() => _expandedContactId = _expandedContactId == contactId ? null : contactId);
  }

  Future<void> _refreshContacts() async {
    try {
      final succeeded = await context.read<ContactsExternalTabBloc>().refresh();
      if (!succeeded && mounted) {
        context.showErrorSnackBar(context.l10n.contacts_ExternalTabSnackBar_requestFailed);
      }
    } catch (_) {
      if (mounted) {
        context.showErrorSnackBar(context.l10n.contacts_ExternalTabSnackBar_requestFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(handset: _handset, watch: _watch);
  }

  /// The phone's placeholders become the face's state pages; a failed fetch
  /// gets Refresh on the edge, where the phone has the pull.
  Widget _watch(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ContactsExternalTabBloc, ContactsExternalTabState>(
      builder: (context, state) {
        final refresh = WatchAction(
          label: l10n.contacts_ExternalTabButton_refresh,
          identifier: contactsWatchRefreshId,
          onPressed: _refreshContacts,
        );
        return ContactsWatchBody(
          loading:
              state.contacts.isEmpty &&
              (state.status == ContactsExternalTabStatus.initial ||
                  state.status == ContactsExternalTabStatus.inProgress),
          itemCount: state.contacts.length,
          itemBuilder: (context, index) => ContactsWatchTile(
            key: ValueKey(state.contacts[index].id),
            tileKey: contactsExtContactTileKey,
            contact: state.contacts[index],
          ),
          searching: state.searching,
          empty: switch (state.status) {
            ContactsExternalTabStatus.failure => ContactsWatchEmpty(
              message: l10n.contacts_ExternalTabText_failure,
              icon: Icons.error_outline,
              action: refresh,
            ),
            _ when state.searching => ContactsWatchEmpty(message: l10n.contacts_ExternalTabText_emptyOnSearching),
            _ => ContactsWatchEmpty(message: l10n.contacts_ExternalTabText_empty, action: refresh),
          },
        );
      },
    );
  }

  Widget _handset(BuildContext context) {
    return BlocBuilder<ContactsExternalTabBloc, ContactsExternalTabState>(
      builder: (context, state) {
        final contacts = state.contacts;

        if (contacts.isNotEmpty) {
          return RefreshIndicator(
            // See the local tab: the body runs behind the app bar, so the
            // spinner needs the same inset the list content is given, or it
            // is drawn underneath the bar.
            edgeOffset: MediaQuery.of(context).padding.top,
            onRefresh: _refreshContacts,
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];

                return ContactTileAdapter(
                  tileKey: contactsExtContactTileKey,
                  markFavorite: widget.markFavorites,
                  contact: contact,
                  expanded: _expandedContactId == contact.id,
                  onToggleExpanded: () => _toggleExpanded(contact.id),
                );
              },
            ),
          );
        }

        // No contacts to show yet: keep a loading indicator visible while the
        // initial remote fetch is still in flight, so an empty list is not
        // mistaken for "no data".
        switch (state.status) {
          case ContactsExternalTabStatus.initial:
          case ContactsExternalTabStatus.inProgress:
            return const Center(child: CircularProgressIndicator());
          case ContactsExternalTabStatus.failure:
            return NoDataPlaceholder(content: Text(context.l10n.contacts_ExternalTabText_failure));
          case ContactsExternalTabStatus.success:
            if (state.searching) {
              return NoDataPlaceholder(content: Text(context.l10n.contacts_ExternalTabText_emptyOnSearching));
            }
            return NoDataPlaceholder(
              content: Text(context.l10n.contacts_ExternalTabText_empty),
              actions: [
                TextButton(onPressed: _refreshContacts, child: Text(context.l10n.contacts_ExternalTabButton_refresh)),
              ],
            );
        }
      },
    );
  }
}
