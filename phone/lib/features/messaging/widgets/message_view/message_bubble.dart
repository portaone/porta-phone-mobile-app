import 'package:flutter/material.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

/// One message in a conversation: the bubble with its content on the
/// sender's side of the row, an optional [leading] slot beside it, and the
/// menu of [actions] a long press on the bubble opens.
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.isMine,
    required this.decoration,
    required this.padding,
    required this.actions,
    required this.child,
    this.leading,
    this.fadeIn = false,
  });

  final bool isMine;
  final Decoration decoration;
  final EdgeInsetsGeometry padding;

  /// The menu a long press opens. With nothing in it the bubble offers no
  /// long press at all - to a finger or to a screen reader.
  final List<PopupMenuEntry<dynamic>> actions;

  final Widget child;

  /// What stands beside an incoming bubble: the sender's avatar, or the room
  /// kept for it.
  final Widget? leading;

  /// Whether the bubble fades in, as a message that has just arrived does.
  final bool fadeIn;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final _bubbleKey = GlobalKey();

  Future<void> _openActions() async {
    // An open keyboard is put away first, and the menu waits for it to go so
    // it lands where the bubble is once the layout has settled.
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
    }
    showMenu<dynamic>(context: context, position: _anchor(), items: widget.actions);
  }

  /// Where the menu hangs: off the bubble's bottom corner on the sender's
  /// side, and never above the status bar.
  RelativeRect _anchor() {
    final bubble = _bubbleKey.currentContext!.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    var top = bubble.localToGlobal(Offset.zero, ancestor: overlay);
    final statusBar = MediaQuery.paddingOf(context).top;
    if (top.dy < statusBar) top = Offset(top.dx, statusBar + 12);
    final corner = widget.isMine ? bubble.size.bottomRight(Offset.zero) : bubble.size.bottomLeft(Offset.zero);
    final bottom = bubble.localToGlobal(corner, ancestor: overlay);
    return RelativeRect.fromRect(Rect.fromPoints(top, bottom), Offset.zero & overlay.size);
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    final hasActions = widget.actions.isNotEmpty;

    final bubble = GestureDetector(
      onLongPress: hasActions ? _openActions : null,
      child: Container(
        key: _bubbleKey,
        decoration: widget.decoration,
        padding: widget.padding,
        child: IntrinsicWidth(child: widget.child),
      ),
    );

    return Padding(
      padding: isMine
          ? const EdgeInsets.only(left: 48, right: 8, top: 4, bottom: 4)
          : const EdgeInsets.only(left: 8, right: 48, top: 4, bottom: 4),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ?widget.leading,
          Flexible(
            child: FadeIn(duration: widget.fadeIn ? const Duration(milliseconds: 300) : Duration.zero, child: bubble),
          ),
        ],
      ),
    );
  }
}
