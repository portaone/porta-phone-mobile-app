import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The sign-in forms on a watch face.
///
/// No logo and no app bar: the brand was on the landing, and a watch goes back
/// with a swipe to the right. Segments for the ways in do not fit a face, so
/// choosing one is a page of its own, [LoginTypeSelectScreen].
class LoginSwitchWatch extends StatelessWidget {
  const LoginSwitchWatch({super.key, required this.body});

  /// The form of the current way in, or the ways in themselves.
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<LoginSwitchScreenStyles>()?.primary;

    return LoginScaffold.watch(
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar,
      appBarTheme: style?.appBarTheme,
      systemUiOverlayStyle: style?.systemUiOverlayStyle,
      body: body,
    );
  }
}

/// The ways in as a grid of round buttons, in the brand's order, as the main
/// screen shows its sections, the first - the brand's usual one - filled.
/// Only those a watch can use are offered ([LoginTypeWatch.availableOnWatch]).
class LoginTypeSelectScreen extends StatelessWidget {
  const LoginTypeSelectScreen({super.key, required this.supportedLoginTypes, required this.onChosen});

  final List<LoginType> supportedLoginTypes;

  /// Null leaves the buttons disabled, as the phone's segments do nothing
  /// without a handler.
  final ValueChanged<LoginType>? onChosen;

  @override
  Widget build(BuildContext context) {
    final onChosen = this.onChosen;
    final types = supportedLoginTypes.where((type) => type.availableOnWatch).toList(growable: false);
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
