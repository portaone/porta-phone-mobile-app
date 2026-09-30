import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/crashlytics_utils.dart';

final _logger = Logger('RegisterStatusCubit');

class RegisterStatus {
  const RegisterStatus({required this.value, this.isUpdating = false});

  final bool value;
  final bool isUpdating;

  RegisterStatus copyWith({bool? value, bool? isUpdating}) =>
      RegisterStatus(value: value ?? this.value, isUpdating: isUpdating ?? this.isUpdating);
}

class RegisterStatusCubit extends Cubit<RegisterStatus> {
  RegisterStatusCubit(this.appRepository, this.registerStatusRepository)
    : super(RegisterStatus(value: registerStatusRepository.getRegisterStatus())) {
    fetchStatus();
    _connectivitySub = Connectivity().onConnectivityChanged.listen(_handleConnectivity);
  }

  final AppRepository appRepository;
  final RegisterStatusRepository registerStatusRepository;

  late final StreamSubscription _connectivitySub;

  void _handleConnectivity(List<ConnectivityResult> results) {
    if (results.any((result) => result != ConnectivityResult.none)) fetchStatus();
  }

  /// Returns whether the fetched value reached the state, so an explicit
  /// user-triggered refresh can report a failure instead of silently keeping
  /// the stale value.
  ///
  /// A rejected session is not handled here: the shell's API client reports
  /// it, and the shell logs out.
  Future<bool> fetchStatus() async {
    final bool status;
    try {
      status = await appRepository.getRegisterStatus();
      await registerStatusRepository.setRegisterStatus(status);
    } catch (e, s) {
      _reportFailure('Failed to get register status', 'RegisterStatusCubit.fetchStatus', e, s);
      return false;
    }
    // The shell closes this cubit on logout, and a request already sent still
    // completes afterwards.
    if (isClosed) return false;
    emit(RegisterStatus(value: status));
    return true;
  }

  /// Returns whether the change was accepted by the server. On failure the
  /// previous value is restored, so the caller must tell the user why the
  /// switch snapped back.
  Future<bool> setStatus(bool value) async {
    emit(RegisterStatus(value: value, isUpdating: true));
    var accepted = true;
    try {
      await appRepository.setRegisterStatus(value);
      await registerStatusRepository.setRegisterStatus(value);
    } catch (e, s) {
      _reportFailure('_onRegisterStatusChanged', 'RegisterStatusCubit.setStatus', e, s);
      accepted = false;
    }
    if (isClosed) return accepted;
    emit(RegisterStatus(value: accepted ? value : !value, isUpdating: false));
    return accepted;
  }

  void _reportFailure(String message, String reason, Object error, StackTrace stackTrace) {
    _logger.warning(message, error, stackTrace);
    if (!_isTransientNetworkError(error)) {
      CrashlyticsUtils.recordError(error, stack: stackTrace, reason: reason);
    }
  }

  bool _isTransientNetworkError(Object error) =>
      error is SocketException || error is TimeoutException || error is TlsException;

  @override
  Future<void> close() {
    _connectivitySub.cancel();
    return super.close();
  }
}
