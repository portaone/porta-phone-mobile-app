import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/models.dart';

import 'avatar_status_badge.dart';
import 'leading_avatar.dart';

/// A contact's avatar in a row on a watch: the picture or the initials and
/// the registered badge, in the size every watch row draws it.
class WatchContactAvatar extends StatelessWidget {
  const WatchContactAvatar({super.key, required this.contact, this.name});

  /// Null for a number no contact has: the initials of [name] alone.
  final Contact? contact;

  /// What the initials come from where the row names it otherwise than the
  /// contact does; the contact's own title by default.
  final String? name;

  /// How large the avatar is drawn in a watch row.
  static const radius = 12.0;

  @override
  Widget build(BuildContext context) {
    final contact = this.contact;
    return LeadingAvatar(
      username: name ?? contact?.displayTitle,
      thumbnail: contact?.thumbnail,
      thumbnailUrl: contact?.thumbnailUrl,
      badge: AvatarStatusBadge.maybe(registered: contact?.registered),
      radius: radius,
    );
  }
}
