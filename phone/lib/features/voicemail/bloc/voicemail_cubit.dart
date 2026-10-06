import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/crashlytics_utils.dart';

import '../cubits/cubits.dart';
import '../models/models.dart';

part 'voicemail_state.dart';
part 'voicemail_view.dart';

part 'voicemail_cubit.freezed.dart';

final _logger = Logger('VoicemailCubit');

/// One voicemail screen: which view is on, what is picked, the trash while it
/// is being looked at, and what the person does to a message.
///
/// The mailbox itself is not kept here, and neither is a copy of it. It
/// belongs to the session - see [VoicemailSessionCubit] - so two screens and
/// the badge can never disagree about it. What a widget shows is both states
/// read together: [VoicemailView], built from the two where it is needed and
/// stored nowhere. Built per screen because what is left is the screen's own.
class VoicemailCubit extends Cubit<VoicemailState> {
  VoicemailCubit({
    required VoicemailRepository repository,
    required VoicemailSessionCubit session,
    required ContactsRepository contactsRepository,
    required this.onCallStarted,
    required this.onSubmitNotification,
    required bool saveSupported,
    required bool trashSupported,
    required bool forwardSupported,
  }) : _repository = repository,
       _session = session,
       _contactsRepository = contactsRepository,
       super(
         VoicemailState(
           forwardSupported: forwardSupported,
           filters: [
             VoicemailFilter.all,
             VoicemailFilter.unheard,
             if (saveSupported) VoicemailFilter.saved,
             if (trashSupported) VoicemailFilter.trash,
           ],
         ),
       ) {
    _initialize();
  }

  final VoicemailRepository _repository;
  final VoicemailSessionCubit _session;

  /// Only for resolving who a message came from into a card that can be
  /// opened. The mailbox itself knows nothing about the address book.
  final ContactsRepository _contactsRepository;
  final ValueChanged<String> onCallStarted;
  final ValueChanged<Notification> onSubmitNotification;

  late final StreamSubscription<VoicemailSessionState> _subscription;

  /// What this screen shows right now: the session's mailbox and this
  /// screen's own state, read together.
  VoicemailView get view => VoicemailView(mailbox: _session.state, screen: state);

  /// Reads the mailbox again.
  ///
  /// The read is the session's, and so is how it went; this only says so where
  /// nothing on this screen says it already.
  Future<void> fetchVoicemails() async {
    final outcome = await _session.fetchVoicemails();
    if (outcome != VoicemailReadOutcome.failed) return;

    // Only a refusal from the backend carries something to show behind the
    // sentence. A request that never arrived has nothing the backend said.
    final error = _session.state.error;
    _reportFailedRead(error is RequestFailure ? error : null);
  }

  /// Reads the trash, which is not stored and so has to be asked for every
  /// time the screen wants it.
  ///
  /// How this read stands is kept apart from how the mailbox's does: they are
  /// two reads of two lists, and one finishing says nothing about the other.
  ///
  /// The read is slow - a request per message - so the person can have left
  /// the trash by the time it lands. An answer for a view that is no longer on
  /// is dropped whole: written, it would be a stale list waiting for the next
  /// visit, and its ids would be taken for the list a selection made since was
  /// made over.
  Future<void> fetchTrashedVoicemails() async {
    try {
      _safeEmit(state.copyWith(trashStatus: VoicemailStatus.loading, trashError: null));
      final trashedItems = await _repository.fetchTrashedVoicemails();
      if (!state.isShowingTrash) return;

      _safeEmit(state.copyWith(trashStatus: VoicemailStatus.loaded, trashedItems: trashedItems));
      _keepSelectionWithin(trashedItems);
    } on EndpointNotSupportedException catch (e) {
      _safeEmit(state.copyWith(trashStatus: VoicemailStatus.featureNotSupported, trashError: e));
    } on VoicemailNotConfiguredException catch (e) {
      _safeEmit(state.copyWith(trashStatus: VoicemailStatus.featureNotSupported, trashError: e));
    } on RequestFailure catch (e, s) {
      _logger.severe('Error fetching trashed voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.fetchTrashedVoicemails');
      if (!state.isShowingTrash) return;

      _safeEmit(state.copyWith(trashStatus: VoicemailStatus.loaded, trashError: e));
      _reportFailedRead(e);
    } catch (e, s) {
      _logger.severe('Error fetching trashed voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.fetchTrashedVoicemails');
      if (!state.isShowingTrash) return;

      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _safeEmit(state.copyWith(trashStatus: VoicemailStatus.loaded, trashError: e));
      _reportFailedRead(null);
    }
  }

