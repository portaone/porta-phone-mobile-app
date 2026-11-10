import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// The watch keyboard behind a button: a field nobody sees, the one the
/// keyboard types into, under what [builder] draws - a search pill, a Reply
/// button - which is given `open` to call.
///
/// A watch's keyboard takes the whole face with a line of its own to type
/// in, so a box on the screen to type into would never be seen; without a
/// field, though, the app cannot ask for a keyboard. A page or a dialog over
/// the screen takes the field's focus with it: the keyboard closed with Back
/// leaves the field focused, and the route handing focus back when it closes
/// would bring the keyboard up again over a screen nobody is typing on.
class WatchKeyboardInput extends StatefulWidget {
  const WatchKeyboardInput({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.maxLength,
    this.fieldKey,
    required this.builder,
  });

  /// What the field holds; one of its own when null.
  final TextEditingController? controller;

  final ValueChanged<String>? onChanged;

  /// The keyboard's action key; the keyboard closes after it.
  final ValueChanged<String>? onSubmitted;

  final TextInputAction textInputAction;
  final int? maxLength;

  /// The key of the field, for a test to type into.
  final Key? fieldKey;

  /// Draws what opens the keyboard; `open` asks for it.
  final Widget Function(BuildContext context, VoidCallback open) builder;

  @override
  State<WatchKeyboardInput> createState() => _WatchKeyboardInputState();
}

class _WatchKeyboardInputState extends State<WatchKeyboardInput> {
  late final _own = widget.controller == null ? TextEditingController() : null;
  final _focus = FocusNode();

  TextEditingController get _controller => widget.controller ?? _own!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Covered: the field may not take focus back when the route over it
    // closes. Opening the keyboard lets it again.
    if (ModalRoute.isCurrentOf(context) == false) _focus.canRequestFocus = false;
  }

  @override
  void dispose() {
    _own?.dispose();
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

  @override
  Widget build(BuildContext context) {
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
                  textInputAction: widget.textInputAction,
                  maxLength: widget.maxLength,
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
        widget.builder(context, _open),
      ],
    );
  }
}
