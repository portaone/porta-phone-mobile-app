import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';

import 'package:webtrit_phone/models/models.dart';

import 'keypad_screen_style.dart';

/// Everything both arrangements of the pad read, built once by [KeypadView]
/// above the switch: the number, its field and what can be done with it
/// live in the view's state whichever face shows them.
@immutable
class KeypadViewParams {
  const KeypadViewParams({
    required this.style,
    required this.videoEnabled,
    required this.transferEnabled,
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.hasNumber,
    required this.onPaste,
    required this.onShowInputMenu,
    required this.onKey,
    required this.onKeyHeld,
    required this.onBackspace,
    required this.onClear,
    required this.onCall,
    required this.onVideoCall,
    required this.onCallFrom,
    required this.onTransfer,
    required this.onPick,
  });

  final KeypadScreenStyle? style;
  final bool videoEnabled;

  /// The call-transfer configuration; the transfer is offered only with a
  /// call to hand over as well.
  final bool transferEnabled;

  /// The view reaches the field's text selection through it.
  final GlobalKey fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;

  /// Whether the field holds a number, as soon as it does - not a debounce
  /// later, as the cubit's value does.
  final ValueListenable<bool> hasNumber;

  /// Puts the number on the clipboard into the field.
  final VoidCallback onPaste;

  /// Shows the field's paste and copy menu, from a long press beside it.
  final VoidCallback onShowInputMenu;

  /// A key's character, put in at the caret.
  final ValueChanged<String> onKey;

  /// A held key: its alternate in place of what it just put in.
  final void Function(String entered, String alternate) onKeyHeld;

  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// Calls the typed number, which the pad then clears.
  final VoidCallback onCall;
  final VoidCallback onVideoCall;
  final ValueChanged<String> onCallFrom;

  /// Hands the current call over to the typed number.
  final VoidCallback onTransfer;

  /// Answers the choice being made with the typed number.
  final ValueChanged<DestinationPickPurpose> onPick;
}
