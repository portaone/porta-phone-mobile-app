import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/bloc.dart';

/// Deleting a message, which is two different things.
///
/// Where there is a trash the message can be had back, so it goes without
/// asking - a question before every delete trains people to dismiss it, and
/// this one has nothing to warn about. Where there is no trash the same
/// gesture is final, so it asks first. What is said afterwards, and whether
/// the way back is offered, belongs to the mailbox rather than to the row or
/// the page it was asked from.
Future<void> deleteVoicemail(BuildContext context, Voicemail voicemail, {required bool trashSupported}) async {
  final cubit = context.read<VoicemailCubit>();

  if (trashSupported) return cubit.removeVoicemail(voicemail.id);

  final confirmed =
      (await ConfirmDialog.showDangerous(
        context,
        title: context.l10n.voicemail_Dialog_deleteSingleTitle,
        content: context.l10n.voicemail_Dialog_deleteSingleContent,
      )) ??
      false;

  if (!confirmed) return;

  await cubit.removeVoicemail(voicemail.id);
}

/// Finishes deleting a message in the trash, which cannot be taken back, so it
/// asks first.
Future<void> deleteVoicemailPermanently(BuildContext context, Voicemail voicemail) async {
  final cubit = context.read<VoicemailCubit>();

  final confirmed =
      (await ConfirmDialog.showDangerous(
        context,
        title: context.l10n.voicemail_Dialog_deletePermanentlyTitle,
        content: context.l10n.voicemail_Dialog_deletePermanentlyContent,
      )) ??
      false;

  if (!confirmed) return;

  await cubit.removeVoicemailPermanently(voicemail.id);
}
