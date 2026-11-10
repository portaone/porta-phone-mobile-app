import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';
import 'watch_pill.dart';
import 'watch_round_button.dart';

/// The row over a searchable list on a watch: the search and the list's
/// chooser side by side, so the first row is in view on a small face. With no
/// query, a round search button and the chooser as a pill; with one, the query
/// takes the row as a pill with its cross and the chooser shrinks to a round
/// button. With nothing to choose the search takes the row as a pill.
///
/// The search is a button, not a field: a watch's keyboard takes the whole
/// face with a line of its own to type in, so a box on the list to type into
/// would never be seen. Under the row is a field nobody sees, the one the
/// keyboard types into - without it the app cannot ask for a keyboard. It is
/// the same field whichever shape the row takes, so the keyboard stays open
/// while the query appears; what it holds shows in the row as it is typed,
/// for a watch whose keyboard leaves the face in view.
class WatchSearchRow extends StatefulWidget {
  const WatchSearchRow({
    super.key,
    required this.initialQuery,
    required this.onChanged,
    this.onSubmitted,
    this.chooser,
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

  /// The list's chooser: a pill, or with [round] a round button beside a
  /// query. Null where there is nothing to choose.
  final Widget Function({required bool round})? chooser;

  /// The search's name for a screen reader, also on the pill with no query.
  final String searchLabel;
  final String clearLabel;

  /// The phone's keys and ids of the search box, so automation finds it.
  final Key? fieldKey;
  final String? searchIdentifier;
  final Key? clearKey;
  final String? clearIdentifier;

  @override
  State<WatchSearchRow> createState() => _WatchSearchRowState();
}

class _WatchSearchRowState extends State<WatchSearchRow> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  final _focus = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A page or a dialog over the list: the field may not take focus back
    // when it closes. The keyboard closed with Back leaves the field focused,
    // and the route handing focus back would bring the keyboard up again over
    // a list nobody is searching. The search button lets it again.
    if (ModalRoute.isCurrentOf(context) == false) _focus.canRequestFocus = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _open() {
    _focus.canRequestFocus = true;
    if (_focus.hasFocus) {
      // Focused already, the keyboard may have been closed with Back: ask
      // for it again.
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focus.requestFocus();
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final chooser = widget.chooser;

    return Stack(
      children: [
        // Out of sight and out of reach: the keyboard's target only.
        Positioned(
          left: 0,
          top: 0,
          width: 1,
          height: 1,
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  key: widget.fieldKey,
                  controller: _controller,
                  focusNode: _focus,
                  textInputAction: TextInputAction.search,
                  onChanged: widget.onChanged,
                  onSubmitted: (value) {
                    widget.onSubmitted?.call(value);
                    _focus.unfocus();
                  },
                ),
              ),
            ),
          ),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            final query = value.text;
            final search = _SearchPill(
              query: query,
              searchLabel: widget.searchLabel,
              clearLabel: widget.clearLabel,
              searchIdentifier: widget.searchIdentifier,
              clearKey: widget.clearKey,
              clearIdentifier: widget.clearIdentifier,
              onOpen: _open,
              onClear: _clear,
            );
            if (chooser == null) return search;
            return Row(
              spacing: 8,
              children: query.isEmpty
                  ? [
                      WatchRoundButton(
                        identifier: widget.searchIdentifier,
                        label: widget.searchLabel,
                        icon: const Icon(Icons.search),
                        size: WatchPill.height,
                        width: WatchPill.height,
                        onPressed: _open,
                      ),
                      Expanded(child: chooser(round: false)),
                    ]
                  : [Expanded(child: search), chooser(round: true)],
            );
          },
        ),
      ],
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
                          // With a query the pill sits beside the chooser's button
                          // and the cross needs its room; the query and the cross
                          // say what it is.
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
              // Narrow, full height: beside the chooser's button the query
              // needs the width more than the cross does.
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
