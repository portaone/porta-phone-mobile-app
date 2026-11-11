import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/extension/elevated_button_styles.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../contacts.dart';
import 'widgets/widgets.dart';

class ContactsLocalTab extends StatefulWidget {
  const ContactsLocalTab({super.key, this.markFavorites = false});

  /// Whether a star marks the people with a favourite among their numbers.
  /// Only where favourites are reachable from this screen: a star that leads
  /// nowhere is worse than no star at all.
  final bool markFavorites;

  @override
  State<ContactsLocalTab> createState() => _ContactsLocalTabState();
}

class _ContactsLocalTabState extends State<ContactsLocalTab>
    with WidgetsBindingObserver, ContactsLocalTabRefreshOnResume {
  int? _expandedContactId;

  void _toggleExpanded(int contactId) {
    setState(() => _expandedContactId = _expandedContactId == contactId ? null : contactId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final elevatedButtonStyles = theme.extension<ElevatedButtonStyles>();

    return _handset(context, elevatedButtonStyles);
  }

  Widget _handset(BuildContext context, ElevatedButtonStyles? elevatedButtonStyles) {
    return BlocBuilder<ContactsLocalTabBloc, ContactsLocalTabState>(
      builder: (context, state) {
        final shown = state.contacts;
        // A search that finds nothing is about the query, not about access.
        final selectionNotice = state.selectionOnly && !state.searching;

        if (state.status == ContactsLocalTabStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state.status == ContactsLocalTabStatus.permissionFailure) {
          return NoDataPlaceholder(
            content: Text(context.l10n.contacts_LocalTabText_permissionFailure),
            actions: [
              ContactsSettingsButton(
                key: contactsLocalGrantAccessKey,
                identifier: contactsLocalGrantAccessId,
                label: context.l10n.contacts_LocalTabButton_openAppSettings,
              ),
            ],
          );
        } else if (shown.isNotEmpty) {
          return RefreshIndicator(
            // The list runs behind the app bar, so without this the spinner
            // settles forty points from the top of the SCREEN - a bar's height
            // out of sight, and a pull looks like it did nothing. The inset the
            // screen already applied to the body is the one figure both this
            // and the first row are placed by, so they cannot drift apart.
            edgeOffset: MediaQuery.of(context).padding.top,
            onRefresh: _refreshContacts,
            child: ListView.builder(
              itemCount: shown.length + (selectionNotice ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == shown.length) return const ContactsSelectionNotice();
                final contact = shown[index];
                return ContactTileAdapter(
                  tileKey: contactsLocalContactTileKey,
                  markFavorite: widget.markFavorites,
                  contact: contact,
                  expanded: _expandedContactId == contact.id,
                  onToggleExpanded: () => _toggleExpanded(contact.id),
                );
              },
            ),
          );
        } else {
          if (state.status == ContactsLocalTabStatus.failure) {
            return NoDataPlaceholder(content: Text(context.l10n.contacts_LocalTabText_failure));
          }
          if (state.status == ContactsLocalTabStatus.contactsAgreementFailure) {
            return NoDataPlaceholder(
              content: Column(
                children: [
                  Text(context.l10n.contacts_LocalTabText_contactsAgreementFailure),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => routeToContactsDiagnostic(context),
                    style: elevatedButtonStyles?.neutral,
                    child: Text(context.l10n.contacts_LocalTabButton_contactsAgreement),
                  ),
                  TextButton(
                    onPressed: _refreshContacts,
                    style: elevatedButtonStyles?.neutral,
                    child: Text(context.l10n.contacts_LocalTabButton_refresh),
                  ),
                ],
              ),
            );
          } else {
            if (state.searching) {
              return NoDataPlaceholder(content: Text(context.l10n.contacts_LocalTabText_emptyOnSearching));
            } else if (selectionNotice) {
              return NoDataPlaceholder(
                content: Text(context.l10n.contacts_LocalTabText_selectionOnlyEmpty),
                actions: [
                  ContactsSettingsButton(
                    key: contactsLocalChangeSelectionKey,
                    identifier: contactsLocalChangeSelectionId,
                    label: context.l10n.contacts_LocalTabButton_changeSelection,
                  ),
                  TextButton(onPressed: _refreshContacts, child: Text(context.l10n.contacts_LocalTabButton_refresh)),
                ],
              );
            } else {
              return NoDataPlaceholder(
                content: Text(context.l10n.contacts_LocalTabText_empty),
                actions: [
                  TextButton(onPressed: _refreshContacts, child: Text(context.l10n.contacts_LocalTabButton_refresh)),
                ],
              );
            }
          }
        }
      },
    );
  }

  Future<void> _refreshContacts() => refreshLocalContacts(context);
}

/// Reads the phone book again when the app comes back to the foreground.
/// Shared by the phone's list and the watch's.
mixin ContactsLocalTabRefreshOnResume<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh contacts when the app is resumed.
      // This is to account for cases where contacts were updated while the app was collapsed,
      // or if the user changed contact permissions in the background,
      // which is a common scenario on Android.
      refreshLocalContacts(context);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

/// Reads the phone book again.
Future<void> refreshLocalContacts(BuildContext context) => context.read<ContactsLocalTabBloc>().refresh();

/// Opens the diagnostic, where the contacts agreement is given.
Future<void> routeToContactsDiagnostic(BuildContext context) async {
  FocusScope.of(context).unfocus();
  context.router.push(const SettingsRouterPageRoute(children: [DiagnosticScreenPageRoute()]));
}
