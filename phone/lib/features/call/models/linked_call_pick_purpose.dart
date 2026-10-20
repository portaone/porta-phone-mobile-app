import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_bloc.dart';

/// Choosing whom to call on behalf of a call that is up - the anchor - from
/// the call screen: a consultation before a transfer, or somebody to bring
/// into the conversation. What the choice is for is the subclass's; how it is
/// asked for and taken back is shared.
///
/// Anything a number can be dialled from will do. Nothing has happened to the
/// call yet while the person chooses - it is held only once the new call is
/// placed - so the request is the person's own to give up, and the choice ends
/// it. The call screen asks for it and steps aside
/// ([CallControlEvent.linkedCallPickingStarted]);
/// `widgets/linked_call_picking.dart` takes it back once it has outlived what
/// it was asked for ([outlivedIn]).
///
/// A row with one number is the choice. A contact with several is not: which
/// number the row would dial is a guess the person never sees, so the row
/// opens a chooser of its numbers instead ([acceptsFallback]).
abstract class LinkedCallPickPurpose extends Equatable
    implements DestinationPickPurpose, DestinationPickFallbackPurpose {
  const LinkedCallPickPurpose({
    required this.announcement,
    required String Function(String number) pickLabel,
    required this.anchorCallId,
  }) : _pickLabel = pickLabel;

  @override
  final String announcement;

  /// The call the new one is placed for.
  final String anchorCallId;

  final String Function(String number) _pickLabel;

  @override
  bool offeredBy(MainFlavor flavor) => switch (flavor) {
    MainFlavor.favorites || MainFlavor.recents || MainFlavor.contacts || MainFlavor.keypad => true,
    MainFlavor.messaging || MainFlavor.embedded || MainFlavor.voicemail || MainFlavor.callCenter => false,
  };

  @override
  bool accepts(DestinationCandidate candidate) => candidate.number != null && candidate.availableNumbers.length == 1;

  @override
  bool acceptsFallback(DestinationCandidate candidate) => candidate.availableNumbers.length > 1;

  /// Somebody is on the line while this is being chosen, as for a transfer.
  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.live;

  @override
  bool get closedByChoice => true;

  @override
  bool get cancellable => true;

  @override
  String pickLabel(DestinationCandidate candidate) => _pickLabel(_named(candidate) ?? '');

  // A contact with several numbers is named rather than numbered: a tap there
  // opens the chooser, and naming the number the row shows would announce a
  // call to it.
  String? _named(DestinationCandidate candidate) =>
      candidate.availableNumbers.length > 1 ? candidate.contact?.displayTitle ?? candidate.number : candidate.number;

  /// The picked contact's name goes with the number, so the ringing call is
  /// shown under it rather than as a bare number.
  @override
  void submit(DestinationCandidate candidate) =>
      place(number: candidate.number!, displayName: candidate.contact?.displayTitle);

  /// Places the new call for [anchorCallId].
  void place({required String number, String? displayName});

  /// Whether the request has outlived what it was asked for in [state]: the
  /// anchor is gone. A choice then would place a call that is for nothing.
  bool outlivedIn(CallState state) => state.retrieveActiveCall(anchorCallId) == null;
}
