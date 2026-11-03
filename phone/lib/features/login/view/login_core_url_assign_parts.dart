import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'login_core_url_assign_screen_style.dart';

/// Everything both arrangements of the custom-core screen show, built once by
/// the screen, so a watch and a phone cannot drift apart in what they offer.
@immutable
class LoginCoreUrlAssignParams {
  const LoginCoreUrlAssignParams({
    required this.style,
    required this.logoStyle,
    required this.buttonStyle,
    required this.historyController,
    required this.initialValue,
    required this.errorText,
    required this.processing,
    required this.onChanged,
    required this.onSubmit,
  });

  /// The screen's own style: bar, status bar and theme override.
  final LoginCoreUrlAssignScreenStyle? style;

  /// The logo, still borrowed from the switch screen's style.
  final ThemeImageStyle? logoStyle;

  final ButtonStyle? buttonStyle;

  /// Owned by the screen, above the arrangement switch, so the typed URL and
  /// its history survive a change of arrangement.
  final HistoryAutocompleteController historyController;

  final String initialValue;
  final String? errorText;
  final bool processing;
  final ValueChanged<String> onChanged;

  /// Null while the URL is not valid or a check is running.
  final VoidCallback? onSubmit;
}

/// The URL field, with the history of URLs used before.
class LoginCoreUrlField extends StatelessWidget {
  const LoginCoreUrlField({super.key, required this.params, required this.labelText});

  final LoginCoreUrlAssignParams params;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return SemanticId(
      identifier: coreUrlInputId,
      child: HistoryAutocompleteField(
        storageKey: 'recent_core_urls',
        labelText: labelText,
        key: coreUrlInputKey,
        controller: params.historyController,
        initialValue: params.initialValue,
        errorText: params.errorText,
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.url],
        enabled: !params.processing,
        onChanged: params.onChanged,
        onSubmit: params.onSubmit,
      ),
    );
  }
}

/// The Proceed button, showing progress while the URL is checked.
class LoginCoreUrlProceedButton extends StatelessWidget {
  const LoginCoreUrlProceedButton({super.key, required this.params, required this.style});

  final LoginCoreUrlAssignParams params;

  /// The theme's style, with whatever the arrangement lays over it.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return SemanticAction(
      identifier: coreUrlButtonId,
      child: ElevatedButton(
        key: coreUrlButtonKey,
        onPressed: params.processing ? null : params.onSubmit,
        style: style,
        child: !params.processing
            ? Text(context.l10n.login_Button_coreUrlAssignProceed)
            : SizedCircularProgressIndicator(
                size: 16,
                strokeWidth: 2,
                color: params.buttonStyle?.foregroundColor?.resolve({}),
                semanticsLabel: context.l10n.common_SemanticsLabel_loading,
              ),
      ),
    );
  }
}

/// The status bar style of the screen: its own, or, for themes saved before
/// the screen had one, the historic dark icons over the light login page.
SystemUiOverlayStyle loginCoreUrlAssignOverlayStyle(LoginCoreUrlAssignScreenStyle? style) =>
    style?.systemUiOverlayStyle ?? SystemUiOverlayStyle.dark;
