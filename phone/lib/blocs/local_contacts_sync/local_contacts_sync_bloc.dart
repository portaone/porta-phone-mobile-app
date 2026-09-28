import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';

part 'local_contacts_sync_event.dart';

part 'local_contacts_sync_state.dart';

final _logger = Logger('LocalContactsSyncBloc');

typedef AsyncCallback = Future<bool> Function();

class LocalContactsSyncBloc extends Bloc<LocalContactsSyncEvent, LocalContactsSyncState> {
  LocalContactsSyncBloc({
    required this.localContactsRepository,
    required this.contactsAgreementStatusRepository,
    required this.contactsRepository,
    required this.isFeatureEnabled,
    required this.isAgreementAccepted,
    required this.isContactsPermissionGranted,
    required this.requestContactPermission,
  }) : super(const LocalContactsSyncInitial()) {
    on<LocalContactsSyncStarted>(_onStarted, transformer: sequential());
    // No droppable here: a dropped event never reaches the handler that
    // completes it, and the caller of refresh() would wait forever.
    on<LocalContactsSyncRefreshed>(_onRefreshed);
    on<_LocalContactsSyncUpdated>(_onUpdated, transformer: droppable());
  }

  final LocalContactsRepository localContactsRepository;
  final ContactsRepository contactsRepository;
  final ContactsAgreementStatusRepository contactsAgreementStatusRepository;
  final AsyncCallback isFeatureEnabled;
  final AsyncCallback isAgreementAccepted;
  final AsyncCallback isContactsPermissionGranted;
  final AsyncCallback requestContactPermission;

  StreamSubscription<List<LocalContact>>? _contactsSubscription;

  /// Refreshes the device contacts and completes once the refresh is over: a
  /// gate turned it down, the load failed, or the loaded contacts were synced.
  /// The future never fails, and a bloc that closes meanwhile completes it.
  ///
  /// Await this rather than the next state: a gate that turns a refresh down
  /// re-emits a state equal to the current one, the bloc drops it, and no next
  /// state ever comes.
  Future<void> refresh() {
    if (isClosed) return Future.value();

    final event = LocalContactsSyncRefreshed();
    add(event);
    return event.completed;
  }

  void _onStarted(LocalContactsSyncStarted event, Emitter<LocalContactsSyncState> emit) async {
    _logger.finer('_onStarted');

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

    _initContactsSubscription();

    add(LocalContactsSyncRefreshed());
  }

  Future<void> _onRefreshed(LocalContactsSyncRefreshed event, Emitter<LocalContactsSyncState> emit) async {
    _logger.finer('_onRefreshed');

    try {
      await _refresh(emit);
    } finally {
      event.complete();
    }
  }

  Future<void> _refresh(Emitter<LocalContactsSyncState> emit) async {
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

    _initContactsSubscription();

    emit(const LocalContactsSyncRefreshInProgress());

    // The loaded contacts come back through the repository stream and are
    // synced by _onUpdated, so the refresh is over when the state leaves
    // progress - or when the bloc closes and the stream ends.
    final settled = stream.firstWhere((next) => next is! LocalContactsSyncRefreshInProgress, orElse: () => state);

    try {
      await localContactsRepository.load();
    } catch (error) {
      _logger.warning('_onRefreshed error: ', error);
      if (!isClosed) emit(const LocalContactsSyncRefreshFailure());
    }

    await settled;
  }

  Future<void> _onUpdated(
    _LocalContactsSyncUpdated event,
    Emitter<LocalContactsSyncState> emit, {
    int retryCount = 0,
  }) async {
    _logger.finer('_onUpdated contacts count:${event.contacts.length}');

    try {
      await contactsRepository.syncLocalContacts(event.contacts);
      if (!isClosed) emit(const LocalContactsSyncSuccess());
    } on Exception catch (e) {
      _logger.warning('_onUpdated retry: $retryCount, error: ', e);

      if (retryCount < 3) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (isClosed) return;
        await _onUpdated(event, emit, retryCount: retryCount + 1);
      } else {
        if (!isClosed) emit(const LocalContactsSyncUpdateFailure());
      }
    }
  }

  void _initContactsSubscription() {
    if (_contactsSubscription != null) return;

    _logger.info('_initContactsSubscription: subscribing to contacts stream');
    _contactsSubscription = localContactsRepository.contacts().listen((contacts) {
      if (!isClosed) add(_LocalContactsSyncUpdated(contacts: contacts));
    }, onError: (error, stackTrace) => _logger.warning('Contacts stream error', error, stackTrace));
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    return super.close();
  }
}
