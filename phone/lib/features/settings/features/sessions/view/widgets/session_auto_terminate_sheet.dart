import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/settings/features/sessions/cubit/sessions_cubit.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'session_auto_terminate_period.dart';

/// Automation id of one row of the sheet, from what the row stands for.
String sessionAutoTerminateOptionId(String value) => settingsOptionId(sessionsAutoTerminateOptionIdPrefix, value);

/// The modal bottom sheet that picks after how long idle sessions end.
///
/// A pick is saved at once and the sheet stays open, the row showing progress,
/// until the core has answered, then closes. What the core answered is said by
/// whoever passed [onSave], not by the sheet: the sheet may be dragged away
/// while the core is being asked. Offered: the installation's period, the presets shorter than it,
/// the period in force when it is none of those (set by another client), and a
/// number of days of one's own. "Other..." takes that number on a page of its
/// own inside the sheet: the list slides away, and back - its arrow or the
/// system back - returns to the list rather than closing the sheet.
class SessionAutoTerminateSheet extends StatefulWidget {
  const SessionAutoTerminateSheet({super.key, required this.autoTerminate, required this.onSave});

  final SessionAutoTerminate autoTerminate;

  final Future<SessionAutoTerminateSaveResult> Function(int? days) onSave;

  static Future<void> show(
    BuildContext context, {
    required SessionAutoTerminate autoTerminate,
    required Future<SessionAutoTerminateSaveResult> Function(int? days) onSave,
  }) {
    return context.showModalBottomSheet<void>(
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SessionAutoTerminateSheet(autoTerminate: autoTerminate, onSave: onSave),
    );
  }

  @override
  State<SessionAutoTerminateSheet> createState() => _SessionAutoTerminateSheetState();
}

class _SessionAutoTerminateSheetState extends State<SessionAutoTerminateSheet> {
  static const _pageDuration = Duration(milliseconds: 250);

  /// The id of the row whose period is being saved.
  String? _saving;

  /// Whether the page of "Other..." is shown instead of the list.
  bool _otherOpen = false;

  late final TextEditingController _otherDays = TextEditingController(
    text: widget.autoTerminate.isInstallationDefault
        ? ''
        : widget.autoTerminate.inactivityTimeoutDays?.toString() ?? '',
  );

  /// Whether the typed number is outside 1..maxDays after a save was tried.
  bool _otherInvalid = false;

