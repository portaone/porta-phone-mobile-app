import 'package:material_ui/material_ui.dart';

import 'adaptive_metrics.dart';
import 'screen_shape.dart';
import 'watch_fade_mask.dart';
import 'watch_round_button.dart';
import 'watch_title.dart';

/// A question a watch asks before it does something: the whole face, in place
/// of a phone's dialog card, which leaves no room around it on a face.
///
/// The [question] and an optional [detail] under it take the middle and scroll
/// when they do not fit; the two answers are round buttons below them, the way
/// a call's controls are: [cancelLabel] on the left, tonal, and [confirmLabel]
/// on the right, filled - in the colours of an error when [destructive], as
/// for deleting or signing out. The kit has no strings of its own, so the
/// labels are the app's.
///
/// It draws no background of its own: whatever holds it - a full-screen
/// dialog, a page - is the surface, so that surface's colour is the one seen.
/// When that surface is not the scheme's, [questionColor], [detailColor] and
/// [confirmColor] carry the colours drawn for it.
class WatchConfirm extends StatelessWidget {
  const WatchConfirm({
    super.key,
    required this.question,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
    this.detail,
    this.destructive = false,
    this.confirmColor,
    this.questionColor,
    this.detailColor,
    this.cancelIdentifier,
    this.confirmIdentifier,
    this.cancelKey,
    this.confirmKey,
  });

  /// What is asked, as a question.
  final String question;

  /// The words under the button that answers no, and its name for assistive technology.
  final String cancelLabel;

  /// The words under the button that answers yes, and its name for assistive technology.
  final String confirmLabel;

  /// Called when the no button is pressed.
  final VoidCallback onCancel;

  /// Called when the yes button is pressed.
  final VoidCallback onConfirm;

  /// What the question is about, under it; none when the question says it all.
  final String? detail;

  /// Whether yes destroys or ends something; its button then takes the error colours.
  final bool destructive;

  /// The fill of the yes button, its icon then black or white, whichever reads
  /// on it. When null a [destructive] yes takes the scheme's error colours and
  /// any other the theme's filled button.
  final Color? confirmColor;

  /// The colour of the [question]; the text theme's when null.
  final Color? questionColor;

  /// The colour of the [detail]; the scheme's onSurfaceVariant when null.
  final Color? detailColor;

  /// The automation id of the no button.
  final String? cancelIdentifier;

  /// The automation id of the yes button.
  final String? confirmIdentifier;

  /// The widget key of the no button, for tests that find it.
  final Key? cancelKey;

  /// The widget key of the yes button, for tests that find it.
  final Key? confirmKey;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final metrics = context.adaptiveMetrics;
    final content = context.watchContentPadding();
    final detail = this.detail;

    // A question that scrolls reaches the narrow top of a round face, where
    // the content padding is still wider than the face: it keeps to a list's
    // padding instead, and fades at both edges of its box, so its top line
    // has faded out before the face is narrower than it.
    final list = context.watchListPadding();

    // Transparent, so the holder's surface shows, but a Material for the
    // buttons' ink when the holder is a bare page.
    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(bottom: list.bottom),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: list.copyWith(bottom: 0),
                child: WatchFadeMask(
                  fadeHeight: _fadeHeight,
                  topFadeHeight: _fadeHeight,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: _fadeHeight),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(header: true, child: WatchTitle(question, color: questionColor)),
                          if (detail != null) ...[
                            SizedBox(height: metrics.gap),
                            Text(
                              detail,
                              textAlign: TextAlign.center,
                              style: themeData.textTheme.bodySmall?.copyWith(
                                color: detailColor ?? colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: content.left),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: metrics.gap * 4,
                children: [
                  WatchRoundButton(
                    buttonKey: cancelKey,
                    identifier: cancelIdentifier,
                    icon: const Icon(Icons.close),
                    caption: cancelLabel,
                    onPressed: onCancel,
                  ),
                  WatchRoundButton(
                    buttonKey: confirmKey,
                    identifier: confirmIdentifier,
                    icon: const Icon(Icons.check),
                    caption: confirmLabel,
                    emphasis: WatchRoundEmphasis.filled,
                    style: _confirmStyle(colorScheme),
                    onPressed: onConfirm,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on WatchConfirm {
  ButtonStyle? _confirmStyle(ColorScheme colorScheme) {
    final fill = confirmColor;
    if (fill != null) {
      final dark = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark;
      return IconButton.styleFrom(backgroundColor: fill, foregroundColor: dark ? Colors.white : Colors.black);
    }
    if (destructive) {
      return IconButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: colorScheme.onError);
    }
    return null;
  }
}

// The band the question fades over at the edges of its box; the scroll keeps
// that much room so a question that fits is never faded.
const _fadeHeight = 10.0;
