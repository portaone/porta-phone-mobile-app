import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../login.dart';
import 'login_core_url_assign_handset.dart';
import 'login_core_url_assign_params.dart';
import 'login_core_url_assign_watch.dart';

class LoginCoreUrlAssignScreen extends StatefulWidget {
  const LoginCoreUrlAssignScreen({super.key});

  @override
  State<LoginCoreUrlAssignScreen> createState() => _LoginCoreUrlAssignScreenState();
}

class _LoginCoreUrlAssignScreenState extends State<LoginCoreUrlAssignScreen> {
  final HistoryAutocompleteController _historyController = HistoryAutocompleteController();

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final ElevatedButtonStyles? elevatedButtonStyles = themeData.extension<ElevatedButtonStyles>();

    // The logo is still borrowed from the switch screen style; the bar and
    // status bar are owned by this screen's own style.
    final LoginSwitchScreenStyles? loginPageStyles = themeData.extension<LoginSwitchScreenStyles>();
    final ownStyle = themeData.extension<LoginCoreUrlAssignScreenStyles>()?.primary;

    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) => whenLoginCoreUrlAssignScreenPageActive(current),
      builder: (context, state) {
        final params = LoginCoreUrlAssignParams(
          style: ownStyle,
          logoStyle: loginPageStyles?.primary?.pictureLogoStyle,
          buttonStyle: elevatedButtonStyles?.primary,
          historyController: _historyController,
          initialValue: state.coreUrlInput.value,
          errorText:
              state.coreUrlInput.displayError?.l10n(context) ??
              (state.coreUrlAssignError != null ? context.l10n.login_validationCoreUrlUnreachableError : null),
          processing: state.processing,
          onChanged: context.read<LoginCubit>().coreUrlInputChanged,
          onSubmit: !state.coreUrlInput.isValid ? null : () => _onCoreUrlAssignSubmitted(context),
        );

        // Both arrangements read the same params and the same controller,
        // built above the switch, so a resize across a class boundary keeps
        // what was typed.
        return AdaptiveLayout(
          handset: (_) => LoginCoreUrlAssignHandset(params: params),
          watch: (_) => LoginCoreUrlAssignWatch(params: params),
        );
      },
    );
  }

  void _onCoreUrlAssignSubmitted(BuildContext context) {
    _historyController.saveToHistory();
    context.read<LoginCubit>().loginCoreUrlAssignSubmitted();
  }
}
