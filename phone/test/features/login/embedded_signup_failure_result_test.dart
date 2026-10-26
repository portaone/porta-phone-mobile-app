import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/login/login.dart';

// What a login page is told when its signup ends without a session is part of the page contract
// (docs/reference/custom_login.md): pages released against it read these exact values.
void main() {
  test('a signup failure answers the signup the page posted on the login channel', () {
    final result = EmbeddedSignupFailure(EmbeddedSignupFailureReason.deviceLimit).result;

    expect(result.toJson(), {
      'channel': 'WebtritLoginChannel',
      'event': 'signup',
      'ok': false,
      'reason': 'device_limit',
    });
  });

  test('each reason is told by its code', () {
    final reasons = {
      for (final reason in EmbeddedSignupFailureReason.values) reason: EmbeddedSignupFailure(reason).result.reason,
    };

    expect(reasons, {
      EmbeddedSignupFailureReason.deviceLimit: 'device_limit',
      EmbeddedSignupFailureReason.deviceSwitchLimit: 'device_switch_limit',
      EmbeddedSignupFailureReason.failed: 'request_failed',
      EmbeddedSignupFailureReason.unsupportedBackend: 'unsupported_backend',
    });
  });
}
