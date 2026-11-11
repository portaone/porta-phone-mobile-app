import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The permissions step on a watch face: a title instead of the icon, the
/// explanation in small text that scrolls, and Continue - which starts the
/// system prompts - as the edge button.
class PermissionsScreenWatch extends StatelessWidget {
  const PermissionsScreenWatch({super.key, required this.onContinue, required this.buttonStyle, required this.child});

  final VoidCallback? onContinue;
  final ButtonStyle? buttonStyle;

  /// The button's label, or its progress while the prompts run.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return WatchActionLayout(
      title: context.l10n.permission_Text_title,
      content: [Text(context.l10n.permission_Text_description, textAlign: TextAlign.center)],
      primary: (overlay) => SemanticAction(
        identifier: permissionsInitButtonId,
        child: OutlinedButton(
          key: permissionsInitButtonKey,
          onPressed: onContinue,
          style: overlay.merge(buttonStyle),
          child: child,
        ),
      ),
    );
  }
}
