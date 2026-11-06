import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/data/aps_environment.dart';

class PushTokensRepository {
  PushTokensRepository({
    required WebtritApiClient webtritApiClient,
    required String token,
    Future<String?> Function() apsEnvironment = ApsEnvironment.read,
  }) : _webtritApiClient = webtritApiClient,
       _token = token,
       _apsEnvironment = apsEnvironment;

  final WebtritApiClient _webtritApiClient;
  final String _token;
  final Future<String?> Function() _apsEnvironment;

  Future<void> insertOrUpdatePushToken(AppPushTokenType type, String value) async {
    final env = pushTokenEnv(type, apsEnvironment: await _apsEnvironment(), debug: kDebugMode);
    var appPushToken = AppPushToken(type: type, value: value, env: env);

    return await _webtritApiClient.createAppPushToken(_token, appPushToken);
  }
}

/// The environment a push token of [type] is registered with. An APNs token - VoIP or not - is
/// good only in the APNs environment of the build that issued it, which the build's
/// `aps-environment` names ([apsEnvironment]): a development-signed release build, as the stand
/// builds are, issues sandbox tokens. When it is not known, a debug build is taken for development
/// and any other for production. FCM tokens carry no environment: FCM handles it.
@visibleForTesting
AppPushTokenEnv? pushTokenEnv(AppPushTokenType type, {required String? apsEnvironment, required bool debug}) {
  if (type != AppPushTokenType.apkvoip && type != AppPushTokenType.apns) return null;
  return switch (apsEnvironment) {
    'development' => AppPushTokenEnv.dev,
    'production' => AppPushTokenEnv.prod,
    _ => debug ? AppPushTokenEnv.dev : AppPushTokenEnv.prod,
  };
}
