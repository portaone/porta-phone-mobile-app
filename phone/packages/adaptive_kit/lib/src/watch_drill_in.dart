import 'package:material_ui/material_ui.dart';

/// A watch screen that starts with a menu: choosing in it opens [content] on
/// the whole face, and going back returns to the menu instead of leaving.
///
/// What a phone shows side by side or as tabs, a face shows one after the
/// other. With [menuFirst] false - a menu of one - the content shows
/// straight away and going back leaves as usual.
class WatchDrillIn extends StatefulWidget {
  const WatchDrillIn({
    super.key,
    required this.menuFirst,
    required this.menu,
    required this.content,
    this.canGoBack = true,
  });

  /// Whether the face starts on the menu. When it changes - the menu grew
  /// past one entry or shrank to one - the face starts over from it.
  final bool menuFirst;

  /// The menu; [open] shows the content, after whatever the choice itself
  /// does.
  final Widget Function(BuildContext context, VoidCallback open) menu;

  final Widget content;

  /// False holds the face where it is: going back neither returns to the
  /// menu nor leaves, as while the content waits on a request it started.
  final bool canGoBack;

  @override
  State<WatchDrillIn> createState() => _WatchDrillInState();
}

class _WatchDrillInState extends State<WatchDrillIn> {
  late bool _onMenu = widget.menuFirst;

  @override
  void didUpdateWidget(WatchDrillIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuFirst != widget.menuFirst) _onMenu = widget.menuFirst;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.canGoBack && (_onMenu || !widget.menuFirst),
      onPopInvokedWithResult: _onPopInvoked,
      child: _onMenu ? widget.menu(context, _open) : widget.content,
    );
  }

  void _onPopInvoked(bool didPop, Object? _) {
    if (!didPop && widget.canGoBack) setState(() => _onMenu = true);
  }

  void _open() => setState(() => _onMenu = false);
}
