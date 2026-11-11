import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../widgets/widgets.dart';
import 'settings_screen_style.dart';
import 'settings_screen_styles.dart';

/// Settings on a watch. No app bar: the list draws the whole face under the
/// account's name, and Log out is its last row.
class SettingsScreenWatch extends StatelessWidget {
  const SettingsScreenWatch({
    super.key,
    required this.sections,
    required this.sessionsEnabled,
    this.style,
    required this.onDiagnostic,
    required this.onSessions,
    required this.onRegisterChanged,
    required this.onItem,
    required this.onLogout,
  });

  final List<SettingsSection> sections;
  final bool sessionsEnabled;
  final SettingScreenStyle? style;
  final VoidCallback onDiagnostic;
  final VoidCallback onSessions;
  final ValueChanged<bool> onRegisterChanged;
  final ValueChanged<SettingItem> onItem;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).extension<SettingsScreenStyles>()?.primary;
    return ThemedScaffold(
      background: effectiveStyle?.background,
      contentThemeOverride: effectiveStyle?.contentThemeOverride,
      body: SettingsWatchList(
        sections: sections,
        sessionsEnabled: sessionsEnabled,
        onDiagnostic: onDiagnostic,
        onSessions: onSessions,
        onRegisterChanged: onRegisterChanged,
        onItem: onItem,
        onLogout: onLogout,
      ),
    );
  }
}
