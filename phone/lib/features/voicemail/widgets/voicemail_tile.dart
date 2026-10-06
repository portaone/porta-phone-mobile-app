import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/extension/written_text_style.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';
import '../models/models.dart';

import 'audio_view.dart';
import 'circle_indicator.dart';

class VoicemailTile extends StatelessWidget {
  const VoicemailTile({
    super.key,
    required this.voicemail,
    required this.displayName,
    required this.selected,
    required this.onCall,
    required this.onDeleted,
    required this.onToggleSeenStatus,
    required this.onToggleSavedStatus,
    required this.onForwarded,
    required this.onForwardRetried,
    required this.onOpenContact,
    required this.onRestored,
    required this.onDeletedPermanently,
    required this.onLongPress,
    required this.onTap,
    this.forwardedByName,
    this.saveSupported = false,
    this.trashSupported = false,
    this.forwardSupported = false,
    this.inTrash = false,
    this.forward,
    this.thumbnail,
    this.thumbnailUrl,
  });

  final Voicemail voicemail;
  final String displayName;
  final bool selected;

  /// Whether this mailbox can keep a message at all.
  ///
  /// Two things have to be true before the control is offered: the backend has
  /// to support keeping, and this particular message has to report the flag.
  /// A message reporting no flag sits in a mailbox that cannot hold one, so
  /// offering to save it would promise something that will not stay.
  final bool saveSupported;

  /// Who passed this message along, or null when nobody did.
  ///
  /// Shown as a line of its own rather than in place of the sender, because
  /// the sender is still the person who left the recording. Both names matter
  /// and they answer different questions: who called, and how it got here.
  final String? forwardedByName;

  /// Whether this mailbox has a trash, which decides what deleting means.
  ///
  /// With one, a delete moves the message there and can be taken back. Without
  /// one it is final, which is why it asks first and this does not.
  final bool trashSupported;

  /// Whether a message can be passed on to a colleague on the same backend.
  final bool forwardSupported;

  /// Whether this message is being shown as part of the trash.
  ///
  /// It answers to a different pair of actions there - put it back, or finish
  /// deleting it - and none of the others apply to a message that is on its
  /// way out.
  final bool inTrash;

  /// Where passing this message to a colleague stands, or null when there is
  /// nothing to show about it.
  ///
  /// While the request is out a progress indicator stands in place of the
  /// menu: the backend has not answered yet, and nothing the menu offers is
  /// something to do to the message in the meantime. A forward that did not go
  /// through, where trying again could change that, leaves a quiet mark - a
  /// badge on the avatar and a line naming who it was for - and the menu
  /// offers to forward again. The sentence about it, with its own way to try
  /// again, is said once elsewhere and passes; the mark is what is still there
  /// when the person looks at the list later.
  final VoicemailForward? forward;

  final Uint8List? thumbnail;
  final Uri? thumbnailUrl;

  final void Function(Voicemail) onCall;
  final void Function(Voicemail) onDeleted;
  final void Function(Voicemail) onToggleSeenStatus;
  final void Function(Voicemail) onToggleSavedStatus;
  final void Function(Voicemail) onForwarded;

  /// Tries a forward that did not go through again, to the colleague it was
  /// for.
  final void Function(Voicemail, Contact recipient) onForwardRetried;
  final void Function(Voicemail) onOpenContact;
  final void Function(Voicemail) onRestored;
  final void Function(Voicemail) onDeletedPermanently;
  final void Function(Voicemail) onLongPress;
  final void Function(Voicemail)? onTap;

  bool get _savingOffered => saveSupported && voicemail.saved != null;

  /// Whether the caller is somebody the address book already knows.
  ///
  /// The name shown on the tile is the answer: it is the caller's number
  /// unless a contact was found for it, so a name that differs from the number
  /// means there is a card to open. Offering the action for a stranger would
  /// lead to an empty screen.
  bool get _contactKnown => voicemail.displaySender != voicemail.sender;
  bool get _saved => voicemail.saved == true;
  bool get _forwarding => forward is VoicemailForwardSending;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = context.read<VoicemailScreenContext>().dateFormat;

