import 'package:material_ui/material_ui.dart';

import '../controllers/call_controller.dart';
import 'linked_call_pick_purpose.dart';

/// Choosing whom to consult before handing the call [anchorCallId] over to
/// them: the attended transfer's first step.
class AttendedTransferPurpose extends LinkedCallPickPurpose {
  const AttendedTransferPurpose({
    required super.announcement,
    required super.pickLabel,
    required CallController controller,
    required super.anchorCallId,
  }) : _controller = controller;

  final CallController _controller;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  void place({required String number, String? displayName}) =>
      _controller.placeAttendedTransferCall(anchorCallId: anchorCallId, number: number, displayName: displayName);

  // Value equality, because the scope above the lists rebuilds with the shell
  // and a purpose that differed by identity alone would rebuild every list on
  // every frame.
  @override
  List<Object?> get props => [announcement, anchorCallId, _controller];
}
