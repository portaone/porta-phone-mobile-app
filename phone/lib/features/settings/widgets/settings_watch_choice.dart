import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

/// One option of a [SettingsWatchChoicePage].
class SettingsWatchOption<T> {
  const SettingsWatchOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.identifier,
    this.fitTitle = false,
  });

  final T value;
  final String label;
  final String? subtitle;

  /// A mark before the label, such as a presence's dot.
  final Widget? leading;

  /// The automation id of the row, the phone's id for the same option.
  final String? identifier;

  /// Keeps the label on one line, as [WatchListTile.fitTitle] does: for a
  /// number, which a line break would cut in the middle.
  final bool fitTitle;
}

/// A setting that is a choice, on a watch: the setting's name, a row per
/// option, the current one tinted with a tick. A tap chooses it - the page
/// applies it at once, as the phone does - and goes back to the list it was
/// opened from, whose row then names the new value.
///
/// [enabled] false shows the rows dimmed, offering nothing, where the brand
/// fixes the setting. [header] goes over the rows (a note such as "Custom"),
/// [footer] after them (what stays on the phone). A page that holds more than
/// the choice - a toggle, an action after it - sets [closeOnChoice] false and
/// stays where it is.
class SettingsWatchChoicePage<T> extends StatelessWidget {
  const SettingsWatchChoicePage({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onChosen,
    this.enabled = true,
    this.header = const [],
    this.footer = const [],
    this.closeOnChoice = true,
  });

  final String title;
  final List<SettingsWatchOption<T>> options;

  /// The option in force; when it is none of [options], no row is tinted.
  final T? selected;

  final ValueChanged<T> onChosen;
  final bool enabled;
  final List<Widget> header;
  final List<Widget> footer;
  final bool closeOnChoice;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WatchScrollList(
        title: title,
        spacing: context.adaptiveMetrics.gap,
        children: [
          ...header,
          for (final option in options)
            WatchListTile(
              identifier: option.identifier,
              leading: option.leading,
              title: option.label,
              fitTitle: option.fitTitle,
              subtitle: option.subtitle,
              selected: option.value == selected,
              trailing: option.value == selected ? const Icon(Icons.check) : null,
              onTap: enabled ? () => _choose(context, option.value) : null,
            ),
          ...footer,
        ],
      ),
    );
  }

  void _choose(BuildContext context, T value) {
    // The option in force is not applied again, as a phone's radio does not
    // re-fire for its checked value: some settings restart a service when
    // they are set, even to the same value.
    if (value != selected) onChosen(value);
    if (closeOnChoice) Navigator.of(context).maybePop();
  }
}
