import 'package:flutter/widgets.dart';

/// What one row offers while somebody is being chosen.
///
/// Its presence is what tells a row that a choice is being made at all; an
/// [onPressed] of null then means this row is not an answer to it. A row in
/// that state offers nothing - not the choice, and not the ordinary actions
/// either, which act on a number the person did not come here to act on.
class TilePick {
  const TilePick({required this.icon, required this.label, this.onPressed});

  /// The mark the control carries. It belongs to whatever is asking: handing a
  /// call on and passing a message along are not the same gesture and should
  /// not wear the same icon.
  final IconData icon;

  /// What the control is called, for a reader.
  final String label;

  /// Takes this row as the answer, or null when the purpose refuses it.
  final VoidCallback? onPressed;

  /// Whether this row can be chosen right now.
  bool get isAnswer => onPressed != null;
}
