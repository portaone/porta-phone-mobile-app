import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:api/api.dart';

class PushTokensRepository {
  PushTokensRepository({required WebtritApiClient webtritApiClient, required String token})
    : _webtritApiClient = webtritApiClient,
      _token = token;

  final WebtritApiClient _webtritApiClient;
  final String _token;

  Future<void> insertOrUpdatePushToken(AppPushTokenType type, String value) async {
    // If you launch the app in debug mode, then you definetely want to use dev environment for push tokens
    // Alternatively you can use ios entitlements from native part, but use kDebugMode is just simpler and cover 99% dev cases
    //
    // fcm on ios handles dev/prod automatically, so we don't need to worry about that
    final env = switch ((type, kDebugMode)) {
      (AppPushTokenType.apkvoip, true) => AppPushTokenEnv.dev,
      (AppPushTokenType.apkvoip, false) => AppPushTokenEnv.prod,
      (AppPushTokenType.apns, true) => AppPushTokenEnv.dev,
      (AppPushTokenType.apns, false) => AppPushTokenEnv.prod,
      _ => null,
    };

    var appPushToken = AppPushToken(type: type, value: value, env: env);

    return await _webtritApiClient.createAppPushToken(_token, appPushToken);
  }
}
