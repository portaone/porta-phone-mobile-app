import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../contacts.dart';
import 'widgets/widgets.dart';

/// The phone book on a watch. The phone's placeholders become the face's
/// state pages: one message, and the first of their buttons on the edge.
class ContactsLocalTabWatch extends StatefulWidget {
  const ContactsLocalTabWatch({super.key});

  @override
  State<ContactsLocalTabWatch> createState() => _ContactsLocalTabWatchState();
}

class _ContactsLocalTabWatchState extends State<ContactsLocalTabWatch>
    with WidgetsBindingObserver, ContactsLocalTabRefreshOnResume {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ContactsLocalTabBloc, ContactsLocalTabState>(
      builder: (context, state) {
        // The phone's "Grant access to your phone contacts" does not fit
        // the edge; what the button does is open the settings.
        final settings = WatchAction(
          label: l10n.contacts_LocalTabButton_contactsAgreement,
          identifier: contactsLocalGrantAccessId,
          onPressed: openAppSettings,
        );
        final refresh = WatchAction(
          label: l10n.contacts_LocalTabButton_refresh,
          identifier: contactsWatchRefreshId,
          onPressed: () => refreshLocalContacts(this.context),
        );
        final empty = switch (state.status) {
          ContactsLocalTabStatus.permissionFailure => ContactsWatchEmpty(
            message: l10n.contacts_LocalTabText_permissionFailure,
            icon: Icons.no_accounts_outlined,
            action: settings,
          ),
          ContactsLocalTabStatus.failure => ContactsWatchEmpty(
            message: l10n.contacts_LocalTabText_failure,
            icon: Icons.error_outline,
            action: refresh,
          ),
          ContactsLocalTabStatus.contactsAgreementFailure => ContactsWatchEmpty(
            message: l10n.contacts_LocalTabText_contactsAgreementFailure,
            action: WatchAction(
              label: l10n.contacts_LocalTabButton_contactsAgreement,
              onPressed: () => routeToContactsDiagnostic(this.context),
            ),
          ),
          _ when state.searching => ContactsWatchEmpty(message: l10n.contacts_LocalTabText_emptyOnSearching),
          _ when state.selectionOnly => ContactsWatchEmpty(
            message: l10n.contacts_LocalTabText_selectionOnlyEmpty,
            action: WatchAction(
              label: l10n.contacts_LocalTabButton_changeSelection,
              identifier: contactsLocalChangeSelectionId,
              onPressed: openAppSettings,
            ),
          ),
          _ => ContactsWatchEmpty(message: l10n.contacts_LocalTabText_empty, action: refresh),
        };
        // Access is asked before the rows, as on the phone: contacts read
        // before it was taken away would otherwise stand in for the way to
        // grant it again.
        final denied = state.status == ContactsLocalTabStatus.permissionFailure;
        return ContactsWatchBody(
          loading: state.status == ContactsLocalTabStatus.initial,
          itemCount: denied ? 0 : state.contacts.length,
          itemBuilder: (context, index) => ContactsWatchTile(
            key: ValueKey(state.contacts[index].id),
            tileKey: contactsLocalContactTileKey,
            contact: state.contacts[index],
          ),
          searching: state.searching && !denied,
          empty: empty,
          // A list of only the shared contacts says so, as on the phone.
          footer: state.selectionOnly && !state.searching && !denied ? const ContactsSelectionNotice() : null,
        );
      },
    );
  }
}
