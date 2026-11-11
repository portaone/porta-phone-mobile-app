import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/keypad/keypad.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';
import '../cubits/cubits.dart';
import '../extensions/extensions.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'circle_indicator.dart';
import 'empty_mailbox_view.dart';
import 'voicemail_body.dart';
import 'voicemail_delete.dart';
import 'voicemail_filter_row.dart';
import 'voicemail_view_builder.dart';

/// The body of voicemail on a watch: the list under [title], drawing the whole
/// face, kept up by the same listeners as the phone's list.
class VoicemailWatchBody extends StatelessWidget {
  const VoicemailWatchBody({super.key, required this.title});

  /// The name heading the list.
  final String title;

  @override
  Widget build(BuildContext context) {
    return VoicemailListScope(
      child: VoicemailViewBuilder(
        builder: (context, view) => VoicemailWatchList(title: title, view: view),
      ),
    );
  }
}

/// The voicemail list on a watch: the section's title, the filter as one
/// pill whose tap shows the next filter, the bar under it, and a row per
/// message - who left it, how long it is and when, a dot while it is new. A
/// tap opens the message's page, where it is played.
///
/// Not supported, on its way, failed and empty are the watch's state pages;
/// an empty or failed filter keeps the pill under its state, so another
/// filter is a tap away. Picking several, forwarding and opening the contact
/// stay on the phone.
class VoicemailWatchList extends StatelessWidget {
  const VoicemailWatchList({super.key, required this.title, required this.view});

  final String title;
  final VoicemailView view;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<VoicemailCubit>();
    final section = WatchSection(
      title: title,
      options: view.filters,
      selected: view.filter,
      onSelected: cubit.setFilter,
    );
    final chip = [if (section.choosable) VoicemailWatchFilterChip(section: section)];

    if (view.isFeatureNotSupported) {
      return WatchStatePage(
        title: title,
        icon: const Icon(Icons.info_outline),
        message: l10n.voicemail_Title_notSupported,
      );
    }
    if (view.isInitializing) {
      return WatchStatePage.loading(title: title, progressLabel: l10n.common_SemanticsLabel_loading);
    }
    if (view.isLoadedWithError) {
      return WatchStatePage(
        title: title,
        icon: const Icon(Icons.error_outline),
        message: l10n.webview_defaultError_title,
        footer: chip,
        action: WatchAction(
          label: l10n.voicemail_Label_retry,
          identifier: voicemailWatchRetryId,
          onPressed: cubit.refresh,
        ),
      );
    }
    if (!view.isVoicemailsExists) {
      return WatchStatePage(
        title: title,
        icon: const Icon(Icons.voicemail),
        message: view.filter.emptyLabel(context),
        // The Saved hint points at the phone's menu, which a watch has not.
        hint: view.isShowingTrash ? l10n.voicemail_Label_emptyTrashHint : null,
        footer: chip,
        // Where a phone pulls to refresh, as the other lists on a watch.
        action: WatchAction(
          label: l10n.common_SemanticsLabel_refresh,
          identifier: voicemailWatchRefreshId,
          onPressed: cubit.refresh,
        ),
      );
    }

    final items = view.visibleItems;
    // The trash closes with what the phone says under it: a message there
    // still takes room in the mailbox.
    final footnote = view.isShowingTrash ? 1 : 0;
    return WatchScrollList.builder(
      title: title,
      header: [
        if (chip.isNotEmpty) ...[...chip, const WatchSeparator()],
      ],
      spacing: context.adaptiveMetrics.gap,
      itemCount: items.length + footnote,
      itemBuilder: (context, index) {
        if (index == items.length) return WatchListNote(l10n.voicemail_Label_trashFootnote);
        final voicemail = items[index];
        return VoicemailWatchTile(
          key: ValueKey(voicemail.id),
          voicemail: voicemail,
          onTap: () => openVoicemailWatchPage(context, voicemail),
        );
      },
    );
  }
}

