import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import 'contacts_settings_button.dart';

/// Closes a list that holds only the contacts the user shared, so a short list
/// reads as a choice and not as a failed read.
class ContactsSelectionNotice extends StatelessWidget {
  const ContactsSelectionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Text(
            context.l10n.contacts_LocalTabText_selectionOnly,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          ContactsSettingsButton(
            key: contactsLocalChangeSelectionKey,
            identifier: contactsLocalChangeSelectionId,
            label: context.l10n.contacts_LocalTabButton_changeSelection,
          ),
        ],
      ),
    );
  }
}
