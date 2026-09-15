import 'dart:async';

import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.mapper.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import 'empty_mailbox_view.dart';
import 'failure_retry_view.dart';
import 'feature_not_supported_view.dart';
import 'voicemail_tile.dart';

/// The list of voicemails and everything it shows in place of one: the feature
/// being unavailable, the first load, an empty mailbox, a failed fetch.
///
/// Only the body, so a screen can put whatever header it belongs under above
/// it - the settings sub-screen its own, a section of the bottom menu the bar
/// every section carries.
class VoicemailBody extends StatelessWidget {
  const VoicemailBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoicemailCubit, VoicemailState>(
      listenWhen: (previous, current) => previous.visibleItems != current.visibleItems,
      listener: _stopPlaybackOfRemovedVoicemail,
      builder: (context, state) {
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
      },
    );
  }

  // The player is screen-scoped and not owned by the tiles, so when the active
  // voicemail leaves the list (deleted on this device or remotely, or simply
  // filtered out from under it) nothing else stops the audio.
  void _stopPlaybackOfRemovedVoicemail(BuildContext context, VoicemailState state) {
    final controller = context.read<VoicemailPlaybackController>();
    final activeId = controller.activeId;
    if (activeId != null && !state.visibleItems.any((it) => it.id == activeId)) {
      unawaited(controller.stop());
    }
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
      itemBuilder: (context, index) {
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
          forwardedByName: forwarderOf?.call(item),
          onToggleSeenStatus: (it) => cubit.toggleSeenStatus(it),
          onToggleSavedStatus: (it) => cubit.toggleSavedStatus(it),
          onForwarded: (it) => _onForwardVoicemail(context, it),
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
  /// asking and the way back is offered afterwards - a question before every
  /// delete trains people to dismiss it, and this one has nothing to warn
  /// about. Where there is no trash the same gesture is final, so it asks
  /// first and there is nothing to offer after.
  void _onDeleteVoicemail(BuildContext context, Voicemail voicemail) async {
    final cubit = context.read<VoicemailCubit>();

    if (!trashSupported) {
      final confirmed =
          (await ConfirmDialog.showDangerous(
            context,
            title: context.l10n.voicemail_Dialog_deleteSingleTitle,
            content: context.l10n.voicemail_Dialog_deleteSingleContent,
          )) ??
          false;

      if (confirmed) cubit.removeVoicemail(voicemail.id);
      return;
    }

    final l10n = context.l10n;
    final moved = await cubit.removeVoicemail(voicemail.id);
    if (!moved || !context.mounted) return;

    context.showSnackBar(
      l10n.voicemail_Snackbar_movedToTrash,
      action: SnackBarAction(label: l10n.voicemail_Label_undo, onPressed: () => cubit.restoreVoicemail(voicemail.id)),
    );
  }

  /// Opens the card of whoever left the message.
  ///
  /// The contact is looked up when it is asked for rather than carried on
  /// every message: the tile already knows that a contact exists, because it
  /// is showing that person's name, and what it does not have is the row's id.
  /// A lookup on an explicit action costs one query; carrying the id would
  /// cost a column and a mapping on every message ever listed.
  void _onOpenContact(BuildContext context, Voicemail voicemail) async {
    final l10n = context.l10n;
    final contact = await context.read<ContactsRepository>().getContactByPhoneNumber(voicemail.sender);
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
  /// chosen two sections away, and by the time the backend answers, this
  /// screen is long gone. Refused where somebody is already choosing for a
  /// call in hand - then the person stays where they are rather than being
  /// sent to a list that would be picking for something else.
  void _onForwardVoicemail(BuildContext context, Voicemail voicemail) {
    final contacts = context.read<FeatureAccess>().bottomMenuConfig.getTabEnabled<ContactsBottomMenuTab>();
    if (contacts == null) return;

    final l10n = context.l10n;
    final picking = context.read<DestinationPickingCubit>();
    final forwarding = VoicemailForwarding(
      repository: context.read<VoicemailRepository>(),
      picking: picking,
      l10n: l10n,
    );

    final asked = picking.ask(
      ForwardVoicemailPurpose(
        announcement: l10n.voicemail_Label_forwardChoosing,
        pickLabel: l10n.voicemail_SemanticsLabel_forwardTo,
        messageId: voicemail.id,
        onPicked: (recipient) => forwarding.send(voicemail, recipient),
      ),
    );
    if (!asked) return;

    context.router.navigate(MainScreenPageRoute(children: [contactsRouteOf(contacts)]));
  }

  void _onDeletePermanently(BuildContext context, Voicemail voicemail) async {
    final cubit = context.read<VoicemailCubit>();

    final confirmed =
        (await ConfirmDialog.showDangerous(
          context,
          title: context.l10n.voicemail_Dialog_deletePermanentlyTitle,
          content: context.l10n.voicemail_Dialog_deletePermanentlyContent,
        )) ??
        false;

    if (confirmed) cubit.removeVoicemailPermanently(voicemail.id);
  }
}
