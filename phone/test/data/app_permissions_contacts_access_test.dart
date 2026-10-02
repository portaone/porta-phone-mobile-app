import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/data/app_permissions.dart';
import 'package:webtrit_phone/models/models.dart';

// The wire values permission_handler's method channel answers with.
const _denied = 0;
const _granted = 1;
const _restricted = 2;
const _limited = 3;
const _permanentlyDenied = 4;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  void answerWith(int status) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'checkPermissionStatus');
      return status;
    });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<AppPermissions> permissions() => AppPermissions.init(() => const []);

  test('a selection of contacts is access to read them', () async {
    answerWith(_limited);
    final appPermissions = await permissions();

    expect(await appPermissions.contactsAccess(), ContactsAccess.selected);
    expect(await appPermissions.isContactPermissionGranted(), isTrue);
  });

  test('full access reads the whole address book', () async {
    answerWith(_granted);
    final appPermissions = await permissions();

    expect(await appPermissions.contactsAccess(), ContactsAccess.all);
    expect(await appPermissions.isContactPermissionGranted(), isTrue);
  });

  for (final (name, status) in [
    ('not asked or refused', _denied),
    ('restricted by the device', _restricted),
    ('refused for good', _permanentlyDenied),
  ]) {
    test('$name is no access', () async {
      answerWith(status);
      final appPermissions = await permissions();

      expect(await appPermissions.contactsAccess(), ContactsAccess.none);
      expect(await appPermissions.isContactPermissionGranted(), isFalse);
    });
  }
}
