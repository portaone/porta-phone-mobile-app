import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';

import 'watch_pill.dart';

/// One row of a watch list - a device, a call, a way to transfer: a pill at
/// the tap floor with an optional icon, a title, a one-line subtitle and a
/// trailing mark.
///
/// The row is one button for assistive technology, named by its title and
/// subtitle (or its [semanticsLabel]); [selected] tints it and is announced.
class WatchListTile extends StatelessWidget {
  const WatchListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleIcon,
    this.semanticsLabel,
    this.leading,
    this.trailing,
    this.selected = false,
    this.outlined = false,
    this.identifier,
    this.fitTitle = false,
    this.onTap,
  });

  final String title;
  final String? subtitle;

  /// A small mark before the [subtitle], such as a call's direction; for the
  /// eye only, the subtitle's words name the row.
  final Widget? subtitleIcon;

  /// The row's name for assistive technology when the words on it are not
  /// enough - a mark that says what the eye reads from its colour; the
  /// title and the subtitle when null.
  final String? semanticsLabel;

  final Widget? leading;
  final Widget? trailing;

  /// The current choice: a stronger tint.
  final bool selected;

  /// The row the screen acts on: an outline around it.
  final bool outlined;

  final String? identifier;

  /// Keeps the title on one line, set smaller when it does not fit - not
  /// below a size still read on a face, past which it wraps to two lines:
  /// for a number or an address, which a line break would cut in the middle.
  final bool fitTitle;

  /// Null shows the row disabled.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final subtitle = this.subtitle;
    final enabled = onTap != null;

    return SemanticAction(
      label: semanticsLabel ?? (subtitle == null ? title : '$title, $subtitle'),
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
                      // The marks beside the text are for the eye: the row is
                      // named by its title and subtitle alone, so an avatar's
                      // initials do not end up in its name.
                      if (leading case final leading?)
                        ExcludeSemantics(
                          child: IconTheme.merge(
                            data: IconThemeData(size: 18, color: colorScheme.primary),
                            child: leading,
                          ),
                        ),
                      Expanded(
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (fitTitle)
                                _FittedTitle(title, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600))
                              else
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              if (subtitle != null)
                                Row(
                                  spacing: 3,
                                  children: [
                                    if (subtitleIcon case final subtitleIcon?)
                                      IconTheme.merge(
                                        data: IconThemeData(size: 12, color: colorScheme.onSurfaceVariant),
                                        child: subtitleIcon,
                                      ),
                                    Flexible(
                                      child: Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (trailing case final trailing?)
                        ExcludeSemantics(
                          child: IconTheme.merge(
                            data: IconThemeData(size: 16, color: colorScheme.primary),
                            child: trailing,
                          ),
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

/// A title kept on one line, set smaller to fit - down to [_minScale] of its
/// size; a title that would need less to fit (a long address) is not shrunk
/// past reading and wraps to two lines instead.
class _FittedTitle extends StatelessWidget {
  const _FittedTitle(this.title, {required this.style});

  final String title;
  final TextStyle? style;

  static const _minScale = 0.7;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: title, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final width = painter.width;
        painter.dispose();
        if (width * _minScale > constraints.maxWidth) {
          return Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: style);
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(title, maxLines: 1, style: style),
        );
      },
    );
  }
}
