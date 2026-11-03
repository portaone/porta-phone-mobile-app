import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/call_routing.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/debounce.dart';

import '../cubit/keypad_cubit.dart';
import '../utils/utils.dart';
import '../widgets/widgets.dart';
import 'keypad_screen_style.dart';
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
    final scaledInset = MediaQuery.of(context).size.height > 800 ? 16.0 : 8.0;
    final themeData = Theme.of(context);

    final inputField = widget.style?.inputField;
    final contactField = widget.style?.contactNameField;
    final actionpadStyle = widget.style?.actionpadStyle;

    final handset = Column(
      children: [
        Expanded(
          // The input is intentionally invisible (blends with the background), so its own hit
          // target is a tiny box in the center. Catch long-presses across the whole upper region
          // and surface the input's context menu (paste/copy) from anywhere on the background.
          // Translucent (not opaque) so pointers still reach the field's own gesture handlers
          // instead of being fully absorbed by this background detector.
          //
          // It says nothing to assistive technology: an unnamed long press on an
          // invisible half of the screen is not something anyone can find, and
          // its annotation merged into the field below, stretching that field
          // over the whole region. The same thing is offered on the field
          // itself, as an action with a name.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            excludeFromSemantics: true,
            onLongPress: _showInputContextMenu,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: scaledInset),
              // The screen draws its body behind the app bar, so the top of this
              // region lies under it. The number is centred in what is left below
              // the bar: on a short screen the middle of the whole region is
              // still behind the bar.
              padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NumberField(
                    fieldKey: _keypadTextFieldKey,
                    controller: _textController,
                    focusNode: _focusNode,
                    onPaste: _pasteNumber,
                    fieldStyle: inputField,
                    style: inputField?.textStyle ?? themeData.textTheme.headlineLarge,
                  ),
                  _ContactName(
                    style: contactField?.textStyle ?? themeData.textTheme.bodyMedium,
                    textAlign: contactField?.textAlign,
                  ),
                ],
              ),
            ),
          ),
        ),
        RepaintBoundary(
          child: Keypad(onKeypadPressed: _addChar, onKeypadHeld: _exchangeEntry, style: widget.style?.keypadStyle),
        ),
        SizedBox(height: scaledInset),
        RepaintBoundary(
          child: BlocBuilder<KeypadCubit, KeypadState>(
            // The whole value, not just whether there is one: what is typed
            // decides whether it can be chosen, so two different nonempty
            // numbers are not the same state.
            buildWhen: (p, c) => p.value != c.value,
            builder: (context, keypadState) {
              // Two questions, as everywhere else. Whether this section can
              // answer the purpose at all - somewhere to forward a message to
              // cannot be typed - and whether what is typed right now is an
              // answer it would take.
              final purpose = context.pickPurpose;
              final typed = DestinationCandidate(number: _sanitized(keypadState.value));
              final picking = purpose != null && purpose.offeredBy(MainFlavor.keypad);
              // What the typed number offers is asked the way every list asks
              // it. With nothing typed there is no number to name, so the
              // control is called after the choice itself rather than read as
              // a sentence missing its end.
              final offer = picking && typed.number != null ? context.pickOfferFor(typed) : null;

              return BlocBuilder<CallBloc, CallState>(
                buildWhen: (p, c) => p.activeCalls != c.activeCalls,
                builder: (context, callState) {
                  final activeCalls = callState.activeCalls;

                  return BlocBuilder<CallRoutingCubit, CallRoutingState?>(
                    builder: (context, callRoutingState) {
                      bool canCall = keypadState.noValue == false;

                      return Actionpad(
                        actionsEnabled: canCall,
                        onBackspacePressed: _removeLastChar,
                        onBackspaceLongPress: _cleanInput,
                        onAudioCallPressed: () => _callController.createCall(destination: _popNumber()),
                        onVideoCallPressed: widget.videoEnabled
                            ? () => _callController.createCall(destination: _popNumber(), video: true)
                            : null,
                        onTransferPressed: widget.transferEnabled && activeCalls.isNotEmpty ? _transferCall : null,
                        // Not gated on the transfer configuration: that is
                        // permission to hand a call over, not permission to
                        // answer whatever is being asked.
                        // Shown for as long as the choice is being made, from
                        // the first key: an empty pad that looked like the
                        // ordinary dialer gave no sign it was choosing.
                        onInitiatedTransferPressed: picking ? () => _pickTyped(purpose) : null,
                        pickEnabled: offer?.isAnswer ?? false,
                        pickIcon: picking ? purpose.pickIcon : null,
                        pickLabel: picking ? offer?.label ?? purpose.announcement : null,
                        callNumbers: callRoutingState?.allNumbers ?? [],
                        onCallFrom: (number) =>
                            _callController.createCall(destination: _popNumber(), fromNumber: number),
                        style: actionpadStyle,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        SizedBox(height: scaledInset),
      ],
    );

    return AdaptiveLayout(
      handset: (_) => handset,
      watch: (_) => RepaintBoundary(
        child: BlocBuilder<KeypadCubit, KeypadState>(
          buildWhen: (p, c) => p.value != c.value,
          builder: (context, keypadState) {
            final purpose = context.pickPurpose;
            final typed = DestinationCandidate(number: _sanitized(keypadState.value));
            final picking = purpose != null && purpose.offeredBy(MainFlavor.keypad);
            final offer = picking && typed.number != null ? context.pickOfferFor(typed) : null;
            final canCall = keypadState.noValue == false;
            final callStyle = (actionpadStyle ?? themeData.extension<ActionpadStyles>()?.primary)?.primary?.style;

            return KeypadViewWatch(
              numberField: _NumberField(
                fieldKey: _keypadTextFieldKey,
                controller: _textController,
                focusNode: _focusNode,
                onPaste: _pasteNumber,
                fieldStyle: inputField,
                style: (inputField?.textStyle ?? themeData.textTheme.titleLarge)?.copyWith(
                  fontSize: context.isSmallWatch ? 16 : 19,
                ),
                // The theme's keypad field pads the number for a phone screen;
                // on a face every point goes to the keys.
                decoration: const InputDecoration.collapsed(hintText: null),
              ),
              contactName: _ContactName(
                style: themeData.textTheme.bodySmall,
                textAlign: contactField?.textAlign,
                collapseWhenEmpty: true,
              ),
              onKeyPressed: _addChar,
              onBackspace: _removeLastChar,
              onClear: _cleanInput,
              // The choice being made, when the pad is asked for one; the call
              // otherwise. Video, transfer and the caller-id menu stay on the
              // phone for now.
              action: (overlay) => picking
                  ? SemanticAction(
                      label: offer?.label ?? purpose.announcement,
                      identifier: actionPadTransferId,
                      child: TextButton(
                        onPressed: canCall && (offer?.isAnswer ?? false) ? () => _pickTyped(purpose) : null,
                        style: overlay.merge(callStyle),
                        child: Icon(purpose.pickIcon),
                      ),
                    )
                  : SemanticAction(
                      label: context.l10n.numberActions_audioCall,
                      identifier: actionPadVoiceCallId,
                      child: TextButton(
                        onPressed: canCall ? () => _callController.createCall(destination: _popNumber()) : null,
                        style: overlay.merge(callStyle),
                        child: const Icon(Icons.call),
                      ),
                    ),
            );
          },
        ),
      ),
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

  /// What is typed, in the form anything downstream would use it in.
  static String? _sanitized(String? value) {
    if (value == null || value.isEmpty) return null;

    final number = PhoneNormalizingFormatter.sanitize(value);
    return number.isEmpty ? null : number;
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
    final candidate = DestinationCandidate(number: _sanitized(_textController.text));
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

/// The number being typed: one field for every arrangement, so the number
/// and its state live in the view's state whichever face shows them.
///
/// Name, id and the paste action sit on the field's own node: an identifier
/// makes a boundary of its own, and anything beside the field would be
/// announced apart from it. The number needs no naming - the field publishes
/// what it holds as its value.
class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.onPaste,
    required this.fieldStyle,
    required this.style,
    this.decoration,
  });

  /// The view reaches the field's text selection through it, for paste.
  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onPaste;

  /// The theme's field: alignment, cursor, keyboard, decoration.
  final TextFieldStyle? fieldStyle;

  /// The digits' type, which each arrangement sizes for itself.
  final TextStyle? style;

  /// In place of the theme's decoration, where its padding does not fit.
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = this.fieldStyle;
    return MergeSemantics(
      child: Semantics(
        label: context.l10n.keypad_SemanticsLabel_number,
        identifier: keypadNumberInputId,
        customSemanticsActions: {CustomSemanticsAction(label: context.l10n.keypad_SemanticsAction_paste): onPaste},
        child: TextField(
          key: fieldKey,
          controller: controller,
          focusNode: focusNode,
          decoration: decoration ?? fieldStyle?.decoration ?? Theme.of(context).extension<InputDecorations>()?.keypad,
          style: style,
          textAlign: fieldStyle?.textAlign ?? TextAlign.center,
          showCursor: fieldStyle?.showCursor ?? true,
          keyboardType: fieldStyle?.keyboardType ?? TextInputType.none,
          cursorColor: fieldStyle?.cursorColor,
          inputFormatters: [PhoneNormalizingFormatter()],
        ),
      ),
    );
  }
}

/// The name of the contact the typed number matches, under the number.
class _ContactName extends StatelessWidget {
  const _ContactName({required this.style, this.textAlign, this.collapseWhenEmpty = false});

  final TextStyle? style;
  final TextAlign? textAlign;

  /// Takes no line while nothing matches, where there is no line to spare.
  final bool collapseWhenEmpty;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BlocBuilder<KeypadCubit, KeypadState>(
        buildWhen: (p, c) => (p.contact?.maybeName ?? '') != (c.contact?.maybeName ?? ''),
        builder: (context, state) {
          final name = state.contact?.maybeName ?? '';
          if (collapseWhenEmpty && name.isEmpty) return const SizedBox.shrink();
          return Text(name, style: style, textAlign: textAlign ?? TextAlign.center);
        },
      ),
    );
  }
}
