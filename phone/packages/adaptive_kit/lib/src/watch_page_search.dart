import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';
import 'watch_keyboard_input.dart';

/// What the page under a [WatchPageSearch] gets from it: the query typed,
/// and how to open the keyboard - for its [WatchSearchEdgeButton].
class WatchSearchControls {
  const WatchSearchControls({required this.query, required this.open});

  final String query;

  /// Opens the watch keyboard over the field, the query in it to change or
  /// delete.
  final VoidCallback open;
}

/// The search of a list page on a watch whose search is its edge button: the
/// field the watch keyboard types into ([WatchKeyboardInput]) around the whole
/// page, so the page opens it from the edge, where the query typed shows
/// ([WatchSearchEdgeButton]). The list's header keeps only its chooser, so
/// the rows the search finds are in view under it.
///
/// The page is drawn by [builder] whichever state it is in, under the same
/// field, so a letter that empties the list and turns the page into another
/// shape does not close the keyboard.
class WatchPageSearch extends StatefulWidget {
  const WatchPageSearch({
    super.key,
    required this.initialQuery,
    required this.onChanged,
    this.onSubmitted,
    this.fieldKey,
    required this.builder,
  });

  /// The query the list is already narrowed by.
  final String initialQuery;

  final ValueChanged<String> onChanged;

  /// The keyboard's search key; the keyboard closes after it.
  final ValueChanged<String>? onSubmitted;

  /// The key of the hidden field, the phone's search box key, so automation
  /// and tests type into it.
  final Key? fieldKey;

  final Widget Function(BuildContext context, WatchSearchControls search) builder;

  @override
  State<WatchPageSearch> createState() => _WatchPageSearchState();
}

class _WatchPageSearchState extends State<WatchPageSearch> {
  late final _controller = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WatchKeyboardInput(
      controller: _controller,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.search,
      fieldKey: widget.fieldKey,
      builder: (context, open) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: _controller,
        // The page fills the face; the hidden field beside it takes no room.
        builder: (context, value, _) => SizedBox.expand(
          child: widget.builder(context, WatchSearchControls(query: value.text, open: open)),
        ),
      ),
    );
  }
}

/// The edge button of a list whose search opens from the edge
/// ([WatchPageSearch]): the search's name, or the query typed, after the
/// search icon. A tap opens the keyboard with the query in it, to change it
/// or delete it. A screen reader hears the name, and the query after it.
class WatchSearchEdgeButton extends StatelessWidget {
  const WatchSearchEdgeButton({
    super.key,
    required this.overlay,
    required this.search,
    required this.label,
    this.identifier,
  });

  /// The edge button's size and shape ([WatchEdgeButton]).
  final ButtonStyle overlay;

  final WatchSearchControls search;

  /// The search's name: "Search contacts".
  final String label;

  /// The automation id, the phone's search box id.
  final String? identifier;

  @override
  Widget build(BuildContext context) {
    final query = search.query;
    return SemanticAction(
      label: query.isEmpty ? label : '$label: $query',
      identifier: identifier,
      child: OutlinedButton(
        onPressed: search.open,
        style: overlay,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              const Icon(Icons.search, size: 18),
              Flexible(child: Text(query.isEmpty ? label : query, maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}
