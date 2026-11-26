import 'package:material_ui/material_ui.dart';

class CallPopupMenuButton<T> extends StatelessWidget {
  const CallPopupMenuButton({
    super.key,
    this.menuKey,
    this.enabled = true,
    this.onSelected,
    this.onOpened,
    this.onCanceled,
    this.child,
    this.offset = Offset.zero,
    this.position,
    required this.items,
  });

  /// Key of the inner [PopupMenuButton]; lets the caller open the menu
  /// programmatically via [PopupMenuButtonState.showButtonMenu].
  final GlobalKey<PopupMenuButtonState<T>>? menuKey;

  /// Whether the trigger reacts at all. Disabling it also drops the tap action
  /// from the accessibility tree, so assistive technology does not announce an
  /// action that would open nothing.
  final bool enabled;

  final PopupMenuItemSelected<T>? onSelected;

  /// The menu opened; [onCanceled] - it closed with nothing chosen.
  final VoidCallback? onOpened;
  final PopupMenuCanceled? onCanceled;

  final Widget? child;
  final Offset offset;

  /// Where the menu opens against its trigger; over it unless said otherwise.
  final PopupMenuPosition? position;
  final List<PopupMenuEntry<T>> items;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
      ),
      child: PopupMenuButton<T>(
        key: menuKey,
        enabled: enabled,
        // Without this the button brings its own "Show menu" tooltip: it is
        // read by screen readers on top of the caller's name (appended to the
        // spoken label on iOS) and it wins the long-press gesture over any
        // tooltip the caller wraps around this widget. An empty message makes
        // the tooltip build its child bare, leaving both to the caller.
        tooltip: '',
        onSelected: onSelected,
        onOpened: onOpened,
        onCanceled: onCanceled,
        offset: offset,
        position: position,
        elevation: 4,
        padding: EdgeInsets.zero,
        splashRadius: 0,
        itemBuilder: (context) => items,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        child: child,
      ),
    );
  }
}

/// One entry of a call popup menu: an icon, a line of text, and a stable id.
///
/// It wraps [PopupMenuItem] instead of extending it because of where the id has
/// to sit. The item merges its own subtree into one node, and only the node
/// that OWNS the identifier hands it to the platform - an identifier absorbed
/// from a merged child shows up in a widget test and arrives nowhere on the
/// device. So the merge is started from the outside, with the identifier on top
/// of it, and the item's name and tap are absorbed into that node.
class CallPopupMenuItem<T> extends PopupMenuEntry<T> {
  const CallPopupMenuItem({
    super.key,
    this.value,
    this.onTap,
    this.enabled = true,
    this.textStyle,
    this.identifier,
    required this.text,
    this.subtitle,
    required this.icon,
    this.hint,
    this.accent,
  });

  final T? value;
  final VoidCallback? onTap;
  final bool enabled;
  final TextStyle? textStyle;

  /// Stable automation id of the entry; it is read out by its own text, so it
  /// needs no separate name.
  final String? identifier;

  final String text;

  /// A second, quieter line saying what the entry does, where its name alone
  /// does not: a person's name in a transfer menu says who, not what happens
  /// to the call.
  final String? subtitle;

  final Widget icon;

  /// The entry's name in this colour, a little bolder: an entry that stands out from the rest,
  /// as the Stop of a screen the others see. Given here, as the menu's own text style decides
  /// the rest of the look.
  final Color? accent;

  /// Said on a long press: why a disabled entry cannot be chosen.
  final String? hint;

  /// The entries size themselves; the menu is asked to reserve nothing.
  @override
  double get height => 0;

  @override
  bool represents(T? value) => value == this.value;

  @override
  State<CallPopupMenuItem<T>> createState() => _CallPopupMenuItemState<T>();
}

class _CallPopupMenuItemState<T> extends State<CallPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    final hint = widget.hint;
    final item = _item();
    if (hint == null) return item;
    return Tooltip(message: hint, triggerMode: TooltipTriggerMode.longPress, child: item);
  }

  Widget _item() {
    return MergeSemantics(
      child: Semantics(
        // A node of its own: an identifier absorbed from a merged child is
        // visible in a widget test and reaches the device as nothing at all.
        container: true,
        identifier: widget.identifier,
        child: PopupMenuItem<T>(
          value: widget.value,
          onTap: widget.onTap,
          enabled: widget.enabled,
          textStyle: widget.textStyle,
          height: 0,
          padding: EdgeInsets.zero,
          child: Row(
            children: [
              Padding(padding: const EdgeInsets.all(8), child: widget.icon),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: widget.accent == null
                      ? _CallPopupMenuItemText(text: widget.text, subtitle: widget.subtitle)
                      : DefaultTextStyle.merge(
                          style: TextStyle(color: widget.accent, fontWeight: FontWeight.w600),
                          child: _CallPopupMenuItemText(text: widget.text, subtitle: widget.subtitle),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The name of an entry and, where it has one, the quieter line under it.
///
/// Built below the menu item, so the text style the item sets - greyed for a
/// disabled entry - is the one it reads.
class _CallPopupMenuItemText extends StatelessWidget {
  const _CallPopupMenuItemText({required this.text, this.subtitle});

  final String text;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final title = Text(text, overflow: TextOverflow.ellipsis, maxLines: 2);
    final subtitle = this.subtitle;
    if (subtitle == null) return title;

    // Fainter than the name by a factor, not set to a fixed opacity: a fixed
    // one would draw the second line of a disabled entry brighter than its
    // greyed name.
    final color = DefaultTextStyle.of(context).style.color;
    final subtitleColor = color?.withValues(alpha: color.a * 0.7);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          title,
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtitleColor),
          ),
        ],
      ),
    );
  }
}
