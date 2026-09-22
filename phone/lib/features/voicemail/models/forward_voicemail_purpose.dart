import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

import 'package:webtrit_phone/models/models.dart';

import '../extensions/contact.dart';

/// Passing a voice message to a colleague.
///
/// The second reason the app sends somebody to its own lists to choose a
/// person, and the reason choosing became a mechanism rather than something
/// blind transfer kept to itself.
class ForwardVoicemailPurpose extends Equatable implements DestinationPickPurpose {
  const ForwardVoicemailPurpose({
    required this.announcement,
    required String Function(String name) pickLabel,
    required void Function(Contact recipient) onPicked,
    required this.messageId,
  }) : _pickLabel = pickLabel,
       _onPicked = onPicked;

  @override
  final String announcement;

  /// The message being passed on. Carried so that two forwards in a row are
  /// not the same purpose, and the scope above the lists notices the change.
  final String messageId;

  final String Function(String name) _pickLabel;
  final void Function(Contact recipient) _onPicked;

  /// Nobody is waiting on the line for this, so it stands aside for a call
  /// being handed over rather than taking the floor from it.
  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  /// This feature owns the request outright: the choice is what it was waiting
  /// for, and what the backend then answers is told in a report rather than by
  /// keeping the lists in picking mode.
  @override
  bool get closedByChoice => true;

  /// There is no other way out of it: the screen that started this is two
  /// sections away, and without a way to give up the only way to stop would be
  /// to send the message to somebody.
  @override
  bool get cancellable => true;

  @override
  IconData get pickIcon => Icons.forward_to_inbox;

  @override
  bool offeredBy(MainFlavor flavor) => switch (flavor) {
    // Wherever a person can be recognised. A number is not enough here: a
    // forward addresses an account on the backend, so the keypad has nothing
    // to offer and is left out rather than showing a control that would refuse
    // everything typed into it.
    MainFlavor.contacts || MainFlavor.favorites || MainFlavor.recents => true,
    MainFlavor.keypad ||
    MainFlavor.messaging ||
    MainFlavor.embedded ||
    MainFlavor.voicemail ||
    MainFlavor.callCenter => false,
  };

  @override
  bool accepts(DestinationCandidate candidate) => candidate.contact?.canReceiveForwardedVoicemail ?? false;

  @override
  String pickLabel(DestinationCandidate candidate) => _pickLabel(candidate.contact?.displayTitle ?? '');

  @override
  void submit(DestinationCandidate candidate) => _onPicked(candidate.contact!);

  @override
  List<Object?> get props => [announcement, messageId];
}
