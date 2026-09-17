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
    }
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
    }
  }

  void removeSelectedVoicemails() async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.removeMultipleVoicemails(state.selectedVoicemailsIds);
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemails');
    }
  }

  /// Puts everything picked back where it was.
  void restoreSelectedVoicemails() async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.restoreMultipleVoicemails(state.selectedVoicemailsIds);
    } catch (e, s) {
      _logger.severe('Error restoring selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreSelectedVoicemails');
    } finally {
      // Whatever happened, some of them may have moved, so the list on screen
      // is re-read rather than guessed at.
      await _afterTrashChange();
    }
  }

  /// Deletes everything picked for good.
  void removeSelectedVoicemailsPermanently() async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.removeMultipleVoicemailsPermanently(state.selectedVoicemailsIds);
    } catch (e, s) {
      _logger.severe('Error permanently removing selected voicemails: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeSelectedVoicemailsPermanently');
    } finally {
      await _afterTrashChange();
    }
  }

  /// Leaves selection and re-reads whichever list is on screen.
  ///
  /// The selection was made over the trash, which is not stored, so nothing
  /// else would notice that it is no longer what it was.
  Future<void> _afterTrashChange() async {
    _safeEmit(state.copyWith(selectedVoicemailsIds: const [], status: VoicemailStatus.loaded));
    if (state.filter.isRemote) await fetchTrashedVoicemails();
  }

  /// Deletes a message, which means the trash where there is one.
  ///
  /// Answers whether the server took it. The caller needs to know because a
  /// move to the trash is offered back afterwards, and offering to undo
  /// something that never happened is worse than saying nothing.
  /// The card of whoever left [voicemail], or null when the address book no
  /// longer knows them.
  ///
  /// Looked up when it is asked for rather than carried on every message: the
  /// tile already knows a contact exists, because it is showing that person's
  /// name, and what it does not have is the row's id. One query on a
  /// deliberate tap against a column and a mapping on every message ever
  /// listed.
  Future<Contact?> callerOf(Voicemail voicemail) => _contactsRepository.getContactByPhoneNumber(voicemail.sender);

  Future<bool> removeVoicemail(String messageId) async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.removeVoicemail(messageId);
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      return true;
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error removing voicemail with id $messageId: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemail');
      return false;
    }
  }

  /// Puts a trashed message back where it was.
  ///
  /// Also what undoing a move to the trash does, because it is the same thing:
  /// the message is in the trash either way, and the only difference is how
  /// long it has been there.
  Future<void> restoreVoicemail(String messageId) async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.restoreVoicemail(messageId);
      // The restored message is gone from the trash and back in the mailbox.
      // The mailbox refreshes itself through the repository; the trash has no
      // stored copy to update, so it is re-read when it is what is on screen.
      if (state.filter.isRemote) {
        await fetchTrashedVoicemails();
      } else {
        _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      }
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error restoring voicemail with id $messageId: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.restoreVoicemail');
    }
  }

  /// Deletes a message for good, wherever it is.
  ///
  /// The only per-message action that frees the space it occupies; moving one
  /// to the trash does not.
  Future<void> removeVoicemailPermanently(String messageId) async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.removeVoicemailPermanently(messageId);
      if (state.filter.isRemote) {
        await fetchTrashedVoicemails();
      } else {
        _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      }
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error permanently removing voicemail with id $messageId: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.removeVoicemailPermanently');
    }
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
    }
  }

  void toggleSeenStatus(Voicemail voicemail) async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      final markAsSeen = !voicemail.status.isRead;
      await _repository.updateVoicemailSeenStatus(voicemail.id, markAsSeen);
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error toggling seen status for voicemail with id ${voicemail.id}: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSeenStatus');
    }
  }

  /// Keeps [voicemail], or stops keeping it.
  ///
  /// Independent of whether it has been heard, in both directions: keeping a
  /// message does not mark it read, and reading one does not stop it being
  /// kept.
  void toggleSavedStatus(Voicemail voicemail) async {
    try {
      _safeEmit(state.copyWith(status: VoicemailStatus.loading));
      await _repository.updateVoicemailSavedStatus(voicemail.id, !(voicemail.saved ?? false));
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
    } catch (e, s) {
      _safeEmit(state.copyWith(status: VoicemailStatus.loaded));
      _logger.severe('Error toggling saved status for voicemail with id ${voicemail.id}: $e', e, s);
      CrashlyticsUtils.recordError(e, stack: s, reason: 'VoicemailCubit.toggleSavedStatus');
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

  /// Safely emits a new state if the cubit is not closed.
  ///
  /// This prevents the "Bad state: Cannot emit new states after calling close"
  /// error, which can occur when asynchronous operations complete after
  /// the cubit has been closed (e.g., when a screen is disposed).
  void _safeEmit(VoicemailState newState) {
    if (!isClosed) emit(newState);
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
