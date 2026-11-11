import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/login_cubit.dart';
import 'login_device_limit_screen.dart';

/// The device limit on a watch face: the devices of the account as rows
/// under the screen's name, a tap signing one out and finishing the login
/// left waiting.
///
/// No app bar: the list draws the whole face under the screen's name; Back
/// is the watch's swipe, held by the screen's PopScope.
class LoginDeviceLimitWatch extends StatelessWidget {
  const LoginDeviceLimitWatch({super.key, required this.dateFormat});

  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SemanticId(
        identifier: loginDeviceLimitScreenId,
        child: BlocBuilder<LoginCubit, LoginState>(
          buildWhen: whenLoginDeviceLimitScreenChange,
          builder: (context, state) {
            // Empty while the screen is leaving: the login it was shown for is gone by then.
            final sessions = state.pendingLogin?.sessions ?? const <ActiveSession>[];
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
                // Each row a pill of its own: a gap between them, no surface
                // or divider.
                Column(
                  spacing: context.adaptiveMetrics.gap,
                  children: [
                    for (final (index, session) in sessions.indexed)
                      SessionWatchTile(
                        session: session,
                        index: index,
                        dateFormat: dateFormat,
                        revoking: state.pendingLoginRevokingSessionId == session.id,
                        onRevoke: (session) => _onRevoke(context, session),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onRevoke(BuildContext context, ActiveSession session) async {
    // While one device is being signed out the others keep their rows, but
    // the login takes no second pick: where the question takes the whole
    // face, it is not asked when a yes would do nothing.
    if (context.read<LoginCubit>().state.processing) return;

    final confirmed = await ConfirmDialog.showDangerous(
      context,
      title: context.l10n.sessions_RevokeConfirmDialog_title,
      content: context.l10n.sessions_RevokeConfirmDialog_content,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<LoginCubit>().loginDeviceLimitSessionPicked(session.id);
  }
}
