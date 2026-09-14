import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

extension ChatTitle on Chat {
  /// What the chat is called on screen: its name, or - for a group that has
  /// none - one title built from its number, the same everywhere the chat is
  /// shown (the list, the chat's own title, Group info). A direct chat is
  /// titled by the other person instead and never asks for this.
  String title(AppLocalizations l10n) => name ?? l10n.messaging_GroupInfo_titlePrefix(id);
}
