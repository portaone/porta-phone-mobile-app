import 'package:flutter/material.dart';

/// One entry of a messaging popup menu, carrying a stable id where the id has
/// to sit.
///
/// The same reason as the call menu's entry: a popup item merges its subtree
/// into one node, and only the node that OWNS the identifier hands it to the
/// platform - an identifier absorbed from a merged child shows up in a widget
/// test and arrives nowhere on the device. Wrapping the child in a plain
/// identifier is worse still: it forces a node of its own above the one that
/// carries the tap, so the entry is announced unnamed and a flow that finds
/// it by id cannot activate it. So the merge is started from the outside,
/// with the identifier on top of it, and the item's words and tap are
/// absorbed into that node.
class MessagingPopupMenuItem<T> extends PopupMenuEntry<T> {
  const MessagingPopupMenuItem({super.key, this.value, this.onTap, required this.identifier, required this.child});

  final T? value;
  final VoidCallback? onTap;

  /// Stable automation id of the entry; it is read out by its own words, so
  /// it needs no separate name.
  final String identifier;

  final Widget child;

  @override
  double get height => kMinInteractiveDimension;

  @override
  bool represents(T? value) => value == this.value;

  @override
  State<MessagingPopupMenuItem<T>> createState() => _MessagingPopupMenuItemState<T>();
}

class _MessagingPopupMenuItemState<T> extends State<MessagingPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        container: true,
        identifier: widget.identifier,
        child: PopupMenuItem<T>(value: widget.value, onTap: widget.onTap, child: widget.child),
      ),
    );
  }
}
