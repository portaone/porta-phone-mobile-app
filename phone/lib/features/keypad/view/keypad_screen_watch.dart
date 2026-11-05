import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import 'keypad_screen_style.dart';
import 'keypad_view.dart';
import 'keypad_view_watch.dart';

/// The keypad screen on a watch: no app bar - a face has no room for one,
/// the name and the account belong to the watch's main screen - and no inset
/// under the pad, whose edge button sits on the bezel itself. The face is the
/// keys'.
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
      body: KeypadView(
        videoEnabled: videoEnabled,
        transferEnabled: transferEnabled,
        style: style,
        arrangement: (params) => KeypadViewWatch(params: params),
      ),
    );
  }
}
