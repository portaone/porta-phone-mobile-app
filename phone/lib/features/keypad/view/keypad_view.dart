import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';
import 'package:webtrit_phone/utils/debounce.dart';

import '../cubit/keypad_cubit.dart';
import '../utils/utils.dart';
import 'keypad_screen_style.dart';
import 'keypad_view_handset.dart';
import 'keypad_view_params.dart';
import 'keypad_view_parts.dart';
import 'keypad_view_watch.dart';

// NOTES:
// - do not use ValueListenableBuilder to watch number change because of huge perfomance impact on low-end devices

class KeypadView extends StatefulWidget {
  const KeypadView({super.key, required this.videoEnabled, required this.transferEnabled, required this.style});

  final bool videoEnabled;
  final bool transferEnabled;
  final KeypadScreenStyle? style;

  @override
  KeypadViewState createState() => KeypadViewState();
}

class KeypadViewState extends State<KeypadView> {
  late final _callController = CallControllerScope.of(context);
  late final _keypadCubit = context.read<KeypadCubit>();
  // Seed the field from the cubit's initial value so the displayed number stays derivable from
  // state (empty in production; lets screenshot mocks and tests pre-fill a dialed number).
  late final _textController = TextEditingController(text: _keypadCubit.state.value ?? '');
  late final _focusNode = FocusNode();
  late final _setValueDebounce = Debounce(Duration(milliseconds: 128));

