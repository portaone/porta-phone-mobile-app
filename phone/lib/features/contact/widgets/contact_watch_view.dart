import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/keypad/keypad.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../models/models.dart';

/// A contact's page on a watch: a small avatar and the name, a row per number
/// - a tap calls it, or, while somebody is being chosen, chooses it - then
/// the rest of what the phone's rows offer as rows of their own, for the
/// main number: a video call, a message, its call history, the favourite;
/// the addresses last. The call to the main number is the edge button.
///
/// No overflow menus, no call-from, no SMS, transfer or SIP options: a face
/// has room for one action per row, and those stay on the phone.
class ContactWatchView extends StatelessWidget {
  const ContactWatchView({
    super.key,
    required this.contact,
    required this.phones,
    required this.onCall,
    this.pickLabel,
    this.pickIcon,
    this.onPick,
    this.onVideoCall,
    this.onMessage,
    this.onCallLog,
    this.onFavoriteChanged,
    this.onEmail,
  });

  final Contact contact;

  /// The numbers as the phone's card lists them; the first is the main one.
  final List<ContactPhoneDisplayEntry> phones;

  /// Calls a number; null when calls are not offered.
  final ValueChanged<String>? onCall;

  /// While somebody is being chosen: what choosing a number is called - each
  /// number's own, as the purpose may name the number - the mark of the
  /// choice, and the choice for a number - null for one the purpose refuses.
  final String Function(ContactPhone phone)? pickLabel;
  final IconData? pickIcon;
  final VoidCallback? Function(ContactPhone phone)? onPick;

  final ValueChanged<String>? onVideoCall;
  final VoidCallback? onMessage;
  final ValueChanged<String>? onCallLog;
  final void Function(ContactPhone phone, bool favorite)? onFavoriteChanged;
  final ValueChanged<ContactEmail>? onEmail;

  bool get _picking => onPick != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final main = phones.firstOrNull;
    final onMessage = this.onMessage;
    final onVideoCall = this.onVideoCall;
    final onCallLog = this.onCallLog;
    final onFavoriteChanged = this.onFavoriteChanged;

    final rows = <Widget>[
      for (final (index, entry) in phones.indexed)
        _NumberRow(
          entry: entry,
          semanticsLabel: _semanticsLabel(context, entry.phone),
          icon: _picking ? pickIcon ?? Icons.phone_forwarded : Icons.call_outlined,
          // The phone's ids: the transfer one while the row is a choice.
          identifier: numberedId(_picking ? contactPhoneTransferId : contactPhoneVoiceCallId, index),
          onTap: _tap(entry.phone),
        ),
      if (main != null && !_picking) ...[
        if (onVideoCall != null)
          WatchListTile(
            title: l10n.numberActions_videoCall,
            semanticsLabel: l10n.callTile_SemanticsLabel_videoCall(main.phone.number),
            leading: Icon(Icons.videocam_outlined),
            identifier: contactPhoneVideoCallId,
            onTap: () => onVideoCall(main.phone.number),
          ),
        if (onMessage != null)
          WatchListTile(
            title: l10n.callTileActions_message,
            leading: Icon(Icons.chat_bubble_outline),
            identifier: contactChatId,
            onTap: onMessage,
          ),
        if (onCallLog != null)
          WatchListTile(
            title: l10n.callTileActions_history,
            leading: Icon(Icons.history),
            identifier: contactWatchCallLogId,
            onTap: () => onCallLog(main.phone.number),
          ),
        if (onFavoriteChanged != null)
          // A row rather than a switch: the switch left the label too
          // little room on a small face. The star and the tint say it is
          // on; the name says what a tap does, as the phone's star does.
          WatchListTile(
            key: contactPhoneTileFavIconKey,
            title: l10n.main_BottomNavigationBarItemLabel_favorites,
            semanticsLabel: main.displayFavorite
                ? l10n.contact_SemanticsLabel_removeFavorite(main.phone.number)
                : l10n.contact_SemanticsLabel_addFavorite(main.phone.number),
            leading: Icon(main.displayFavorite ? Icons.star : Icons.star_border),
            selected: main.displayFavorite,
            identifier: contactPhoneTileFavIconId,
            onTap: () => onFavoriteChanged(main.phone, !main.displayFavorite),
          ),
      ],
      for (final (index, email) in contact.emails.indexed) _EmailRow(email: email, index: index, onEmail: onEmail),
    ];

