// ignore_for_file: deprecated_member_use_from_same_package

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';

import 'keypad_key_style.dart';
import 'keypad_key_styles.dart';

export 'keypad_key_style.dart';
export 'keypad_key_styles.dart';

class KeypadKeyButton extends StatefulWidget {
  const KeypadKeyButton({
    super.key,
    required this.text,
    required this.subtext,
    required this.onKeyPressed,
    this.alternate,
    this.onKeyHeld,
    this.style,
    @Deprecated('Use style.textStyle instead') this.textFontSize,
    @Deprecated('Use style.textStyle instead') this.textColor,
    @Deprecated('Use style.subtextStyle instead') this.subtextFontSize,
  });

  static const _subextPadding = EdgeInsets.symmetric(horizontal: 8);

  /// Minimum alpha value applied when deriving subtext color.
  static const double _minAlphaValue = 0.2;

  /// Amount to reduce alpha from main text color for subtext.
  static const double _subtextAlphaReduction = 0.3;

  final String text;

  /// The caption under [text]. It is only drawn and read out; what a long
  /// press enters is [alternate].
  final String subtext;

  /// A character was entered.
  ///
  /// A finger enters [text] the moment it touches the key, not when it lifts.
  /// A lift-based tap is cancelled by the framework once the finger travels 18
  /// logical pixels, which fast typing does all the time - the key lights up
  /// and enters nothing (WT-1436). Nothing is decided on the lift, so there is
  /// nothing for a slide, a late lift or a second finger to change.
  ///
  /// Assistive technology has no touch to follow: it enters [text] with a tap
  /// and [alternate] with a long press, one character either way.
  final void Function(String character) onKeyPressed;

  /// The character a long press gives instead of [text]: the "+" of "0".
  /// Null, or no [onKeyHeld], leaves the key without a long press.
  final String? alternate;

  /// The finger that entered [text] stayed for a long press: `alternate` is to
  /// take the place of that `entered` character.
  ///
  /// Reported for the latest touch of the key only, and not at all once that
  /// finger has slid away or lifted. Whether the exchange still makes sense is
  /// the receiver's to decide - it knows what happened to the entry since. A
  /// keypad whose characters cannot be taken back leaves this null.
  final void Function(String entered, String alternate)? onKeyHeld;

  final KeypadKeyStyle? style;

  @Deprecated('Use style.textStyle.fontSize instead')
  final double? textFontSize;

  @Deprecated('Use style.textStyle.color instead')
  final Color? textColor;

  @Deprecated('Use style.subtextStyle.fontSize instead')
  final double? subtextFontSize;

  @override
  State<KeypadKeyButton> createState() => _KeypadKeyButtonState();
}

class _KeypadKeyButtonState extends State<KeypadKeyButton> {
  /// The fingers on the key that may still turn into a long press: where each
  /// one touched and the countdown to its long press.
  final _holds = <int, ({Offset origin, Timer countdown})>{};

  /// The latest touch of the key. An earlier finger still resting on it holds
  /// a character that is no longer the last one entered.
  int? _latestTouch;

  /// What a long press gives, when the key has one and somebody takes it.
  String? get _alternate => widget.onKeyHeld == null ? null : widget.alternate;

  void _onPointerDown(PointerDownEvent event) {
    _latestTouch = event.pointer;
    widget.onKeyPressed(widget.text);

    if (_alternate == null) return;
    _holds[event.pointer] = (origin: event.position, countdown: Timer(kLongPressTimeout, () => _onHeld(event.pointer)));
  }

  /// A finger that slides away is typing, not holding: the same distance at
  /// which the framework gives up a long press, for every kind of pointer.
  void _onPointerMove(PointerMoveEvent event) {
    final hold = _holds[event.pointer];
    if (hold == null) return;

    final slop = MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;
    if ((event.position - hold.origin).distance > slop) _release(event.pointer);
  }

  void _release(int pointer) => _holds.remove(pointer)?.countdown.cancel();

  void _onHeld(int pointer) {
    _holds.remove(pointer);
    final alternate = _alternate;
    if (alternate == null || pointer != _latestTouch) return;
    widget.onKeyHeld?.call(widget.text, alternate);
  }

  @override
  void dispose() {
    for (final hold in _holds.values) {
      hold.countdown.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themed = theme.extension<KeypadKeyStyles>()?.primary;

    final merged = KeypadKeyStyle.merge(themed, widget.style);

    final textStyle = (merged.textStyle ?? theme.textTheme.headlineLarge)?.copyWith(
      fontSize: widget.textFontSize ?? merged.textStyle?.fontSize,
      color: widget.textColor ?? merged.textStyle?.color,
      height: 1.0,
    );

    // Derive subtext color from text color with reduced opacity if not set.
    Color? derivedSubColor = textStyle?.color;
    if (derivedSubColor != null) {
      var a = derivedSubColor.a - KeypadKeyButton._subtextAlphaReduction;
      if (a < KeypadKeyButton._minAlphaValue) a = KeypadKeyButton._minAlphaValue;
      derivedSubColor = derivedSubColor.withValues(alpha: a);
    }

    final subStyle = (merged.subtextStyle ?? theme.textTheme.bodyMedium)?.copyWith(
      fontSize: widget.subtextFontSize ?? merged.subtextStyle?.fontSize,
      color: merged.subtextStyle?.color ?? derivedSubColor,
      height: 1.0,
    );

    final alternate = _alternate;

    // The pointer input stays on the Listener below; this node carries the
    // accessibility contract for the key. The subtree is excluded so the
    // decorative TextButton's no-op handler and the raw glyph texts do not
    // form nodes of their own - assistive-technology activation must reach
    // the same input path as a finger.
    return Semantics(
      identifier: keypadKeyId(widget.text),
      label: widget.subtext.isEmpty ? widget.text : '${widget.text} ${widget.subtext}',
      button: true,
      excludeSemantics: true,
      onTap: () => widget.onKeyPressed(widget.text),
      onLongPress: alternate == null ? null : () => widget.onKeyPressed(alternate),
      // Raw pointers, outside the gesture arena: the touch must enter its
      // character whatever else competes for the gesture, and the button
      // below keeps the press all to itself, drawn the way it always was.
      child: Listener(
        key: Key(widget.text),
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: (event) => _release(event.pointer),
        onPointerCancel: (event) => _release(event.pointer),
        // The button only draws the press.
        child: TextButton(
          onPressed: () {},
          style: merged.buttonStyle,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.text, style: textStyle),
              Padding(
                padding: KeypadKeyButton._subextPadding,
                child: Text(widget.subtext, style: subStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
