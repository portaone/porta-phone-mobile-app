import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.label, required this.value, this.valueIdentifier});

  final String label;
  final String? value;

  /// Stable automation id of the value line alone, so it can be read without
  /// the translated caption above it.
  final String? valueIdentifier;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final effectiveValue = value ?? '-';
    final valueIdentifier = this.valueIdentifier;

    final valueText = Text(
      effectiveValue,
      style: themeData.textTheme.labelSmall,
      textAlign: TextAlign.center,
      overflow: TextOverflow.ellipsis,
    );

    if (valueIdentifier == null) {
      return CopyToClipboard(
        data: effectiveValue,
        child: Column(mainAxisSize: MainAxisSize.min, children: [Text(label), valueText]),
      );
    }

    // The value gets a node of its own so it can be read without the caption.
    // The copy goes with it: an identifier inside the copy would leave the
    // copy action on the caption and the value without one. The caption has
    // its own copy of the same value, so a long press anywhere on the tile
    // copies it.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CopyToClipboard(data: effectiveValue, child: Text(label)),
        SemanticId(
          identifier: valueIdentifier,
          child: CopyToClipboard(data: effectiveValue, child: valueText),
        ),
      ],
    );
  }
}
