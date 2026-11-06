import 'package:material_ui/material_ui.dart';

/// A watch screen that starts with a menu: choosing in it opens [content] on
/// the whole face, and going back returns to the menu instead of leaving.
///
/// What a phone shows side by side or as tabs, a face shows one after the
/// other. With [menuFirst] false - a menu of one - the content shows
/// straight away and going back leaves as usual.
class WatchDrillIn extends StatefulWidget {
  const WatchDrillIn({super.key, required this.menuFirst, required this.menu, required this.content});

  final bool menuFirst;

  /// The menu; [open] shows the content, after whatever the choice itself
  /// does.
  final Widget Function(BuildContext context, VoidCallback open) menu;

  final Widget content;

  @override
  State<WatchDrillIn> createState() => _WatchDrillInState();
}

class _WatchDrillInState extends State<WatchDrillIn> {
  late bool _onMenu = widget.menuFirst;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _onMenu || !widget.menuFirst,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _onMenu = true);
      },
      child: _onMenu ? widget.menu(context, _open) : widget.content,
    );
  }

  void _open() => setState(() => _onMenu = false);
}
