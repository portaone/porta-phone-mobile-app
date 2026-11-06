import 'package:flutter_test/flutter_test.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/repositories/push_tokens/push_tokens_repository.dart';

void main() {
  group('pushTokenEnv', () {
    test('an APNs token takes the environment the build was signed for', () {
      for (final type in [AppPushTokenType.apkvoip, AppPushTokenType.apns]) {
        expect(pushTokenEnv(type, apsEnvironment: 'development', debug: false), AppPushTokenEnv.dev);
        expect(pushTokenEnv(type, apsEnvironment: 'production', debug: true), AppPushTokenEnv.prod);
      }
    });

    test('a development-signed release build registers a sandbox token as dev', () {
      expect(pushTokenEnv(AppPushTokenType.apkvoip, apsEnvironment: 'development', debug: false), AppPushTokenEnv.dev);
    });

    test('without the signed environment a debug build is dev and any other prod', () {
      expect(pushTokenEnv(AppPushTokenType.apkvoip, apsEnvironment: null, debug: true), AppPushTokenEnv.dev);
      expect(pushTokenEnv(AppPushTokenType.apkvoip, apsEnvironment: null, debug: false), AppPushTokenEnv.prod);
      expect(pushTokenEnv(AppPushTokenType.apns, apsEnvironment: 'unknown', debug: false), AppPushTokenEnv.prod);
    });

    test('an FCM token carries no environment', () {
      expect(pushTokenEnv(AppPushTokenType.fcm, apsEnvironment: 'development', debug: true), isNull);
    });
  });
}
