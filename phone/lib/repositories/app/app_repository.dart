import 'dart:async';

import 'package:api/api.dart';

import 'package:webtrit_phone/app/session/session.dart';

class AppRepository {
  AppRepository({required WebtritApiClient webtritApiClient, required String token, SessionGuard? sessionGuard})
    : _sessionGuard = sessionGuard ?? const EmptySessionGuard(),
      _webtritApiClient = webtritApiClient,
      _token = token;

  final WebtritApiClient _webtritApiClient;
  final String _token;
  final SessionGuard _sessionGuard;

  Future<bool> getRegisterStatus() async {
    final appStatus = await _guarded(() => _webtritApiClient.getAppStatus(_token));
    return appStatus.register;
  }

  Future<void> setRegisterStatus(bool value) {
    return _guarded(() => _webtritApiClient.updateAppStatus(_token, AppStatus(register: value)));
  }

  /// Hands a rejected session to [_sessionGuard] and rethrows. The same three
  /// rejections as the user datasource: a missing session is a sibling of
  /// [UnauthorizedException], not a subtype, and is the one Core sends once
  /// the session is gone.
  Future<T> _guarded<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on UnauthorizedException catch (e) {
      _sessionGuard.onUnauthorized(e);
      rethrow;
    } on SessionMissingException catch (e) {
      _sessionGuard.onUnauthorized(e);
      rethrow;
    } on UserNotFoundException catch (e) {
      _sessionGuard.onUnauthorized(e);
      rethrow;
    }
  }
}