  final _keypadTextFieldKey = GlobalKey();
  EditableTextState? get _keypadTextFieldEditableTextState {
    // Guard the cast: currentState is null while the field is detached/rebuilt under the key
    // (e.g. a theme swap reparenting the subtree in the same frame). A hard cast would throw a
    // _TypeError there; return null instead so `?.showToolbar()` skips gracefully.
    final delegate = _keypadTextFieldKey.currentState;
    if (delegate is! TextSelectionGestureDetectorBuilderDelegate) return null;
    // The `is` guard covers both null and wrong-type; promotion does not apply here because the
    // delegate mixin is not a subtype of State, so an explicit (now safe) cast is still needed.
    return (delegate as TextSelectionGestureDetectorBuilderDelegate).editableTextKey.currentState;
  }

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      // Whatever a held key could still exchange is settled by any later
      // change of the number or of the caret.
      final entry = _exchangeable;
      if (entry != null && !entry.stillAsEntered(_textController.value)) _exchangeable = null;
      // deffer value set, let app concentrate on gesture handling on low-end devices
      _setValueDebounce.schedule(() {
        if (mounted) _keypadCubit.setValue(_textController.text);
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Built above the switch, so both arrangements act on the one number.
    final params = KeypadViewParams(
      style: widget.style,
      videoEnabled: widget.videoEnabled,
      transferEnabled: widget.transferEnabled,
      fieldKey: _keypadTextFieldKey,
      controller: _textController,
      focusNode: _focusNode,
      onPaste: _pasteNumber,
      onShowInputMenu: _showInputContextMenu,
      onKey: _addChar,
      onKeyHeld: _exchangeEntry,
      onBackspace: _removeLastChar,
      onClear: _cleanInput,
      onCall: () => _callController.createCall(destination: _popNumber()),
      onVideoCall: () => _callController.createCall(destination: _popNumber(), video: true),
      onCallFrom: (number) => _callController.createCall(destination: _popNumber(), fromNumber: number),
      onTransfer: _transferCall,
      onPick: _pickTyped,
    );

    return AdaptiveLayout(
      handset: (_) => KeypadViewHandset(params: params),
      watch: (_) => KeypadViewWatch(params: params),
    );
  }

  Future<void> _showInputContextMenu() async {
    // Decide whether there is anything to show BEFORE taking focus. The keypad input is
    // paste-oriented: an empty field has nothing selected to copy, so the toolbar is only
    // meaningful when the clipboard holds text. Guarding first also avoids focusing the hidden
    // input on a long-press that would surface nothing (which would leave a stray blinking
    // cursor and shift caret/toolbar timing for later key presses).
    //
    // The question is whether the clipboard holds text, not what the text is: reading the
    // content here would make Android 12+ announce "pasted from your clipboard" for a paste
    // nobody has asked for yet. The content is read by the field when Paste is tapped.
    final hasSelection = !_textController.selection.isCollapsed;
    final hasPasteableText = await Clipboard.hasStrings();
    if (!mounted || (!hasSelection && !hasPasteableText)) return;

    _focusNode.requestFocus();
    // Defer so the just-requested focus / input connection is established before showToolbar(),
    // which is a no-op on an unfocused/unconnected field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_textController.selection.isValid) {
        _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
      }
      _keypadTextFieldEditableTextState?.showToolbar();
    });
  }

  /// Puts whatever number is on the clipboard into the field.
  ///
  /// The same thing a long press offers through the field's own context menu,
  /// as an action of its own: a long press on an invisible area is not
  /// something assistive technology can be expected to find. Nothing happens
  /// when the clipboard holds no text - the action has to be declared while the
  /// screen is built, and what the clipboard holds can only be asked later.
  Future<void> _pasteNumber() async {
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = clipboard?.text ?? '';
    if (!mounted || pasted.isEmpty) return;

    if (!_textController.selection.isValid) {
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }

    final textBefore = _textController.selection.textBefore(_textController.text);
    final textAfter = _textController.selection.textAfter(_textController.text);
    final sanitized = PhoneNormalizingFormatter.sanitize(pasted);

    final value = _textController.value.copyWith(
      text: textBefore + sanitized + textAfter,
      selection: TextSelection.collapsed(offset: textBefore.length + sanitized.length),
    );
    // Through the field itself where it is attached, so the number lands the
    // same way a key press does; straight onto the controller otherwise.
    final field = _keypadTextFieldEditableTextState;
    if (field != null) {
      field.userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);
    } else {
      _textController.value = value;
    }
  }

  String _popNumber() {
    final number = PhoneNormalizingFormatter.sanitize(_textController.text);
    _textController.clear();
    _keypadCubit.setValue('');
    return number;
  }

  void _transferCall() {
    _focusNode.unfocus();
    _callController.submitTransfer(_popNumber());
  }

  /// Hands over what was typed, if the purpose will take it.
  ///
  /// The input is cleared only once it has been taken: a number the purpose
  /// refuses is still the number the person typed, and wiping it would make a
  /// refusal look like a successful send.
  ///
  /// No pop afterwards, unlike a list: the keypad is where somebody already
  /// was, not somewhere they were sent, so there is nothing to come back from.
  void _pickTyped(DestinationPickPurpose purpose) {
    final candidate = DestinationCandidate(number: TypedPick.sanitize(_textController.text));
    if (!submitDestination(context, purpose, candidate)) return;

    _focusNode.unfocus();
    _popNumber();
  }

  /// What a key just entered, for as long as it may still be exchanged for
  /// the key's alternate. Any later change of the number or of the caret
  /// drops it - the next edit ends the previous key - so a long press that
  /// comes after one changes nothing.
  _KeypadEntry? _exchangeable;

  void _addChar(String keyText) {
    if (!_textController.selection.isValid) {
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }

    final textBefore = _textController.selection.textBefore(_textController.text);
    final textAfter = _textController.selection.textAfter(_textController.text);

    final newText = textBefore + keyText + textAfter;
    final newSelection = TextSelection.collapsed(offset: _textController.selection.start + 1);
    final value = _textController.value.copyWith(text: newText, selection: newSelection);
    _keypadTextFieldEditableTextState?.userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);

    _keypadTextFieldEditableTextState?.hideToolbar();

    // Remembered only once the field really holds the entry where it was put.
    final entry = _KeypadEntry(keyText, at: textBefore.length, text: newText, selection: newSelection);
    _exchangeable = entry.stillAsEntered(_textController.value) ? entry : null;
  }

  /// A held key: [alternate] takes the place of the [entered] character, if
  /// that entry is still the last thing that happened to the field.
  void _exchangeEntry(String entered, String alternate) {
    final entry = _exchangeable;
    if (entry == null || entry.character != entered) return;

    final value = _textController.value.copyWith(
      text: entry.text.replaceRange(entry.at, entry.at + entered.length, alternate),
      selection: TextSelection.collapsed(offset: entry.at + alternate.length),
    );
    _keypadTextFieldEditableTextState?.userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);
    // The long press is confirmed only when it changed something.
    Feedback.forLongPress(context);
  }

  void _removeLastChar() {
    if (!_textController.selection.isValid) {
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }

    final textBefore = _textController.selection.textBefore(_textController.text);
    final textAfter = _textController.selection.textAfter(_textController.text);

    String? newText;
    TextSelection? newSelection;
    if (_textController.selection.isCollapsed) {
      if (textBefore.isNotEmpty) {
        newText = textBefore.substring(0, textBefore.length - 1) + textAfter;
        newSelection = TextSelection.collapsed(offset: _textController.selection.start - 1);
      }
    } else {
      newText = textBefore + textAfter;
      newSelection = TextSelection.collapsed(offset: _textController.selection.start);
    }
    final value = _textController.value.copyWith(text: newText, selection: newSelection);
    _keypadTextFieldEditableTextState?.userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);

    _keypadTextFieldEditableTextState?.hideToolbar();
  }

  void _cleanInput() {
    if (!_textController.selection.isValid) {
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }

    final textBefore = _textController.selection.textBefore(_textController.text);
    final textAfter = _textController.selection.textAfter(_textController.text);

    String newText;
    TextSelection newSelection;
    if (_textController.selection.isCollapsed) {
      newText = textAfter;
      newSelection = const TextSelection.collapsed(offset: 0);
    } else {
      newText = textBefore + textAfter;
      newSelection = TextSelection.collapsed(offset: _textController.selection.start);
    }
    final value = _textController.value.copyWith(text: newText, selection: newSelection);
    _keypadTextFieldEditableTextState?.userUpdateTextEditingValue(value, SelectionChangedCause.keyboard);

    _keypadTextFieldEditableTextState?.hideToolbar();
  }
}

/// A character a key put into the number: which one, where, and what the
/// field looked like right after.
class _KeypadEntry {
  const _KeypadEntry(this.character, {required this.at, required this.text, required this.selection});

  final String character;
  final int at;
  final String text;
  final TextSelection selection;

  /// Whether [value] is still the number and the caret this entry left.
  bool stillAsEntered(TextEditingValue value) => value.text == text && value.selection == selection;
}