    final tile = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => onLongPress(voicemail),
      onTap: onTap != null ? () => onTap!(voicemail) : null,
      child: PlainListTile(
        contentPadding: EdgeInsetsGeometry.all(16),
        selected: selected,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: .5),
        crossAxisAlignment: CrossAxisAlignment.start,
        leading: LeadingAvatar(
          username: displayName,
          thumbnail: thumbnail,
          thumbnailUrl: thumbnailUrl,
          badge: forward is VoicemailForwardFailed ? const _ForwardFailedBadge() : null,
        ),
        title: Row(
          spacing: 6,
          children: [
            Flexible(
              child: Text(
                voicemail.displaySender,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.written,
              ),
            ),
            if (_saved)
              Icon(
                Icons.bookmark,
                size: 16,
                color: colorScheme.primary,
                // Named rather than decorative. The design leaves the mark
                // silent because it writes the whole tile's name itself; this
                // tile does not, so without a name here the one difference
                // between a kept message and any other is invisible to a
                // reader.
                semanticLabel: context.l10n.voicemail_SemanticsLabel_saved,
              ),
          ],
        ),
        subtitle: _VoicemailSubtitle(
          voicemail: voicemail,
          dateFormat: dateFormat,
          forwardedByName: forwardedByName,
          forward: forward,
        ),
        bottom: AudioView(path: voicemail.url!, cacheKey: voicemail.id, onPlaybackStarted: _onPlaybackStarted),
        trailing: _forwarding
            ? const _ForwardingIndicator()
            : SemanticAction(
                label: context.l10n.voicemail_SemanticsLabel_moreActions,
                identifier: voicemailMenuId,
                // The button's own tooltip is replaced rather than removed: it says
                // "Show menu", which a screen reader reads on top of the name above
                // (appended to it on iOS), and dropping it outright would take the
                // long press with it - the row's long press would then fire instead
                // and silently start selecting messages.
                child: Tooltip(
                  message: context.l10n.voicemail_SemanticsLabel_moreActions,
                  excludeFromSemantics: true,
                  child: PopupMenuButton<_VoicemailMenuAction>(
                    padding: EdgeInsets.zero,
                    position: PopupMenuPosition.under,
                    tooltip: '',
                    onSelected: _onPopupMenuSelected,
                    itemBuilder: (context) => _buildMenuItems(context, colorScheme),
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                  ),
                ),
              ),
      ),
    );

    // A trashed message is drawn back rather than differently: it is still the
    // same message, and the one thing that changed is that the mailbox is done
    // with it. Opacity says that without a second style to keep in step.
    return inTrash ? Opacity(opacity: 0.6, child: tile) : tile;
  }

  List<PopupMenuEntry<_VoicemailMenuAction>> _buildMenuItems(BuildContext context, ColorScheme colorScheme) =>
      inTrash ? _trashMenuItems(context, colorScheme) : _mailboxMenuItems(context, colorScheme);

  /// What a message on its way out answers to: put it back, or finish the job.
  ///
  /// Calling, marking and keeping are left out rather than disabled. They are
  /// about a message someone still has; this one is already gone as far as the
  /// mailbox is concerned, and the only question left is whether that stands.
  List<PopupMenuEntry<_VoicemailMenuAction>> _trashMenuItems(BuildContext context, ColorScheme colorScheme) => [
    PopupMenuItem(
      value: _VoicemailMenuAction.restore,
      child: ListTile(leading: const Icon(Icons.restore_from_trash), title: Text(context.l10n.voicemail_Label_restore)),
    ),
    const PopupMenuDivider(),
    PopupMenuItem(
      value: _VoicemailMenuAction.deletePermanently,
      child: ListTile(
        leading: Icon(Icons.delete_forever, color: colorScheme.error),
        title: Text(context.l10n.voicemail_Label_deletePermanently),
      ),
    ),
  ];

  List<PopupMenuEntry<_VoicemailMenuAction>> _mailboxMenuItems(BuildContext context, ColorScheme colorScheme) => [
    PopupMenuItem(
      value: _VoicemailMenuAction.call,
      child: ListTile(leading: const Icon(Icons.call), title: Text(context.l10n.voicemail_Label_call)),
    ),
    PopupMenuItem(
      value: _VoicemailMenuAction.toggleSeenStatus,
      enabled: !voicemail.status.isUnknown,
      child: ListTile(
        leading: const Icon(Icons.voicemail),
        title: Badge(
          isLabelVisible: voicemail.status.showBadge,
          backgroundColor: colorScheme.tertiary,
          label: null,
          child: Text(voicemail.status.toggleActionLabelL10n(context)),
        ),
      ),
    ),
    if (_savingOffered)
      PopupMenuItem(
        value: _VoicemailMenuAction.toggleSavedStatus,
        child: ListTile(
          leading: Icon(_saved ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
          title: Text(_saved ? context.l10n.voicemail_Label_unsave : context.l10n.voicemail_Label_save),
        ),
      ),
    if (_contactKnown)
      PopupMenuItem(
        value: _VoicemailMenuAction.openContact,
        child: ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(context.l10n.voicemail_Label_openContact),
        ),
      ),
    if (forwardSupported)
      PopupMenuItem(
        value: _VoicemailMenuAction.forward,
        child: ListTile(
          leading: const Icon(Icons.forward_to_inbox_outlined),
          title: Text(context.l10n.voicemail_Label_forward),
        ),
      ),
    // Only on a message that carries the mark of a forward that did not go
    // through - which is kept only where trying again could end differently -
    // and to the same colleague: the person already chose. Choosing somebody
    // else is the entry above.
    if (forwardSupported && forward is VoicemailForwardFailed)
      PopupMenuItem(
        value: _VoicemailMenuAction.forwardAgain,
        child: ListTile(leading: const Icon(Icons.replay), title: Text(context.l10n.voicemail_Label_forwardAgain)),
      ),
    PopupMenuItem(
      value: _VoicemailMenuAction.delete,
      child: ListTile(
        leading: Icon(trashSupported ? Icons.delete_outline : Icons.delete, color: colorScheme.error),
        // Named for what it does rather than for the icon it carries. Where
        // there is a trash the message can be had back; where there is not it
        // cannot, and saying "Delete" in both places would make the reversible
        // one look as final as the other.
        title: Text(trashSupported ? context.l10n.voicemail_Label_moveToTrash : context.l10n.voicemail_Label_delete),
      ),
    ),
  ];

  void _onPlaybackStarted() {
    if (voicemail.status.isUnread) onToggleSeenStatus(voicemail);
  }

  void _onPopupMenuSelected(_VoicemailMenuAction action) {
    switch (action) {
      case _VoicemailMenuAction.call:
        onCall(voicemail);
        break;
      case _VoicemailMenuAction.toggleSeenStatus:
        onToggleSeenStatus(voicemail);
        break;
      case _VoicemailMenuAction.toggleSavedStatus:
        onToggleSavedStatus(voicemail);
        break;
      case _VoicemailMenuAction.delete:
        onDeleted(voicemail);
        break;
      case _VoicemailMenuAction.openContact:
        onOpenContact(voicemail);
        break;
      case _VoicemailMenuAction.forward:
        onForwarded(voicemail);
        break;
      case _VoicemailMenuAction.forwardAgain:
        final forward = this.forward;
        if (forward is VoicemailForwardFailed) onForwardRetried(voicemail, forward.recipient);
        break;
      case _VoicemailMenuAction.restore:
        onRestored(voicemail);
        break;
      case _VoicemailMenuAction.deletePermanently:
        onDeletedPermanently(voicemail);
        break;
    }
  }
}

