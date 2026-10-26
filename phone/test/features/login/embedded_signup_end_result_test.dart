import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/login/login.dart';

// What a login page is told when its signup ends without a session is part of the page contract
// (docs/reference/custom_login.md): pages released against it read these exact values.
void main() {
  test('a signup end answers the signup the page posted on the login channel', () {
    final result = EmbeddedSignupEnd(EmbeddedSignupEndReason.deviceLimit).result;

    expect(result.toJson(), {
      'channel': 'WebtritLoginChannel',
      'event': 'signup',
      'ok': false,
      'reason': 'device_limit',
    });
  });

  test('each reason is told by its code', () {
    final reasons = {
      for (final reason in EmbeddedSignupEndReason.values) reason: EmbeddedSignupEnd(reason).result.reason,
    };

    expect(reasons, {
      EmbeddedSignupEndReason.deviceLimit: 'device_limit',
      EmbeddedSignupEndReason.deviceSwitchLimit: 'device_switch_limit',
      EmbeddedSignupEndReason.failed: 'request_failed',
      EmbeddedSignupEndReason.unsupportedBackend: 'unsupported_backend',
    });
  });
}
