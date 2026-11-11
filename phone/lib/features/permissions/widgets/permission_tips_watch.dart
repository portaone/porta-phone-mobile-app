import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The tips on a watch face: the title, the steps and notes in small text
/// that scroll, going to the settings - what the steps lead to - at their
/// end, and the dismissal as the edge button, the main action as on a phone,
/// so leaving the tips never waits on scrolling through them.
class PermissionTipsWatch extends StatelessWidget {
  const PermissionTipsWatch({
    super.key,
    required this.title,
    required this.instruction,
    required this.onGoToAppSettings,
    required this.onPop,
    this.note,
    this.dismissLabel,
  });

  final String title;
  final List<String> instruction;
  final VoidCallback onGoToAppSettings;
  final VoidCallback? onPop;

  /// What the user is choosing when they move on without granting the permission.
  /// Omitted where there is nothing to choose.
  final String? note;

  /// Label of the button that leaves the screen. Defaults to acknowledging the tips.
  final String? dismissLabel;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final ElevatedButtonStyles? elevatedButtonStyles = themeData.extension<ElevatedButtonStyles>();
    final note = this.note;
    final gap = context.adaptiveMetrics.gap;

    return WatchActionLayout(
      title: title,
      content: [
        for (final (index, step) in instruction.indexed) Text('${index + 1}. $step'),
        SizedBox(height: gap),
        Text(context.l10n.permission_manufacturer_Text_trailing, textAlign: TextAlign.center),
        if (note != null) ...[SizedBox(height: gap), Text(note, textAlign: TextAlign.center)],
      ],
      secondary: SemanticAction(
        identifier: permissionTipsSettingsButtonId,
        child: OutlinedButton(
          key: permissionTipsSettingsButtonKey,
          onPressed: onGoToAppSettings,
          style: WatchPill.style.merge(elevatedButtonStyles?.neutral),
          child: Text(context.l10n.permission_manufacturer_Button_toSettings),
        ),
      ),
      action: WatchAction(
        label: dismissLabel ?? context.l10n.permission_manufacturer_Button_gotIt,
        onPressed: onPop,
        style: elevatedButtonStyles?.primary,
        identifier: permissionTipsButtonId,
        buttonKey: permissionTipsButtonKey,
      ),
    );
  }
}
