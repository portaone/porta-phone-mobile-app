import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_bloc.dart';
import '../controllers/call_controller.dart';
import '../controllers/call_controller_scope.dart';

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

  /// The purpose while a call is being handed over, and null when none is -
  /// which is how the shell asks this feature whether it wants somebody
  /// chosen, without knowing what a transfer is.
  static BlindTransferPurpose? maybeOf(BuildContext context) {
    final handingOver = context.select<CallBloc, bool>((bloc) => bloc.state.isBlingTransferInitiated);
    if (!handingOver) return null;

    return BlindTransferPurpose(
      announcement: context.l10n.main_Text_blindTransferInitiated,
      pickLabel: context.l10n.contact_SemanticsLabel_transfer,
      controller: CallControllerScope.of(context),
    );
  }

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

  /// Nothing: the way out of handing a call over is to go back to the call,
  /// and the floating call thumbnail is on screen the whole time offering
  /// exactly that.
  @override
  VoidCallback? get onCancel => null;

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
