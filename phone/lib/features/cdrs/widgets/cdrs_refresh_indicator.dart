import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

/// Pull to refresh over a call history list, on either arrangement: a failed
/// refresh is said in a snackbar and the list stays as it was.
class CdrsRefreshIndicator extends StatelessWidget {
  const CdrsRefreshIndicator({super.key, required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  Future<void> _refresh(BuildContext context) async {
    try {
      await onRefresh();
    } catch (_) {
      // Cached records keep the list visible after a failed cycle, so the
      // task-state failure does not replace the content with an error view.
      if (context.mounted) {
        context.showErrorSnackBar(context.l10n.cdrs_refreshFailed_message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      edgeOffset: MediaQuery.of(context).padding.top,
      onRefresh: () => _refresh(context),
      child: child,
    );
  }
}
