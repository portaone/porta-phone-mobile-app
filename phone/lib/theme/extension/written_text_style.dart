import 'package:material_ui/material_ui.dart';

extension WrittenTextStyle on TextStyle {
  /// This style for text a person wrote - a name, a note, a subject.
  ///
  /// Such text may be in any script. Where the app's typeface has no letters
  /// for it the platform draws it, and for most scripts the platform has a
  /// regular and a bold face with nothing between: asked for 500 or 600 it
  /// answers with bold, beside Latin text in a medium face. Regular and bold
  /// exist for every script and in every typeface a brand picks, so the weight
  /// is moved to the nearer of the two.
  TextStyle get written {
    final weight = fontWeight ?? FontWeight.w400;
    return copyWith(fontWeight: weight.value >= FontWeight.w600.value ? FontWeight.w700 : FontWeight.w400);
  }
}
