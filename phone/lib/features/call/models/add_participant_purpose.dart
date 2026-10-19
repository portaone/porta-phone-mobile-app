import 'package:material_ui/material_ui.dart';

import '../bloc/call_bloc.dart';
import '../controllers/call_controller.dart';
import 'linked_call_pick_purpose.dart';

/// Choosing somebody to call into the conversation on the call screen: the
/// call [anchorCallId], or the room when it is a leg of one.
class AddParticipantPurpose extends LinkedCallPickPurpose {
  const AddParticipantPurpose({
    required super.announcement,
    required super.pickLabel,
    required CallController controller,
    required super.anchorCallId,
    this.intoRoom = false,
  }) : _controller = controller;

  /// Whether [anchorCallId] was a leg of the room when the person asked: the
  /// request is then for the room, and goes when the room does.
  final bool intoRoom;

  final CallController _controller;

  @override
  IconData get pickIcon => Icons.person_add_alt_1;

  @override
  void place({required String number, String? displayName}) =>
      _controller.placeParticipantCall(anchorCallId: anchorCallId, number: number, displayName: displayName);

  /// A request for the room goes with the room too, though the call it was
  /// asked from may stay as an ordinary one: a choice then would merge
  /// somebody with that one former participant rather than bring them into
  /// the conference. A leg of the room going takes it back as well: the
  /// request was made from that leg, and the person asks again from the room
  /// as it is.
  @override
  bool outlivedIn(CallState state) => super.outlivedIn(state) || (intoRoom && !state.conference.isPresent);

  @override
  List<Object?> get props => [announcement, anchorCallId, intoRoom, _controller];
}
