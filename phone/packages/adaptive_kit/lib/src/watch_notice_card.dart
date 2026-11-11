import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';

/// A notice in a watch list - a message from the service: a mark and a title,
/// a few lines of its text under them and the time at the end; [unread]
/// tints it. One button for assistive technology, named by the title, the
/// text and the time (or its [semanticsLabel]); a tap opens the whole notice,
/// a long press does what [onLongPress] does (deleting it), named by
/// [longPressHint].
class WatchNoticeCard extends StatelessWidget {
  const WatchNoticeCard({
    super.key,
    required this.title,
    required this.body,
    this.leading,
    this.time,
    this.unread = false,
    this.maxBodyLines = 3,
    this.semanticsLabel,
    this.identifier,
    this.onTap,
    this.onLongPress,
    this.longPressHint,
  });

  final String title;
  final String body;

  /// A mark before the title, such as the kind of notice.
  final Widget? leading;

  /// When it came, as the list writes it.
  final String? time;

  final bool unread;
  final int maxBodyLines;
  final String? semanticsLabel;
  final String? identifier;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? longPressHint;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;
    final time = this.time;
    final label = semanticsLabel ?? [title, if (body.isNotEmpty) body, ?time].join(', ');
    final card = Semantics(
      onLongPressHint: onLongPress == null ? null : longPressHint,
      child: Material(
        color: unread ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(_radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      if (leading case final leading?)
                        IconTheme.merge(
                          data: IconThemeData(size: 16, color: colorScheme.primary),
                          child: leading,
                        ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  if (body.isNotEmpty)
                    Text(body, maxLines: maxBodyLines, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall),
                  if (time != null)
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: Text(time, style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // An InkWell carries no role of its own: a card that opens is named a
    // button, one without a tap is read as text.
    return onTap == null
        ? SemanticAction(label: label, identifier: identifier, child: card)
        : SemanticAction.button(label: label, identifier: identifier, child: card);
  }
}
