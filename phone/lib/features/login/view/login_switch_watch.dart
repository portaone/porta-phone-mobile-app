import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The sign-in forms on a watch face.
///
/// Segments for the ways in do not fit a face - their labels are cut even
/// on a phone - so the watch first shows the configured ways in as a grid of
/// round buttons, as the main screen shows its sections, in the brand's
/// order, and tapping one opens its form on the whole face. Going
/// back from a form returns to the list. With a single way in the list is
/// skipped. No logo and no app bar: the brand was on the landing, and a watch
/// goes back with a swipe to the right.
class LoginSwitchWatch extends StatelessWidget {
  const LoginSwitchWatch({
    super.key,
    required this.body,
    required this.currentLoginType,
    required this.supportedLoginTypes,
    this.onLoginTypeChanged,
  });

  /// The form of the current way in.
  final Widget body;
  final LoginType currentLoginType;
  final List<LoginType> supportedLoginTypes;
  final ValueChanged<LoginType>? onLoginTypeChanged;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<LoginSwitchScreenStyles>()?.primary;

    return ThemedScaffold(
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar ?? true,
      appBarTheme: style?.appBarTheme,
      resizeToAvoidBottomInset: watchResizesForKeyboard,
      body: WatchDrillIn(
        menuFirst: supportedLoginTypes.length > 1,
        menu: (context, open) => _WaysIn(
          types: supportedLoginTypes,
          onChosen: (type) {
            onLoginTypeChanged?.call(type);
            open();
          },
        ),
        content: body,
      ),
    );
  }
}

/// The configured ways in as a grid of round buttons, the first - the
/// brand's usual one - filled.
class _WaysIn extends StatelessWidget {
  const _WaysIn({required this.types, required this.onChosen});

  final List<LoginType> types;
  final ValueChanged<LoginType> onChosen;

  @override
  Widget build(BuildContext context) {
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
            onPressed: () => onChosen(type),
          ),
      ],
    );
  }
}