  /// Fetches whatever the current filter is showing.
  ///
  /// What a pull to refresh and a retry both mean. Three of the four filters
  /// read the stored mailbox, so they refresh it; the trash is its own fetch.
  Future<void> refresh() => state.filter.isRemote ? fetchTrashedVoicemails() : fetchVoicemails();

  /// Shows a different view of the mailbox.
  ///
  /// Leaving the trash drops the copy that was read, so coming back shows the
  /// trash as it is now rather than as it was. A stale list here is worse than
  /// a moment of loading: the trash is the list most likely to have been
  /// changed from somewhere else since it was last looked at.
  void setFilter(VoicemailFilter filter) {
    if (filter == state.filter) return;

    _safeEmit(
      state.copyWith(
        filter: filter,
        trashedItems: const [],
        selectedVoicemailsIds: const [],
        trashStatus: VoicemailStatus.loaded,
        trashError: null,
      ),
    );

    if (filter.isRemote) fetchTrashedVoicemails();
  }

  void removeAllVoicemails() async {
    try {
      _safeEmit(state.copyWith(busy: true));
      await _repository.removeAllVoicemails();
      _safeEmit(state.copyWith(busy: false));
    } on RequestFailure catch (e, s) {
      _safeEmit(state.copyWith(busy: false));
      _logger.severe('Error removing all voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeAllVoicemails');
      onSubmitNotification(VoicemailDeleteFailedNotification(e, count: view.visibleItems.length));
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _safeEmit(state.copyWith(busy: false));
      _logger.severe('Error removing all voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeAllVoicemails');
      onSubmitNotification(VoicemailDeleteFailedNotification(null, count: view.visibleItems.length));
    }
  }

  void removeSelectedVoicemails() async {
    // Held before anything is emitted: what was picked is cleared as the list
    // is put right, and the sentence about a failure needs to know how many
    // messages it was about.
    final selected = state.selectedVoicemailsIds;

    try {
      _safeEmit(state.copyWith(busy: true));
      await _repository.removeMultipleVoicemails(selected);
      _safeEmit(state.copyWith(busy: false));
    } on RequestFailure catch (e, s) {
      _safeEmit(state.copyWith(busy: false));
      _logger.severe('Error removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemails');
      onSubmitNotification(VoicemailDeleteFailedNotification(e, count: selected.length));
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _safeEmit(state.copyWith(busy: false));
      _logger.severe('Error removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemails');
      onSubmitNotification(VoicemailDeleteFailedNotification(null, count: selected.length));
    }
  }

  /// Puts everything picked back where it was.
  void restoreSelectedVoicemails() async {
    final selected = state.selectedVoicemailsIds;

    try {
      _safeEmit(state.copyWith(busy: true));
      await _repository.restoreMultipleVoicemails(selected);
    } on RequestFailure catch (e, s) {
      _logger.severe('Error restoring selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreSelectedVoicemails');
      onSubmitNotification(VoicemailRestoreFailedNotification(e, count: selected.length));
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _logger.severe('Error restoring selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreSelectedVoicemails');
      onSubmitNotification(VoicemailRestoreFailedNotification(null, count: selected.length));
    } finally {
      // Whatever happened, some of them may have moved, so the list on screen
      // is re-read rather than guessed at.
      await _afterTrashChange();
    }
  }

