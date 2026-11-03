import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import 'keypad_screen_style.dart';
import 'keypad_view.dart';

/// The keypad screen on a watch: no app bar - the hub it came from shows the
/// name and the account - and no inset under the pad, whose edge button sits
/// on the bezel itself. The face is the keys'.
class KeypadScreenWatch extends StatelessWidget {
  const KeypadScreenWatch({super.key, required this.videoEnabled, required this.transferEnabled, required this.style});

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
      body: KeypadView(videoEnabled: videoEnabled, transferEnabled: transferEnabled, style: style),
    );
  }
}
