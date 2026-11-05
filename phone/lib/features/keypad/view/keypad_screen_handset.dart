import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import 'keypad_screen_style.dart';
import 'keypad_view.dart';
import 'keypad_view_handset.dart';

/// The keypad screen on a phone: the main app bar with the title and the
/// account, the pad drawn behind it, and the pad kept above the system's
/// bottom inset.
class KeypadScreenHandset extends StatelessWidget {
  const KeypadScreenHandset({
    super.key,
    required this.title,
    required this.videoEnabled,
    required this.transferEnabled,
    required this.style,
  });

  final Widget? title;
  final bool videoEnabled;
  final bool transferEnabled;
  final KeypadScreenStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = this.style;
    return ThemedScaffold(
      background: style?.background,
      contentThemeOverride: style?.contentThemeOverride,
      applyToAppBar: style?.applyToAppBar ?? true,
      appBarTheme: style?.appBarTheme,
      extendBodyBehindAppBar: true,
      appBar: MainAppBar(
        title: title,
        context: context,
        flexibleSpace: BlurredSurface.fromStyle(style?.appBarBlurredSurface),
      ),
      body: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: KeypadView(
          videoEnabled: videoEnabled,
          transferEnabled: transferEnabled,
          style: style,
          arrangement: (params) => KeypadViewHandset(params: params),
        ),
      ),
    );
  }
}
