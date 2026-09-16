import 'package:flutter/widgets.dart';

import 'package:webtrit_phone/app/keys.dart';

import 'contact_phone_tile.dart';

class ContactPhoneTileAdapter extends StatelessWidget {
  const ContactPhoneTileAdapter({
    super.key,
    required this.number,
    required this.displayLabel,
    required this.favorite,
    required this.callNumbers,
    this.index = 0,
    required this.isSmsEnabled,
    required this.isMessageEnabled,
    required this.enableTileFavorite,
    required this.enableTileVoiceCall,
    required this.enableTileVideoCall,
    required this.enableTileTransfer,
    required this.enableTileCallLog,
    required this.hasActiveCall,
    required this.isPickingDestination,
    required this.onPickPressed,
    required this.pickLabel,
    required this.onFavoriteChanged,
    required this.onAudioPressed,
    required this.onVideoPressed,
    required this.onTransferPressed,
    required this.onSmsPressed,
    required this.onCallLogPressed,
    required this.onMessagePressed,
    required this.onCallFromPressed,
  });

  final String number;

  /// Label shown in the tile; may be a merged string (e.g. "number / sms")
  /// when multiple phones share the same number.
  final String displayLabel;

  final bool favorite;
  final List<String> callNumbers;

  /// Position of the number on the card; see [ContactPhoneTile.index].
  final int index;

  /// Whether this number is eligible for SMS (pre-computed by the caller).
  final bool isSmsEnabled;

  /// Whether the contact supports in-app messaging (pre-computed by the caller).
  final bool isMessageEnabled;

  final bool enableTileFavorite;
  final bool enableTileVoiceCall;
  final bool enableTileVideoCall;
  final bool enableTileTransfer;
  final bool enableTileCallLog;
  final bool hasActiveCall;

  /// Whether a choice is being made at all, which is not the same as this row
  /// being an answer to it.
  ///
  /// While one is, the row stops offering to call, to start a video call and
  /// to hand a call over - those act on a number the person is not here to
  /// act on - whether or not this particular number can be chosen.
  final bool isPickingDestination;

  /// Offers this number as the answer, and is null when the purpose will not
  /// take it. A number it refuses leaves the row visible and inert.
  final VoidCallback? onPickPressed;

  /// What that offer is called, which belongs to whatever is asking.
  final String? pickLabel;

  final void Function(bool) onFavoriteChanged;
  final VoidCallback onAudioPressed;
  final VoidCallback onVideoPressed;
  final VoidCallback onTransferPressed;
  final VoidCallback onSmsPressed;
  final VoidCallback onCallLogPressed;
  final VoidCallback onMessagePressed;
  final void Function(String fromNumber) onCallFromPressed;

  @override
  Widget build(BuildContext context) {
    // While a choice is being made the ordinary actions are withdrawn, the way
    // the lists withdraw theirs. Left in place they offer to call somebody the
    // person came here to choose, and on a row the purpose refuses they were
    // the only thing on offer - which is how a refused row still ended up
    // acting.
    final picking = isPickingDestination;
    final favoriteCallback = enableTileFavorite ? onFavoriteChanged : null;
    final audioCallback = !picking && enableTileVoiceCall ? onAudioPressed : null;
    final videoCallback = !picking && enableTileVideoCall ? onVideoPressed : null;
    final transferCallback = !picking && enableTileTransfer && hasActiveCall ? onTransferPressed : null;
    // Not gated on the transfer configuration: that is permission to hand a
    // call over, not permission to answer whatever is being asked.
    final pickCallback = onPickPressed;
    final smsCallback = isSmsEnabled ? onSmsPressed : null;
    final messageCallback = isMessageEnabled ? onMessagePressed : null;
    final callLogCallback = enableTileCallLog ? onCallLogPressed : null;

    return SizedBox(
      key: ValueKey(number),
      child: ContactPhoneTile(
        key: contactPhoneTileKey,
        number: number,
        label: displayLabel,
        index: index,
        favorite: favorite,
        callNumbers: callNumbers,
        onFavoriteChanged: favoriteCallback,
        onAudioPressed: audioCallback,
        onVideoPressed: videoCallback,
        onTransferPressed: transferCallback,
        onPickPressed: pickCallback,
        pickLabel: pickLabel,
        onSendSmsPressed: smsCallback,
        onMessagePressed: messageCallback,
        onCallLogPressed: callLogCallback,
        onCallFrom: onCallFromPressed,
      ),
    );
  }
}