/// The filter of the voicemail list on a watch: one pill naming the filter
/// shown; a tap moves to the next one.
class VoicemailWatchFilterChip extends StatelessWidget {
  const VoicemailWatchFilterChip({super.key, required this.section});

  final WatchSection<VoicemailFilter> section;

  @override
  Widget build(BuildContext context) {
    final label = section.selected.label(context);
    return WatchPillButton(
      buttonKey: voicemailWatchFilterKey,
      identifier: voicemailWatchFilterId,
      icon: Icons.filter_list,
      label: label,
      semanticsLabel: context.l10n.voicemail_SemanticsLabel_filter(label),
      onPressed: () => section.onSelected(section.next),
    );
  }
}

/// One message in the voicemail list on a watch: who left it, how long it is
/// and when; a dot while it is new, "New" in its name for a screen reader.
class VoicemailWatchTile extends StatelessWidget {
  const VoicemailWatchTile({super.key, required this.voicemail, required this.onTap});

  final Voicemail voicemail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = voicemail.senderName(context);
    final when = context
        .read<AppTime>()
        .timeOrDateFormat(Localizations.localeOf(context))
        .format(DateTime.parse(voicemail.date).toLocal());
    final length = voicemail.length;
    final unheard = voicemail.status.isUnread;

    return WatchListTile(
      title: name,
      subtitle: [if (length != null) drawnDuration(length), when].join(' \u00B7 '),
      // Read out, `0:42` is a time of day, and the dot is for the eye.
      semanticsLabel: [
        name,
        if (unheard) l10n.voicemail_Filter_unheard,
        if (length != null) spokenDuration(l10n, length),
        when,
      ].join(', '),
      leading: LeadingAvatar(username: name, radius: 12),
      trailing: unheard ? CircleIndicator(color: Theme.of(context).colorScheme.tertiary) : null,
      onTap: onTap,
    );
  }
}

/// Opens the page of [voicemail] over the list, with what the list's screen
/// holds: the page is a route of its own, which need not be under them.
void openVoicemailWatchPage(BuildContext context, Voicemail voicemail) {
  final cubit = context.read<VoicemailCubit>();
  final session = context.read<VoicemailSessionCubit>();
  final controller = context.read<VoicemailPlaybackController>();
  final screenContext = context.read<VoicemailScreenContext>();
  final appTime = context.read<AppTime>();

  unawaited(
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            BlocProvider<VoicemailCubit>.value(value: cubit),
            BlocProvider<VoicemailSessionCubit>.value(value: session),
            ChangeNotifierProvider<VoicemailPlaybackController>.value(value: controller),
            Provider<VoicemailScreenContext>.value(value: screenContext),
            Provider<AppTime>.value(value: appTime),
          ],
          child: VoicemailWatchPage(id: voicemail.id),
        ),
      ),
    ),
  );
}

/// One message on a watch, as a call has its page: who left it and when, the
/// player, what can be done with it as rows - heard or new, saved, deleted;
/// in the trash restored or deleted for good - and Call back on the edge.
///
/// Closes once the message has left the list it was opened from: deleted,
/// restored, or no longer what the filter shows. Going back stops it playing,
/// for nothing on the list could.
class VoicemailWatchPage extends StatefulWidget {
  const VoicemailWatchPage({super.key, required this.id});

  final String id;

  @override
  State<VoicemailWatchPage> createState() => _VoicemailWatchPageState();
}

class _VoicemailWatchPageState extends State<VoicemailWatchPage> {
  late final _controller = context.read<VoicemailPlaybackController>();
  var _closing = false;

