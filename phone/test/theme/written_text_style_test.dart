import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/theme/extension/written_text_style.dart';

/// The weight of text a person wrote.
///
/// Every script has a regular and a bold face on both platforms and in any
/// typeface a brand picks; the weights between them exist for few scripts.
void main() {
  FontWeight? written(FontWeight? weight) => TextStyle(fontWeight: weight).written.fontWeight;

  test('a weight short of semi-bold becomes regular', () {
    for (final weight in [null, FontWeight.w300, FontWeight.w400, FontWeight.w500]) {
      expect(written(weight), FontWeight.w400, reason: '$weight');
    }
  });

  test('a weight from semi-bold up becomes bold', () {
    for (final weight in [FontWeight.w600, FontWeight.w700, FontWeight.w900]) {
      expect(written(weight), FontWeight.w700, reason: '$weight');
    }
  });

  test('nothing but the weight changes', () {
    const style = TextStyle(fontFamily: 'Brand Sans', fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15);

    expect(style.written, style.copyWith(fontWeight: FontWeight.w400));
  });
}
