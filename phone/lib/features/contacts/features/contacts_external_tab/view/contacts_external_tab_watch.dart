import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../contacts.dart';

/// The cloud book on a watch. The phone's placeholders become the face's
/// state pages; a failed fetch gets Refresh on the edge, where the phone has
/// the pull.
class ContactsExternalTabWatch extends StatelessWidget {
  const ContactsExternalTabWatch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ContactsExternalTabBloc, ContactsExternalTabState>(
      builder: (context, state) {
        final refresh = WatchAction(
          label: l10n.contacts_ExternalTabButton_refresh,
          identifier: contactsWatchRefreshId,
          onPressed: () => refreshExternalContacts(context),
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
}
