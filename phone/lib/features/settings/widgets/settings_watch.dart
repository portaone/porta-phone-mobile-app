import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/features/call_routing/cubit/call_routing_cubit.dart';
import 'package:webtrit_phone/features/register_status/register_status.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/features/user_info/user_info.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../settings.dart';
import 'register_status_list_tile.dart';
import 'unread_voicemail_count_builder.dart';

/// Settings on a watch: one list under the account's name - the number and
/// the balance under it - then the connection, Online, Sessions, the brand's
/// sections with their titles as small labels and each item a row naming its
/// value where the app holds one, and Log out last, in red.
///
/// The log console is not offered: a face has no room to read a log on.
/// Pull to refresh is not there either; the cubits keep the account fresh.
class SettingsWatchList extends StatelessWidget {
  const SettingsWatchList({
    super.key,
    required this.sections,
    required this.sessionsEnabled,
    required this.onDiagnostic,
    required this.onSessions,
    required this.onRegisterChanged,
    required this.onItem,
    required this.onLogout,
  });

  final List<SettingsSection> sections;
  final bool sessionsEnabled;

  /// Opens Diagnostics: from the connection row, and from Online while the
  /// server cannot be reached, which is where the reason is.
  final VoidCallback onDiagnostic;
  final VoidCallback onSessions;
  final ValueChanged<bool> onRegisterChanged;
  final ValueChanged<SettingItem> onItem;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeData = Theme.of(context);
    final info = context.watch<UserInfoCubit>().state.userInfo;
    final busy = context.select<SettingsBloc, bool>((bloc) => bloc.state.progress);
    // Formatted as the phone's header has it: an extension-only account still
    // shows its extension, and a blank main number is no number at all.
    final number = info != null && info.hasAnyPhoneNumber ? info.formatPhoneNumber(context) : null;
    final balance = info?.balanceWithCurrency;
    final name = info?.name;

    final list = WatchScrollList(
      title: name ?? number ?? l10n.settings_AppBarTitle_myAccount,
      spacing: context.adaptiveMetrics.gap,
      children: [
        // The number and the balance under the name, as the phone's header
        // has them; the name alone heads the list when it is the number.
        if ([if (name != null) ?number, if (balance?.isNotEmpty == true) balance] case final parts
            when parts.isNotEmpty)
          Text(
            parts.join(' \u00B7 '),
            // Read out as a pause, not as the dot drawn between them.
            semanticsLabel: parts.join(', '),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: themeData.textTheme.labelSmall?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
          ),
        _ConnectionRow(onTap: onDiagnostic),
        _OnlineChip(onChanged: onRegisterChanged, onUnavailable: onDiagnostic),
        if (sessionsEnabled) _SessionsRow(onTap: onSessions),
        // A section whose rows all hide themselves (Caller ID without extra
        // numbers, Call center for somebody who is no agent) keeps its label,
        // as the phone does; one holding only the log console, which the
        // phone does show, has nothing on a watch and goes.
        for (final section in sections)
          if (section.items.any((item) => item.flavor != SettingsFlavor.log)) ...[
            WatchListLabel(context.parseL10n(section.titleL10n)),
            // Hidden rows are left out of the list rather than drawn empty:
            // the list puts its gap between every two children, so an empty
            // one would leave a double gap.
            for (final item in section.items)
              if (_isShown(context, item)) _ItemRow(item: item, onTap: () => onItem(item)),
          ],
        WatchListTile(
          // The Patrol logout subsequence taps this key.
          key: settingsLogoutButtonKey,
          identifier: settingsLogoutButtonId,
          leading: Icon(Icons.logout, color: themeData.colorScheme.error),
          title: l10n.settings_ListViewTileTitle_logout,
          onTap: busy ? null : onLogout,
        ),
      ],
    );

    // The list keeps its place in the tree whether or not the spinner is
    // over it, or it would be built anew - scrolled back to the top - each
    // time a logout or a deletion starts and fails.
    return Stack(
      children: [
        AbsorbPointer(absorbing: busy, child: list),
        if (busy) Center(child: WatchSpinner(label: l10n.common_SemanticsLabel_loading)),
      ],
    );
  }

  /// Whether the row of [item] is shown: the log console never on a watch,
  /// the rest where the phone shows them.
  static bool _isShown(BuildContext context, SettingItem item) => switch (item.flavor) {
    SettingsFlavor.log => false,
    SettingsFlavor.callerId => context.select<CallRoutingCubit, bool>(
      (cubit) => cubit.state?.additionalNumbers.isNotEmpty ?? false,
    ),
    SettingsFlavor.presence => PresenceViewParams.of(context).hybridPresenceSupport,
    SettingsFlavor.callCenter => context.select<CallQueuesCubit, bool>((cubit) => cubit.state.isAgent),
    _ => true,
  };
}

