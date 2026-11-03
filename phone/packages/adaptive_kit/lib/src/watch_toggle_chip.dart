import 'package:material_ui/material_ui.dart';

import 'semantic_action.dart';

/// A consent or a setting on a watch: one full-width pill with a switch.
///
/// A checkbox beside a paragraph is a small target next to a long text; on a
/// face the whole pill is the target and its [label] is short. The switch is
/// drawn smaller than a phone's, so the label keeps the width it needs.
class WatchToggleChip extends StatelessWidget {
  const WatchToggleChip({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.identifier,
    this.toggleKey,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  /// The automation id of the toggle.
  final String? identifier;

  /// The key automation finds the toggle by.
  final Key? toggleKey;

  static const _switchScale = 0.7;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final onChanged = this.onChanged;
    final chip = Material(
      key: toggleKey,
      color: themeData.colorScheme.surfaceContainerHighest,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: themeData.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                ),
                // The pill is the target; the switch only shows the state, so
                // it stays out of the semantics and out of the hit test.
                ExcludeSemantics(
                  child: IgnorePointer(
                    child: Transform.scale(
                      scale: _switchScale,
                      child: Switch(
                        value: value,
                        onChanged: onChanged,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // One node: the label, the on/off state and the tap.
    final node = Semantics(toggled: value, child: chip);
    final identifier = this.identifier;
    return identifier != null ? SemanticAction(identifier: identifier, child: node) : MergeSemantics(child: node);
  }
}
