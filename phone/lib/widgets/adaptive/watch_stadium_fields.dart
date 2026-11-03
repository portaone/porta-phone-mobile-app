import 'package:material_ui/material_ui.dart';

/// Rounds the outlined borders of the text fields below into pills, the
/// shape every control on a watch face takes; the theme's colours and widths
/// stay.
class WatchStadiumFields extends StatelessWidget {
  const WatchStadiumFields({super.key, required this.child});

  final Widget child;

  static const _radius = BorderRadius.all(Radius.circular(24));

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final decoration = themeData.inputDecorationTheme;

    InputBorder? round(InputBorder? border) =>
        border is OutlineInputBorder ? border.copyWith(borderRadius: _radius) : border;

    return Theme(
      data: themeData.copyWith(
        inputDecorationTheme: decoration.copyWith(
          border: round(decoration.border),
          enabledBorder: round(decoration.enabledBorder),
          focusedBorder: round(decoration.focusedBorder),
          errorBorder: round(decoration.errorBorder),
          focusedErrorBorder: round(decoration.focusedErrorBorder),
          disabledBorder: round(decoration.disabledBorder),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      child: child,
    );
  }
}
