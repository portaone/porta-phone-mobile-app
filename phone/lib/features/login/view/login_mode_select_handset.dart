import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'login_mode_select_params.dart';
import 'widgets/login_mode_select_widgets.dart';

/// The landing on a phone: logo and greeting in the middle, the launch
/// buttons at the bottom, the demo build's custom sign-in in the app bar.
class LoginModeSelectHandset extends StatelessWidget {
  const LoginModeSelectHandset({super.key, required this.params});

  final LoginModeSelectParams params;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final style = params.style;
    final onboardingStyle = style?.onboardingTextStyle;
    final titleStyle = themeData.textTheme.displayMedium?.merge(onboardingStyle?.textStyle);
    final dividerHeight = (titleStyle?.fontSize ?? 0) / 3;
    final customCore = params.customCoreEntry;

    return LoginModeSelectScaffold(
      params: params,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: BlurredSurface.fromStyle(style?.appBarBlurredSurface),
        systemOverlayStyle: style?.systemUiOverlayStyle,
        actions: customCore != null
            ? [
                // The tooltip alone does not name the button: it lands in a
                // separate semantics property, so the control still
                // announces as an anonymous icon and cannot be targeted.
                SemanticAction(
                  label: customCore.title,
                  identifier: customCore.semanticsId,
                  // The tooltip keeps its long-press hint but stays out of
                  // the semantics, otherwise the merged node would carry
                  // the same sentence twice.
                  child: Tooltip(
                    message: customCore.title,
                    excludeFromSemantics: true,
                    child: IconButton(
                      key: customCore.buttonKey,
                      icon: Icon(
                        Icons.link,
                        // color set here because of https://github.com/flutter/flutter/issues/110878
                        color: themeData.colorScheme.onPrimary,
                      ),
                      onPressed: customCore.onPressed,
                    ),
                  ),
                ),
              ]
            : null,
      ),
      body: SemanticId(
        identifier: loginModeScreenId,
        child: Container(
          padding: const EdgeInsets.fromLTRB(kInset, 0, kInset, kInset),
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConfigurableThemeImage(style: style?.pictureLogoStyle),
                    if (params.greeting != null) ...[
                      SizedBox(height: dividerHeight),
                      ExtendedText(
                        params.greeting!,
                        extendedStyle: onboardingStyle?.copyWith(textStyle: titleStyle),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                const Spacer(),
                for (final entry in params.entries) LoginModeSelectEntryButton(entry: entry, style: params.buttonStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