/// The connection's state as a row with its dot: the phone's words, the
/// issue in place of the subtitle when there is one. A tap opens Diagnostics.
class _ConnectionRow extends StatelessWidget {
  const _ConnectionRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionStatusCubit>().state;
    final registered = context.select<RegisterStatusCubit, bool>((cubit) => cubit.state.value);
    final updating = context.select<RegisterStatusCubit, bool>((cubit) => cubit.state.isUpdating);
    final status = session.status;

    return WatchListTile(
      identifier: sessionStatusTileId,
      leading: Icon(Icons.circle, size: 10, color: status.color(context)),
      title: status.l10n(context),
      subtitle:
          session.topIssue?.caption(context) ??
          status.subtitleL10n(context, registered: registered, updating: updating),
      onTap: onTap,
    );
  }
}

/// Online as a toggle pill, saying what it means under it. While the server
/// cannot be reached it says so and a tap opens Diagnostics, where the
/// reason is; while it changes, it says "Updating...".
class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.onChanged, required this.onUnavailable});

  final ValueChanged<bool> onChanged;
  final VoidCallback onUnavailable;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final register = context.watch<RegisterStatusCubit>().state;
    final session = context.select<SessionStatusCubit, SessionStatus>((cubit) => cubit.state.status);
    final available = session.mayReachServer;

    return Opacity(
      opacity: available ? 1 : 0.45,
      child: WatchToggleChip(
        identifier: registerStatusSwitchId,
        label: l10n.settings_ListViewTileTitle_registered,
        subtitle: registerStatusSubtitle(context, sessionStatus: session, registerStatus: register),
        value: register.value,
        onChanged: switch ((register.isUpdating, available)) {
          (true, _) => null,
          (false, true) => onChanged,
          (false, false) => (_) => onUnavailable(),
        },
      ),
    );
  }
}

class _SessionsRow extends StatelessWidget {
  const _SessionsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = context.select<SessionsCubit, int>((cubit) => cubit.state.sessions.length);
    final title = context.l10n.settings_ListViewTileTitle_sessions;
    return WatchListTile(
      leading: const Icon(Icons.devices),
      title: title,
      semanticsLabel: count > 0 ? '$title, ${context.l10n.common_SemanticsValue_totalCount(count)}' : null,
      trailing: count > 0 ? CountBadge(count: count) : null,
      onTap: onTap,
    );
  }
}

/// One item of a brand's section, with its value or count where the app holds
/// one; whether it is shown at all is the list's call.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onTap});

  final SettingItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final title = context.parseL10n(item.titleL10n);
    _ItemTile row({String? subtitle, Widget? trailing, String? semanticsLabel}) => _ItemTile(
      item: item,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      semanticsLabel: semanticsLabel,
      onTap: onTap,
    );

    switch (item.flavor) {
      case SettingsFlavor.callCenter:
        final queues = context.select<CallQueuesCubit, CallQueuesState>((cubit) => cubit.state);
        return row(subtitle: l10n.callCenter_Text_loggedInOfTotal(queues.loggedInCount, queues.queues.length));
      case SettingsFlavor.voicemail:
        return UnreadVoicemailCountBuilder(
          builder: (context, unread) => row(
            trailing: unread > 0 ? CountBadge(count: unread) : null,
            semanticsLabel: unread > 0 ? '$title, ${l10n.common_SemanticsValue_unreadCount(unread)}' : null,
          ),
        );
      case SettingsFlavor.language:
        final locale = context.select<AppBloc, Locale?>((bloc) => bloc.state.locale);
        return row(subtitle: (locale ?? LocaleExtension.defaultNull).l10n(context));
      case SettingsFlavor.themeMode:
        final mode = context.select<AppBloc, ThemeMode>((bloc) => bloc.state.themeMode);
        return row(subtitle: context.watch<ThemeSettings>().effectiveThemeMode(mode).l10n(context));
      default:
        return row();
    }
  }
}

/// The row of a brand's item, with what its kind shows beside the name.
class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.semanticsLabel,
  });

  final SettingItem item;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return WatchListTile(
      identifier: switch (item.flavor) {
        SettingsFlavor.about => settingsAboutTileId,
        SettingsFlavor.mediaSettings => settingsMediaTileId,
        _ => null,
      },
      leading: Icon(
        item.icon,
        color:
            item.iconColor ??
            (item.flavor == SettingsFlavor.deleteAccount ? Theme.of(context).colorScheme.error : null),
      ),
      title: title,
      subtitle: subtitle,
      semanticsLabel: semanticsLabel,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
