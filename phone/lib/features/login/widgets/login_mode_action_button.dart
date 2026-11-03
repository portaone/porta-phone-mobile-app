import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class LoginModeActionButton extends StatelessWidget {
  const LoginModeActionButton({
    super.key,
    required this.processing,
    required this.onPressed,
    required this.style,
    required this.title,
    this.maxLines,
  });

  final bool processing;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final String title;

  /// Lines the title may take before it ends in an ellipsis; unlimited when
  /// null.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: processing ? null : onPressed,
      style: style,
      child: !processing
          ? Text(
              title,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              textAlign: maxLines != null ? TextAlign.center : null,
            )
          : SizedCircularProgressIndicator(
              size: 16,
              strokeWidth: 2,
              color: style?.foregroundColor?.resolve({}),
              semanticsLabel: context.l10n.common_SemanticsLabel_loading,
            ),
    );
  }
}
