import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../widgets/login_action_button.dart';
import '../../widgets/login_scaffold.dart';
import '../login_core_url_assign_params.dart';
import '../login_core_url_assign_screen_style.dart';

/// The custom-core screen's scaffold, themed from the screen's own style the
/// same way in every arrangement: theme override, bar theme, status bar.
class LoginCoreUrlAssignScaffold extends StatelessWidget {
  /// The phone's: the body scrolls as a page under [appBar].
  const LoginCoreUrlAssignScaffold({super.key, required this.style, required this.body, this.appBar}) : _watch = false;

  /// A watch face's: no bar, the body is the whole face and scrolls itself.
  const LoginCoreUrlAssignScaffold.watch({super.key, required this.style, required this.body})
    : appBar = null,
      _watch = true;

  final LoginCoreUrlAssignScreenStyle? style;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool _watch;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    if (!_watch) {
      return LoginScaffold(
        contentThemeOverride: style?.contentThemeOverride,
        applyToAppBar: style?.applyToAppBar,
        appBarTheme: style?.appBarTheme,
        appBar: appBar,
        body: body,
      );
    }
    return ThemedScaffold(
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar ?? true,
      appBarTheme: style?.appBarTheme,
      resizeToAvoidBottomInset: watchResizesForKeyboard,
      body: AnnotatedRegion<SystemUiOverlayStyle>(value: loginCoreUrlAssignOverlayStyle(style), child: body),
    );
  }
}

/// The URL field, with the history of URLs used before.
class LoginCoreUrlField extends StatelessWidget {
  const LoginCoreUrlField({super.key, required this.params, required this.labelText, this.suggestHistory = true});

  final LoginCoreUrlAssignParams params;
  final String labelText;

  /// See [HistoryAutocompleteField.suggestHistory].
  final bool suggestHistory;

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
        suggestHistory: suggestHistory,
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
    return LoginActionButton(
      identifier: coreUrlButtonId,
      buttonKey: coreUrlButtonKey,
      title: context.l10n.login_Button_coreUrlAssignProceed,
      processing: params.processing,
      onPressed: params.onSubmit,
      style: style,
    );
  }
}
