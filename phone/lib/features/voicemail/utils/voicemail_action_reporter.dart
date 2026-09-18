import 'package:flutter/material.dart';

import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../models/models.dart';

/// Says whatever an action over one message leaves to be said.
///
/// Which sentence goes with which answer is the feature's rule rather than a
/// row's, and the row is usually the wrong place to keep it anyway: a message
/// that is gone takes its element with it, and by the time there is anything
/// to say the widget that asked has left the tree. Built from a context while
/// that context is alive, and used afterwards.
class VoicemailActionReporter {
  const VoicemailActionReporter(this._snackBars, this._l10n);

  final AppSnackBars _snackBars;
  final AppLocalizations _l10n;

  /// Waits for [action] and says the one thing its answer can say for itself.
  Future<void> report(Future<VoicemailActionOutcome> action) async => _say(await action);

  /// The same for a move to the trash, which is the one action worth a word
  /// when it succeeds: the way back is offered with it.
  ///
  /// [onUndo] is an action of its own and can meet the same answers, so it is
  /// reported like any other.
  Future<void> reportMoveToTrash(
    Future<VoicemailActionOutcome> action, {
    required Future<VoicemailActionOutcome> Function() onUndo,
  }) async {
    final outcome = await action;
    if (outcome != VoicemailActionOutcome.done) return _say(outcome);

    _snackBars.show(
      _l10n.voicemail_Snackbar_movedToTrash,
      action: SnackBarAction(label: _l10n.voicemail_Label_undo, onPressed: () => report(onUndo())),
    );
  }

  /// A message the backend no longer has is the only answer that explains
  /// itself, and the list has already been put right by the time this runs -
  /// this only tells the person why the row they acted on went. Every other
  /// refusal is still silent; that is a change of its own.
  void _say(VoicemailActionOutcome outcome) {
    if (outcome != VoicemailActionOutcome.gone) return;

    _snackBars.show(_l10n.voicemail_Snackbar_messageGone);
  }
}
