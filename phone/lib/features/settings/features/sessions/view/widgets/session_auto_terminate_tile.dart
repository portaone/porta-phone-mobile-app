import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'session_auto_terminate_period.dart';

/// The row above the session list that says when idle sessions end.
///
/// Where the user may choose ([selectable]) it is a setting that opens the
/// choice; elsewhere it only states the period, and says nothing at all when
/// sessions never end - there is nothing to warn about then.
class SessionAutoTerminateTile extends StatelessWidget {
  const SessionAutoTerminateTile({
    super.key,
    required this.autoTerminate,
    required this.selectable,
    required this.saving,
    required this.onTap,
  });

  final SessionAutoTerminate autoTerminate;

  final bool selectable;

  /// A new period is on its way to the core; the row cannot be opened again.
  final bool saving;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = autoTerminate.inactivityTimeoutDays;

    if (!selectable) {
      if (days == null) return const SizedBox.shrink();
      return SemanticId(
        identifier: sessionsAutoTerminateInfoId,
        child: ListTile(leading: const Icon(Icons.timer_outlined), title: Text(l10n.sessions_AutoTerminate_info(days))),
      );
    }

    return SemanticAction(
      identifier: sessionsAutoTerminateId,
      child: ListTile(
        key: sessionsAutoTerminateKey,
        leading: const Icon(Icons.timer_outlined),
        title: Text(l10n.sessions_AutoTerminate_title),
        subtitle: Text(sessionAutoTerminatePeriod(l10n, days)),
        trailing: saving
            ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.chevron_right),
        onTap: saving ? null : onTap,
      ),
    );
  }
}
