import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/features/voicemail/extensions/extensions.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/crashlytics_utils.dart';

part 'voicemail_forwarding_state.dart';

final _logger = Logger('VoicemailForwardingCubit');

/// A message waiting for somebody to pass it to.
///
/// It outlives the voicemail screen on purpose: choosing the colleague happens
/// in the address book, which is a different section of the app, and the
/// message has to still be known when the choice comes back.
class VoicemailForwardingCubit extends Cubit<VoicemailForwardingState> {
  VoicemailForwardingCubit({required VoicemailRepository repository})
    : _repository = repository,
      super(const VoicemailForwardingState());

  final VoicemailRepository _repository;

  /// Begins looking for somebody to pass [message] to.
  void start(Voicemail message) => emit(VoicemailForwardingState(pending: message));

  /// Gives up on it, which is what leaving the address book means.
  void cancel() => emit(const VoicemailForwardingState());

  /// Passes the waiting message to [recipient] and records what came of it.
  Future<void> sendTo(Contact recipient) async {
    final message = state.pending;
    if (message == null) return;

    emit(const VoicemailForwardingState());
    await _send(message, recipient);
  }

  /// Sends again after a failure worth retrying, to the same colleague: the
  /// person already chose, and the failure was not about who they chose.
  Future<void> retry(VoicemailForwardReport report) async {
    emit(const VoicemailForwardingState());
    await _send(report.message, report.recipient);
  }

  /// Forgets the last outcome once it has been said, so it is not said twice.
  void reportShown() => emit(VoicemailForwardingState(pending: state.pending));

  Future<void> _send(Voicemail message, Contact recipient) async {
    var outcome = VoicemailForwardOutcome.sent;
    try {
      await _repository.forwardVoicemail(message.id, toUserId: recipient.sourceId!);
    } catch (e, s) {
      // Only a refusal from the backend carries a meaning worth telling apart.
      // A socket that died on the way there says nothing about the message or
      // the colleague, so it is the plain failure.
      outcome = e is RequestFailure ? e.voicemailForwardOutcome : VoicemailForwardOutcome.failed;
      // A message too large and a colleague who is full are answers, not
      // faults: the request reached the backend and it said no for a reason
      // the screen is about to explain. Only the rest is worth recording.
      if (outcome == VoicemailForwardOutcome.failed || outcome == VoicemailForwardOutcome.unavailable) {
        _logger.severe('Error forwarding voicemail with id ${message.id}: $e', e, s);
        CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailForwardingCubit.sendTo');
      }
    }

    if (isClosed) return;
    emit(
      VoicemailForwardingState(
        report: VoicemailForwardReport(outcome, message: message, recipient: recipient),
      ),
    );
  }
}
