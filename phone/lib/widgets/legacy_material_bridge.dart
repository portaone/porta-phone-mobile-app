import 'package:material_ui/material_ui.dart';

/// Gives the widgets below it the theme and the localizations of
/// flutter/material, mapped from the material_ui ones above it.
///
/// The app is built on material_ui, but the emoji and country pickers are
/// still built on flutter/material, and without these they find no
/// MaterialLocalizations and throw. Goes once those packages have moved.
class LegacyMaterialBridge extends StatelessWidget {
  const LegacyMaterialBridge({required this.child, super.key});

  final Widget child;

  @override
  // ignore: deprecated_member_use
  Widget build(BuildContext context) => MaterialUiCompatibilityBridge(child: child);
}