    return WatchScrollList.builder(
      header: [
        // The name under it says who; the initials would be read twice.
        ExcludeSemantics(
          child: Center(
            child: LeadingAvatar(
              username: contact.displayTitle,
              thumbnail: contact.thumbnail,
              thumbnailUrl: contact.thumbnailUrl ?? GravatarUrl.forEmail(contact.emails.firstOrNull?.address),
              radius: 18,
            ),
          ),
        ),
        WatchTitle(contact.displayTitle),
      ],
      spacing: context.adaptiveMetrics.gap,
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index],
      // Nothing to call or choose leaves the edge empty rather than a
      // button that does nothing.
      edge: main == null || (!_picking && onCall == null)
          ? null
          : (context, overlay) => WatchCallEdgeButton(
              overlay: overlay,
              buttonKey: contactWatchCallKey,
              identifier: contactWatchCallId,
              label: _semanticsLabel(context, main.phone),
              icon: _picking ? pickIcon ?? Icons.phone_forwarded : Icons.call,
              onPressed: _tap(main.phone),
            ),
    );
  }

  /// What a tap on a number does: chooses it while somebody is being chosen
  /// (null for a number the purpose refuses), calls it otherwise.
  VoidCallback? _tap(ContactPhone phone) {
    if (_picking) return onPick?.call(phone);
    final onCall = this.onCall;
    return onCall == null ? null : () => onCall(phone.number);
  }

  /// What a tap on a number does, for assistive technology: chooses it while
  /// somebody is being chosen, calls it otherwise.
  String _semanticsLabel(BuildContext context, ContactPhone phone) {
    final l10n = context.l10n;
    if (!_picking) return l10n.callTile_SemanticsLabel_call(phone.number);
    return pickLabel?.call(phone) ?? l10n.contact_SemanticsLabel_transfer(phone.number);
  }
}

/// One of a contact's numbers on a watch: the number on one line, its label
/// under it; what a tap does is the page's.
class _NumberRow extends StatelessWidget {
  const _NumberRow({
    required this.entry,
    required this.semanticsLabel,
    required this.icon,
    required this.identifier,
    required this.onTap,
  });

  final ContactPhoneDisplayEntry entry;
  final String semanticsLabel;
  final IconData icon;
  final String identifier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return WatchListTile(
      key: contactPhoneTileKey,
      title: entry.phone.number,
      fitTitle: true,
      subtitle: entry.displayLabel.isEmpty ? null : entry.displayLabel,
      semanticsLabel: semanticsLabel,
      leading: Icon(icon),
      identifier: identifier,
      onTap: onTap,
    );
  }
}

/// One of a contact's addresses on a watch; a tap sends it an email when the
/// brand allows it.
class _EmailRow extends StatelessWidget {
  const _EmailRow({required this.email, required this.index, required this.onEmail});

  final ContactEmail email;
  final int index;
  final ValueChanged<ContactEmail>? onEmail;

  @override
  Widget build(BuildContext context) {
    final onEmail = this.onEmail;
    return WatchListTile(
      key: contactEmailTileKey,
      title: email.address,
      fitTitle: true,
      subtitle: email.label.isEmpty ? null : email.label,
      semanticsLabel: onEmail == null ? null : context.l10n.contact_SemanticsLabel_sendEmail(email.address),
      leading: const Icon(Icons.email_outlined),
      identifier: numberedId(contactEmailSendId, index),
      onTap: onEmail == null ? null : () => onEmail(email),
    );
  }
}
