import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'login_mode_select_params.dart';
import 'widgets/login_mode_select_widgets.dart';

/// The landing on a watch face.
///
/// Not the phone screen made smaller: a watch shows one thing and one
/// action. With a single way in, the brand sits in the middle of the face and
/// the button fills its bottom edge. With several - more launch buttons, or
/// the demo build's custom sign-in - the face becomes a short list the user
/// scrolls, because two edge buttons do not fit and a row of small ones
/// cannot be hit.
class LoginModeSelectWatch extends StatelessWidget {
  const LoginModeSelectWatch({super.key, required this.params});

  final LoginModeSelectParams params;

  @override
  Widget build(BuildContext context) {
    final single = params.entries.length == 1 && params.customCoreEntry == null;

    return LoginModeSelectScaffold(
      params: params,
      body: SemanticId(
        identifier: loginModeScreenId,
        child: single ? _EdgeLayout(params: params) : _ListLayout(params: params),
      ),
    );
  }
}

/// The brand in the middle of the face, the one way in along its bottom.
class _EdgeLayout extends StatelessWidget {
  const _EdgeLayout({required this.params});

  final LoginModeSelectParams params;

  @override
  Widget build(BuildContext context) {
    return WatchEdgeLayout(
      body: _Brand(params: params, logoHeight: context.isSmallWatch ? 46 : 56),
      edge: (context, overlay) => LoginModeSelectEntryButton(
        entry: params.entries.single,
        style: overlay.merge(params.buttonStyle),
        // One line: the edge narrows with the face, so a second line would
        // run past its curve.
        maxLines: 1,
      ),
    );
  }
}

/// The ways in as a list under a small brand header.
class _ListLayout extends StatelessWidget {
  const _ListLayout({required this.params});

  final LoginModeSelectParams params;

  @override
  Widget build(BuildContext context) {
    final gap = context.adaptiveMetrics.gap;
    final buttonStyle = WatchPill.style.merge(params.buttonStyle);
    final customCore = params.customCoreEntry;

    return WatchScrollList(
      bottom: [
        for (final (index, entry) in params.entries.indexed) ...[
          if (index > 0) SizedBox(height: gap * 1.5),
          LoginModeSelectEntryButton(entry: entry, style: buttonStyle, maxLines: 2),
        ],
        if (customCore != null) ...[
          SizedBox(height: gap * 1.5),
          _CustomCoreButton(
            entry: customCore,
            shortTitle: params.customCoreShortTitle,
            color: params.style?.secondaryActionColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ],
      children: [
        _Brand(params: params, logoHeight: 28, compact: true),
        SizedBox(height: gap * 2),
      ],
    );
  }
}

/// The demo build's custom sign-in as one outlined line on the page.
///
/// The face holds [shortTitle]; the full phrase stays the name assistive
/// technology reads.
class _CustomCoreButton extends StatelessWidget {
  const _CustomCoreButton({required this.entry, required this.shortTitle, required this.color});

  final LoginModeSelectEntry entry;
  final String shortTitle;

  /// The colour the page's background calls for.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SemanticAction(
      label: entry.title,
      identifier: entry.semanticsId,
      child: OutlinedButton(
        key: entry.buttonKey,
        // A narrower padding than the pill's, so the short title keeps to one
        // line on the smallest face.
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.38),
        ).copyWith(side: WidgetStateProperty.resolveWith(_side)).merge(WatchPill.style),
        onPressed: entry.onPressed,
        child: ExcludeSemantics(
          child: Text(shortTitle, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  BorderSide _side(Set<WidgetState> states) {
    return BorderSide(color: color.withValues(alpha: states.contains(WidgetState.disabled) ? 0.19 : 0.5));
  }
}

/// The logo and the greeting, sized for a watch.
class _Brand extends StatelessWidget {
  const _Brand({required this.params, required this.logoHeight, this.compact = false});

  final LoginModeSelectParams params;
  final double logoHeight;

  /// The list header: smaller type, and no shrinking to fit, since the list
  /// scrolls.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final onboardingStyle = params.style?.onboardingTextStyle;
    // The brand's colour, weight and decoration, at a size a watch can hold:
    // the phone's display size would not fit the word on the face.
    final greetingStyle = themeData.textTheme.titleMedium
        ?.merge(onboardingStyle?.textStyle)
        .copyWith(fontSize: compact ? 13 : (context.isSmallWatch ? 16 : 18));
    final greeting = params.greeting;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WatchLogo(style: params.style?.pictureLogoStyle, height: logoHeight),
        if (greeting != null) ...[
          SizedBox(height: context.adaptiveMetrics.gap),
          ExtendedText(
            greeting,
            extendedStyle: (onboardingStyle ?? const ExtendedTextStyle()).copyWith(textStyle: greetingStyle),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (compact) return content;

    // A guard for the window nobody designed for (a raised font scale on the
    // smallest face): the brand block shrinks, the button below never does.
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: content,
          ),
        ),
      ),
    );
  }
}
