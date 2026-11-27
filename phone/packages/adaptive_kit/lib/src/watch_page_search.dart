import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';
import 'watch_keyboard_input.dart';

/// What a search on a watch gives what it draws: the query typed, how to
/// open the keyboard and how to clear the query.
class WatchSearchControls {
  const WatchSearchControls({required this.query, required this.open, required this.clear});

  final String query;

  /// Opens the watch keyboard over the field, the query in it to change or
  /// delete.
  final VoidCallback open;

  /// Empties the query and says so through `onChanged`.
  final VoidCallback clear;
}

/// The search on a watch, whatever draws it: the field the watch keyboard
/// types into ([WatchKeyboardInput]) and its query, handed to [builder] as it
/// is typed. [WatchSearchRow] draws it as a pill across a row,
/// [WatchPageSearch] as a whole page with the search on its edge.
class WatchSearchInput extends StatefulWidget {
  const WatchSearchInput({
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
  State<WatchSearchInput> createState() => _WatchSearchInputState();
}

class _WatchSearchInputState extends State<WatchSearchInput> {
  late final _controller = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
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
        builder: (context, value, _) =>
            widget.builder(context, WatchSearchControls(query: value.text, open: open, clear: _clear)),
      ),
    );
  }
}

/// The search of a list page on a watch whose search is its edge button: a
/// [WatchSearchInput] around the whole page, so the page opens it from the
/// edge, where the query typed shows ([WatchSearchEdgeButton]). The list's
/// header keeps only its chooser, so the rows the search finds are in view
/// under it.
///
/// The page is drawn by [builder] whichever state it is in, under the same
/// field, so a letter that empties the list and turns the page into another
/// shape does not close the keyboard.
class WatchPageSearch extends StatelessWidget {
  const WatchPageSearch({
    super.key,
    required this.initialQuery,
    required this.onChanged,
    this.onSubmitted,
    this.fieldKey,
    required this.builder,
  });

  final String initialQuery;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final Key? fieldKey;
  final Widget Function(BuildContext context, WatchSearchControls search) builder;

  @override
  Widget build(BuildContext context) {
    return WatchSearchInput(
      initialQuery: initialQuery,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      fieldKey: fieldKey,
      // The field sits in a stack beside what is drawn, which gives the page
      // loose constraints: the page fills the face itself.
      builder: (context, search) => SizedBox.expand(child: builder(context, search)),
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
