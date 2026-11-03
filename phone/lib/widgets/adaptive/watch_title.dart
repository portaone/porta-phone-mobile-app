import 'package:material_ui/material_ui.dart';

/// The title of a watch screen: short, centred, in place of the icon or the
/// app bar a phone screen has.
class WatchTitle extends StatelessWidget {
  const WatchTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
