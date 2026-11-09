import 'package:material_ui/material_ui.dart';

import 'adaptive_metrics.dart';
import 'screen_shape.dart';
import 'watch_action_layout.dart';
import 'watch_edge_layout.dart';
import 'watch_fade_mask.dart';
import 'watch_spinner.dart';
import 'watch_title.dart';

/// A watch screen with nothing to list yet: a section empty, on its way, failed
/// or refused. Every list section shows these states the same way, in place of
/// the phone's placeholders with a paragraph and inline buttons.
///
/// The section's [title] stays at the top. The state takes the middle: an
/// optional [icon], the [message] in one or two lines and an optional [hint]
/// under it, read as one node by assistive technology. When there is something
/// to do about it - try again, open the settings, start a chat - it is the
/// [action], the edge button along the bottom of the face.
///
/// [WatchStatePage.loading] is the section on its way: a spinner in the middle,
/// an optional [hint] under it ("Connecting..."), no action.
///
/// The state is a live region: when a section's loading page is replaced by
/// what came of it, a screen reader says the new state without the person
/// moving to it. The middle scrolls when it does not fit and fades into the
/// edge below it, as the kit's lists do.
class WatchStatePage extends StatelessWidget {
  const WatchStatePage({super.key, required String this.message, this.title, this.icon, this.hint, this.action})
    : progressLabel = null;

  const WatchStatePage.loading({super.key, required String this.progressLabel, this.title, this.hint})
    : icon = null,
      message = null,
      action = null;

  /// The section's name, at the top of the face.
  final String? title;

  /// Drawn at the icon size of the state (smaller on a small face) in the
  /// face's muted colour, unless it sets its own; decoration only, never read out.
  final Widget? icon;

  /// What the state is, in one or two lines; null only on [WatchStatePage.loading].
  final String? message;

  /// A line under the message: what it means or what to do.
  final String? hint;

  /// What can be done about the state, on the edge button.
  final WatchAction? action;

  /// What a screen reader says for the spinner of [WatchStatePage.loading]: the
  /// app's own word for loading, the kit having no strings of its own.
  final String? progressLabel;

  /// Whether this is the spinner of a section on its way.
  bool get loading => message == null;

  static const _iconSize = 28.0;
  static const _smallIconSize = 20.0;
  static const _fadeHeight = 16.0;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    final body = _body(context);
    // Without the edge button the state reaches down to the bottom of the
    // face; a round face narrows there, so the bottom keeps a list's room
    // and a long message does not scroll under the bezel.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: action == null
          ? Padding(
              padding: context.watchContentPadding().copyWith(bottom: context.watchListPadding().bottom),
              child: body,
            )
          : WatchEdgeLayout(body: body, edge: (context, overlay) => action.buildButton(overlay)),
    );
  }

  Widget _body(BuildContext context) {
    final title = this.title;
    return Column(
      children: [
        if (title != null) WatchTitle(title),
        Expanded(
          child: WatchFadeMask(
            fadeHeight: _fadeHeight,
            child: Center(
              child: SingleChildScrollView(
                child: Semantics(liveRegion: true, child: loading ? _spinner(context) : _state(context)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _spinner(BuildContext context) {
    final hint = this.hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WatchSpinner(label: progressLabel!),
        if (hint != null) ...[SizedBox(height: context.adaptiveMetrics.gap * 2), _hint(context, hint)],
      ],
    );
  }

  Widget _state(BuildContext context) {
    final themeData = Theme.of(context);
    final icon = this.icon;
    final hint = this.hint;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          ExcludeSemantics(
            child: IconTheme.merge(
              data: IconThemeData(
                size: context.isSmallWatch ? _smallIconSize : _iconSize,
                color: themeData.colorScheme.onSurfaceVariant,
              ),
              child: icon,
            ),
          ),
          SizedBox(height: context.isSmallWatch ? context.adaptiveMetrics.gap : context.adaptiveMetrics.gap * 2),
        ],
        MergeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message!,
                textAlign: TextAlign.center,
                style: themeData.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (hint != null) ...[SizedBox(height: context.adaptiveMetrics.gap), _hint(context, hint)],
            ],
          ),
        ),
      ],
    );
  }

  Widget _hint(BuildContext context, String hint) {
    final themeData = Theme.of(context);
    return Text(
      hint,
      textAlign: TextAlign.center,
      style: themeData.textTheme.bodySmall?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
    );
  }
}
