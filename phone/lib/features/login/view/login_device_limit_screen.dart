import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/login_cubit.dart';

bool whenLoginDeviceLimitScreenChange(LoginState previous, LoginState current) {
  return previous.pendingLogin != current.pendingLogin ||
      previous.pendingLoginRevokingSessionId != current.pendingLoginRevokingSessionId;
}

/// Shown instead of signing in when the account is on as many devices as it is
/// allowed: the user picks one of them to sign out, and this one is signed in.
class LoginDeviceLimitScreen extends StatelessWidget {
  const LoginDeviceLimitScreen({super.key, required this.dateFormat});

  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    // While a device is being signed out the screen cannot be left: the answer
    // would arrive for a login the user had already walked away from.
    return BlocSelector<LoginCubit, LoginState, bool>(
      selector: (state) => state.processing,
      builder: (context, processing) {
        return PopScope(
          canPop: !processing,
          child: AdaptiveLayout(
            handset: (context) => Scaffold(
              appBar: AppBar(
                title: Text(context.l10n.login_Text_deviceLimitTitle),
                leading: ExtBackButton(disabled: processing),
              ),
              body: SafeArea(child: LoginDeviceLimitBody(dateFormat: dateFormat)),
            ),
            // No app bar: the list draws the whole face under the screen's
            // name; Back is the watch's swipe, held by the same PopScope.
            watch: (context) => Scaffold(body: LoginDeviceLimitBody(dateFormat: dateFormat)),
          ),
        );
      },
    );
  }
}

/// The devices of the account, each with the action that signs it out and
/// finishes the login left waiting.
class LoginDeviceLimitBody extends StatelessWidget {
  const LoginDeviceLimitBody({super.key, required this.dateFormat});

  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return SemanticId(
      identifier: loginDeviceLimitScreenId,
      child: BlocBuilder<LoginCubit, LoginState>(
        buildWhen: whenLoginDeviceLimitScreenChange,
        builder: (context, state) {
          // Empty while the screen is leaving: the login it was shown for is gone by then.
          final sessions = state.pendingLogin?.sessions ?? const <ActiveSession>[];
          // On a watch the same rows are pills with a gap between them.
          final tiles = SessionTiles(
            children: [
              for (final (index, session) in sessions.indexed)
                SessionTile(
                  session: session,
                  index: index,
                  dateFormat: dateFormat,
                  revoking: state.pendingLoginRevokingSessionId == session.id,
                  onRevoke: (session) => _onRevoke(context, session),
                ),
            ],
          );

          if (context.formFactor == FormFactor.watch) {
            final themeData = Theme.of(context);
            return WatchScrollList(
              title: context.l10n.login_Text_deviceLimitTitle,
              spacing: context.adaptiveMetrics.gap,
              children: [
                Text(
                  context.l10n.login_Text_deviceLimitDescription,
                  textAlign: TextAlign.center,
                  style: themeData.textTheme.bodySmall?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
                ),
                tiles,
              ],
            );
          }

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(kInset, kInset, kInset, kInset / 2),
                child: Text(context.l10n.login_Text_deviceLimitDescription),
              ),
              tiles,
            ],
          );
        },
      ),
    );
  }

  Future<void> _onRevoke(BuildContext context, ActiveSession session) async {
    // While one device is being signed out the others keep their rows, but
    // the login takes no second pick: on a watch, where the question takes the
    // whole face, it is not asked when a yes would do nothing. The phone asks
    // as it always has.
    if (context.formFactor == FormFactor.watch && context.read<LoginCubit>().state.processing) return;

    final confirmed = await ConfirmDialog.showDangerous(
      context,
      title: context.l10n.sessions_RevokeConfirmDialog_title,
      content: context.l10n.sessions_RevokeConfirmDialog_content,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<LoginCubit>().loginDeviceLimitSessionPicked(session.id);
  }
}
