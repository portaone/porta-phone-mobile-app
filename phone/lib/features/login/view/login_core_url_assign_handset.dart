import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';
import 'login_core_url_assign_params.dart';
import 'widgets/login_core_url_widgets.dart';

/// The custom-core screen on a phone: logo, the explanation, the field, the
/// sales contact, and Proceed at the bottom; back in the app bar.
class LoginCoreUrlAssignHandset extends StatelessWidget {
  const LoginCoreUrlAssignHandset({super.key, required this.params});

  final LoginCoreUrlAssignParams params;

  @override
  Widget build(BuildContext context) {
    final style = params.style;
    final preDescription = context.l10n.login_Text_coreUrlAssignPreDescription;
    final postDescription = context.l10n.login_Text_coreUrlAssignPostDescription(EnvironmentConfig.SALES_EMAIL);

    return LoginScaffold(
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar,
      appBarTheme: style?.appBarTheme,
      appBar: AppBar(
        leading: ExtBackButton(disabled: params.processing),
        flexibleSpace: BlurredSurface.fromStyle(style?.appBarBlurredSurface),
        systemOverlayStyle: loginCoreUrlAssignOverlayStyle(style),
      ),
      body: SemanticId(
        identifier: loginCoreUrlScreenId,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              ConfigurableThemeImage(style: params.logoStyle),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(kInset, kInset / 2, kInset, kInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (preDescription.isNotEmpty) ...[
                        Description(text: preDescription),
                        const SizedBox(height: kInset / 2),
                      ],
                      LoginCoreUrlField(params: params, labelText: context.l10n.login_TextFieldLabelText_coreUrlAssign),
                      if (postDescription.isNotEmpty) ...[
                        const SizedBox(height: kInset / 8),
                        Description(text: postDescription, launchLinkableElement: true),
                      ],
                      const Spacer(),
                      const SizedBox(height: kInset),
                      LoginCoreUrlProceedButton(params: params, style: params.buttonStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
