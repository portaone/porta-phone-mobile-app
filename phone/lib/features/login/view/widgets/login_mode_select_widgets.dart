import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../../widgets/login_action_button.dart';
import '../login_mode_select_params.dart';

/// The landing's scaffold, themed the same in every arrangement: the
/// configured background, theme override and app bar theme.
class LoginModeSelectScaffold extends StatelessWidget {
  const LoginModeSelectScaffold({
    super.key,
    required this.params,
    required this.body,
    this.appBar,
    this.extendBodyBehindAppBar = false,
  });

  final LoginModeSelectParams params;
  final Widget body;

  /// The phone's bar; none on a face.
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final style = params.style;
    return ThemedScaffold(
      background: style?.background,
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar ?? true,
      appBarTheme: style?.appBarTheme,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      body: body,
    );
  }
}

/// A launch button of the landing, with the automation id its entry carries.
class LoginModeSelectEntryButton extends StatelessWidget {
  const LoginModeSelectEntryButton({super.key, required this.entry, required this.style, this.maxLines});

  final LoginModeSelectEntry entry;

  /// The theme's button style, with whatever the arrangement lays over it.
  final ButtonStyle? style;

  /// Lines the title may take; unlimited when null.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return LoginActionButton(
      key: entry.buttonKey,
      identifier: entry.semanticsId,
      processing: entry.processing,
      onPressed: entry.onPressed,
      style: style,
      title: entry.title,
      maxLines: maxLines,
    );
  }
}
