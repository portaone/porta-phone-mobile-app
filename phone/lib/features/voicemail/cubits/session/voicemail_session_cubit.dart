import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/crashlytics_utils.dart';

import '../../extensions/extensions.dart';
import '../../models/models.dart';

part 'voicemail_session_state.dart';

part 'voicemail_session_cubit.freezed.dart';

final _logger = Logger('VoicemailSessionCubit');

/// How a read of the mailbox ended.
enum VoicemailReadOutcome {
  done,

  /// The backend does not serve voicemail for this account at all.
  notSupported,

  /// The read did not go through; the reason is the state's `error`.
  failed,
}

/// What every part of the app shares about voicemail for as long as the person
/// is signed in: the stored mailbox, how many messages are waiting, who
/// forwarded the ones that were passed along, and the messages the person is
/// passing on themselves.
///
/// Session-scoped because these outlive any one screen. Voicemail is shown
/// from two places and counted on a third, and the screen reached from
/// settings is torn down and built again as the person moves about; a copy
/// held by each screen is a copy read again on every visit and allowed to
/// disagree with the badge beside it.
///
/// What belongs to one screen stays there: which view is on, what is picked,
/// and the trash, which is never stored and is read only while it is looked
/// at. See `VoicemailCubit`.
///
/// The count is followed from the start, because a badge reads it. The
/// mailbox is followed only while a screen is showing it ([attach] and
/// [detach]): the query behind it joins the address book and runs again on
/// every write to either, which is not a cost to carry for somebody who never
/// opens voicemail.
///
/// It does not read the mailbox on its own. The repository is registered for
/// polling, whose leading cycle refreshes it at the start of the session and
/// every interval after, and for refresh on connectivity recovery; this
/// follows what that leaves in the store, and reads when it is asked to -
/// see `VoicemailCubit` for when a screen asks.
///
/// Where voicemail is not available for the session the repository is the
/// empty one, whose streams are a constant nothing, so this needs no gate of
/// its own.
class VoicemailSessionCubit extends Cubit<VoicemailSessionState> {
  VoicemailSessionCubit({required VoicemailRepository repository, required ContactsRepository contactsRepository})
    : _repository = repository,
      _contactsRepository = contactsRepository,
      super(const VoicemailSessionState());

  final VoicemailRepository _repository;

  /// Only for putting a name to whoever forwarded a message. The mailbox
  /// itself knows nothing about the address book.
  final ContactsRepository _contactsRepository;

  StreamSubscription<List<Voicemail>>? _itemsSubscription;
  StreamSubscription<int>? _unreadSubscription;

  /// How many screens are showing the mailbox.
  int _screens = 0;

  void init() {
    _logger.fine('Initializing');
    _unreadSubscription = _repository.watchUnreadVoicemailsCount().listen(_onUnreadCount);
  }

  /// A screen starts showing the mailbox.
  void attach() {
    _screens++;
    _checkSupport();
    if (_screens > 1) return;

    _itemsSubscription = _repository.watchVoicemails().listen(_onItems);
  }

  /// A screen stops showing the mailbox. With the last one gone the list is
  /// no longer followed; what was last seen stays, and is brought up to date
  /// the moment the next screen attaches.
  void detach() {
    if (_screens == 0) return;

    _screens--;
    if (_screens > 0) return;

    _itemsSubscription?.cancel();
    _itemsSubscription = null;
  }

