import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import 'list_tile_separator.dart';

/// A reusable settings list tile widget that combines a [ListTile]
/// with an optional [ListTileSeparator] below it.
///
/// Displays a leading [Icon], a text [title], an optional [trailing]
/// widget, and can show or hide the separator via [showSeparator].
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.trailing,
    this.trailingLabel,
    this.textStyle,
    this.showSeparator = true,
    this.separatorColor,
    this.enabled = true,
    this.opacity = 1.0,
    this.identifier,
    super.key,
  }) : assert(opacity >= 0.0 && opacity <= 1.0, 'opacity must be between 0.0 and 1.0');

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget? trailing;

  /// What a badge in [trailing] stands for, spoken after the row's title.
  ///
  /// A tile merges into a single node whose name is assembled in the order its
  /// parts are drawn, and the trailing slot is drawn last - which is what puts
  /// this behind the title instead of ahead of it. Anything the trailing widget
  /// draws by itself would be read out inside the title.
  final String? trailingLabel;

  final TextStyle? textStyle;
  final bool showSeparator;
  final Color? separatorColor;
  final VoidCallback onTap;
  final bool enabled;
  final double opacity;

  /// Stable automation id of the row; the title is translated and, for some
  /// rows, configured per install, so it cannot be relied on to find one.
  final String? identifier;

  @override
  Widget build(BuildContext context) {
    final trailingLabel = this.trailingLabel;
    final trailing = this.trailing;

    // On the trailing widget rather than around the tile: a name given to the
    // tile itself would be assembled before everything the tile draws, and so
    // spoken ahead of the title it is meant to follow.
    final spokenTrailing = trailingLabel == null || trailing == null
        ? trailing
        : Semantics(label: trailingLabel, child: trailing);

    final identifier = this.identifier;
    final listTile = ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: textStyle),
      trailing: spokenTrailing,
      onTap: onTap,
      enabled: enabled,
    );

    // Only a row that is given an id is wrapped: merging a row whose trailing
    // widget forms a node of its own would fold that node into the row.
    final tile = Opacity(
      opacity: opacity,
      child: identifier == null ? listTile : SemanticAction(identifier: identifier, child: listTile),
    );

    if (!showSeparator) return tile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        ListTileSeparator(color: separatorColor),
      ],
    );
  }
}
