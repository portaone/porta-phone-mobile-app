import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';
import 'login_core_url_assign_params.dart';
import 'widgets/login_core_url_widgets.dart';

/// The custom-core screen on a watch face.
///
/// The landing's language: Proceed is the edge button along the bottom of
/// the face, and above it one short column scrolls - the prompt, the field,
/// the sales contact. No app bar: a watch goes back with a swipe to the
/// right, and an icon in a corner would be cut off by the bezel. No logo:
/// the brand was on the landing, and on a face this small the room goes to
/// the field. The phone's long explanation does not fit a face, so the
/// field's own prompt leads instead.
class LoginCoreUrlAssignWatch extends StatelessWidget {
  const LoginCoreUrlAssignWatch({super.key, required this.params});

  final LoginCoreUrlAssignParams params;

  @override
  Widget build(BuildContext context) {
    final style = params.style;
    final postDescription = context.l10n.login_Text_coreUrlAssignPostDescription(EnvironmentConfig.SALES_EMAIL);

    return ThemedScaffold(
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar ?? true,
      appBarTheme: style?.appBarTheme,
      resizeToAvoidBottomInset: watchResizesForKeyboard,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: loginCoreUrlAssignOverlayStyle(style),
        child: SemanticId(
          identifier: loginCoreUrlScreenId,
          child: WatchActionLayout(
            content: [
              Text(
                context.l10n.login_TextFieldLabelText_coreUrlAssign,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: context.adaptiveMetrics.gap * 2),
              LoginCoreUrlField(params: params, labelText: context.l10n.login_TextFieldLabelText_coreUrlAssignShort),
              if (postDescription.isNotEmpty) Description(text: postDescription, launchLinkableElement: true),
            ],
            primary: (overlay) => LoginCoreUrlProceedButton(params: params, style: overlay.merge(params.buttonStyle)),
          ),
        ),
      ),
    );
  }
}
