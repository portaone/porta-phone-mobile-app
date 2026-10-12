import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/system_notification.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class SystemNotificationListTile extends StatefulWidget {
  const SystemNotificationListTile(
    this.notification, {
    this.seenPending = false,
    this.onSeen,
    this.onDelete,
    super.key,
  });

  final SystemNotification notification;
  final bool seenPending;
  final VoidCallback? onSeen;

  /// Deletes the notification and answers whether it is gone. A swipe waits
  /// for the answer, so a refused delete springs back instead of leaving.
  final Future<bool> Function()? onDelete;

  @override
  State<SystemNotificationListTile> createState() => _SystemNotificationListTileState();
}

class _SystemNotificationListTileState extends State<SystemNotificationListTile> with TickerProviderStateMixin {
  late final controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800), value: 1);
  late final animation = CurvedAnimation(parent: controller, curve: Curves.elasticOut);

  bool get seen => widget.notification.seen || widget.seenPending;
  late bool wasSeen = seen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || seen) return;
      controller.value = 0;
      controller.forward();
      widget.onSeen?.call();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final style = TextStyle(color: colorScheme.onSurface, fontSize: 14);

    final card = AnimatedContainer(
      duration: const Duration(seconds: 5),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: _cardRadius,
        color: seen ? _readSurface(colorScheme) : colorScheme.primaryContainer,
        border: Border(left: BorderSide(color: wasSeen ? colorScheme.primary : colorScheme.tertiary, width: 4)),
      ),
      child: Column(
        children: [
          content(style, theme),
          LinkPreviewBuilder(
            text: widget.notification.content,
            builder: (context, preview, url) =>
                LinkPreviewReveal(preview: preview, card: (preview) => linkPreview(preview, url, colorScheme, style)),
          ),
        ],
      ),
    );

    final onDelete = widget.onDelete;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.05, -0.05), end: Offset.zero).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: Column(
          children: [
            const SizedBox(height: 8),
            // The margin sits outside the swipe so the area behind the card is
            // exactly the card: the delete background takes its shape, and the
            // date below stays where it is while the card moves.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: onDelete == null
                  ? card
                  : _SwipeToDelete(id: widget.notification.id, onDelete: onDelete, child: card),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: time(style)),
          ],
        ),
      ),
    );
  }

  Widget time(TextStyle style) {
    return SizedBox(
      width: double.infinity,
      child: Text(
        widget.notification.createdAt.timeOrDate,
        style: TextStyle(fontSize: 10, color: style.color),
        textAlign: TextAlign.right,
      ),
    );
  }

  Widget content(TextStyle style, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.notification.title, style: style.copyWith(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            Icon(
              switch (widget.notification.type) {
                SystemNotificationType.announcement => Icons.announcement_outlined,
                SystemNotificationType.promotion => Icons.local_offer_outlined,
                SystemNotificationType.security => Icons.security_outlined,
                SystemNotificationType.system => Icons.settings_outlined,
              },
              size: 20,
              color: _typeColor(widget.notification.type, colorScheme),
            ),
          ],
        ),
        Divider(height: 12, color: style.color?.withAlpha(10)),
        FormattedText(
          text: widget.notification.content,
          style: style.copyWith(fontFamily: theme.textTheme.bodyMedium?.fontFamily),
          quoteDecoration: BoxDecoration(
            color: colorScheme.primaryFixed.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(0),
            border: Border(left: BorderSide(color: colorScheme.primaryFixed, width: 2)),
          ),
          textWidthBasis: TextWidthBasis.longestLine,
        ),
      ],
    );
  }

  Widget linkPreview(LinkPreview preview, Uri? url, ColorScheme colorScheme, TextStyle style) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: colorScheme.primaryFixed.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: colorScheme.primaryFixed, width: 3)),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (preview.image != null) ...[
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
              child: LinkPreviewImage(preview.image!),
            ),
            const SizedBox(height: 8),
          ],
          if (preview.title != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    preview.title!,
                    style: style.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.link_sharp, size: 16, color: Colors.grey.shade600),
              ],
            ),
          if (preview.description != null) ...[Text(preview.description!, style: style)],
          if (preview.image != null && preview.title == null && preview.description == null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    url.toString(),
                    style: style.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.link_sharp, size: 16, color: Colors.grey.shade600),
              ],
            ),
        ],
      ),
    );
  }
}

final _cardRadius = BorderRadius.circular(8);

/// Swiping a notification card away deletes it.
///
/// The swipe waits for [onDelete]: a delete that did not happen springs the
/// card back. What the card uncovers has its shape and is not clipped, so the
/// card leaves past the screen edge. A swipe is out of reach of a screen
/// reader, so the same delete is offered as an action of the card.
class _SwipeToDelete extends StatelessWidget {
  const _SwipeToDelete({required this.id, required this.onDelete, required this.child});

  final int id;
  final Future<bool> Function() onDelete;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: context.l10n.system_notifications_SemanticsAction_delete): onDelete,
      },
      child: Dismissible(
        key: ValueKey(id),
        direction: DismissDirection.endToStart,
        // The error container is laid over the card's own surface rather than
        // shown as it is: on its own it is a saturated red that shouts in a
        // list a person is tidying up.
        background: DecoratedBox(
          decoration: BoxDecoration(
            color: Color.alphaBlend(colorScheme.errorContainer.withValues(alpha: 0.45), _readSurface(colorScheme)),
            borderRadius: _cardRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.delete_outline, color: colorScheme.onSurface),
            ),
          ),
        ),
        confirmDismiss: (_) => onDelete(),
        child: child,
      ),
    );
  }
}

/// A read card, a shade lighter than the screen behind it.
///
/// In the stock dark theme the screen behind the list is as light as
/// `surfaceBright`, the lightest surface role, so a card in any surface role
/// melts into it or reads as a hole. A little of `onSurface` laid over
/// `surfaceBright` lifts it instead, stays neutral, and follows the brand's
/// scheme.
Color _readSurface(ColorScheme colorScheme) =>
    Color.alphaBlend(colorScheme.onSurface.withValues(alpha: 0.06), colorScheme.surfaceBright);

/// The kind of a notification at a glance, taken from the scheme so a brand
/// that recolours the app recolours these with it.
Color _typeColor(SystemNotificationType type, ColorScheme colorScheme) => switch (type) {
  SystemNotificationType.announcement => colorScheme.primary,
  SystemNotificationType.promotion => colorScheme.tertiary,
  SystemNotificationType.security => colorScheme.error,
  SystemNotificationType.system => colorScheme.secondary,
};
