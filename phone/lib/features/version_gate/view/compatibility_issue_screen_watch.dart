import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The unsupported-core gate on a watch face.
///
/// The phone's text under the title - the reason and both versions - Update
/// as a row where the store has a newer build, Log out on the soft edge.
class CompatibilityIssueScreenWatch extends StatelessWidget {
  const CompatibilityIssueScreenWatch({
    super.key,
    required this.content,
    required this.onUpdate,
    required this.onLogout,
  });

  /// The reason and both versions, as the phone says them.
  final String content;

  /// Opens the store; null while the store has no newer build.
  final VoidCallback? onUpdate;

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = [
      Text(content, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
      if (onUpdate case final onUpdate?)
        WatchListTile(
          leading: const Icon(Icons.system_update),
          title: l10n.main_CompatibilityIssueDialogActions_update,
          onTap: onUpdate,
        ),
    ];
    return Scaffold(
      body: WatchScrollList.builder(
        title: l10n.main_CompatibilityIssueDialog_title,
        spacing: context.adaptiveMetrics.gap,
        itemCount: rows.length,
        itemBuilder: (context, index) => rows[index],
        edge: (context, overlay) => WatchAction(
          label: l10n.main_CompatibilityIssueDialogActions_logout,
          // styleFrom, not fixed colours: the press ripple follows the label's
          // colour instead of the theme's primary.
          style: OutlinedButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            foregroundColor: theme.colorScheme.onSurface,
          ),
          onPressed: onLogout,
        ).buildButton(overlay),
      ),
    );
  }
}
