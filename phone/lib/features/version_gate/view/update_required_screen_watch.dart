import 'package:material_ui/material_ui.dart';

import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The force-update gate on a watch face.
///
/// Why in a line, the versions as rows, Log out as the last row; Update on
/// the edge once the store has the app.
class UpdateRequiredScreenWatch extends StatelessWidget {
  const UpdateRequiredScreenWatch({
    super.key,
    required this.currentVersion,
    required this.storeVersion,
    required this.minSupportedVersion,
    required this.onUpdate,
    required this.onLogout,
  });

  final Version currentVersion;
  final String storeVersion;
  final Version minSupportedVersion;

  /// Opens the store; null until the store listing resolves.
  final VoidCallback? onUpdate;

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = [
      Text(
        l10n.main_AppUpdateRequiredDialog_description,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      WatchInfoRow(label: l10n.main_AppUpdateRequiredDialog_currentVersionLabel, value: currentVersion.toString()),
      WatchInfoRow(label: l10n.main_AppUpdateRequiredDialog_buildVersionLabel, value: storeVersion),
      WatchInfoRow(label: l10n.main_AppUpdateRequiredDialog_minimumVersionLabel, value: minSupportedVersion.toString()),
      WatchListTile(
        leading: Icon(Icons.logout, color: theme.colorScheme.error),
        title: l10n.main_CompatibilityIssueDialogActions_logout,
        onTap: onLogout,
      ),
    ];
    return Scaffold(
      body: WatchScrollList.builder(
        title: l10n.main_AppUpdateRequiredDialog_title,
        spacing: context.adaptiveMetrics.gap,
        itemCount: rows.length,
        itemBuilder: (context, index) => rows[index],
        edge: switch (onUpdate) {
          null => null,
          final onUpdate => (context, overlay) => WatchAction(
            label: l10n.main_CompatibilityIssueDialogActions_update,
            onPressed: onUpdate,
          ).buildButton(overlay),
        },
      ),
    );
  }
}
