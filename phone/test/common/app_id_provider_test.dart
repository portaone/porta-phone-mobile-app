import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:durable_device_id/durable_device_id.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/data/data.dart';

const _appIdKey = 'app_id_key';
const _appIdSourceKey = 'app_id_source_key';

class _DeviceId implements DurableDeviceId {
  _DeviceId(this.id);

  final String? id;
  int reads = 0;

  @override
  Future<String?> read() async {
    reads++;
    return id;
  }
}

class _Fallback implements AppIdProvider, Disposable {
  final controller = StreamController<String>.broadcast();
  var disposed = false;

  @override
  Future<String> getId() async => 'fallback-id';

  @override
  Stream<String> get onIdChange => controller.stream;

  @override
  Future<void> dispose() async {
    disposed = true;
    await controller.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<_Fallback> fallbacks;

  DeviceAppIdProvider providerWith(_DeviceId deviceId) {
    return DeviceAppIdProvider(
      deviceId: deviceId,
      fallback: () {
        final fallback = _Fallback();
        fallbacks.add(fallback);
        return fallback;
      },
    );
  }

  Future<String?> savedId() async => (await SharedPreferences.getInstance()).getString(_appIdKey);

  setUp(() {
    fallbacks = [];
    SharedPreferences.setMockInitialValues({});
  });

  group('a clean install', () {
    test('takes the id from the device', () async {
      final provider = providerWith(_DeviceId('device-id'));

      expect(await provider.getId(), 'device-id');
    });

    test('saves it where the other isolates read it', () async {
      await providerWith(_DeviceId('device-id')).getId();

      expect(await savedId(), 'device-id');
      expect(await const SharedPreferencesAppIdProvider().getId(), 'device-id');
    });

    test('does not create the fallback', () async {
      await providerWith(_DeviceId('device-id')).getId();

      expect(fallbacks, isEmpty);
    });

    test('never reports a change of the id', () async {
      final provider = providerWith(_DeviceId('device-id'));
      await provider.getId();

      expect(await provider.onIdChange.isEmpty, isTrue);
    });
  });

  group('an install that took its id from the device', () {
    Future<void> firstStartOn(String deviceId) => providerWith(_DeviceId(deviceId)).getId();

    test('gives the same id on the next start', () async {
      await firstStartOn('device-id');

      expect(await providerWith(_DeviceId('device-id')).getId(), 'device-id');
    });

    test('asks the device again on every start', () async {
      await firstStartOn('device-id');
      final deviceId = _DeviceId('device-id');

      await providerWith(deviceId).getId();

      expect(deviceId.reads, 1);
    });

    test('restored on another phone takes the id of that phone', () async {
      // What is saved travels with a backup; what the device answers does not.
      await firstStartOn('id-of-the-first-phone');

      expect(await providerWith(_DeviceId('id-of-the-second-phone')).getId(), 'id-of-the-second-phone');
      expect(await savedId(), 'id-of-the-second-phone');
    });

    test('keeps its id while the device cannot answer', () async {
      // An iPhone started before its first unlock cannot read the Keychain.
      await firstStartOn('device-id');

      expect(await providerWith(_DeviceId(null)).getId(), 'device-id');
      expect(fallbacks, isEmpty);
    });
  });

  group('an install made by an earlier version', () {
    setUp(() => SharedPreferences.setMockInitialValues({_appIdKey: 'id-the-backend-knows'}));

    test('keeps the id it already goes by', () async {
      final deviceId = _DeviceId('device-id');

      expect(await providerWith(deviceId).getId(), 'id-the-backend-knows');
      expect(await savedId(), 'id-the-backend-knows');
    });

    test('keeps it on every later start too', () async {
      await providerWith(_DeviceId('device-id')).getId();

      expect(await providerWith(_DeviceId('device-id')).getId(), 'id-the-backend-knows');
    });

    test('asks neither the device nor the fallback', () async {
      final deviceId = _DeviceId('device-id');

      await providerWith(deviceId).getId();

      expect(deviceId.reads, 0);
      expect(fallbacks, isEmpty);
    });

    test('never reports a change of the id', () async {
      final provider = providerWith(_DeviceId('device-id'));
      await provider.getId();

      expect(await provider.onIdChange.isEmpty, isTrue);
    });

    test('an empty saved id is no id', () async {
      SharedPreferences.setMockInitialValues({_appIdKey: ''});

      expect(await providerWith(_DeviceId('device-id')).getId(), 'device-id');
    });
  });

  group('a device with no id to give', () {
    test('falls back', () async {
      final provider = providerWith(_DeviceId(null));

      expect(await provider.getId(), 'fallback-id');
      expect(fallbacks, hasLength(1));
    });

    test('does not save an id of its own: that is the business of the fallback', () async {
      await providerWith(_DeviceId(null)).getId();

      expect(await savedId(), isNull);
    });

    test('creates the fallback once', () async {
      final provider = providerWith(_DeviceId(null));

      await provider.getId();
      await provider.getId();

      expect(fallbacks, hasLength(1));
    });

    test('reports the changes the fallback reports', () async {
      final provider = providerWith(_DeviceId(null));
      await provider.getId();

      final changes = <String>[];
      final subscription = provider.onIdChange.listen(changes.add);
      fallbacks.single.controller.add('replaced-id');
      await pumpEventQueue();
      await subscription.cancel();

      expect(changes, ['replaced-id']);
    });

    test('is asked again on the next start, and its id is taken once it has one', () async {
      // The fallback saves its id under the same key; it must not be taken
      // for an id an earlier version left.
      await providerWith(_DeviceId(null)).getId();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appIdKey, 'fallback-id');

      expect(await providerWith(_DeviceId('device-id')).getId(), 'device-id');
      expect(await savedId(), 'device-id');
    });

    test('falls back again on the next start while it still has none', () async {
      await providerWith(_DeviceId(null)).getId();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appIdKey, 'fallback-id');

      expect(await providerWith(_DeviceId(null)).getId(), 'fallback-id');
      expect((await SharedPreferences.getInstance()).getString(_appIdSourceKey), 'fallback');
    });
  });

  group('dispose', () {
    test('releases the fallback it created', () async {
      final provider = providerWith(_DeviceId(null));
      await provider.getId();

      await provider.dispose();

      expect(fallbacks.single.disposed, isTrue);
    });

    test('has nothing to release when the id came from the device', () async {
      final provider = providerWith(_DeviceId('device-id'));
      await provider.getId();

      await provider.dispose();

      expect(fallbacks, isEmpty);
    });
  });

  test('AppInfo carries the id of the device', () async {
    final appInfo = await AppInfo.init(providerWith(_DeviceId('device-id')));
    addTearDown(appInfo.dispose);

    expect(appInfo.identifier, 'device-id');
  });
}