  /// Deletes everything picked for good.
  void removeSelectedVoicemailsPermanently() async {
    final selected = state.selectedVoicemailsIds;

    try {
      _safeEmit(state.copyWith(busy: true));
      await _repository.removeMultipleVoicemailsPermanently(selected);
    } on RequestFailure catch (e, s) {
      _logger.severe('Error permanently removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemailsPermanently');
      onSubmitNotification(VoicemailDeleteFailedNotification(e, count: selected.length));
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _logger.severe('Error permanently removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemailsPermanently');
      onSubmitNotification(VoicemailDeleteFailedNotification(null, count: selected.length));
    } finally {
      await _afterTrashChange();
    }
  }

  /// The card of whoever left [voicemail], or null when the address book no
  /// longer knows them.
  ///
  /// Looked up when it is asked for rather than carried on every message: the
  /// tile already knows a contact exists, because it is showing that person's
  /// name, and what it does not have is the row's id. One query on a
  /// deliberate tap against a column and a mapping on every message ever
  /// listed.
  Future<Contact?> callerOf(Voicemail voicemail) => _contactsRepository.getContactByPhoneNumber(voicemail.sender);

  /// Deletes a message, which means the trash where there is one.
  ///
  /// Where there is one the move is worth saying, because it carries the way
  /// back; where there is not, the message is simply gone and there is nothing
  /// to offer.
  Future<void> removeVoicemail(String messageId) async {
    _safeEmit(state.copyWith(busy: true));

    try {
      await _repository.removeVoicemail(messageId);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.removeVoicemail: the message was already gone: $e', e, s);
      _safeEmit(state.copyWith(busy: false));
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } on RequestFailure catch (e, s) {
      _logger.severe('VoicemailCubit.removeVoicemail: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemail');
      onSubmitNotification(VoicemailDeleteFailedNotification(e));
      _safeEmit(state.copyWith(busy: false));
      return;
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _logger.severe('VoicemailCubit.removeVoicemail: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemail');
      onSubmitNotification(const VoicemailDeleteFailedNotification(null));
      _safeEmit(state.copyWith(busy: false));
      return;
    }

    _safeEmit(state.copyWith(busy: false));
    if (!state.trashSupported) return;

    onSubmitNotification(VoicemailMovedToTrashNotification(onUndo: () => restoreVoicemail(messageId)));
  }

  /// Puts a trashed message back where it was.
  ///
  /// Also what undoing a move to the trash does, because it is the same thing:
  /// the message is in the trash either way, and the only difference is how
  /// long it has been there.
  Future<void> restoreVoicemail(String messageId) async {
    _safeEmit(state.copyWith(busy: true));

    try {
      await _repository.restoreVoicemail(messageId);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.restoreVoicemail: the message was already gone: $e', e, s);
      _safeEmit(state.copyWith(busy: false));
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } on RequestFailure catch (e, s) {
      _logger.severe('VoicemailCubit.restoreVoicemail: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreVoicemail');
      onSubmitNotification(VoicemailRestoreFailedNotification(e));
      _safeEmit(state.copyWith(busy: false));
      return;
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _logger.severe('VoicemailCubit.restoreVoicemail: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreVoicemail');
      onSubmitNotification(const VoicemailRestoreFailedNotification(null));
      _safeEmit(state.copyWith(busy: false));
      return;
    }

    await _readAgainIfShowingTrash();
  }

  /// Deletes a message for good, wherever it is.
  ///
  /// The only per-message action that frees the space it occupies; moving one
  /// to the trash does not.
  Future<void> removeVoicemailPermanently(String messageId) async {
    _safeEmit(state.copyWith(busy: true));

    try {
      await _repository.removeVoicemailPermanently(messageId);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.removeVoicemailPermanently: the message was already gone: $e', e, s);
      _safeEmit(state.copyWith(busy: false));
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } on RequestFailure catch (e, s) {
      _logger.severe('VoicemailCubit.removeVoicemailPermanently: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemailPermanently');
      onSubmitNotification(VoicemailDeleteFailedNotification(e));
      _safeEmit(state.copyWith(busy: false));
      return;
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _logger.severe('VoicemailCubit.removeVoicemailPermanently: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemailPermanently');
      onSubmitNotification(const VoicemailDeleteFailedNotification(null));
      _safeEmit(state.copyWith(busy: false));
      return;
    }

    await _readAgainIfShowingTrash();
  }

