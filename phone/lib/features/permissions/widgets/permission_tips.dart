import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class PermissionTips extends StatelessWidget {
  const PermissionTips({
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

    return Scaffold(
      body: AdaptiveLayout(
        watch: (context) => _PermissionTipsWatch(tips: this),
        handset: (context) => LayoutBuilder(
          builder: (context, viewportConstraints) {
            final body = Padding(
              padding: const EdgeInsets.all(kInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: kInset * 2),
                  Icon(Icons.settings_suggest, color: themeData.colorScheme.primary, size: kInset * 6),
                  const SizedBox(height: kInset * 2),
                  Text(title, textAlign: TextAlign.center, style: themeData.textTheme.bodyLarge),
                  const SizedBox(height: kInset / 4),
                  Card(
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: instruction.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: kInset / 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${entry.key + 1}. ', style: themeData.textTheme.labelLarge),
                                Expanded(child: Text(entry.value, style: themeData.textTheme.labelLarge)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.permission_manufacturer_Text_trailing,
                    textAlign: TextAlign.center,
                    style: themeData.textTheme.labelMedium,
                  ),
                  if (note != null) ...[
                    const SizedBox(height: kInset / 2),
                    Text(note!, textAlign: TextAlign.center, style: themeData.textTheme.labelMedium),
                  ],
                  const Spacer(),
                  const SizedBox(height: kInset),
                  SemanticAction(
                    identifier: permissionTipsSettingsButtonId,
                    child: OutlinedButton(
                      key: permissionTipsSettingsButtonKey,
                      onPressed: onGoToAppSettings,
                      style: elevatedButtonStyles?.neutral,
                      child: Text(context.l10n.permission_manufacturer_Button_toSettings),
                    ),
                  ),
                  const SizedBox(height: kInset / 4),
                  SemanticAction(
                    identifier: permissionTipsButtonId,
                    child: OutlinedButton(
                      key: permissionTipsButtonKey,
                      onPressed: onPop,
                      style: elevatedButtonStyles?.primary,
                      child: Text(dismissLabel ?? context.l10n.permission_manufacturer_Button_gotIt),
                    ),
                  ),
                ],
              ),
            );

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
                child: IntrinsicHeight(child: InertSafeArea(bottom: true, child: body)),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The tips on a watch face: the title, the steps and notes in small text
/// that scroll, going to the settings - what the steps lead to - at their
/// end, and the dismissal as the edge button, the main action as on a phone,
/// so leaving the tips never waits on scrolling through them.
class _PermissionTipsWatch extends StatelessWidget {
  const _PermissionTipsWatch({required this.tips});

  final PermissionTips tips;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final ElevatedButtonStyles? elevatedButtonStyles = themeData.extension<ElevatedButtonStyles>();
    final note = tips.note;
    final gap = context.adaptiveMetrics.gap;

    return WatchActionLayout(
      title: tips.title,
      content: [
        for (final (index, step) in tips.instruction.indexed) Text('${index + 1}. $step'),
        SizedBox(height: gap),
        Text(context.l10n.permission_manufacturer_Text_trailing, textAlign: TextAlign.center),
        if (note != null) ...[SizedBox(height: gap), Text(note, textAlign: TextAlign.center)],
      ],
      secondary: SemanticAction(
        identifier: permissionTipsSettingsButtonId,
        child: OutlinedButton(
          key: permissionTipsSettingsButtonKey,
          onPressed: tips.onGoToAppSettings,
          style: WatchPill.style.merge(elevatedButtonStyles?.neutral),
          child: Text(context.l10n.permission_manufacturer_Button_toSettings),
        ),
      ),
      action: WatchAction(
        label: tips.dismissLabel ?? context.l10n.permission_manufacturer_Button_gotIt,
        onPressed: tips.onPop,
        style: elevatedButtonStyles?.primary,
        identifier: permissionTipsButtonId,
        buttonKey: permissionTipsButtonKey,
      ),
    );
  }
}