  @override
  void dispose() {
    _otherDays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _saving == null && !_otherOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _otherOpen && _saving == null) _closeOther();
      },
      child: SemanticId(
        identifier: sessionsAutoTerminateSheetId,
        child: SafeArea(
          child: AnimatedSize(
            duration: _pageDuration,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: _pageDuration,
              layoutBuilder: (current, previous) =>
                  Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
              transitionBuilder: (child, animation) {
                // The page of "Other..." comes in from the end, the list from
                // the start - each leaves the way it came.
                final fromEnd = child.key == const ValueKey('other');
                return SlideTransition(
                  position: Tween(
                    begin: Offset(fromEnd ? 1 : -1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: _otherOpen
                  ? KeyedSubtree(key: const ValueKey('other'), child: _buildOther(context))
                  : KeyedSubtree(key: const ValueKey('list'), child: _buildList(context)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final autoTerminate = widget.autoTerminate;
    final current = autoTerminate.inactivityTimeoutDays;
    final isDefault = autoTerminate.isInstallationDefault;
    final presets = autoTerminate.presets;
    final installationMaxDays = autoTerminate.installationMaxDays;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.sessions_AutoTerminate_title, style: theme.textTheme.titleMedium),
          ),
          _SessionAutoTerminateOption(
            id: 'default',
            label: l10n.sessions_AutoTerminate_default(sessionAutoTerminatePeriod(l10n, installationMaxDays)),
            selected: isDefault,
            saving: _saving,
            onTap: () => _pick('default', null, isDefault),
          ),
          for (final days in presets)
            _SessionAutoTerminateOption(
              id: 'days$days',
              label: sessionAutoTerminatePeriod(l10n, days),
              selected: !isDefault && current == days,
              saving: _saving,
              onTap: () => _pick('days$days', days, !isDefault && current == days),
            ),
          if (!isDefault && current != null && !presets.contains(current))
            _SessionAutoTerminateOption(
              id: 'current',
              label: sessionAutoTerminatePeriod(l10n, current),
              selected: true,
              saving: _saving,
              onTap: () => _pick('current', current, true),
            ),
          _SessionAutoTerminateOption(
            id: 'other',
            label: l10n.sessions_AutoTerminate_other,
            selected: false,
            opensPage: true,
            saving: _saving,
            onTap: _openOther,
          ),
          if (installationMaxDays != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                l10n.sessions_AutoTerminate_adminLimitNote(installationMaxDays),
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOther(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final range = l10n.sessions_AutoTerminateOther_range(widget.autoTerminate.maxDays);
    final saving = _saving != null;

    return SingleChildScrollView(
      // The field brings up the keyboard; keep the page above it.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 16, 0),
            child: Row(
              children: [
                SemanticAction(
                  identifier: sessionsAutoTerminateOtherBackId,
                  child: IconButton(
                    icon: const BackButtonIcon(),
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    onPressed: saving ? null : _closeOther,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(child: Text(l10n.sessions_AutoTerminateOther_title, style: theme.textTheme.titleMedium)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SemanticId(
              identifier: sessionsAutoTerminateOtherInputId,
              child: TextField(
                controller: _otherDays,
                autofocus: true,
                enabled: !saving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.sessions_AutoTerminateOther_label,
                  helperText: _otherInvalid ? null : range,
                  errorText: _otherInvalid ? range : null,
                ),
                onChanged: (_) => setState(() => _otherInvalid = false),
                onSubmitted: (_) => _saveOther(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SemanticAction(
                identifier: sessionsAutoTerminateOtherSaveId,
                child: FilledButton(
                  onPressed: saving ? null : _saveOther,
                  child: saving
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.sessions_AutoTerminateOther_save),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openOther() => setState(() => _otherOpen = true);

  void _closeOther() {
    FocusScope.of(context).unfocus();
    setState(() {
      _otherOpen = false;
      _otherInvalid = false;
    });
  }

  Future<void> _saveOther() async {
    final autoTerminate = widget.autoTerminate;
    final days = int.tryParse(_otherDays.text);
    if (days == null || days < 1 || days > autoTerminate.maxDays) {
      setState(() => _otherInvalid = true);
      return;
    }
    final unchanged = !autoTerminate.isInstallationDefault && days == autoTerminate.inactivityTimeoutDays;
    await _pick('other', days, unchanged);
  }

  Future<void> _pick(String id, int? days, bool unchanged) async {
    if (unchanged) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = id);
    await widget.onSave(days);
    if (!mounted) return;
    setState(() => _saving = null);
    // Dismissed by a drag while the core was being asked: the sheet is no
    // longer the route on top, and popping would close whatever is.
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.pop(context);
  }
}

class _SessionAutoTerminateOption extends StatelessWidget {
  const _SessionAutoTerminateOption({
    required this.id,
    required this.label,
    required this.selected,
    required this.saving,
    required this.onTap,
    this.opensPage = false,
  });

  final String id;

  final String label;

  final bool selected;

  /// Whether a tap opens a page of the sheet rather than picking a period.
  final bool opensPage;

  /// The id of the row being saved, if any; every row waits for it.
  final String? saving;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget? trailing;
    if (saving == id) {
      trailing = const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2));
    } else if (selected) {
      trailing = const Icon(Icons.check);
    } else if (opensPage) {
      trailing = const Icon(Icons.chevron_right);
    } else {
      trailing = null;
    }

    return SemanticAction(
      identifier: sessionAutoTerminateOptionId(id),
      child: ListTile(title: Text(label), selected: selected, trailing: trailing, onTap: saving == null ? onTap : null),
    );
  }
}