  Future<void> toggleSeenStatus(Voicemail voicemail) async {
    _safeEmit(state.copyWith(busy: true));

    try {
      await _repository.updateVoicemailSeenStatus(voicemail.id, !voicemail.status.isRead);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.toggleSeenStatus: the message was already gone: $e', e, s);
      _safeEmit(state.copyWith(busy: false));
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } on RequestFailure catch (e, s) {
      _logger.severe('VoicemailCubit.toggleSeenStatus: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSeenStatus');
      onSubmitNotification(VoicemailUpdateFailedNotification(e));
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _logger.severe('VoicemailCubit.toggleSeenStatus: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSeenStatus');
      onSubmitNotification(const VoicemailUpdateFailedNotification(null));
    }

    _safeEmit(state.copyWith(busy: false));
  }

  /// Keeps [voicemail], or stops keeping it.
  ///
  /// Independent of whether it has been heard, in both directions: keeping a
  /// message does not mark it read, and reading one does not stop it being
  /// kept.
  Future<void> toggleSavedStatus(Voicemail voicemail) async {
    _safeEmit(state.copyWith(busy: true));

    try {
      await _repository.updateVoicemailSavedStatus(voicemail.id, !(voicemail.saved ?? false));
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.toggleSavedStatus: the message was already gone: $e', e, s);
      _safeEmit(state.copyWith(busy: false));
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } on RequestFailure catch (e, s) {
      _logger.severe('VoicemailCubit.toggleSavedStatus: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSavedStatus');
      onSubmitNotification(VoicemailUpdateFailedNotification(e));
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _logger.severe('VoicemailCubit.toggleSavedStatus: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSavedStatus');
      onSubmitNotification(const VoicemailUpdateFailedNotification(null));
    }

    _safeEmit(state.copyWith(busy: false));
  }

  /// Deletes everything in the trash for good.
  ///
  /// Along with deleting one message permanently, the only thing that frees
  /// the space the trash occupies.
  Future<void> emptyVoicemailTrash() async {
    try {
      _safeEmit(state.copyWith(busy: true));
      await _repository.emptyVoicemailTrash();
      _safeEmit(state.copyWith(busy: false));
      // Re-read rather than assume empty: the backend deletes what it can and
      // a partial pass leaves the rest, which the screen has to show.
      await fetchTrashedVoicemails();
    } on RequestFailure catch (e, s) {
      _safeEmit(state.copyWith(busy: false));
      _logger.severe('Error emptying the voicemail trash: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.emptyVoicemailTrash');
      onSubmitNotification(VoicemailEmptyTrashFailedNotification(e));
    } catch (e, s) {
      // The request never arrived, so there is nothing the backend said and
      // nothing to show behind the sentence.
      _safeEmit(state.copyWith(busy: false));
      _logger.severe('Error emptying the voicemail trash: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.emptyVoicemailTrash');
      onSubmitNotification(const VoicemailEmptyTrashFailedNotification(null));
    }
  }

  void startCall(Voicemail voicemail) {
    onCallStarted(voicemail.sender);
  }

  /// Adds [voicemail] to the multi-select set, or removes it when it is
  /// already there. Selection only: nothing is sent to the server.
  void toggleSelection(Voicemail voicemail) {
    final selectedVoicemailsIds = List.of(state.selectedVoicemailsIds);

    if (selectedVoicemailsIds.contains(voicemail.id)) {
      selectedVoicemailsIds.remove(voicemail.id);
    } else {
      selectedVoicemailsIds.add(voicemail.id);
    }

    _safeEmit(state.copyWith(selectedVoicemailsIds: selectedVoicemailsIds));
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    _session.detach();
    return super.close();
  }

