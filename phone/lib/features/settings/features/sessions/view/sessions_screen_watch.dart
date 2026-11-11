import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/settings_watch_choice.dart';
import '../cubit/sessions_cubit.dart';
import 'widgets/widgets.dart';

/// Active sessions on a watch face.
///
/// When idle sessions end as a row, this device first and tinted, the other
/// devices under their count - a tap signs one out after the watch confirm -
/// and Sign out others as the red edge button. On its way, failed and empty
/// are the watch's state pages.
///
/// The handlers that confirm, sign out, refresh and save are the screen's own,
/// shared with the phone, and come in from it.
class SessionsScreenWatch extends StatelessWidget {
  const SessionsScreenWatch({
    super.key,
    required this.dateFormat,
    required this.autoTerminateSelectable,
    required this.onRefresh,
    required this.onRevoke,
    required this.onRevokeAllOthers,
    required this.onSaveAutoTerminate,
    this.appVersion,
  });

  final DateFormat dateFormat;

  /// The version this build runs, so a row says its own only when it differs.
  final Version? appVersion;

  /// Whether the user may choose when idle sessions end; without it the
  /// period is only stated.
  final bool autoTerminateSelectable;

  final Future<void> Function(BuildContext context) onRefresh;

  final Future<void> Function(BuildContext context, ActiveSession session) onRevoke;

  final Future<void> Function(BuildContext context) onRevokeAllOthers;

  /// Saves the period chosen and reports the outcome from the screen.
  final Future<SessionAutoTerminateSaveResult> Function(BuildContext context, SessionsCubit cubit, int? days)
  onSaveAutoTerminate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final title = l10n.sessions_AppBar_title;
    return Scaffold(
      body: BlocBuilder<SessionsCubit, SessionsState>(
        builder: (context, state) {
          if (state.loading && state.sessions.isEmpty) {
            return WatchStatePage.loading(title: title, progressLabel: l10n.common_SemanticsLabel_loading);
          }
          if (state.failed && state.sessions.isEmpty) {
            return WatchStatePage(
              title: title,
              icon: const Icon(Icons.error_outline),
              message: l10n.sessions_Placeholder_failure,
              action: WatchAction(label: l10n.sessions_Button_retry, onPressed: () => onRefresh(context)),
            );
          }
          // Refresh on the edge in place of the phone's pull to refresh: the
          // list may fill once another device signs in.
          if (state.sessions.isEmpty) {
            return WatchStatePage(
              title: title,
              icon: const Icon(Icons.devices),
              message: l10n.sessions_Placeholder_empty,
              action: WatchAction(label: l10n.common_SemanticsLabel_refresh, onPressed: () => onRefresh(context)),
            );
          }
          final autoTerminate = state.autoTerminate;
          final days = autoTerminate?.inactivityTimeoutDays;
          final rows = [
            if (autoTerminate != null && autoTerminateSelectable)
              WatchListTile(
                identifier: sessionsAutoTerminateId,
                leading: const Icon(Icons.timer_outlined),
                title: l10n.sessions_AutoTerminate_title,
                subtitle: sessionAutoTerminatePeriod(l10n, days),
                trailing: state.savingAutoTerminate
                    ? const SizedCircularProgressIndicator(size: 16, strokeWidth: 2)
                    : null,
                onTap: state.savingAutoTerminate ? null : () => _onWatchAutoTerminate(context, autoTerminate),
              )
            else if (days != null)
              SemanticId(
                identifier: sessionsAutoTerminateInfoId,
                child: WatchListNote(l10n.sessions_AutoTerminate_info(days)),
              ),
            if (state.currentSession case final current?) ...[
              WatchListLabel(l10n.sessions_Tile_currentSession),
              SessionWatchTile(
                session: current,
                index: 0,
                dateFormat: dateFormat,
                revoking: false,
                onRevoke: (_) {},
                ownAppVersion: appVersion,
              ),
            ],
            if (state.hasOtherSessions) ...[
              WatchListLabel(l10n.sessions_Section_otherDevices(state.otherSessions.length)),
              for (final (index, session) in state.otherSessions.indexed)
                SessionWatchTile(
                  session: session,
                  index: index,
                  dateFormat: dateFormat,
                  revoking: state.isRevoking(session.id),
                  onRevoke: (session) => onRevoke(context, session),
                  ownAppVersion: appVersion,
                ),
            ],
          ];
          return WatchScrollList.builder(
            title: title,
            spacing: context.adaptiveMetrics.gap,
            itemCount: rows.length,
            itemBuilder: (context, index) => rows[index],
            edge: !state.hasOtherSessions
                ? null
                : (context, overlay) => WatchAction(
                    label: l10n.sessions_Watch_revokeAllOthers,
                    identifier: sessionsRevokeAllOthersButtonId,
                    // styleFrom, not fixed colours: the button disabled
                    // while a sign-out is on its way must not look red and live.
                    style: OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
                      disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
                      side: BorderSide.none,
                    ),
                    // Not while a sign-out is on its way: the one under way
                    // would be asked for a second time.
                    onPressed: state.revoking.isEmpty ? () => onRevokeAllOthers(context) : null,
                  ).buildButton(overlay),
          );
        },
      ),
    );
  }

  /// The choice of when idle sessions end on a watch: the installation's
  /// period, the presets shorter than it and a period of one's own already in
  /// force. A number of days of one's own is chosen on the phone.
  Future<void> _onWatchAutoTerminate(BuildContext context, SessionAutoTerminate autoTerminate) async {
    final l10n = context.l10n;
    final cubit = context.read<SessionsCubit>();
    final current = autoTerminate.inactivityTimeoutDays;
    final isDefault = autoTerminate.isInstallationDefault;
    final options = <(String, int?, String)>[
      (
        'default',
        null,
        l10n.sessions_AutoTerminate_default(sessionAutoTerminatePeriod(l10n, autoTerminate.installationMaxDays)),
      ),
      for (final days in autoTerminate.presets) ('days$days', days, sessionAutoTerminatePeriod(l10n, days)),
      if (!isDefault && current != null && !autoTerminate.presets.contains(current))
        ('current', current, sessionAutoTerminatePeriod(l10n, current)),
    ];
    // As the phone's sheet: Default only while the installation's period is
    // in force, a period only while it is - with none in force, nothing.
    final selected = isDefault
        ? 'default'
        : options.where((option) => option.$1 != 'default' && option.$2 == current).firstOrNull?.$1;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsWatchChoicePage<String>(
          title: l10n.sessions_AutoTerminate_title,
          options: [
            for (final (id, _, label) in options)
              SettingsWatchOption(
                value: id,
                label: label,
                identifier: settingsOptionId(sessionsAutoTerminateOptionIdPrefix, id),
              ),
          ],
          selected: selected,
          onChosen: (id) => onSaveAutoTerminate(context, cubit, options.firstWhere((option) => option.$1 == id).$2),
          footer: [
            if (autoTerminate.installationMaxDays case final max?)
              WatchListNote(l10n.sessions_AutoTerminate_adminLimitNote(max)),
          ],
        ),
      ),
    );
  }
}
