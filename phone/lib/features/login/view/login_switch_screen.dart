import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class LoginSwitchScreen extends StatelessWidget {
  const LoginSwitchScreen({
    super.key,
    required this.appBar,
    required this.header,
    required this.body,
    required this.currentLoginType,
    required this.supportedLoginTypes,
    this.onLoginTypeChanged,
    this.processing = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget? header;
  final Widget body;
  final LoginType currentLoginType;
  final List<LoginType> supportedLoginTypes;
  final ValueChanged<LoginType>? onLoginTypeChanged;

  /// A request of the current form is in flight: the way back stays shut
  /// until it answers.
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      handset: (_) => _Handset(screen: this),
      watch: (_) => LoginSwitchWatch(body: body),
    );
  }
}

/// The sign-in forms on a phone: logo, the ways in as segments, the chosen
/// form below.
class _Handset extends StatelessWidget {
  const _Handset({required this.screen});

  final LoginSwitchScreen screen;

  @override
  Widget build(BuildContext context) {
    final LoginSwitchScreen(:appBar, :header, :body, :currentLoginType, :supportedLoginTypes, :onLoginTypeChanged) =
        screen;
    final themeData = Theme.of(context);
    final LoginSwitchScreenStyles? loginStyles = themeData.extension<LoginSwitchScreenStyles>();
    final localStyle = loginStyles?.primary;

    return LoginScaffold(
      contentThemeOverride: localStyle?.contentThemeOverride,
      applyToAppBar: localStyle?.applyToAppBar,
      appBarTheme: localStyle?.appBarTheme,
      systemUiOverlayStyle: localStyle?.systemUiOverlayStyle,
      appBar: appBar,
      body: Column(
        children: [
          ?header,
          if (supportedLoginTypes.length > 1) ...[
            SegmentedButton<LoginType>(
              style: localStyle?.segmentButtonStyle,
              segments: supportedLoginTypes
                  .map(
                    (loginType) => ButtonSegment(
                      value: loginType,
                      // The segment merges its label with its own node, so the
                      // id lands next to the selected state and the tap action
                      // instead of forming a node of its own.
                      label: SemanticId(
                        identifier: loginType.toLoginSegmentId(),
                        child: Text(
                          key: loginType.toLoginSegmentKey(),
                          loginType.l10n(context),
                          softWrap: false,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              selected: {currentLoginType},
              onSelectionChanged: (Set<LoginType> newSelection) => onLoginTypeChanged?.call(newSelection.first),
              showSelectedIcon: false,
            ),
            const SizedBox(height: kInset),
          ],
          Expanded(
            child: Ink(
              color: themeData.scaffoldBackgroundColor, // background color necessary for visually proper transition
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}
