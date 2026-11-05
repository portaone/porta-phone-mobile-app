import 'dart:math' as math;

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
///
/// A greeting the face cuts short opens whole on a page of its own, and going
/// back returns to the landing.
class _EdgeLayout extends StatelessWidget {
  const _EdgeLayout({required this.params});

  final LoginModeSelectParams params;

  @override
  Widget build(BuildContext context) {
    return WatchDrillIn(
      // The landing is the menu: the greeting's page opens only from the
      // greeting itself.
      menuFirst: true,
      menu: (context, open) => WatchEdgeLayout(
        body: _Brand(params: params, logoHeight: context.isSmallWatch ? 46 : 56, onMore: open),
        edge: (context, overlay) => LoginModeSelectEntryButton(
          entry: params.entries.single,
          style: overlay.merge(params.buttonStyle),
          // One line: the edge narrows with the face, so a second line would
          // run past its curve.
          maxLines: 1,
        ),
      ),
      content: _GreetingPage(params: params),
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
        _Brand(params: params, logoHeight: _GreetingSize.logoHeight, compact: true),
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

/// The greeting's sizes on a watch: the brand's colour, weight and plate at
/// a size a face can hold - the phone's display size would not fit a word.
abstract final class _GreetingSize {
  /// A greeting the brand area holds whole, as a name or a slogan.
  static double whole(BuildContext context) => context.isSmallWatch ? 16 : 18;

  /// A greeting read as text: the list header and the greeting's own page.
  static const read = 13.0;

  /// A greeting too long for [whole], on the landing.
  static const small = 11.0;

  /// The logo over a greeting read as text, so the text gets the room.
  static const logoHeight = 28.0;

  static ExtendedTextStyle style(BuildContext context, LoginModeSelectParams params, double size) {
    final onboardingStyle = params.style?.onboardingTextStyle;
    // Text set tighter than a title's line, so a paragraph shows more of it.
    final textStyle = Theme.of(context).textTheme.titleMedium
        ?.merge(onboardingStyle?.textStyle)
        .copyWith(fontSize: size, height: size > read ? null : 1.3);
    return (onboardingStyle ?? const ExtendedTextStyle()).copyWith(textStyle: textStyle);
  }
}

/// How the greeting goes into the brand area: whole at [size], or cut to
/// [maxLines] with a way to the rest. Below its whole size the logo steps
/// down to [_GreetingSize.logoHeight].
class _GreetingFit {
  const _GreetingFit(this.size, {this.maxLines});

  final double size;
  final int? maxLines;

  bool get whole => size > _GreetingSize.read;

  static const _chevronSize = 16.0;

  /// The largest of the greeting's sizes that holds it whole in [area]
  /// under its logo, else its small size cut to the lines left. [logoRoom]
  /// is the room a logo of the height given takes, gap included.
  static _GreetingFit measure(
    BuildContext context, {
    required String greeting,
    required LoginModeSelectParams params,
    required Size area,
    required double wholeLogoHeight,
    required double Function(double logoHeight) logoRoom,
  }) {
    final padding = params.style?.onboardingTextStyle?.decoration?.padding ?? EdgeInsets.zero;
    final width = area.width - padding.horizontal;
    double height(double size) {
      final logo = size > _GreetingSize.read ? wholeLogoHeight : _GreetingSize.logoHeight;
      return area.height - logoRoom(logo) - padding.vertical;
    }

    TextPainter laidOut(double size, double width) {
      return TextPainter(
        text: TextSpan(text: greeting, style: _GreetingSize.style(context, params, size).textStyle),
        textAlign: TextAlign.center,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: width);
    }

    for (final size in [_GreetingSize.whole(context), _GreetingSize.small]) {
      final painter = laidOut(size, width);
      final fits = painter.height <= height(size);
      painter.dispose();
      if (fits) return _GreetingFit(size);
    }

    final painter = laidOut(_GreetingSize.small, width - _chevronSize - ExtendedText.trailingGap);
    final lines = painter.computeLineMetrics();
    final lineHeight = painter.height / lines.length;
    painter.dispose();
    final maxLines = (height(_GreetingSize.small) / lineHeight).floor();
    return _GreetingFit(_GreetingSize.small, maxLines: math.max(1, maxLines));
  }
}

/// The logo and the greeting, sized for a watch.
class _Brand extends StatelessWidget {
  const _Brand({required this.params, required this.logoHeight, this.compact = false, this.onMore});

  final LoginModeSelectParams params;
  final double logoHeight;

  /// The list header: smaller type, and no shrinking to fit, since the list
  /// scrolls.
  final bool compact;

  /// Opens the greeting whole; given, a greeting the room cuts short says so
  /// and opens with a tap.
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final greeting = params.greeting;
    final logoStyle = params.style?.pictureLogoStyle;
    final gap = context.adaptiveMetrics.gap;

    if (compact) {
      return _BrandColumn(
        logo: WatchLogo(style: logoStyle, height: logoHeight),
        greeting: greeting == null
            ? null
            : ExtendedText(
                greeting,
                extendedStyle: _GreetingSize.style(context, params, _GreetingSize.read),
                textAlign: TextAlign.center,
              ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = greeting == null
            ? null
            : _GreetingFit.measure(
                context,
                greeting: greeting,
                params: params,
                area: constraints.biggest,
                wholeLogoHeight: logoHeight,
                logoRoom: (height) => logoStyle == null ? 0 : height + gap,
              );
        final onMore = this.onMore;

        final content = _BrandColumn(
          logo: WatchLogo(style: logoStyle, height: fit == null || fit.whole ? logoHeight : _GreetingSize.logoHeight),
          greeting: greeting == null || fit == null
              ? null
              : fit.maxLines != null && onMore != null
              ? _GreetingTeaser(
                  greeting: greeting,
                  style: _GreetingSize.style(context, params, fit.size),
                  maxLines: fit.maxLines!,
                  onTap: onMore,
                )
              : ExtendedText(
                  greeting,
                  extendedStyle: _GreetingSize.style(context, params, fit.size),
                  textAlign: TextAlign.center,
                ),
        );

        // A guard for the window nobody designed for (a raised font scale on
        // the smallest face): the brand block shrinks, the button below never
        // does.
        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: content,
            ),
          ),
        );
      },
    );
  }
}