  /// Reads the mailbox from the backend into the store this follows.
  ///
  /// Never throws: how it ended is the answer, and why it failed is in the
  /// state. Whether a failure is worth a sentence depends on what is on screen
  /// at the time, so saying it is left to whoever asked.
  Future<VoicemailReadOutcome> fetchVoicemails() async {
    if (_checkSupport()) return VoicemailReadOutcome.notSupported;

    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading, error: null));
      await _repository.fetchVoicemails();
      // The repository can find out on this very read that there is no
      // voicemail, and it says so by the flag rather than by throwing.
      if (_checkSupport()) return VoicemailReadOutcome.notSupported;

      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      return VoicemailReadOutcome.done;
    } on EndpointNotSupportedException catch (e) {
      _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported, error: e));
      return VoicemailReadOutcome.notSupported;
    } on VoicemailNotConfiguredException catch (e) {
      _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported, error: e));
      return VoicemailReadOutcome.notSupported;
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded, error: e));
      _logger.severe('Error fetching voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailSessionCubit.fetchVoicemails');
      return VoicemailReadOutcome.failed;
    }
  }

  /// Passes [message] to [recipient] and answers what the backend made of it,
  /// or null when nothing was sent because a forward of that message is
  /// already out.
  ///
  /// The message is marked as on its way for exactly as long as the request is
  /// out. A forward that did not go through for a reason another try could
  /// change stays on the message, with who it was for, until another forward
  /// of that message goes through or the message leaves the mailbox. One that
  /// went through, or was refused for good, leaves nothing. Saying how it went
  /// is the caller's business.
  ///
  /// One at a time for a message: a refusal can be answered from two places,
  /// the sentence that says it and the menu of the message, and each try has
  /// an idempotency key of its own - two at once would put two copies in the
  /// colleague's mailbox.
  ///
  /// Here rather than on a screen because the request outlives every screen
  /// that could start it: the colleague is chosen on another section, and the
  /// voicemail screen reached from settings is torn down on the way there.
  ///
  /// Never throws: a refusal is an answer.
  Future<VoicemailForwardOutcome?> forward(Voicemail message, Contact recipient) async {
    if (state.forwards[message.id] is VoicemailForwardSending) return null;

    _setForward(message.id, const VoicemailForwardSending());

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
      // the person is about to be told. Only the rest is worth recording.
      if (outcome == VoicemailForwardOutcome.failed || outcome == VoicemailForwardOutcome.unavailable) {
        _logger.severe('Error forwarding voicemail with id ${message.id}: $e', e, s);
        CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailSessionCubit.forward');
      }
    }

    // A refusal is kept on the message only where trying again could end
    // differently. A recording that is too big stays too big and a colleague
    // who is full stays full: said once, there is nothing left to do about
    // them, and a mark nothing could take off would only be a blemish.
    _setForward(
      message.id,
      outcome.isRetryable ? VoicemailForwardFailed(outcome: outcome, recipient: recipient) : null,
    );
    return outcome;
  }

  void _setForward(String messageId, VoicemailForward? forward) {
    final forwards = {...state.forwards};
    if (forward == null) {
      forwards.remove(messageId);
    } else {
      forwards[messageId] = forward;
    }

    _safeEmit(state.copyWith(forwards: forwards));
  }

  /// The forwards still worth keeping once the mailbox is [items].
  ///
  /// A refusal is a mark on a message, and goes with it: moved to the trash or
  /// deleted, the message is no longer there to carry it, and one that comes
  /// back from the trash should not come back wearing an old refusal. A
  /// forward still out is kept whatever happens to the message - its request
  /// is in flight and its answer will settle it.
  Map<String, VoicemailForward> _forwardsAmong(List<Voicemail> items) {
    final ids = items.map((item) => item.id).toSet();

    return {
      for (final MapEntry(key: id, value: forward) in state.forwards.entries)
        if (forward is VoicemailForwardSending || ids.contains(id)) id: forward,
    };
  }

  void _onItems(List<Voicemail> items) {
    if (_checkSupport() || state.isFeatureNotSupported) return;

    // The list alone. How the read stands is not touched: the store emits
    // for reasons that have nothing to do with a read - a write to the address
    // book it is joined with, the cached copy the repository shows before it
    // asks - and one of those must neither end the progress of a read still
    // out nor pass a failed one off as good.
    _safeEmit(state.copyWith(items: items, forwards: _forwardsAmong(items)));
    unawaited(_resolveForwarders(items));
  }

  void _onUnreadCount(int count) => _safeEmit(state.copyWith(unreadCount: count));

  /// Takes in whether the backend serves voicemail at all, and answers
  /// whether it does not.
  ///
  /// Asked every time it could have changed rather than once. The repository
  /// learns it from its own first read - which polling makes, at a moment of
  /// its choosing - keeps it as a plain flag, and from then on answers every
  /// read with nothing instead of an error. A flag read once at the start
  /// would be read before that, and the screen would show an empty mailbox
  /// where there is no mailbox.
  bool _checkSupport() {
    if (_repository.isFeatureSupported) return false;

    if (!state.isFeatureNotSupported) _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported));
    return true;
  }

  @override
  Future<void> close() {
    _logger.fine('Closing');
    _itemsSubscription?.cancel();
    _unreadSubscription?.cancel();
    return super.close();
  }

  /// Puts a name to whoever forwarded each of these messages on.
  ///
  /// Detached from the list arriving rather than awaited before it: a message
  /// is worth showing at once, and the line naming the forwarder appears a
  /// moment later. Only ids not already known are looked up, so a list that
  /// changes for other reasons costs nothing.
  ///
  /// A forwarded message carries the id of whoever passed it along and nothing
  /// else about them, so the address book is asked - on that id, not on a
  /// number: a forward names a user, and the same person may answer on several
  /// numbers or none. The answer is the title the address book itself shows
  /// the person under, so a colleague with no name reads here as they do
  /// there, by extension or number. An id with nobody behind it stays unnamed:
  /// a colleague who has left the address book is still a fact about the
  /// message, and their id is a poor but honest stand-in for their name.
  Future<void> _resolveForwarders(List<Voicemail> items) async {
    final unknown = items
        .map((item) => item.forwardedBy)
        .nonNulls
        .where((userId) => !state.forwarderNames.containsKey(userId))
        .toSet()
        .toList();
    if (unknown.isEmpty) return;

    final names = await Future.wait(unknown.map(_forwarderName));
    final resolved = {for (final (index, name) in names.indexed) unknown[index]: ?name};
    if (resolved.isEmpty) return;

    _safeEmit(state.copyWith(forwarderNames: {...state.forwarderNames, ...resolved}));
  }

  /// The title the address book shows this colleague under, or null when it
  /// does not know them or could not be asked.
  ///
  /// Each colleague is asked about on their own: a name that could not be
  /// looked up is not worth failing a list over, nor the names found beside
  /// it. The tile falls back to the id and the message still reads correctly.
  Future<String?> _forwarderName(String userId) async {
    try {
      final contact = await _contactsRepository.getContactBySource(ContactSourceType.external, userId);
      return contact?.displayTitle;
    } catch (e, s) {
      _logger.warning('Error resolving voicemail forwarder name: $e', e, s);
      return null;
    }
  }

  /// An answer can arrive after the session has ended, and a closed cubit
  /// refuses an emit.
  void _safeEmit(VoicemailSessionState newState) {
    if (!isClosed) emit(newState);
  }
}
