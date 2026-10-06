import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.mapper.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';
import '../cubits/cubits.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'empty_mailbox_view.dart';
import 'failure_retry_view.dart';
import 'feature_not_supported_view.dart';
import 'voicemail_tile.dart';
import 'voicemail_view_builder.dart';

/// The list of voicemails and everything it shows in place of one: the feature
/// being unavailable, the first load, an empty mailbox, a failed fetch.
///
/// Only the body, so a screen can put whatever header it belongs under above
/// it - the settings sub-screen its own, a section of the bottom menu the bar
/// every section carries.
class VoicemailBody extends StatelessWidget {
  const VoicemailBody({super.key, required this.origin});

  /// The route of the screen this body is shown on. Voicemail is offered from
  /// two places, and a forward has to bring the person back to the one they
  /// started it from.
  final PageRouteInfo origin;

  @override
  Widget build(BuildContext context) {
    // What is on screen can change from either side - the mailbox or the
    // screen's own filter and trash - so both are listened to.
    return MultiBlocListener(
      listeners: [
        BlocListener<VoicemailSessionCubit, VoicemailSessionState>(
          listenWhen: (previous, current) => previous.items != current.items,
          listener: (context, _) => _stopPlaybackOfRemovedVoicemail(context),
        ),
        BlocListener<VoicemailCubit, VoicemailState>(
          listenWhen: (previous, current) =>
              previous.filter != current.filter || previous.trashedItems != current.trashedItems,
          listener: (context, _) => _stopPlaybackOfRemovedVoicemail(context),
        ),
      ],
      child: VoicemailViewBuilder(
        builder: (context, view) => _VoicemailList(state: view, origin: origin),
      ),
    );
  }

  // The player is screen-scoped and not owned by the tiles, so when the active
  // voicemail leaves the list (deleted on this device or remotely, or simply
  // filtered out from under it) nothing else stops the audio.
  void _stopPlaybackOfRemovedVoicemail(BuildContext context) {
    final controller = context.read<VoicemailPlaybackController>();
    final activeId = controller.activeId;
    final visibleItems = VoicemailView(
      mailbox: context.read<VoicemailSessionCubit>().state,
      screen: context.read<VoicemailCubit>().state,
    ).visibleItems;
    if (activeId != null && !visibleItems.any((it) => it.id == activeId)) {
      unawaited(controller.stop());
    }
  }
}

/// What stands where the list is: the list, or whatever is shown in place of
/// one.
class _VoicemailList extends StatelessWidget {
  const _VoicemailList({required this.state, required this.origin});

  final VoicemailView state;
  final PageRouteInfo origin;

  @override
  Widget build(BuildContext context) {
    if (state.isFeatureNotSupported) {
      return const FeatureNotSupportedView();
    }
    if (state.isInitializing) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.isLoadedWithError) {
      return FailureRetryView(onRetry: () => context.read<VoicemailCubit>().refresh());
    }

    return RefreshIndicator(
      // The bottom-menu section runs its body behind the bar, so without an
      // offset the spinner settles a bar's height out of sight and the pull
      // looks like it did nothing. A host that keeps its body below an app
      // bar hands this a top padding of zero, so the one figure serves both.
      edgeOffset: MediaQuery.of(context).padding.top,
      // A refresh means whichever list is on screen: the stored mailbox for
      // three of the filters, a fresh read of the trash for the fourth.
      onRefresh: () => context.read<VoicemailCubit>().refresh(),
      child: Stack(
        children: [
          if (state.isRefreshing) const LinearProgressIndicator(minHeight: 1),
          if (state.isVoicemailsExists)
            Column(
              children: [
                Expanded(
                  child: VoicemailListView(
                    items: state.visibleItems,
                    selectedVoicemailsIds: state.selectedVoicemailsIds,
                    isMultipleVoicemailsSelection: state.isMultipleVoicemailsSelection,
                    saveSupported: state.saveSupported,
                    trashSupported: state.trashSupported,
                    forwardSupported: state.forwardSupported,
                    inTrash: state.isShowingTrash,
                    forwarderOf: state.forwarderOf,
                    forwardOf: state.forwardOf,
                    origin: origin,
                  ),
                ),
                // The one thing about the trash a person cannot see by
                // looking at it: a message in here is still occupying the
                // mailbox, so leaving it here is not the same as deleting
                // it.
                if (state.filter == VoicemailFilter.trash) const _TrashFootnote(),
              ],
            )
          else
            EmptyMailboxView(filter: state.filter),
        ],
      ),
    );
  }
}