  /// Closes this page and nothing else. The delete confirm opens on the same
  /// navigator, so a pop of whatever is on top would close the question
  /// instead and leave this page blank under it, with no second try.
  void _close() {
    if (_closing) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final route = ModalRoute.of(context);
      if (route == null) return;
      final navigator = Navigator.of(context);
      if (route.isCurrent) {
        navigator.pop();
      } else {
        // Removed without a pop, so the back handler does not run: the body
        // under the list already stops a message that has left the list.
        navigator.removeRoute(route);
      }
    });
  }

  void _onPopInvoked(bool didPop, Object? _) {
    if (didPop && _controller.activeId == widget.id) unawaited(_controller.stop());
  }

  Widget _messageOrClose(BuildContext context, VoicemailView view) {
    final voicemail = view.visibleItems.where((item) => item.id == widget.id).firstOrNull;
    if (voicemail == null) {
      _close();
      return const SizedBox.shrink();
    }
    return VoicemailWatchMessage(view: view, voicemail: voicemail);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: _onPopInvoked,
      child: Scaffold(body: VoicemailViewBuilder(builder: _messageOrClose)),
    );
  }
}

/// What the page of one message on a watch shows: the name and the date, the
/// player, the rows of what can be done with it, and Call back on the edge.
class VoicemailWatchMessage extends StatelessWidget {
  const VoicemailWatchMessage({super.key, required this.view, required this.voicemail});

  final VoicemailView view;
  final Voicemail voicemail;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final l10n = context.l10n;
    final cubit = context.read<VoicemailCubit>();
    final appTime = context.read<AppTime>();
    final locale = Localizations.localeOf(context);
    final date = DateTime.parse(voicemail.date).toLocal();
    final time = appTime.is24HourFormat
        ? appTime.hourMinuteFormat(locale)
        : DateFormat.jm(Intl.canonicalizedLocale(locale.toString()));
    final error = themeData.colorScheme.error;

    final actions = view.isShowingTrash
        ? [
            WatchListTile(
              identifier: voicemailWatchRestoreId,
              leading: const Icon(Icons.restore_from_trash),
              title: l10n.voicemail_Label_restore,
              onTap: () => cubit.restoreVoicemail(voicemail.id),
            ),
            WatchListTile(
              identifier: voicemailWatchDeleteId,
              leading: Icon(Icons.delete_forever, color: error),
              title: l10n.voicemail_Label_deletePermanently,
              onTap: () => deleteVoicemailPermanently(context, voicemail),
            ),
          ]
        : [
            if (!voicemail.status.isUnknown)
              WatchListTile(
                identifier: voicemailWatchHeardId,
                leading: Icon(voicemail.status.isRead ? Icons.mark_email_unread_outlined : Icons.drafts_outlined),
                title: voicemail.status.toggleActionLabelL10n(context),
                onTap: () => cubit.toggleSeenStatus(voicemail),
              ),
            if (view.saveSupported && voicemail.saved != null)
              WatchListTile(
                identifier: voicemailWatchSaveId,
                leading: Icon(voicemail.saved! ? Icons.bookmark_remove : Icons.bookmark_add_outlined),
                title: voicemail.saved! ? l10n.voicemail_Label_unsave : l10n.voicemail_Label_save,
                onTap: () => cubit.toggleSavedStatus(voicemail),
              ),
            WatchListTile(
              identifier: voicemailWatchDeleteId,
              leading: Icon(Icons.delete_outline, color: error),
              // Named for what it does: with a trash the message can be had
              // back, without one it cannot.
              title: view.trashSupported ? l10n.voicemail_Label_moveToTrash : l10n.voicemail_Label_delete,
              onTap: () => deleteVoicemail(context, voicemail, trashSupported: view.trashSupported),
            ),
          ];

    // A message in the trash is on its way out: nobody calls back from there.
    final callBack = voicemail.hasSender && !view.isShowingTrash;

    return WatchScrollList.builder(
      title: voicemail.senderName(context),
      header: [
        Text(
          // The day and the time, no seconds and no year: the line has to fit
          // under the name on a face.
          '${appTime.weekdayDayMonthFormat(locale).format(date)}, ${time.format(date)}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: themeData.textTheme.labelSmall?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
        ),
      ],
      spacing: context.adaptiveMetrics.gap,
      itemCount: 1 + actions.length,
      itemBuilder: (context, index) => index == 0 ? VoicemailWatchPlayer(voicemail: voicemail) : actions[index - 1],
      edge: callBack
          ? (context, overlay) => WatchCallEdgeButton(
              overlay: overlay,
              buttonKey: voicemailWatchCallKey,
              identifier: voicemailWatchCallId,
              label: l10n.voicemail_Label_call,
              onPressed: () => cubit.startCall(voicemail),
            )
          : null,
    );
  }
}

