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
    on<LocalContactsSyncRefreshed>(_onRefreshed, transformer: droppable());
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

  final _refreshWaiters = <Completer<void>>[];
  bool _refreshRunning = false;

  /// Refreshes the device contacts and completes once the refresh has settled.
  ///
  /// Settled means no refresh is running and the state is no longer
  /// [LocalContactsSyncRefreshInProgress]: a gate turned the refresh down, the
  /// load failed, or the loaded contacts were synced. A call made while a
  /// refresh runs joins it, the way the droppable handler folds its event into
  /// the running one. The future never fails, and it completes on [close].
  ///
  /// Wait on this rather than on the next state: a gate that turns a refresh
  /// down re-emits a state equal to the current one, the bloc drops it, and no
  /// next state ever comes.
  Future<void> refresh() {
    if (isClosed) return Future.value();

    final waiter = Completer<void>();
    _refreshWaiters.add(waiter);
    add(const LocalContactsSyncRefreshed());
    return waiter.future;
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

    add(const LocalContactsSyncRefreshed());
  }

  void _onRefreshed(LocalContactsSyncRefreshed event, Emitter<LocalContactsSyncState> emit) async {
    _logger.finer('_onRefreshed');

    _refreshRunning = true;
    try {
      await _refresh(emit);
    } finally {
      _refreshRunning = false;
      _settleRefreshWaiters(state);
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
    try {
      await localContactsRepository.load();
    } catch (error) {
      _logger.warning('_onRefreshed error: ', error);
      if (!isClosed) emit(const LocalContactsSyncRefreshFailure());
    }
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

  void _settleRefreshWaiters(LocalContactsSyncState state) {
    if (_refreshRunning || state is LocalContactsSyncRefreshInProgress) return;
    _completeRefreshWaiters();
  }

  void _completeRefreshWaiters() {
    final waiters = List.of(_refreshWaiters);
    _refreshWaiters.clear();
    for (final waiter in waiters) {
      waiter.complete();
    }
  }

  @override
  void onChange(Change<LocalContactsSyncState> change) {
    super.onChange(change);
    // Runs before the state is updated, so the new state has to be passed in.
    _settleRefreshWaiters(change.nextState);
  }

  @override
  Future<void> close() {
    _contactsSubscription?.cancel();
    _completeRefreshWaiters();
    return super.close();
  }
}
