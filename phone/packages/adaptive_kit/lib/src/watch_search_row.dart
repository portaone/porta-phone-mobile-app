import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';
import 'watch_keyboard_input.dart';
import 'watch_page_search.dart';
import 'watch_pill.dart';

/// The row over a searchable list on a watch: the search as one pill across
/// the row - its name with no query, the query with its cross to clear it
/// once one is typed. A list that also offers a chooser keeps its search on
/// the edge instead ([WatchPageSearch]).
///
/// The search is a button, not a field ([WatchKeyboardInput]): a watch's
/// keyboard takes the whole face with a line of its own. What the field holds
/// shows in the row as it is typed, for a watch whose keyboard leaves the face
/// in view.
class WatchSearchRow extends StatelessWidget {
  const WatchSearchRow({
    super.key,
    required this.initialQuery,
    required this.onChanged,
    this.onSubmitted,
    required this.searchLabel,
    required this.clearLabel,
    this.fieldKey,
    this.searchIdentifier,
    this.clearKey,
    this.clearIdentifier,
  });

  /// The query the list is already narrowed by.
  final String initialQuery;

  final ValueChanged<String> onChanged;

  /// The keyboard's search key; the keyboard closes after it.
  final ValueChanged<String>? onSubmitted;

  /// The search's name for a screen reader, also on the pill with no query.
  final String searchLabel;
  final String clearLabel;

  /// The phone's keys and ids of the search box, so automation finds it.
  final Key? fieldKey;
  final String? searchIdentifier;
  final Key? clearKey;
  final String? clearIdentifier;

  @override
  Widget build(BuildContext context) {
    return WatchSearchInput(
      initialQuery: initialQuery,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      fieldKey: fieldKey,
      builder: (context, search) => _SearchPill(
        query: search.query,
        searchLabel: searchLabel,
        clearLabel: clearLabel,
        searchIdentifier: searchIdentifier,
        clearKey: clearKey,
        clearIdentifier: clearIdentifier,
        onOpen: search.open,
        onClear: search.clear,
      ),
    );
  }
}

/// The search as a pill: its name, or the query with a cross to clear it.
class _SearchPill extends StatelessWidget {
  const _SearchPill({
    required this.query,
    required this.searchLabel,
    required this.clearLabel,
    required this.searchIdentifier,
    required this.clearKey,
    required this.clearIdentifier,
    required this.onOpen,
    required this.onClear,
  });

  final String query;
  final String searchLabel;
  final String clearLabel;
  final String? searchIdentifier;
  final Key? clearKey;
  final String? clearIdentifier;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;

    return Material(
      color: colorScheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: SemanticAction(
              label: query.isEmpty ? searchLabel : query,
              identifier: searchIdentifier,
              child: InkWell(
                onTap: onOpen,
                // The pill's name is the label above; its words are for the eye.
                child: ExcludeSemantics(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: WatchPill.height),
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(start: query.isEmpty ? 12 : 14, end: query.isEmpty ? 16 : 0),
                      child: Row(
                        spacing: 8,
                        children: [
                          // With a query the cross needs its room; the query and
                          // the cross say what it is.
                          if (query.isEmpty) Icon(Icons.search, size: 20, color: colorScheme.onSurfaceVariant),
                          Expanded(
                            child: Text(
                              query.isEmpty ? searchLabel : query,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: query.isEmpty
                                  ? textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)
                                  : textTheme.labelLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (query.isNotEmpty)
            SemanticAction(
              label: clearLabel,
              identifier: clearIdentifier,
              // Narrow, full height: the query needs the width more than
              // the cross does.
              child: IconButton(
                key: clearKey,
                icon: const Icon(Icons.close, size: 18),
                color: colorScheme.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 36, height: WatchPill.height),
                style: IconButton.styleFrom(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                onPressed: onClear,
              ),
            ),
        ],
      ),
    );
  }
}