/// A widget that displays the voicemail's timestamp and a dynamic unread status indicator.
/// It uses an [AnimatedSwitcher] to transition between an empty state, a loading indicator
/// for unknown statuses, and a solid circle for unread messages
class _VoicemailSubtitle extends StatelessWidget {
  const _VoicemailSubtitle({required this.voicemail, required this.dateFormat, this.forwardedByName, this.forward});

  final Voicemail voicemail;
  final DateFormat dateFormat;
  final String? forwardedByName;
  final VoicemailForward? forward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final forwardedByName = this.forwardedByName;
    final forward = this.forward;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dateRow(context, colorScheme),
        if (forwardedByName != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              spacing: 4,
              children: [
                Icon(Icons.forward_to_inbox_outlined, size: 14, color: colorScheme.onSurfaceVariant),
                Flexible(
                  child: Text(
                    context.l10n.voicemail_Label_forwardedBy(forwardedByName),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        if (forward is VoicemailForwardFailed)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Row(
              spacing: 4,
              children: [
                Icon(Icons.forward_to_inbox_outlined, size: 14, color: colorScheme.error),
                Flexible(
                  child: Text(
                    context.l10n.voicemail_Label_notForwarded(forward.recipient.displayTitle),
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dateRow(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => SizeTransition(
            sizeFactor: animation,
            axis: Axis.horizontal,
            // TODO: migrate to alignment (deprecated after Flutter 3.41.0-1.0.pre)
            // ignore: deprecated_member_use
            axisAlignment: -1,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: voicemail.status.isRead
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('unread_indicator'),
                  padding: const EdgeInsets.only(right: 8),
                  child: voicemail.status.isUnknown
                      ? SizedCircularProgressIndicator(
                          size: 8,
                          outerSize: 10,
                          color: colorScheme.tertiary,
                          strokeWidth: 1,
                        )
                      : CircleIndicator(color: colorScheme.tertiary),
                ),
        ),
        Text(dateFormat.format(DateTime.parse(voicemail.date).toLocal())),
      ],
    );
  }
}

/// Stands where the menu does while the message is being forwarded, at the
/// menu's own size so the row does not shift when the answer arrives.
class _ForwardingIndicator extends StatelessWidget {
  const _ForwardingIndicator();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: voicemailForwardingId,
      label: context.l10n.voicemail_SemanticsLabel_forwarding,
      liveRegion: true,
      child: const SizedCircularProgressIndicator(
        key: voicemailForwardingKey,
        size: 20,
        outerSize: kMinInteractiveDimension,
        strokeWidth: 2,
      ),
    );
  }
}

/// Marks the avatar of a message whose forward did not go through.
///
/// Decorative on purpose: the line under the date says the same thing in
/// words, and a second announcement of it would only be noise.
class _ForwardFailedBadge extends StatelessWidget {
  const _ForwardFailedBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomRight,
      child: ExcludeSemantics(
        child: Container(
          key: voicemailForwardFailedBadgeKey,
          decoration: BoxDecoration(
            color: colorScheme.error,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.surface, width: 2),
          ),
          child: Icon(Icons.priority_high, size: 10, color: colorScheme.onError),
        ),
      ),
    );
  }
}

enum _VoicemailMenuAction {
  call,
  toggleSeenStatus,
  toggleSavedStatus,
  openContact,
  forward,
  forwardAgain,
  delete,
  restore,
  deletePermanently,
}