/// The logo over the greeting.
class _BrandColumn extends StatelessWidget {
  const _BrandColumn({required this.logo, required this.greeting});

  final Widget logo;
  final Widget? greeting;

  @override
  Widget build(BuildContext context) {
    final greeting = this.greeting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        if (greeting != null) ...[SizedBox(height: context.adaptiveMetrics.gap), greeting],
      ],
    );
  }
}

/// The greeting's first lines and a chevron; a tap opens it whole.
///
/// Assistive technology reads the whole greeting here, so nothing of it is
/// lost to the cut.
class _GreetingTeaser extends StatelessWidget {
  const _GreetingTeaser({required this.greeting, required this.style, required this.maxLines, required this.onTap});

  final String greeting;
  final ExtendedTextStyle style;
  final int maxLines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SemanticAction.button(
      label: greeting,
      identifier: loginModeScreenGreetingId,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ExcludeSemantics(
          child: ExtendedText(
            greeting,
            extendedStyle: style,
            textAlign: TextAlign.center,
            maxLines: maxLines,
            trailing: Icon(Icons.chevron_right, size: _GreetingFit._chevronSize, color: style.textStyle?.color),
          ),
        ),
      ),
    );
  }
}

/// The greeting whole, on a page that scrolls.
class _GreetingPage extends StatelessWidget {
  const _GreetingPage({required this.params});

  final LoginModeSelectParams params;

  @override
  Widget build(BuildContext context) {
    final greeting = params.greeting;
    if (greeting == null) return const SizedBox.shrink();
    return WatchScrollList(
      children: [
        ExtendedText(
          greeting,
          extendedStyle: _GreetingSize.style(context, params, _GreetingSize.read),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
