import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The sign-in forms on a watch face.
///
/// Segments for the ways in do not fit a face - their labels are cut even
/// on a phone - so the watch first shows the ways in as a grid of round
/// buttons, as the main screen shows its sections, in the brand's order, and
/// tapping one opens its form on the whole face. Going back from a form
/// returns to the grid. With a single way in the grid is skipped. Only the
/// ways in a watch can use are offered ([LoginTypeWatch.availableOnWatch]).
/// No logo and no app bar: the brand was on the landing, and a watch goes
/// back with a swipe to the right - which waits while a form's request is in
/// flight.
class LoginSwitchWatch extends StatelessWidget {
  const LoginSwitchWatch({
    super.key,
    required this.body,
    required this.currentLoginType,
    required this.supportedLoginTypes,
    this.onLoginTypeChanged,
    this.processing = false,
  });

  /// The form of the current way in.
  final Widget body;
  final LoginType currentLoginType;
  final List<LoginType> supportedLoginTypes;
  final ValueChanged<LoginType>? onLoginTypeChanged;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<LoginSwitchScreenStyles>()?.primary;
    final types = supportedLoginTypes.where((type) => type.availableOnWatch).toList(growable: false);

    return LoginScaffold.watch(
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar,
      appBarTheme: style?.appBarTheme,
      systemUiOverlayStyle: style?.systemUiOverlayStyle,
      body: WatchDrillIn(
        // The grid also comes first when the brand's first way in is one a
        // watch does not offer, so the face never opens on its form.
        menuFirst: types.length > 1 || !types.contains(currentLoginType),
        canGoBack: !processing,
        menu: (context, open) =>
            _WaysIn(types: types, onChosen: onLoginTypeChanged == null ? null : (type) => _choose(type, open)),
        content: body,
      ),
    );
  }

  void _choose(LoginType type, VoidCallback open) {
    onLoginTypeChanged?.call(type);
    open();
  }
}

/// The ways in as a grid of round buttons, the first - the brand's usual
/// one - filled.
class _WaysIn extends StatelessWidget {
  const _WaysIn({required this.types, required this.onChosen});

  final List<LoginType> types;

  /// Null leaves the buttons disabled, as the phone's segments do nothing
  /// without a handler.
  final ValueChanged<LoginType>? onChosen;

  @override
  Widget build(BuildContext context) {
    final onChosen = this.onChosen;
    return WatchIconGrid(
      items: [
        for (final (index, type) in types.indexed)
          WatchIconGridItem(
            icon: Icon(type.watchIcon),
            caption: type.shortL10n(context),
            // The full name, and the same ids the phone's segments carry, so
            // assistive technology and automation pick a way in the same way
            // on both.
            semanticLabel: type.l10n(context),
            identifier: type.toLoginSegmentId(),
            buttonKey: type.toLoginSegmentKey(),
            emphasis: index == 0 ? WatchRoundEmphasis.filled : WatchRoundEmphasis.tonal,
            onPressed: onChosen == null ? null : () => onChosen(type),
          ),
      ],
    );
  }
}
