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

import '../models/models.dart';

part 'voicemail_state.dart';

part 'voicemail_cubit.freezed.dart';

final _logger = Logger('VoicemailCubit');

class VoicemailCubit extends Cubit<VoicemailState> {
  VoicemailCubit({
    required VoicemailRepository repository,
    required ContactsRepository contactsRepository,
    required this.onCallStarted,
    required this.onSubmitNotification,
    required bool saveSupported,
    required bool trashSupported,
    required bool forwardSupported,
  }) : _repository = repository,
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

  /// Only for resolving who a message came from into a card that can be
  /// opened. The mailbox itself knows nothing about the address book.
  final ContactsRepository _contactsRepository;
  final ValueChanged<String> onCallStarted;
  final ValueChanged<Notification> onSubmitNotification;

  late final StreamSubscription<List<Voicemail>> _subscription;

  Future<void> fetchVoicemails() async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading, error: null));
      await _repository.fetchVoicemails();
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
    } on EndpointNotSupportedException catch (e) {
      _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported, error: e));
    } on VoicemailNotConfiguredException catch (e) {
      _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported, error: e));
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded, error: e));
      _logger.severe('Error fetching voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.fetchVoicemails');
      _reportFailedRead(_answerOf(e));
    }
  }

  /// Reads the trash, which is not stored and so has to be asked for every
  /// time the screen wants it.
  Future<void> fetchTrashedVoicemails() async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading, error: null));
      final trashedItems = await _repository.fetchTrashedVoicemails();
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded, trashedItems: trashedItems));
    } on EndpointNotSupportedException catch (e) {
      _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported, error: e));
    } on VoicemailNotConfiguredException catch (e) {
      _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported, error: e));
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded, error: e));
      _logger.severe('Error fetching trashed voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.fetchTrashedVoicemails');
      _reportFailedRead(_answerOf(e));
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

    _safeEmit(state.copyWith(filter: filter, trashedItems: const [], selectedVoicemailsIds: const [], error: null));

    if (filter.isRemote) fetchTrashedVoicemails();
  }

  void removeAllVoicemails() async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.removeAllVoicemails();
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error removing all voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeAllVoicemails');
      onSubmitNotification(VoicemailDeleteFailedNotification(_answerOf(e), count: state.visibleItems.length));
    }
  }

  void removeSelectedVoicemails() async {
    // Held before anything is emitted: what was picked is cleared as the list
    // is put right, and the sentence about a failure needs to know how many
    // messages it was about.
    final selected = state.selectedVoicemailsIds;

    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.removeMultipleVoicemails(selected);
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemails');
      onSubmitNotification(VoicemailDeleteFailedNotification(_answerOf(e), count: selected.length));
    }
  }

  /// Puts everything picked back where it was.
  void restoreSelectedVoicemails() async {
    final selected = state.selectedVoicemailsIds;

    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.restoreMultipleVoicemails(selected);
    } catch (e, s) {
      _logger.severe('Error restoring selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreSelectedVoicemails');
      onSubmitNotification(VoicemailRestoreFailedNotification(_answerOf(e), count: selected.length));
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
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.removeMultipleVoicemailsPermanently(selected);
    } catch (e, s) {
      _logger.severe('Error permanently removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemailsPermanently');
      onSubmitNotification(VoicemailDeleteFailedNotification(_answerOf(e), count: selected.length));
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
    _safeEmit(state.copyWith(status: VoicemailStatus.loading));

    try {
      await _repository.removeVoicemail(messageId);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.removeVoicemail: the message was already gone: $e', e, s);
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } catch (e, s) {
      _logger.severe('VoicemailCubit.removeVoicemail: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemail');
      onSubmitNotification(VoicemailDeleteFailedNotification(_answerOf(e)));
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      return;
    }

    _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
    if (!state.trashSupported) return;

    onSubmitNotification(VoicemailMovedToTrashNotification(onUndo: () => restoreVoicemail(messageId)));
  }

  /// Puts a trashed message back where it was.
  ///
  /// Also what undoing a move to the trash does, because it is the same thing:
  /// the message is in the trash either way, and the only difference is how
  /// long it has been there.
  Future<void> restoreVoicemail(String messageId) async {
    _safeEmit(state.copyWith(status: VoicemailStatus.loading));

    try {
      await _repository.restoreVoicemail(messageId);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.restoreVoicemail: the message was already gone: $e', e, s);
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } catch (e, s) {
      _logger.severe('VoicemailCubit.restoreVoicemail: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreVoicemail');
      onSubmitNotification(VoicemailRestoreFailedNotification(_answerOf(e)));
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      return;
    }

    await _readAgainIfShowingTrash();
  }

  /// Deletes a message for good, wherever it is.
  ///
  /// The only per-message action that frees the space it occupies; moving one
  /// to the trash does not.
  Future<void> removeVoicemailPermanently(String messageId) async {
    _safeEmit(state.copyWith(status: VoicemailStatus.loading));

    try {
      await _repository.removeVoicemailPermanently(messageId);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.removeVoicemailPermanently: the message was already gone: $e', e, s);
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } catch (e, s) {
      _logger.severe('VoicemailCubit.removeVoicemailPermanently: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemailPermanently');
      onSubmitNotification(VoicemailDeleteFailedNotification(_answerOf(e)));
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      return;
    }

    await _readAgainIfShowingTrash();
  }

  Future<void> toggleSeenStatus(Voicemail voicemail) async {
    _safeEmit(state.copyWith(status: VoicemailStatus.loading));

    try {
      await _repository.updateVoicemailSeenStatus(voicemail.id, !voicemail.status.isRead);
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.toggleSeenStatus: the message was already gone: $e', e, s);
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } catch (e, s) {
      _logger.severe('VoicemailCubit.toggleSeenStatus: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSeenStatus');
      onSubmitNotification(VoicemailUpdateFailedNotification(_answerOf(e)));
    }

    _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
  }

  /// Keeps [voicemail], or stops keeping it.
  ///
  /// Independent of whether it has been heard, in both directions: keeping a
  /// message does not mark it read, and reading one does not stop it being
  /// kept.
  Future<void> toggleSavedStatus(Voicemail voicemail) async {
    _safeEmit(state.copyWith(status: VoicemailStatus.loading));

    try {
      await _repository.updateVoicemailSavedStatus(voicemail.id, !(voicemail.saved ?? false));
    } on VoicemailMessageGoneException catch (e, s) {
      _logger.warning('VoicemailCubit.toggleSavedStatus: the message was already gone: $e', e, s);
      await refresh();
      onSubmitNotification(const VoicemailMessageGoneNotification());
      return;
    } catch (e, s) {
      _logger.severe('VoicemailCubit.toggleSavedStatus: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSavedStatus');
      onSubmitNotification(VoicemailUpdateFailedNotification(_answerOf(e)));
    }

    _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
  }

  /// Deletes everything in the trash for good.
  ///
  /// Along with deleting one message permanently, the only thing that frees
  /// the space the trash occupies.
  Future<void> emptyVoicemailTrash() async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.emptyVoicemailTrash();
      // Re-read rather than assume empty: the backend deletes what it can and
      // a partial pass leaves the rest, which the screen has to show.
      await fetchTrashedVoicemails();
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error emptying the voicemail trash: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.emptyVoicemailTrash');
      onSubmitNotification(VoicemailEmptyTrashFailedNotification(_answerOf(e)));
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
    return super.close();
  }

  void _initialize() async {
    _subscription = _repository.watchVoicemails().listen((items) {
      if (state.isFeatureNotSupported) return;
      // A selection only means something for messages still in the list: once a
      // selected message is deleted, its id must leave the set too, or the app
      // bar stays in selection mode, counting messages nobody can see.
      final ids = items.map((item) => item.id).toSet();
      final selectedVoicemailsIds = state.selectedVoicemailsIds.where(ids.contains).toList();
      _safeEmit(
        state.copyWith(
          items: items,
          selectedVoicemailsIds: selectedVoicemailsIds,
          error: null,
          status: VoicemailStatus.loaded,
        ),
      );
      unawaited(_resolveForwarders(items));
    });

    if (!_repository.isFeatureSupported) {
      _safeEmit(state.copyWith(status: VoicemailStatus.featureNotSupported));
      return;
    }

    fetchVoicemails();
  }

  /// Puts a name to whoever forwarded each of these messages on.
  ///
  /// Detached from the list arriving rather than awaited before it: a message
  /// is worth showing at once, and the line naming the forwarder appears a
  /// moment later. Only ids not already known are looked up, so a list that
  /// changes for other reasons costs nothing.
  Future<void> _resolveForwarders(List<Voicemail> items) async {
    final unknown = items
        .map((item) => item.forwardedBy)
        .nonNulls
        .where((userId) => !state.forwarderNames.containsKey(userId))
        .toSet();
    if (unknown.isEmpty) return;

    try {
      final resolved = await _repository.resolveForwarderNames(unknown);
      if (resolved.isEmpty) return;

      _safeEmit(state.copyWith(forwarderNames: {...state.forwarderNames, ...resolved}));
    } catch (e, s) {
      // A name that could not be looked up is not worth failing a list over;
      // the tile falls back to the id and the message still reads correctly.
      _logger.warning('Error resolving voicemail forwarder names: $e', e, s);
    }
  }

  /// Says a read failed, where nothing on screen says it already.
  ///
  /// With nothing to show, the screen puts a retry in place of the list and
  /// the sentence would be the second one saying the same thing. With a list
  /// still on it, the only visible difference is that it did not change.
  void _reportFailedRead(RequestFailure? failure) {
    if (!state.isVoicemailsExists) return;

    onSubmitNotification(VoicemailRefreshFailedNotification(failure));
  }

  /// Leaves selection and re-reads whichever list is on screen.
  ///
  /// The selection was made over the trash, which is not stored, so nothing
  /// else would notice that it is no longer what it was.
  Future<void> _afterTrashChange() async {
    _safeEmit(state.copyWith(selectedVoicemailsIds: const [], status: VoicemailStatus.loaded));
    if (state.filter.isRemote) await fetchTrashedVoicemails();
  }

  /// Reads the trash again after something changed it, while it is what is on
  /// screen.
  ///
  /// It keeps no stored copy that could be corrected in place. A read like any
  /// other: it says so itself when it fails, and it cannot turn a write that
  /// already happened into one that did not.
  Future<void> _readAgainIfShowingTrash() async {
    if (state.filter.isRemote) return fetchTrashedVoicemails();

    _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
  }

  /// Safely emits a new state if the cubit is not closed.
  ///
  /// This prevents the "Bad state: Cannot emit new states after calling close"
  /// error, which can occur when asynchronous operations complete after
  /// the cubit has been closed (e.g., when a screen is disposed).
  /// What the backend answered, where it answered at all.
  ///
  /// A request that never arrived - no network, a socket that died - carries
  /// nothing worth showing anyone, so it is not carried.
  RequestFailure? _answerOf(Object error) => error is RequestFailure ? error : null;

  void _safeEmit(VoicemailState newState) {
    if (!isClosed) emit(newState);
  }
}