  void _initialize() {
    _session.attach();
    _subscription = _session.stream.listen(_onMailbox);

    if (_session.state.isFeatureNotSupported) return;

    _readOnOpening();
  }

  /// Asks for the mailbox as the screen opens, where that is still worth
  /// doing.
  ///
  /// The first screen of a session asks, and says so if it fails: that read
  /// is how a person finds out the list they are looking at is not current.
  /// After it the list is kept fresh by polling and by a pull to refresh, so a
  /// later screen does not ask again - the screen reached from settings is
  /// built on every visit, and on a connection that is down each of those
  /// reads would fail the same way.
  ///
  /// The exception is a session whose last read failed: nothing else would
  /// clear that failure where the mailbox is empty, because a poll that finds
  /// nothing writes nothing. That read is tried again, and quietly - the
  /// person has been told once, and a second sentence would push aside
  /// whatever else they were just told.
  void _readOnOpening() {
    if (!_session.readAsked) {
      fetchVoicemails();
    } else if (_session.state.error != null) {
      _session.fetchVoicemails();
    }
  }

  /// A selection made over the mailbox follows the mailbox.
  void _onMailbox(VoicemailSessionState mailbox) {
    if (state.isShowingTrash) return;

    _keepSelectionWithin(view.visibleItems);
  }

  /// Keeps only what is picked among [items], the list the selection was made
  /// over.
  ///
  /// A selection only means something for messages the person can see: once a
  /// selected message is deleted, or stops matching the view that is on - a
  /// message heard while New is showing - its id must leave the set too, or
  /// the app bar goes on counting, and the bulk actions go on reaching,
  /// messages nobody is looking at.
  void _keepSelectionWithin(List<Voicemail> items) {
    if (state.selectedVoicemailsIds.isEmpty) return;

    final ids = items.map((item) => item.id).toSet();
    final selectedVoicemailsIds = state.selectedVoicemailsIds.where(ids.contains).toList();
    if (selectedVoicemailsIds.length == state.selectedVoicemailsIds.length) return;

    _safeEmit(state.copyWith(selectedVoicemailsIds: selectedVoicemailsIds));
  }

  /// Says a read failed, where nothing on screen says it already.
  ///
  /// With nothing to show, the screen puts a retry in place of the list and
  /// the sentence would be the second one saying the same thing. With a list
  /// still on it, the only visible difference is that it did not change.
  void _reportFailedRead(RequestFailure? failure) {
    if (!view.isVoicemailsExists) return;

    onSubmitNotification(VoicemailRefreshFailedNotification(failure));
  }

  /// Leaves selection and re-reads whichever list is on screen.
  ///
  /// The selection was made over the trash, which is not stored, so nothing
  /// else would notice that it is no longer what it was.
  Future<void> _afterTrashChange() async {
    _safeEmit(state.copyWith(selectedVoicemailsIds: const [], busy: false));
    if (state.filter.isRemote) await fetchTrashedVoicemails();
  }

  /// Reads the trash again after something changed it, while it is what is on
  /// screen.
  ///
  /// It keeps no stored copy that could be corrected in place. A read like any
  /// other: it says so itself when it fails, and it cannot turn a write that
  /// already happened into one that did not.
  Future<void> _readAgainIfShowingTrash() async {
    _safeEmit(state.copyWith(busy: false));
    if (state.filter.isRemote) await fetchTrashedVoicemails();
  }

  /// Safely emits a new state if the cubit is not closed.
  ///
  /// This prevents the "Bad state: Cannot emit new states after calling close"
  /// error, which can occur when asynchronous operations complete after
  /// the cubit has been closed (e.g., when a screen is disposed).
  void _safeEmit(VoicemailState newState) {
    if (!isClosed) emit(newState);
  }
}
