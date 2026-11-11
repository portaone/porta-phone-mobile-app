import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The session restart on a watch face.
///
/// On its way, the spinner and the line saying why; unreachable, the reason
/// with Try again on the edge and Log out under it.
class SessionRestartScreenWatch extends StatelessWidget {
  const SessionRestartScreenWatch({
    super.key,
    required this.unreachable,
    required this.progressText,
    required this.onRetry,
    required this.onLogOut,
  });

  /// Whether the core could not be reached.
  final bool unreachable;

  /// What the screen is waiting for, under the spinner.
  final String progressText;

  final VoidCallback onRetry;

  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: unreachable
          ? WatchStatePage(
              icon: const Icon(Icons.cloud_off),
              message: l10n.session_Restart_unreachableText,
              action: WatchAction(
                label: l10n.session_Restart_retryButton,
                identifier: sessionRestartRetryButtonId,
                buttonKey: sessionRestartRetryButtonKey,
                onPressed: onRetry,
              ),
              footer: [
                WatchListTile(
                  key: sessionRestartLogoutButtonKey,
                  identifier: sessionRestartLogoutButtonId,
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: l10n.session_Restart_logoutButton,
                  onTap: onLogOut,
                ),
              ],
            )
          : WatchStatePage.loading(progressLabel: l10n.common_SemanticsLabel_loading, hint: progressText),
    );
  }
}
