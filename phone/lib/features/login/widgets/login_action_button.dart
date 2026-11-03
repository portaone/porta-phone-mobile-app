import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The main button of a sign-in step - a way in on the landing, Proceed on
/// the custom-core screen, the action of each form: its title, or a spinner
/// while the step is under way, when it does not take a press.
class LoginActionButton extends StatelessWidget {
  const LoginActionButton({
    super.key,
    required this.title,
    required this.processing,
    required this.onPressed,
    required this.style,
    this.identifier,
    this.buttonKey,
  });

  final String title;

  /// Shows the spinner in place of the title and takes no press.
  final bool processing;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// The style to draw the button with; the spinner takes its colour from
  /// it too.
  final ButtonStyle? style;

  /// The automation id of the button.
  final String? identifier;

  /// The key of the button itself, for the tests that reach it.
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(
      key: buttonKey,
      onPressed: processing ? null : onPressed,
      style: style,
      child: !processing
          ? Text(title)
          : SizedCircularProgressIndicator(
              size: 16,
              strokeWidth: 2,
              color: style?.foregroundColor?.resolve({}),
              semanticsLabel: context.l10n.common_SemanticsLabel_loading,
            ),
    );
    final identifier = this.identifier;
    return identifier == null ? button : SemanticAction(identifier: identifier, child: button);
  }
}
