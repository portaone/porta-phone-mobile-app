import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/login/login.dart';

void main() {
  group('sortLoginTypes', () {
    test('applies the built-in default (password first) when no config', () {
      // Input in backend-ish, "unstable" order.
      final result = sortLoginTypes([LoginType.signup, LoginType.otpSignin, LoginType.passwordSignin]);

      expect(result, [LoginType.passwordSignin, LoginType.otpSignin, LoginType.signup]);
    });

    test('is stable regardless of input order', () {
      const expected = [LoginType.passwordSignin, LoginType.otpSignin];

      expect(sortLoginTypes([LoginType.otpSignin, LoginType.passwordSignin]), expected);
      expect(sortLoginTypes([LoginType.passwordSignin, LoginType.otpSignin]), expected);
    });

    test('honours an explicit configured order', () {
      final result = sortLoginTypes(
        [LoginType.passwordSignin, LoginType.otpSignin],
        orderConfig: const ['otpSignin', 'passwordSignin'],
      );

      expect(result, [LoginType.otpSignin, LoginType.passwordSignin]);
    });

    test('ignores unknown config names and falls back to default when none valid', () {
      final result = sortLoginTypes(
        [LoginType.otpSignin, LoginType.passwordSignin],
        orderConfig: const ['nope', 'bogus'],
      );

      expect(result, [LoginType.passwordSignin, LoginType.otpSignin]);
    });

    test('keeps types missing from the config at the end, preserving relative order', () {
      final result = sortLoginTypes(
        [LoginType.signup, LoginType.otpSignin, LoginType.passwordSignin],
        orderConfig: const ['otpSignin'],
      );

      // otpSignin first (configured), then the rest in their original relative order.
      expect(result, [LoginType.otpSignin, LoginType.signup, LoginType.passwordSignin]);
    });

    test('returns empty for empty input', () {
      expect(sortLoginTypes(const []), isEmpty);
    });
  });

  group('resolveLoginTypes', () {
    const all = ['otpSignin', 'passwordSignin', 'signup'];

    test('offers what the backend advertises, in the client order', () {
      expect(resolveLoginTypes(const ['signup', 'otpSignin', 'passwordSignin', 'voicemail'], qrEnabled: false), [
        LoginType.passwordSignin,
        LoginType.otpSignin,
        LoginType.signup,
      ]);
    });

    test('adds the QR tab next to password sign-in when the app enables it', () {
      expect(resolveLoginTypes(all, qrEnabled: true), contains(LoginType.qrSignin));
      expect(resolveLoginTypes(all, qrEnabled: false), isNot(contains(LoginType.qrSignin)));
    });

    test('offers no QR tab without password sign-in, whatever the backend advertises', () {
      expect(resolveLoginTypes(const ['otpSignin', 'qrSignin'], qrEnabled: true), [LoginType.otpSignin]);
      expect(resolveLoginTypes(const ['passwordSignin', 'qrSignin'], qrEnabled: false), [LoginType.passwordSignin]);
    });

    test('shows the QR tab once when the backend advertises it too', () {
      final types = resolveLoginTypes(const ['passwordSignin', 'qrSignin'], qrEnabled: true);

      expect(types.where((type) => type == LoginType.qrSignin), hasLength(1));
    });

    test('honours the configured order', () {
      expect(resolveLoginTypes(all, qrEnabled: false, orderConfig: const ['otpSignin']).first, LoginType.otpSignin);
    });

    test('a demo offers signing up only', () {
      expect(resolveLoginTypes(all, qrEnabled: true, demo: true), [LoginType.signup]);
      expect(resolveLoginTypes(const ['passwordSignin'], qrEnabled: true, demo: true), isEmpty);
    });
  });
}
