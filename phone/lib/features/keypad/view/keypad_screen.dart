import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import 'keypad_screen_handset.dart';
import 'keypad_screen_style.dart';
import 'keypad_screen_styles.dart';
import 'keypad_screen_watch.dart';

export 'keypad_screen_style.dart';
export 'keypad_screen_styles.dart';

class KeypadScreen extends StatelessWidget {
  const KeypadScreen({super.key, this.title, required this.videoEnabled, required this.transferEnabled, this.style});

  final Widget? title;
  final bool videoEnabled;
  final bool transferEnabled;
  final KeypadScreenStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ?? Theme.of(context).extension<KeypadScreenStyles>()?.primary;
    return AdaptiveLayout(
      handset: (_) => KeypadScreenHandset(
        title: title,
        videoEnabled: videoEnabled,
        transferEnabled: transferEnabled,
        style: effectiveStyle,
      ),
      watch: (_) =>
          KeypadScreenWatch(videoEnabled: videoEnabled, transferEnabled: transferEnabled, style: effectiveStyle),
    );
  }
}
