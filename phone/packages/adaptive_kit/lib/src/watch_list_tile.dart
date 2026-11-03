import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';

import 'watch_pill.dart';

/// One row of a watch list - a device, a call, a way to transfer: a pill at
/// the tap floor with an optional icon, a title, a one-line subtitle and a
/// trailing mark.
///
/// The row is one button for assistive technology, named by its title and
/// subtitle; [selected] tints it and is announced.
class WatchListTile extends StatelessWidget {
  const WatchListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.outlined = false,
    this.identifier,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// The current choice: a stronger tint.
  final bool selected;

  /// The row the screen acts on: an outline around it.
  final bool outlined;

  final String? identifier;

  /// Null shows the row disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final enabled = onTap != null;

    return SemanticAction(
      label: subtitle == null ? title : '$title, $subtitle',
      identifier: identifier,
      child: Semantics(
        selected: selected,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Material(
            color: selected ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest,
            shape: StadiumBorder(side: outlined ? BorderSide(color: colorScheme.primary, width: 1.5) : BorderSide.none),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: WatchPill.height),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    spacing: 8,
                    children: [
                      if (leading case final leading?)
                        IconTheme.merge(
                          data: IconThemeData(size: 18, color: colorScheme.primary),
                          child: leading,
                        ),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (trailing case final trailing?)
                        IconTheme.merge(
                          data: IconThemeData(size: 16, color: colorScheme.primary),
                          child: trailing,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
