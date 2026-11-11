import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../../../widgets/settings_watch_choice.dart';
import '../cubit/sessions_cubit.dart';
import 'session_auto_terminate_snack_bar.dart';
import 'widgets/widgets.dart';

class SessionsScreen extends StatelessWidget {
  const SessionsScreen({
    super.key,
    required this.dateFormat,
    required this.autoTerminateSnackBar,
    this.autoTerminateSelectable = false,
    this.appVersion,
  });

  final DateFormat dateFormat;

  /// The version this build runs, so a row says its own only when it differs.
  final Version? appVersion;

  final SessionAutoTerminateSnackBar autoTerminateSnackBar;

  /// Whether the user may choose when idle sessions end (the adapter's
  /// `sessionAutoTerminate`); without it the period is only stated.
  final bool autoTerminateSelectable;

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// When idle sessions end as a row, this device first and tinted, the other
  /// devices under their count - a tap signs one out after the watch confirm -
  /// and Sign out others as the red edge button. On its way, failed and empty
  /// are the watch's state pages.
  Widget _watch(BuildContext context) {
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
              action: WatchAction(label: l10n.sessions_Button_retry, onPressed: () => _onRefresh(context)),
            );
          }
          // Refresh on the edge in place of the phone's pull to refresh: the
          // list may fill once another device signs in.
          if (state.sessions.isEmpty) {
            return WatchStatePage(
              title: title,
              icon: const Icon(Icons.devices),
              message: l10n.sessions_Placeholder_empty,
              action: WatchAction(label: l10n.common_SemanticsLabel_refresh, onPressed: () => _onRefresh(context)),
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
              SessionTile(
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
                SessionTile(
                  session: session,
                  index: index,
                  dateFormat: dateFormat,
                  revoking: state.isRevoking(session.id),
                  onRevoke: (session) => _onRevoke(context, session),
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
                    onPressed: state.revoking.isEmpty ? () => _onRevokeAllOthers(context) : null,
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
          onChosen: (id) => _saveAutoTerminate(context, cubit, options.firstWhere((option) => option.$1 == id).$2),
          footer: [
            if (autoTerminate.installationMaxDays case final max?)
              WatchListNote(l10n.sessions_AutoTerminate_adminLimitNote(max)),
          ],
        ),
      ),
    );
  }

  Widget _handset(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.sessions_AppBar_title), leading: const ExtBackButton()),
      body: BlocBuilder<SessionsCubit, SessionsState>(
        builder: (context, state) {
          if (state.loading && state.sessions.isEmpty) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state.failed && state.sessions.isEmpty) {
            return _FailurePlaceholder(onRetry: () => _onRefresh(context));
          }

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _onRefresh(context),
                    child: state.sessions.isEmpty
                        ? _EmptyPlaceholder(text: l10n.sessions_Placeholder_empty)
                        : ListView(
                            children: [
                              if (state.autoTerminate case final autoTerminate?)
                                SessionAutoTerminateTile(
                                  autoTerminate: autoTerminate,
                                  selectable: autoTerminateSelectable,
                                  saving: state.savingAutoTerminate,
                                  onTap: () => _onAutoTerminate(context, autoTerminate),
                                ),
                              // Two sections under one kind of heading: this device,
                              // then the others. Each row sits on one surface, a
                              // divider between rows, edge to edge like the tiles of
                              // the settings screens: the list reads as one list, not
                              // a stack of cards each saying the same things over.
                              if (state.currentSession case final current?) ...[
                                _SectionHeader(l10n.sessions_Tile_currentSession),
                                SessionTiles(
                                  children: [
                                    SessionTile(
                                      session: current,
                                      index: 0,
                                      dateFormat: dateFormat,
                                      revoking: false,
                                      onRevoke: (_) {},
                                      ownAppVersion: appVersion,
                                    ),
                                  ],
                                ),
                              ],
                              if (state.hasOtherSessions) ...[
                                _SectionHeader(l10n.sessions_Section_otherDevices(state.otherSessions.length)),
                                SessionTiles(
                                  children: [
                                    for (final (index, session) in state.otherSessions.indexed)
                                      SessionTile(
                                        session: session,
                                        index: index,
                                        dateFormat: dateFormat,
                                        revoking: state.isRevoking(session.id),
                                        onRevoke: (session) => _onRevoke(context, session),
                                        ownAppVersion: appVersion,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                  ),
                ),
                if (state.hasOtherSessions)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: SemanticAction(
                      identifier: sessionsRevokeAllOthersButtonId,
                      // The same red as each device's own sign-out above it:
                      // the container tone of the error colour is a pale
                      // wash that reads as disabled next to them.
                      child: FilledButton.icon(
                        icon: const Icon(Icons.logout),
                        label: Text(l10n.sessions_Button_revokeAllOthers),
                        // Not while a sign-out is on its way: the one under
                        // way would be asked for a second time.
                        onPressed: state.revoking.isEmpty ? () => _onRevokeAllOthers(context) : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: colorScheme.onError,
                          backgroundColor: colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onRefresh(BuildContext context) => context.read<SessionsCubit>().fetch();

  Future<void> _onAutoTerminate(BuildContext context, SessionAutoTerminate autoTerminate) {
    final cubit = context.read<SessionsCubit>();
    return SessionAutoTerminateSheet.show(
      context,
      autoTerminate: autoTerminate,
      onSave: (days) => _saveAutoTerminate(context, cubit, days),
    );
  }

  /// Saves and reports the outcome from the screen itself, not from the sheet: the sheet can be
  /// dragged away while the core is being asked, and a failure must still be said, with its retry.
  ///
  /// A new save takes down what an earlier one said: its "try again" no longer stands for the
  /// user's choice, and a save that succeeds puts up nothing that would replace it. Two saves
  /// never run at once - the row is disabled while one does - so a retry hidden this way is
  /// the only one that could undo a later choice.
  Future<SessionAutoTerminateSaveResult> _saveAutoTerminate(
    BuildContext context,
    SessionsCubit cubit,
    int? days,
  ) async {
    autoTerminateSnackBar.hide();
    final result = await cubit.setInactivityTimeout(days);
    if (context.mounted) _reportAutoTerminate(context, cubit, days, result);
    return result;
  }

  /// The snack bar that offers this belongs to the messenger above the route and outlives the
  /// screen: once the user has left Active sessions there is nothing left to retry for.
  void _retryAutoTerminate(BuildContext context, SessionsCubit cubit, int? days) {
    if (!context.mounted || cubit.isClosed) return;
    _saveAutoTerminate(context, cubit, days);
  }

  void _reportAutoTerminate(
    BuildContext context,
    SessionsCubit cubit,
    int? days,
    SessionAutoTerminateSaveResult result,
  ) {
    final l10n = context.l10n;
    switch (result) {
      case SessionAutoTerminateSaveResult.saved:
        return;
      case SessionAutoTerminateSaveResult.exceedsInstallationLimit:
        autoTerminateSnackBar.showError(context, l10n.sessions_SnackBar_autoTerminateLimitChanged);
      case SessionAutoTerminateSaveResult.notSupported:
        autoTerminateSnackBar.showError(context, l10n.sessions_SnackBar_autoTerminateNotSupported);
      case SessionAutoTerminateSaveResult.failed:
        autoTerminateSnackBar.showError(
          context,
          l10n.sessions_SnackBar_autoTerminateFailed,
          action: SnackBarAction(
            label: l10n.sessions_Button_retry,
            onPressed: () => _retryAutoTerminate(context, cubit, days),
          ),
        );
    }
  }

  Future<void> _onRevoke(BuildContext context, ActiveSession session) async {
    final confirmed = await ConfirmDialog.showDangerous(
      context,
      title: context.l10n.sessions_RevokeConfirmDialog_title,
      content: context.l10n.sessions_RevokeConfirmDialog_content,
    );
    if (confirmed != true || !context.mounted) return;

    final succeeded = await context.read<SessionsCubit>().revoke(session.id);
    if (!succeeded && context.mounted) {
      context.showErrorSnackBar(context.l10n.sessions_SnackBar_revokeFailed);
    }
  }

  Future<void> _onRevokeAllOthers(BuildContext context) async {
    final confirmed = await ConfirmDialog.showDangerous(
      context,
      title: context.l10n.sessions_RevokeAllConfirmDialog_title,
      content: context.l10n.sessions_RevokeAllConfirmDialog_content,
    );
    if (confirmed != true || !context.mounted) return;

    final succeeded = await context.read<SessionsCubit>().revokeAllOthers();
    if (!succeeded && context.mounted) {
      context.showErrorSnackBar(context.l10n.sessions_SnackBar_revokeFailed);
    }
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    // A scrollable is required so pull-to-refresh keeps working while the list is empty.
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Center(child: Text(text)),
        ),
      ],
    );
  }
}

class _FailurePlaceholder extends StatelessWidget {
  const _FailurePlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(context.l10n.sessions_Placeholder_failure, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text(context.l10n.sessions_Button_retry)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}
