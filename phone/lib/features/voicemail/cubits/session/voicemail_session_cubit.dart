import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/crashlytics_utils.dart';

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
/// is signed in: the stored mailbox, how many messages are waiting, and who
/// forwarded the ones that were passed along.
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

  /// Whether the mailbox has been asked for in this session, however that
  /// went.
  bool get readAsked => _readAsked;
  bool _readAsked = false;

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
    _readAsked = true;
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

  void _onItems(List<Voicemail> items) {
    if (_checkSupport() || state.isFeatureNotSupported) return;

    // The list alone. How the read stands is not touched: the store emits
    // for reasons that have nothing to do with a read - a write to the address
    // book it is joined with, the cached copy the repository shows before it
    // asks - and one of those must neither end the progress of a read still
    // out nor pass a failed one off as good.
    _safeEmit(state.copyWith(items: items));
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
