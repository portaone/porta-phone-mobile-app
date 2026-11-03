import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';

import '../login.dart';
import 'login_mode_select_handset.dart';
import 'login_mode_select_params.dart';

export 'login_mode_select_screen_style.dart';
export 'login_mode_select_screen_styles.dart';

class LoginModeSelectScreen extends StatelessWidget {
  const LoginModeSelectScreen({super.key, this.appGreetingL10n, this.style, required this.launchButtons});

  final String? appGreetingL10n;

  final LoginModeSelectScreenStyle? style;
  final List<LoginModeAction> launchButtons;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final ElevatedButtonStyles? elevatedButtonStyles = themeData.extension<ElevatedButtonStyles>();
    final LoginModeSelectScreenStyles? loginPageStyles = themeData.extension<LoginModeSelectScreenStyles>();

    final localStyle = style ?? loginPageStyles?.primary;

    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => previous.processing != current.processing,
      builder: (context, state) {
        // TODO(Serdun): Looks like we can move logic with enabling demo mode to the app config
        final isDemoModeEnabled = context.read<LoginCubit>().isDemoModeEnabled;
        final shouldProcess = state.processing;

        final params = LoginModeSelectParams(
          style: localStyle,
          buttonStyle: elevatedButtonStyles?.getStyle(localStyle?.signUpTypeButton),
          greeting: appGreetingL10n != null ? context.parseL10n(appGreetingL10n!) : null,
          entries: launchButtons.map((button) => _entry(context, state, button)).toList(growable: false),
          customCoreEntry: isDemoModeEnabled
              ? LoginModeSelectEntry(
                  title: context.l10n.login_ButtonTooltip_signInToYourInstance,
                  processing: false,
                  onPressed: shouldProcess ? null : () => _onCustomCoreLogin(context),
                  buttonKey: loginModeScreenUrlButtonKey,
                )
              : null,
        );

        // Both arrangements read the same params, built above the switch, so
        // a resize across a class boundary loses nothing.
        return LoginModeSelectHandset(params: params);
      },
    );
  }

  LoginModeSelectEntry _entry(BuildContext context, LoginState state, LoginModeAction button) {
    final shouldProcess = state.processing;

    // Determine if the button should show a loading state:
    // - If the app is processing:
    //   - For non-embedded buttons: show loading only when no embedded switch is active
    //   - For embedded buttons: show loading only if the active embedded config matches this button
    final processing =
        shouldProcess &&
        switch (button) {
          LoginEmbeddedModeButton(:final customLoginFeature) => state.embedded == customLoginFeature,
          _ => state.embedded == null,
        };

    // Use a stable key for integration tests:
    // - assign the dedicated test key for the sign-up flavor
    // - otherwise generate a unique ValueKey from the button
    final buttonKey = button.flavor == LoginFlavor.login ? loginModeScreenSignUpButtonKey : ValueKey(button.hashCode);

    return LoginModeSelectEntry(
      title: context.parseL10n(button.titleL10n),
      processing: processing,
      onPressed: shouldProcess ? null : () => _onActionPressed(context, button),
      buttonKey: buttonKey,
      // Only the sign-up flavor has a stable anchor; the rest are configured
      // per brand and their ids would not survive a config change.
      semanticsId: button.flavor == LoginFlavor.login ? loginModeScreenSignUpButtonId : null,
    );
  }

  void _onActionPressed(BuildContext context, LoginModeAction action) {
    final cubit = context.read<LoginCubit>();
    final mode = cubit.isDemoModeEnabled ? LoginMode.demoCore : LoginMode.core;

    if (action case LoginEmbeddedModeButton(:final customLoginFeature)) {
      cubit.setEmbedded(customLoginFeature);
    }

    cubit.loginModeSelectSubmitted(mode);
  }

  void _onCustomCoreLogin(BuildContext context) {
    context.read<LoginCubit>().loginModeSelectSubmitted(LoginMode.customCore);
  }
}