class _TrashFootnote extends StatelessWidget {
  const _TrashFootnote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Text(
        context.l10n.voicemail_Label_trashFootnote,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class VoicemailListView extends StatelessWidget {
  const VoicemailListView({
    super.key,
    required this.items,
    required this.selectedVoicemailsIds,
    required this.isMultipleVoicemailsSelection,
    required this.origin,
    this.forwardOf,
    this.saveSupported = false,
    this.trashSupported = false,
    this.forwardSupported = false,
    this.inTrash = false,
    this.forwarderOf,
  });

  final List<Voicemail> items;
  final List<String> selectedVoicemailsIds;
  final bool isMultipleVoicemailsSelection;
  final bool saveSupported;
  final bool trashSupported;
  final bool forwardSupported;
  final bool inTrash;

  /// Who passed a given message along, or null when nobody did.
  final String? Function(Voicemail)? forwarderOf;

  /// Where passing a given message on stands, or null when there is nothing
  /// to show about it.
  final VoicemailForward? Function(Voicemail)? forwardOf;

  /// Where a forward brings the person back to: the screen this list is on.
  final PageRouteInfo origin;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<VoicemailCubit>();
    final colorScheme = Theme.of(context).colorScheme;

    return ListView.separated(
      // A mailbox with a message or two has nothing to scroll, and a list that
      // cannot scroll swallows the drag instead of passing it to the refresh
      // indicator above it.
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(color: colorScheme.surfaceContainerHigh, height: 1),
      itemBuilder: (_, index) {
        final item = items[index];
        return VoicemailTile(
          voicemail: item,
          displayName: item.displaySender,
          selected: selectedVoicemailsIds.contains(item.id),
          onDeleted: (it) => _onDeleteVoicemail(context, it),
          saveSupported: saveSupported,
          trashSupported: trashSupported,
          forwardSupported: forwardSupported,
          inTrash: inTrash,
          forward: forwardOf?.call(item),
          forwardedByName: forwarderOf?.call(item),
          onToggleSeenStatus: (it) => cubit.toggleSeenStatus(it),
          onToggleSavedStatus: (it) => cubit.toggleSavedStatus(it),
          onForwarded: (it) => _onForwardVoicemail(context, it),
          onForwardRetried: (it, recipient) => _forwarding(context).send(it, recipient),
          onOpenContact: (it) => _onOpenContact(context, it),
          onRestored: (it) => cubit.restoreVoicemail(it.id),
          onDeletedPermanently: (it) => _onDeletePermanently(context, it),
          onCall: (it) => cubit.startCall(it),
          onLongPress: (it) => cubit.toggleSelection(it),
          onTap: isMultipleVoicemailsSelection ? (it) => cubit.toggleSelection(it) : null,
        );
      },
    );
  }

  /// Deleting a message, which is two different things.
  ///
  /// Where there is a trash the message can be had back, so it goes without
  /// asking - a question before every delete trains people to dismiss it, and
  /// this one has nothing to warn about. Where there is no trash the same
  /// gesture is final, so it asks first. What is said afterwards, and whether
  /// the way back is offered, belongs to the mailbox rather than to this row.
  void _onDeleteVoicemail(BuildContext context, Voicemail voicemail) async {
    final cubit = context.read<VoicemailCubit>();

    if (trashSupported) return cubit.removeVoicemail(voicemail.id);

    final confirmed =
        (await ConfirmDialog.showDangerous(
          context,
          title: context.l10n.voicemail_Dialog_deleteSingleTitle,
          content: context.l10n.voicemail_Dialog_deleteSingleContent,
        )) ??
        false;

    if (!confirmed) return;

    await cubit.removeVoicemail(voicemail.id);
  }

  /// Opens the card of whoever left the message.
  ///
  /// Who that is belongs to the mailbox, which knows the number and can ask
  /// the address book; this only decides where the person lands.
  void _onOpenContact(BuildContext context, Voicemail voicemail) async {
    final l10n = context.l10n;
    final contact = await context.read<VoicemailCubit>().callerOf(voicemail);
    if (!context.mounted) return;

    // The address book can have moved on since the list was drawn - a contact
    // deleted on another device, a sync that dropped them.
    if (contact == null) {
      context.showSnackBar(l10n.voicemail_Snackbar_contactGone);
      return;
    }

    context.router.navigate(ContactScreenPageRoute(contactId: contact.id));
  }

  /// Sends the person to the address book to choose a colleague.
  ///
  /// The request outlives this screen, which is the point: the colleague is
  /// chosen two sections away, and reached from settings this screen is torn
  /// down on the way there. The choice brings the person back to [origin],
  /// where the message shows that it is being forwarded, and afterwards
  /// carries a mark if that did not go through. Refused where somebody is
  /// already choosing for a call in hand - then the person stays where they
  /// are rather than being sent to a list that would be picking for something
  /// else.
  void _onForwardVoicemail(BuildContext context, Voicemail voicemail) {
    final contacts = context.read<FeatureAccess>().bottomMenuConfig.getTabEnabled<ContactsBottomMenuTab>();
    if (contacts == null) return;

    final l10n = context.l10n;
    final picking = context.read<DestinationPickingCubit>();
    final forwarding = _forwarding(context);

    final asked = picking.ask(
      ForwardVoicemailPurpose(
        announcement: l10n.voicemail_Label_forwardChoosing,
        pickLabel: l10n.voicemail_SemanticsLabel_forwardTo,
        messageId: voicemail.id,
        origin: origin,
        onPicked: (recipient) => forwarding.send(voicemail, recipient),
      ),
    );
    if (!asked) return;

    context.router.navigate(MainScreenPageRoute(children: [contactsRouteOf(contacts)]));
  }

  /// What sends a message on. Built where the person asks - for a first try or
  /// for another - because the sentences about how a forward went have to be
  /// resolved while there is still a context to resolve them against.
  VoicemailForwarding _forwarding(BuildContext context) => VoicemailForwarding(
    picking: context.read<DestinationPickingCubit>(),
    session: context.read<VoicemailSessionCubit>(),
    l10n: context.l10n,
  );

  void _onDeletePermanently(BuildContext context, Voicemail voicemail) async {
    final cubit = context.read<VoicemailCubit>();

    final confirmed =
        (await ConfirmDialog.showDangerous(
          context,
          title: context.l10n.voicemail_Dialog_deletePermanentlyTitle,
          content: context.l10n.voicemail_Dialog_deletePermanentlyContent,
        )) ??
        false;

    if (!confirmed) return;

    await cubit.removeVoicemailPermanently(voicemail.id);
  }
}
