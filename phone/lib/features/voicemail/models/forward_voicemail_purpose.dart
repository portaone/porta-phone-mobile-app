import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../cubits/cubits.dart';
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
    required this.onCancel,
    required this.messageId,
  }) : _pickLabel = pickLabel,
       _onPicked = onPicked;

  /// The purpose while a message is waiting for a recipient, and null when
  /// none is - which is how the shell asks this feature whether it wants
  /// somebody chosen, without knowing what forwarding is.
  static ForwardVoicemailPurpose? maybeOf(BuildContext context) {
    final pending = context.select<VoicemailForwardingCubit, Voicemail?>((cubit) => cubit.state.pending);
    if (pending == null) return null;

    final cubit = context.read<VoicemailForwardingCubit>();

    return ForwardVoicemailPurpose(
      announcement: context.l10n.voicemail_Label_forwardChoosing,
      pickLabel: context.l10n.voicemail_SemanticsLabel_forwardTo,
      messageId: pending.id,
      onPicked: cubit.sendTo,
      onCancel: cubit.cancel,
    );
  }

  @override
  final String announcement;

  /// The message being passed on. Carried so that two forwards in a row are
  /// not the same purpose, and the scope above the lists notices the change.
  final String messageId;

  final String Function(String name) _pickLabel;
  final void Function(Contact recipient) _onPicked;

  /// A message looking for a recipient has no other way out: without this the
  /// only way to stop would be to send it to somebody.
  @override
  final VoidCallback? onCancel;

  @override
  IconData get pickIcon => Icons.forward_to_inbox;

  @override
  bool offeredBy(MainFlavor flavor) => switch (flavor) {
    // Wherever a person can be recognised. A number is not enough here: a
    // forward addresses an account on the backend, so the keypad has nothing
    // to offer and is left out rather than showing a control that would refuse
    // everything typed into it.
    MainFlavor.contacts || MainFlavor.favorites || MainFlavor.recents => true,
    MainFlavor.keypad || MainFlavor.messaging || MainFlavor.embedded || MainFlavor.voicemail => false,
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
