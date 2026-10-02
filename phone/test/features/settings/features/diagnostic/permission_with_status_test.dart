import 'package:flutter_test/flutter_test.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:webtrit_phone/features/settings/features/diagnostic/models/models.dart';

void main() {
  test('a selection of contacts is a working permission and reads as granted', () {
    final contacts = PermissionWithStatus(Permission.contacts, PermissionStatus.limited);

    expect(contacts.isWorking, isTrue);
    expect(contacts.severity, PermissionStatus.granted);
  });

  test('a limited grant of anything else keeps its own status', () {
    final camera = PermissionWithStatus(Permission.camera, PermissionStatus.limited);

    expect(camera.isWorking, isFalse);
    expect(camera.severity, PermissionStatus.limited);
  });

  test('a refusal is never working', () {
    final contacts = PermissionWithStatus(Permission.contacts, PermissionStatus.permanentlyDenied);

    expect(contacts.isWorking, isFalse);
    expect(contacts.severity, PermissionStatus.permanentlyDenied);
  });
}
