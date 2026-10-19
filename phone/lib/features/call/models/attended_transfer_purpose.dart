import 'package:material_ui/material_ui.dart';

import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/models.dart';

import '../controllers/call_controller.dart';

/// Choosing whom to consult before handing the call [anchorCallId] over to
/// them: the attended transfer's first step.
///
/// Anything a number can be dialled from will do, as for the blind transfer.
/// Unlike that one, nothing has happened to the call yet while the person
/// chooses - it is held only once the consultation call is placed - so the
/// request is the person's own to give up, and the choice ends it.
class AttendedTransferPurpose extends Equatable implements DestinationPickPurpose {
  const AttendedTransferPurpose({
    required this.announcement,
    required String Function(String number) pickLabel,
    required CallController controller,
    required this.anchorCallId,
  }) : _pickLabel = pickLabel,
       _controller = controller;

  @override
  final String announcement;

  /// The call that will be handed over after the consultation.
  final String anchorCallId;

  final String Function(String number) _pickLabel;

  final CallController _controller;

  @override
  bool offeredBy(MainFlavor flavor) => switch (flavor) {
    MainFlavor.favorites || MainFlavor.recents || MainFlavor.contacts || MainFlavor.keypad => true,
    MainFlavor.messaging || MainFlavor.embedded || MainFlavor.voicemail || MainFlavor.callCenter => false,
  };

  @override
  bool accepts(DestinationCandidate candidate) => candidate.number != null;

  /// Somebody is on the line while this is being chosen, as for a transfer.
  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.live;

  @override
  bool get closedByChoice => true;

  @override
  bool get cancellable => true;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => _pickLabel(candidate.number ?? '');

  @override
  void submit(DestinationCandidate candidate) =>
      _controller.placeAttendedTransferCall(anchorCallId: anchorCallId, number: candidate.number!);

  // Value equality, because the scope above the lists rebuilds with the shell
  // and a purpose that differed by identity alone would rebuild every list on
  // every frame.
  @override
  List<Object?> get props => [announcement, anchorCallId, _controller];
}
