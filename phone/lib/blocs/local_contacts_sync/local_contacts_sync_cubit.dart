import 'dart:async';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

part 'local_contacts_sync_state.dart';

final _logger = Logger('LocalContactsSyncCubit');

/// Owns the complete device-contacts read and store update, including retries.
class LocalContactsSyncCubit extends Cubit<LocalContactsSyncState> {
  LocalContactsSyncCubit({
    required this.localContactsRepository,
    required this.contactsRepository,
    required this.isFeatureEnabled,
    required this.isAgreementAccepted,
    required this.isContactsPermissionGranted,
  }) : super(const LocalContactsSyncInitial());

  final ILocalContactsRepository localContactsRepository;
  final ContactsRepository contactsRepository;
  final Future<bool> Function() isFeatureEnabled;
  final Future<bool> Function() isAgreementAccepted;
  final Future<bool> Function() isContactsPermissionGranted;

  StreamSubscription<void>? _contactsSubscription;
  CancelableOperation<void>? _inFlight;

  // A device change during a cycle invalidates its snapshot. Manual callers
  // only join the cycle; a device change requires another read afterwards.
  bool _refreshRequested = false;

  /// Refreshes through the store commit, or completes when a gate refuses the
  /// attempt, the operation fails, or this cubit closes. Failures are reported
  /// through state; this future does not throw, including for background calls.
  /// Concurrent callers share the cycle and any pending device-change reread.
  Future<void> refresh() {
    if (isClosed) return Future<void>.value();

    final operation = _inFlight ??= CancelableOperation.fromFuture(
      // Install _inFlight before invoking dependencies that can notify us back.
      Future<void>.microtask(_refreshUntilCurrent),
    );
    return operation.valueOrCancellation();
  }

  Future<void> _refreshUntilCurrent() async {
    try {
      do {
        _refreshRequested = false;
        if (isClosed) return;
        await _refresh();
      } while (_refreshRequested && !isClosed);
    } finally {
      // Clear before completing the operation, so a new invalidation cannot
      // join a finished cycle and lose the requested reread.
      _inFlight = null;
    }
  }

  Future<void> _refresh() async {
    try {
      final featureEnabled = await isFeatureEnabled();
      if (isClosed) return;
      if (!featureEnabled) {
        emit(const ContactsFeatureDisabledException());
        return;
      }

      final agreementAccepted = await isAgreementAccepted();
      if (isClosed) return;
      if (!agreementAccepted) {
        emit(const ContactsAgreementMissingException());
        return;
      }

      final permissionGranted = await isContactsPermissionGranted();
      if (isClosed) return;
      if (!permissionGranted) {
        emit(const LocalContactsSyncPermissionFailure());
        return;
      }

      _contactsSubscription ??= localContactsRepository.watchChanges().listen(
        _onContactsChanged,
        onError: _onContactsError,
      );

      emit(const LocalContactsSyncRefreshInProgress());
      final contacts = await localContactsRepository.fetchContacts();
      if (isClosed) return;
      await _syncContacts(contacts);
    } catch (error, stackTrace) {
      _logger.warning('refresh failed', error, stackTrace);
      if (!isClosed) emit(const LocalContactsSyncRefreshFailure());
    }
  }

  Future<void> _syncContacts(List<LocalContact> contacts) async {
    for (var attempt = 0; attempt < 4; attempt++) {
      if (isClosed) return;
      try {
        await contactsRepository.syncLocalContacts(contacts);
        if (!isClosed) emit(const LocalContactsSyncSuccess());
        return;
      } catch (error, stackTrace) {
        _logger.warning('store update failed, attempt ${attempt + 1}', error, stackTrace);
        if (isClosed) return;
        if (attempt == 3) {
          emit(const LocalContactsSyncUpdateFailure());
          return;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }

  void _onContactsChanged(void _) {
    if (isClosed) return;
    _refreshRequested = true;
    if (_inFlight == null) unawaited(refresh());
  }

  void _onContactsError(Object error, StackTrace stackTrace) {
    _logger.warning('Contacts change stream failed', error, stackTrace);
  }

  @override
  Future<void> close() async {
    // Mark closed before cancellation: native I/O may still complete, but it
    // must not start another write or emit. Already-started writes may finish.
    final closed = super.close();
    try {
      await _inFlight?.cancel();
      await _contactsSubscription?.cancel();
    } finally {
      await closed;
    }
  }
}
