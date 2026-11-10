import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

extension ContactSourceTypeL10n on ContactSourceType {
  String l10n(BuildContext context) {
    switch (this) {
      case ContactSourceType.local:
        return context.l10n.contactsSourceLocal;
      case ContactSourceType.external:
        return context.l10n.contactsSourceExternal;
    }
  }
}

extension ContactsListSelectionL10n on ContactsListSelection {
  /// What the chooser calls this list. Favourites are named like an address
  /// book rather than like a filter, because in this arrangement that is what
  /// they are: one more entry of the same control.
  String l10n(BuildContext context) {
    return switch (this) {
      ContactsSourceSelection(:final sourceType) => sourceType.l10n(context),
      ContactsFavoritesSelection() => context.l10n.contactsSourceFavorites,
    };
  }

  /// The mark the chooser shows beside the name, on a phone and on a watch.
  IconData get icon => switch (this) {
    ContactsSourceSelection(sourceType: ContactSourceType.local) => Icons.smartphone_outlined,
    ContactsSourceSelection(sourceType: ContactSourceType.external) => Icons.cloud_outlined,
    // Outlined like the two beside it: the check mark of the open menu says
    // which entry is on, so a filled star would answer that a second time.
    ContactsFavoritesSelection() => Icons.star_outline,
  };
}
