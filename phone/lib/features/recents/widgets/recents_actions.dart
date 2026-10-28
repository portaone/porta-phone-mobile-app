import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The side of a regular floating action button.
const _fabSize = 56.0;

/// What the recents actions menu offers.
enum _RecentsAction { clearHistory }

/// The actions of the recents list, offered as a menu: today "Clear call
/// history", which asks before it clears.
///
/// Destructive, so it is kept out of the header, where a press that was meant
/// for something else would land on it; a menu is one step away and names
/// what it does. Both recents screens offer it; they differ in what clearing
/// reaches - every device of the account for the server history, this device
/// for the local one - so the screen says that in [clearDescription], which is
/// what the question shows under its title. The list is cleared as a whole:
/// the Missed calls are part of it, so the menu is the same on either filter.
class RecentsActions {
  const RecentsActions({required this.canClear, required this.clearDescription, required this.onClearConfirmed});

  /// False while there is nothing to clear or a clear is already running; the
  /// entry is then shown but cannot be picked.
  final bool canClear;

  /// What clearing reaches, shown under the question.
  final String clearDescription;

  /// Called once the person has confirmed.
  final VoidCallback onClearConfirmed;

  /// Opens the menu next to [anchor], the context of the control pressed.
  Future<void> open(BuildContext anchor) async {
    final button = anchor.findRenderObject()! as RenderBox;
    final overlay = Navigator.of(anchor).overlay!.context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final colors = Theme.of(anchor).colorScheme;
    final l10n = anchor.l10n;

    final picked = await showMenu<_RecentsAction>(
      context: anchor,
      position: position,
      items: [
        PopupMenuItem(
          key: recentsClearHistoryActionKey,
          value: _RecentsAction.clearHistory,
          enabled: canClear,
          // The item itself is the tap target and merges what is inside it, so
          // the identifier lands on the node that carries the press.
          child: Semantics(
            identifier: recentsClearHistoryActionId,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: canClear ? colors.error : null),
              title: Text(l10n.recents_ClearHistoryAction_label),
            ),
          ),
        ),
      ],
    );
    if (picked != _RecentsAction.clearHistory || !anchor.mounted) return;

    final confirmed = await ConfirmDialog.showDangerous(
      anchor,
      title: l10n.recents_ClearHistoryDialog_title,
      content: clearDescription,
    );
    if (confirmed ?? false) onClearConfirmed();
  }
}

/// The floating button that opens [RecentsActions], at the corner of the list
/// where the conversations screen keeps its own: the tabbed recents screen has
/// no room for it in a header full of tabs.
class RecentsActionsFab extends StatelessWidget {
  const RecentsActionsFab({super.key, required this.actions, this.bottomPadding = 0});

  /// How far up from the bottom padding the button reaches: a list under it
  /// ends this much higher, so its last row can be scrolled out from under
  /// the button.
  static const clearance = _fabSize + kFloatingActionButtonMargin * 2;

  final RecentsActions actions;

  /// What the button leaves clear beneath it. The tab bar of the main screen
  /// floats over the page and is reported as the page's bottom padding, which
  /// the scaffold does not hand down to its floating button: without this the
  /// button is drawn underneath the bar - invisible, and every tap goes to
  /// the bar.
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SemanticAction(
        label: context.l10n.recents_ActionsButton_label,
        identifier: recentsActionsId,
        // The menu is placed by the button's own box, so it is opened from a
        // context inside the button rather than from the screen around it.
        child: Builder(
          builder: (context) => FloatingActionButton(
            key: recentsActionsKey,
            backgroundColor: colors.primary,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(32))),
            onPressed: () => actions.open(context),
            child: Icon(Icons.more_vert, color: colors.onPrimary),
          ),
        ),
      ),
    );
  }
}

/// Ends the scrolling content of [child] [RecentsActionsFab.clearance] higher,
/// through the padding a list with none of its own takes from the media query.
class RecentsActionsFabClearance extends StatelessWidget {
  const RecentsActionsFabClearance({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQueryData.copyWith(
        padding: mediaQueryData.padding.copyWith(bottom: mediaQueryData.padding.bottom + RecentsActionsFab.clearance),
      ),
      child: child,
    );
  }
}
