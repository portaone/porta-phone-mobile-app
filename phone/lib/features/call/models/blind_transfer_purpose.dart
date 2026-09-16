import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/models.dart';

import '../controllers/call_controller.dart';

/// Handing a call that is already up to somebody else.
///
/// The first purpose, and for a long time the only one, which is why the lists
/// used to carry its rules themselves. Anything a number can be dialled from
/// will do, because that is all a transfer needs.
class BlindTransferPurpose extends Equatable implements DestinationPickPurpose {
  const BlindTransferPurpose({
    required this.announcement,
    required String Function(String destination) pickLabel,
    required CallController controller,
  }) : _pickLabel = pickLabel,
       _controller = controller;

  @override
  final String announcement;

  final String Function(String destination) _pickLabel;

  final CallController _controller;

  @override
  bool offeredBy(MainFlavor flavor) => switch (flavor) {
    MainFlavor.favorites || MainFlavor.recents || MainFlavor.contacts || MainFlavor.keypad => true,
    // A conversation, an embedded page and a list of voice messages have
    // nobody to hand a call to: the person who left a message is a number the
    // call history already offers.
    MainFlavor.messaging || MainFlavor.embedded || MainFlavor.voicemail => false,
  };

  @override
  bool accepts(DestinationCandidate candidate) => candidate.number != null;

  /// Somebody is holding a line while this destination is being chosen, so
  /// nothing that can wait takes the floor from it.
  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.live;

  /// The call owns this mode, not the mechanism: the REFER may be refused, and
  /// then the call is still looking for a target. Whoever owns it takes the
  /// request back - see [BlindTransferPicking].
  @override
  bool get closedByChoice => false;

  /// The way out is the call itself: going back to it drops the transfer, and
  /// a second way to abandon it on the banner would be a second thing to keep
  /// in step with the call's own state.
  @override
  bool get cancellable => false;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => _pickLabel(candidate.number ?? '');

  @override
  void submit(DestinationCandidate candidate) => _controller.submitTransfer(candidate.number!);

  // Value equality, because the scope above the lists rebuilds with the shell
  // and a purpose that differed by identity alone would rebuild every list on
  // every frame.
  @override
  List<Object?> get props => [announcement, _controller];
}
