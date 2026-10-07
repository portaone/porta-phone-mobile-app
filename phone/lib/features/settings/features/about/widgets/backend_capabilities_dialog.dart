import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// One capability name, as the backend spells it, and where it holds.
class BackendCapability {
  const BackendCapability({required this.name, required this.inSession, required this.onServer});

  final String name;

  /// The session was started with it, so the app acts on it.
  final bool inSession;

  /// The backend named it the last time it was read.
  final bool onServer;

  /// Every name either side knows, by name.
  ///
  /// [server] is null while nothing the backend said is stored; the session's
  /// own list then stands for both, since nothing says they differ.
  static List<BackendCapability> compare({required Set<String> session, required Set<String>? server}) {
    final known = server ?? session;
    return [
      for (final name in {...session, ...known}.toList()..sort())
        BackendCapability(name: name, inSession: session.contains(name), onServer: known.contains(name)),
    ];
  }
}

/// The backend capabilities the running session acts on, and what the backend
/// has changed since.
///
/// A session keeps the capabilities it was started with (see
/// `docs/features/feature_access.md`), so what the screens do is not what the
/// backend says right now. Nothing on a screen tells the two apart: a tester
/// who turned a capability off had to go looking for the feature it gates.
class BackendCapabilitiesDialog extends StatelessWidget {
  const BackendCapabilitiesDialog({super.key, required this.capabilities});

  final List<BackendCapability> capabilities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.settings_AboutText_BackendCapabilities, textAlign: TextAlign.center),
      content: SizedBox(
        width: double.maxFinite,
        child: SemanticId(
          identifier: aboutBackendCapabilitiesId,
          child: capabilities.isEmpty
              ? Text(l10n.settings_AboutBackendCapabilities_none)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: capabilities.length,
                  itemBuilder: (context, index) => _CapabilityRow(capability: capabilities[index]),
                ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.alertDialogActions_ok))],
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.capability});

  final BackendCapability capability;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final (icon, color, status) = switch (capability) {
      BackendCapability(inSession: true, onServer: true) => (Icons.check_circle_outline, null, null),
      BackendCapability(inSession: true) => (
        Icons.remove_circle_outline,
        theme.colorScheme.error,
        l10n.settings_AboutBackendCapabilities_removedOnServer,
      ),
      _ => (Icons.add_circle_outline, theme.colorScheme.primary, l10n.settings_AboutBackendCapabilities_addedOnServer),
    };

    // One node per capability: its name and, when the two sides differ, how.
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(capability.name),
                  if (status != null) Text(status, style: theme.textTheme.bodySmall?.copyWith(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
