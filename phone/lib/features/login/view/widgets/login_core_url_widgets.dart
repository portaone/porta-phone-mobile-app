import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../widgets/login_action_button.dart';
import '../login_core_url_assign_params.dart';

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

  /// The style to draw the button with.
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
