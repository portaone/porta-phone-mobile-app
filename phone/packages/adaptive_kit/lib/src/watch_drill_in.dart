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
    this.keepContent = false,
    this.openOn,
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

  /// Keeps [content] built, hidden and paused, while the menu shows, so what
  /// it holds - a number typed, a list scrolled, a page loaded - is there
  /// when it opens again, as a phone keeps its tabs.
  final bool keepContent;

  /// Opens the content whenever it changes - something outside the face
  /// moved to the content, as a choice somebody was sent to make, or a
  /// section opened from elsewhere.
  final Object? openOn;

  /// Whether going back from [context] belongs to a drill-in above it. The
  /// content then leaves back alone: one press returns to the menu, rather
  /// than also stepping back in the content.
  static bool ownsBack(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_BackOwner>() != null;

  @override
  State<WatchDrillIn> createState() => _WatchDrillInState();
}

class _WatchDrillInState extends State<WatchDrillIn> {
  late bool _onMenu = widget.menuFirst;

  @override
  void didUpdateWidget(WatchDrillIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.menuFirst != widget.menuFirst) {
      _onMenu = widget.menuFirst;
    } else if (oldWidget.openOn != widget.openOn) {
      _onMenu = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _BackOwner(child: widget.content);
    return PopScope(
      canPop: widget.canGoBack && (_onMenu || !widget.menuFirst),
      onPopInvokedWithResult: _onPopInvoked,
      child: widget.keepContent
          ? Stack(
              fit: StackFit.expand,
              children: [
                Offstage(
                  offstage: _onMenu,
                  child: TickerMode(enabled: !_onMenu, child: content),
                ),
                if (_onMenu) widget.menu(context, _open),
              ],
            )
          : _onMenu
          ? widget.menu(context, _open)
          : content,
    );
  }

  void _onPopInvoked(bool didPop, Object? _) {
    if (!didPop && widget.canGoBack) setState(() => _onMenu = true);
  }

  void _open() => setState(() => _onMenu = false);
}

class _BackOwner extends InheritedWidget {
  const _BackOwner({required super.child});

  @override
  bool updateShouldNotify(_BackOwner oldWidget) => false;
}
