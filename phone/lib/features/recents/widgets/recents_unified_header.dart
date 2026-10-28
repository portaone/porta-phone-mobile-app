import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'recents_actions.dart';

const _pickerIconSize = 20.0;
const _pickerGap = 8.0;
const _pickerMenuGap = 12.0;
const _controlGap = 10.0;

/// The line under the title of the unified recents arrangement: which calls
/// are shown on the left, the list's actions on the right - the header of the
/// unified contacts screen, with the actions where contacts has its search.
class RecentsUnifiedHeader extends StatelessWidget {
  const RecentsUnifiedHeader({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
    required this.actions,
    this.inset = kMainAppBarBottomPaddingGap,
  });

  static const height = kMainAppBarBottomSearchHeight;

  final List<RecentsVisibilityFilter> filters;
  final RecentsVisibilityFilter selected;
  final ValueChanged<RecentsVisibilityFilter> onSelected;
  final RecentsActions actions;

  /// Distance from the screen's edges, the title's own so the line starts
  /// under it.
  final double inset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: inset,
        right: inset,
        top: kMainAppBarBottomPaddingGap / 2,
        bottom: kMainAppBarBottomPaddingGap / 2,
      ),
      child: Row(
        spacing: _controlGap,
        children: [
          // A single filter leaves nothing to pick, and the line keeps its
          // height so the list below does not move.
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: filters.length > 1
                  ? RecentsFilterPicker(filters: filters, selected: selected, onSelected: onSelected)
                  : null,
            ),
          ),
          _RecentsActionsButton(actions: actions),
        ],
      ),
    );
  }
}

/// Opens the list's actions: the bare mark, with no circle drawn around it -
/// the ripple of a press shows where it lands.
class _RecentsActionsButton extends StatelessWidget {
  const _RecentsActionsButton({required this.actions});

  final RecentsActions actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Named from outside the tap target, so the name and the press land on
    // one node.
    return SemanticAction.button(
      label: context.l10n.recents_ActionsButton_label,
      identifier: recentsActionsId,
      child: SizedBox.square(
        dimension: kMainAppBarBottomControlHeight,
        child: Material(
          type: MaterialType.transparency,
          // The menu is placed by the button's own box, so it is opened from
          // a context inside the button rather than from the line around it.
          child: Builder(
            builder: (context) => InkWell(
              key: recentsActionsKey,
              customBorder: const CircleBorder(),
              onTap: () => actions.open(context),
              child: Icon(Icons.more_vert, color: colors.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// Picks which calls the list shows, as a compact control: the name of the
/// filter between a mark and a chevron, the way the contacts screen names its
/// address book.
class RecentsFilterPicker extends StatelessWidget {
  const RecentsFilterPicker({super.key, required this.filters, required this.selected, required this.onSelected});

  final List<RecentsVisibilityFilter> filters;
  final RecentsVisibilityFilter selected;
  final ValueChanged<RecentsVisibilityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = context.l10n.recents_FilterPicker_label;

    // The menu button marks its own node as a button with a menu state, and
    // without the merge the name below would land on a separate node above the
    // one that takes the press.
    return MergeSemantics(
      child: Semantics(
        label: label,
        identifier: recentsFilterPickerId,
        button: true,
        child: PopupMenuButton<RecentsVisibilityFilter>(
          key: recentsFilterPickerKey,
          initialValue: selected,
          onSelected: onSelected,
          tooltip: label,
          itemBuilder: (context) => [
            for (final filter in filters)
              PopupMenuItem(
                key: filter.tabKey,
                value: filter,
                // The tabs' ids, so a flow that opens "the missed calls"
                // reaches them in either arrangement.
                child: Semantics(
                  identifier: filter.tabId,
                  child: Row(
                    spacing: _pickerMenuGap,
                    children: [
                      Expanded(child: Text(filter.l10n(context))),
                      if (filter == selected)
                        Icon(Icons.check, size: _pickerIconSize, color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
          ],
          child: SizedBox(
            height: kMainAppBarBottomControlHeight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: _pickerGap,
              children: [
                Icon(Icons.history, size: _pickerIconSize, color: theme.colorScheme.onSurfaceVariant),
                Text(selected.l10n(context), style: theme.textTheme.bodyMedium),
                Icon(Icons.expand_more, size: _pickerIconSize, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
