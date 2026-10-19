import 'package:material_ui/material_ui.dart';

import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/models.dart';

import '../controllers/call_controller.dart';

/// Choosing somebody to call into the conversation on the call screen: the
/// call [anchorCallId], or the room when it is a leg of one.
///
/// Anything a number can be dialled from will do, as for a transfer. Unlike a
/// transfer nothing has happened to the call yet while the person chooses -
/// the call is held only once the new call is placed - so the request is the
/// person's own to give up, and a choice ends it.
class AddParticipantPurpose extends Equatable implements DestinationPickPurpose {
  const AddParticipantPurpose({
    required this.announcement,
    required String Function(String number) pickLabel,
    required CallController controller,
    required this.anchorCallId,
    this.intoRoom = false,
  }) : _pickLabel = pickLabel,
       _controller = controller;

  @override
  final String announcement;

  /// The call the person is bringing somebody into, or a leg of the room.
  final String anchorCallId;

  /// Whether [anchorCallId] was a leg of the room when the person asked: the
  /// request is then for the room, and goes when the room does.
  final bool intoRoom;

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
  IconData get pickIcon => Icons.person_add_alt_1;

  @override
  String pickLabel(DestinationCandidate candidate) => _pickLabel(candidate.number ?? '');

  @override
  void submit(DestinationCandidate candidate) => _controller.placeParticipantCall(
    anchorCallId: anchorCallId,
    number: candidate.number!,
    displayName: candidate.contact?.displayTitle,
  );

  @override
  List<Object?> get props => [announcement, anchorCallId, intoRoom, _controller];
}
