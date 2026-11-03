import 'package:material_ui/material_ui.dart';

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
/// field's own prompt is the title instead.
class LoginCoreUrlAssignWatch extends StatelessWidget {
  const LoginCoreUrlAssignWatch({super.key, required this.params});

  final LoginCoreUrlAssignParams params;

  @override
  Widget build(BuildContext context) {
    final style = params.style;
    final postDescription = context.l10n.login_Text_coreUrlAssignPostDescription(EnvironmentConfig.SALES_EMAIL);

    // Back is a swipe here, with no button to disable: while the URL is
    // checked the swipe waits, as the phone's back button does.
    return PopScope(
      canPop: !params.processing,
      child: LoginCoreUrlAssignScaffold.watch(
        style: style,
        body: SemanticId(
          identifier: loginCoreUrlScreenId,
          child: WatchActionLayout(
            title: context.l10n.login_TextFieldLabelText_coreUrlAssign,
            content: [
              LoginCoreUrlField(
                params: params,
                labelText: context.l10n.login_TextFieldLabelText_coreUrlAssignShort,
                // A list dropping under the field would cover Proceed and run
                // past the bezel.
                suggestHistory: false,
              ),
              if (postDescription.isNotEmpty) Description(text: postDescription, launchLinkableElement: true),
            ],
            primary: (overlay) => LoginCoreUrlProceedButton(params: params, style: overlay.merge(params.buttonStyle)),
          ),
        ),
      ),
    );
  }
}
