// ignore_for_file: deprecated_member_use_from_same_package

import 'package:clock/clock.dart';
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
  final String subtext;

  /// A press entered a character: [text], or the [subtext] of a key that has
  /// an alternate and was held (see [_KeypadKeyButtonState._alternate]).
  final void Function(String) onKeyPressed;

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
  /// When the finger now on the key touched it.
  DateTime? _touchedAt;

  /// The character a long press enters instead of the key's own: a
  /// one-character subtext - the "+" under "0". The letters under the digits
  /// are a caption, not an alternate.
  String? get _alternate => widget.subtext.length == 1 ? widget.subtext : null;

  /// A key without an alternate enters its character on the touch, not on the
  /// lift: a lift-based tap is cancelled by the framework once the finger
  /// travels 18 logical pixels, which fast typing does all the time - the key
  /// lights up and enters nothing (WT-1436).
  ///
  /// A key with an alternate cannot do that, because its touch may still turn
  /// into a long press; it waits for the lift, see [_onPointerUp].
  void _onPointerDown(PointerDownEvent event) {
    _touchedAt = clock.now();
    if (_alternate == null) widget.onKeyPressed(widget.text);
  }

  /// The lift of a key with an alternate enters the key's own character when
  /// it comes before the long-press timeout. After it the long press of the
  /// button below has entered the alternate ([_enterAlternate]).
  void _onPointerUp(PointerUpEvent event) {
    final touchedAt = _touchedAt;
    if (touchedAt == null) return;
    if (clock.now().difference(touchedAt) < kLongPressTimeout) widget.onKeyPressed(widget.text);
  }

  void _enterAlternate(String alternate) => widget.onKeyPressed(alternate);

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
    final onLongPress = alternate == null ? null : () => _enterAlternate(alternate);

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
      onLongPress: onLongPress,
      child: Listener(
        key: Key(widget.text),
        onPointerDown: _onPointerDown,
        onPointerUp: alternate == null ? null : _onPointerUp,
        child: TextButton(
          // The button draws the press and tells a long press from a short
          // one; what a short press enters is decided by the Listener.
          onPressed: () {},
          onLongPress: onLongPress,
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
