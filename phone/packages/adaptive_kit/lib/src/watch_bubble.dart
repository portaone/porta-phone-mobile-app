import 'package:material_ui/material_ui.dart';

/// One message of a conversation on a watch: a bubble on the right in the
/// primary colour for the user's own, on the left in the surface's for the
/// other side, with the sender's name over it in a group, its time and an
/// optional delivery mark under the text, and a [note] under the bubble for
/// what went wrong ("Not sent").
///
/// One node for a screen reader, named by [semanticsLabel] or by the sender,
/// the text, the time and the note; the mark is for the eye - the label says
/// what it shows.
class WatchBubble extends StatelessWidget {
  const WatchBubble({
    super.key,
    required this.text,
    required this.mine,
    this.sender,
    this.time,
    this.mark,
    this.note,
    this.semanticsLabel,
  });

  final String text;

  /// The user's own message: on the right.
  final bool mine;

  /// Who wrote it, in a group.
  final String? sender;

  final String? time;

  /// A delivery mark beside the time - sent, read.
  final Widget? mark;

  /// What went wrong with it, under the bubble.
  final String? note;

  final String? semanticsLabel;

  /// The share of the list's width a bubble may take.
  static const _widthShare = 0.82;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;
    final foreground = mine ? colorScheme.onPrimary : colorScheme.onSurface;
    final muted = mine ? colorScheme.onPrimary.withValues(alpha: 0.8) : colorScheme.onSurfaceVariant;
    const corner = Radius.circular(16);
    const tail = Radius.circular(4);
    final sender = this.sender;
    final time = this.time;
    final mark = this.mark;
    final note = this.note;

    return Semantics(
      container: true,
      label: semanticsLabel ?? [?sender, text, ?time, ?note].join(', '),
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * _widthShare),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: mine ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: corner,
                      topRight: corner,
                      bottomLeft: mine ? corner : tail,
                      bottomRight: mine ? tail : corner,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sender != null)
                          Text(
                            sender,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(text, style: textTheme.bodyMedium?.copyWith(color: foreground)),
                        if (time != null || mark != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 3,
                            children: [
                              if (time != null)
                                Flexible(
                                  child: Text(
                                    time,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.labelSmall?.copyWith(color: muted),
                                  ),
                                ),
                              if (mark != null)
                                IconTheme.merge(
                                  data: IconThemeData(size: 12, color: muted),
                                  child: mark,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    note,
                    style: textTheme.labelSmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
