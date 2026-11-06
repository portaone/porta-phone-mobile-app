import 'package:material_ui/material_ui.dart';

export 'extended_text_style.dart';

import 'package:webtrit_phone/widgets/extended_text_style.dart';

class ExtendedText extends StatelessWidget {
  const ExtendedText(this.data, {super.key, this.extendedStyle, this.textAlign, this.maxLines, this.trailing});

  final String data;
  final ExtendedTextStyle? extendedStyle;
  final TextAlign? textAlign;

  /// Cuts the text to this many lines with an ellipsis; unlimited when null.
  final int? maxLines;

  /// Drawn after the text inside the decoration, centred on it - a sign
  /// that the text goes on elsewhere.
  final Widget? trailing;

  /// The room [trailing] takes beside the text.
  static const trailingGap = 4.0;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      data,
      style: extendedStyle?.textStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
    );
    final trailing = this.trailing;
    final content = trailing == null
        ? text
        : Row(
            mainAxisSize: MainAxisSize.min,
            spacing: trailingGap,
            children: [
              Flexible(child: text),
              trailing,
            ],
          );

    final decoration = extendedStyle?.decoration;
    if (decoration == null) return content;

    return DecoratedBox(
      decoration: BoxDecoration(color: decoration.color, borderRadius: decoration.borderRadius),
      child: Padding(padding: decoration.padding ?? EdgeInsets.zero, child: content),
    );
  }
}