/// The player of a message on a watch: one round button, the ring around it
/// filling as the message plays and the time under it. Playing a new message
/// is what marks it heard, as on the phone.
class VoicemailWatchPlayer extends StatelessWidget {
  const VoicemailWatchPlayer({super.key, required this.voicemail});

  final Voicemail voicemail;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<VoicemailPlaybackController>();
    final active = controller.activeId == voicemail.id;
    final listed = voicemail.length;
    final start = voicemail.url == null ? null : () => _start(context);

    if (active && controller.error != null) {
      return WatchPlayButton(
        buttonKey: voicemailWatchPlayKey,
        identifier: voicemailWatchPlayId,
        playing: false,
        label: l10n.voicemail_Label_retry,
        time: l10n.voicemail_Label_playbackError,
        // The line under the button is drawn for the eye only, so the failure
        // is said as the button's value or a screen reader hears just Retry.
        value: l10n.voicemail_Label_playbackError,
        onPressed: start,
      );
    }

    if (!active) {
      return WatchPlayButton(
        buttonKey: voicemailWatchPlayKey,
        identifier: voicemailWatchPlayId,
        playing: false,
        label: l10n.voicemail_SemanticsLabel_play,
        time: listed == null ? null : drawnDuration(listed),
        value: listed == null ? null : spokenDuration(l10n, listed),
        onPressed: start,
      );
    }

    return StreamBuilder<Duration>(
      stream: controller.player.positionStream,
      builder: (context, snapshot) {
        // Once the recording is loaded its own length is the true one.
        final length = controller.player.duration ?? listed;
        var position = snapshot.data ?? Duration.zero;
        if (length != null && position > length) position = length;
        final playing = controller.isPlaying;

        return WatchPlayButton(
          buttonKey: voicemailWatchPlayKey,
          identifier: voicemailWatchPlayId,
          playing: playing,
          loading: controller.isLoading,
          progress: length == null || length == Duration.zero ? 0 : position.inMilliseconds / length.inMilliseconds,
          label: playing ? l10n.voicemail_SemanticsLabel_pause : l10n.voicemail_SemanticsLabel_play,
          time: length == null ? drawnDuration(position) : '${drawnDuration(position)} / ${drawnDuration(length)}',
          value: length == null
              ? null
              : l10n.voicemail_SemanticsValue_playbackPosition(
                  spokenDuration(l10n, position),
                  spokenDuration(l10n, length),
                ),
          onPressed: () => _toggle(context, controller),
        );
      },
    );
  }

  void _start(BuildContext context) {
    final controller = context.read<VoicemailPlaybackController>();
    final screenContext = context.read<VoicemailScreenContext>();
    final url = voicemail.url!;
    unawaited(context.read<VoicemailCubit>().markHeardByListening(voicemail));
    unawaited(
      controller.play(
        id: voicemail.id,
        uri: Uri.parse(url),
        headers: screenContext.mediaHeaders,
        cacheBasePath: screenContext.mediaCacheBasePath,
        cacheKey: voicemail.id,
        isLocal: url.isLocalPath,
      ),
    );
  }

  void _toggle(BuildContext context, VoicemailPlaybackController controller) {
    // The controller plays the recording once it has loaded, so a press in
    // the meantime has nothing to start, and a pause would be undone by it.
    if (controller.isLoading) return;
    if (controller.isPlaying) {
      unawaited(controller.pause());
    } else {
      unawaited(context.read<VoicemailCubit>().markHeardByListening(voicemail));
      unawaited(controller.resume());
    }
  }
}
