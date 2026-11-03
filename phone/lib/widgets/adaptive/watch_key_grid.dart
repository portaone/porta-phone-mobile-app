import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/models.dart';

/// Twelve keys in four rows sharing the height they are given, with no gaps
/// between them, so every whole cell is the target: the dial keypad and a
/// call's tones.
///
/// Each key is one node, its digit its name. A key with an alternate (0 for
/// +) enters it on a long press, unless [alternates] is off.
class WatchKeyGrid extends StatelessWidget {
  const WatchKeyGrid({super.key, required this.onPressed, this.alternates = true, this.identifier});

  /// Null shows the keys disabled.
  final ValueChanged<String>? onPressed;

  /// Whether a held key enters its alternate.
  final bool alternates;

  /// The automation id of a key by its text; none by default.
  final String Function(String text)? identifier;

  @override
  Widget build(BuildContext context) {
    final keys = KeypadKey.numbers;
    return Column(
      children: [
        for (var row = 0; row < 4; row++)
          Expanded(
            child: Row(
              children: [
                for (final key in keys.skip(row * 3).take(3))
                  Expanded(
                    child: _Key(
                      keypadKey: key,
                      onPressed: onPressed,
                      alternate: alternates ? key.alternate : null,
                      identifier: identifier?.call(key.text),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.keypadKey, required this.onPressed, required this.alternate, required this.identifier});

  final KeypadKey keypadKey;
  final ValueChanged<String>? onPressed;
  final String? alternate;
  final String? identifier;

  @override
  Widget build(BuildContext context) {
    final text = keypadKey.text;
    final alternate = this.alternate;
    final onPressed = this.onPressed;
    final symbol = text == '*' || text == '#';
    final textTheme = Theme.of(context).textTheme;
    final tap = onPressed == null ? null : () => onPressed(text);
    final hold = onPressed == null || alternate == null ? null : () => onPressed(alternate);

    return Semantics(
      identifier: identifier,
      label: text,
      button: true,
      enabled: onPressed != null,
      excludeSemantics: true,
      onTap: tap,
      onLongPress: hold,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        onTap: tap,
        // A tap enters on release here, so a held key has entered nothing yet:
        // it enters its alternate straight away.
        onLongPress: hold,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: (symbol ? textTheme.titleMedium : textTheme.titleLarge)?.copyWith(
                fontWeight: FontWeight.w500,
                color: onPressed == null ? Theme.of(context).disabledColor : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
