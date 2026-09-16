import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/call_routing/cubit/call_routing_cubit.dart';
import 'package:webtrit_phone/features/messaging/extensions/contact.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'contact_tile.dart';

/// Wires a contacts-list [ContactTile] to the call/chat/history actions so the
/// local and external tabs share one behavior: tap expands the quick-actions
/// bar, the trailing phone icon dials, and while somebody is being chosen the
/// row stops doing either and becomes the choice itself (same semantics as the
/// recents and favorites lists).
class ContactTileAdapter extends StatelessWidget {
  const ContactTileAdapter({
    super.key,
    required this.contact,
    required this.expanded,
    required this.onToggleExpanded,
    this.tileKey,
    this.markFavorite = false,
  });

  final Contact contact;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final Key? tileKey;

  /// Whether a favourite among this contact's numbers is marked in the row.
  final bool markFavorite;

  @override
  Widget build(BuildContext context) {
    final callController = CallControllerScope.of(context);
    final featureAccess = context.read<FeatureAccess>();

    final transferEnabled = featureAccess.callConfig.capabilities.isBlindTransferEnabled;
    final videoEnabled = featureAccess.callConfig.capabilities.isVideoCallEnabled;
    final chatsEnabled = featureAccess.messagingConfig.chatsPresent;
    final cdrsEnabled = featureAccess.bottomMenuConfig.getTabEnabled<RecentsBottomMenuTab>()?.supportsCallHistory;

    final number =
        contact.extension ?? contact.mobileNumber ?? (contact.phones.isNotEmpty ? contact.phones.first.number : null);

    void openCallLog(String number) {
      if (cdrsEnabled == true) {
        context.router.navigate(NumberCdrsScreenPageRoute(number: number));
      } else {
        context.router.navigate(CallLogScreenPageRoute(number: number));
      }
    }

    // Whoever is asking, and whether this row is an answer. Both are needed
    // and they are not the same: while a choice is being made no row does what
    // it normally does, but only a row the purpose accepts can be chosen.
    final purpose = context.pickPurpose;
    final candidate = DestinationCandidate(number: number, contact: contact);
    final picks = purpose != null && purpose.accepts(candidate);
    final pick = purpose == null
        ? null
        : TilePick(
            icon: purpose.pickIcon,
            label: purpose.pickLabel(candidate),
            onPressed: picks ? () => pickDestination(context, purpose, candidate) : null,
          );

    return BlocBuilder<CallBloc, CallState>(
      buildWhen: (previous, current) => previous.activeCalls != current.activeCalls,
      builder: (context, callState) {
        final hasActiveCall = callState.activeCalls.isNotEmpty;

        return BlocBuilder<CallRoutingCubit, CallRoutingState?>(
          builder: (context, callRoutingState) {
            return ContactTile(
              key: tileKey,
              markFavorite: markFavorite,
              favorite: contact.isFavorite,
              displayName: contact.displayTitle,
              thumbnail: contact.thumbnail,
              thumbnailUrl: contact.thumbnailUrl,
              registered: contact.registered,
              presenceInfo: contact.presenceInfo,
              dialogInfo: contact.dialogInfo,
              pick: pick,
              onTap: purpose != null
                  ? (picks ? () => pickDestination(context, purpose, candidate) : null)
                  : onToggleExpanded,
              expanded: expanded && purpose == null,
              onDialPressed: purpose == null && number != null
                  ? () => callController.createCall(destination: number, displayName: contact.maybeName, video: false)
                  : null,
              callNumbers: callRoutingState?.allNumbers ?? [],
              onAudioCallPressed: number != null
                  ? () => callController.createCall(destination: number, displayName: contact.maybeName, video: false)
                  : null,
              onVideoCallPressed: number != null && videoEnabled
                  ? () => callController.createCall(destination: number, displayName: contact.maybeName, video: true)
                  : null,
              // Not part of choosing: this sits in the overflow menu whenever
              // a call is up, and starts the hand-off rather than finishing
              // one.
              onTransferPressed: number != null && transferEnabled && hasActiveCall
                  ? () {
                      callController.submitTransfer(number);
                      context.router.maybePop();
                    }
                  : null,
              onChatPressed: chatsEnabled && contact.canMessage
                  ? () => context.router.navigate(ChatConversationScreenPageRoute(participantId: contact.sourceId!))
                  : null,
              onViewContactPressed: () => context.router.navigate(ContactScreenPageRoute(contactId: contact.id)),
              onCallLogPressed: number != null ? () => openCallLog(number) : null,
              onCallFrom: number != null
                  ? (fromNumber) => callController.createCall(
                      destination: number,
                      displayName: contact.maybeName,
                      fromNumber: fromNumber,
                      video: false,
                    )
                  : null,
              copyNumber: number,
            );
          },
        );
      },
    );
  }
}
