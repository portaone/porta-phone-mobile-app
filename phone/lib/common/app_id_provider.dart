import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:durable_device_id/durable_device_id.dart';
import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import 'disposable.dart';

const _appIdKey = 'app_id_key';

// Where the saved app id came from. Absent for an id saved by a version that
// knew one source only.
const _appIdSourceKey = 'app_id_source_key';
const _appIdSourceDevice = 'device';
const _appIdSourceFallback = 'fallback';

final Logger _logger = Logger('AppIdProvider');

/// Abstract class for providing app ID. It supports fetching the ID and listening for changes in the ID.
abstract class AppIdProvider {
  Future<String> getId();

  Stream<String> get onIdChange;
}

/// Implementation of AppIdProvider using Firebase installations service.
/// This provider retrieves the Firebase installation ID and handles changes in the ID.
class FirebaseAppIdProvider implements AppIdProvider, Disposable {
  final _idChangeController = StreamController<String>.broadcast();
  late final StreamSubscription<String> _idChangeSubscription;

  FirebaseAppIdProvider() {
    _initializeIdListener();
  }

  @override
  Future<String> getId() async {
    try {
      final future = FirebaseInstallations.instance.getId();
      // On web a misconfigured Installations promise can never settle, which would
      // hang bootstrap forever (the catch below never fires). Bound it so we fall
      // back to a locally generated id instead of blocking startup.
      final id = await (kIsWeb ? future.timeout(const Duration(seconds: 5)) : future);
      await _saveIdToSharedPreferences(id);
      return id;
    } catch (e) {
      _logger.severe('Firebase ID fetch failed: $e');
      return _generateFallbackId();
    }
  }

  @override
  Stream<String> get onIdChange => _idChangeController.stream;

  void _initializeIdListener() {
    // Persist a rotated installation id and republish it to listeners; onError
    // keeps a transient stream error from escaping to the zone.
    _idChangeSubscription = FirebaseInstallations.instance.onIdChange.listen((id) async {
      await _saveIdToSharedPreferences(id);
      _idChangeController.add(id);
      _logger.info('Firebase ID changed: $id');
    }, onError: (Object e, StackTrace s) => _logger.warning('Firebase onIdChange stream error', e, s));
  }

  Future<void> _saveIdToSharedPreferences(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appIdKey, id);
  }

  Future<String> _generateFallbackId() async {
    final prefs = await SharedPreferences.getInstance();

    // Reuse a previously stored id so the fallback identifier stays stable across
    // restarts/reloads (important on web, where getId() may keep timing out);
    // generate a fresh one only on first use.
    final existing = prefs.getString(_appIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final newId = _generateRandomId();
    await prefs.setString(_appIdKey, newId);
    _logger.info('Generated fallback ID: $newId');
    return newId;
  }

  String _generateRandomId([int length = 32]) {
    final random = Random();
    return String.fromCharCodes(List.generate(length, (index) => random.nextInt(26) + 97));
  }

  @override
  Future<void> dispose() async {
    await _idChangeSubscription.cancel();
    await _idChangeController.close();
  }
}

/// The app id taken from the device, so that it is the same after the app is
/// removed and installed again.
///
/// The backend tells devices apart by this id, and counts them: an account may
/// be limited in how many devices it is signed in on and in how many new ones
/// it starts using. An id kept only in the app's own data made every reinstall
/// a new device.
///
/// The id is resolved once and does not change while the app runs. It is saved
/// to SharedPreferences, where [SharedPreferencesAppIdProvider] reads it in the
/// other isolates.
class DeviceAppIdProvider implements AppIdProvider, Disposable {
  DeviceAppIdProvider({
    required AppIdProvider Function() fallback,
    DurableDeviceId deviceId = const PlatformDurableDeviceId(),
  }) : _createFallback = fallback,
       _deviceId = deviceId;

  final DurableDeviceId _deviceId;
  final AppIdProvider Function() _createFallback;

  // Created only when the device has no id to give: the Firebase provider
  // rewrites the saved id whenever Firebase replaces its own, and that must not
  // happen to an id taken from the device.
  AppIdProvider? _fallback;

  @override
  Future<String> getId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_appIdKey);
    final source = prefs.getString(_appIdSourceKey);

    if (saved != null && saved.isNotEmpty && source == null) {
      return _idKeptByEarlierVersion(saved);
    }

    // Asked on every start, not only on the first: what is saved travels with a
    // backup to another phone, and what the device answers does not.
    final deviceId = await _deviceId.read();
    if (deviceId != null) {
      if (deviceId != saved || source != _appIdSourceDevice) {
        await prefs.setString(_appIdKey, deviceId);
        await prefs.setString(_appIdSourceKey, _appIdSourceDevice);
        _logger.info('App id taken from the device');
      }
      return deviceId;
    }

    if (saved != null && saved.isNotEmpty && source == _appIdSourceDevice) {
      // The device cannot answer right now - an iPhone before its first unlock -
      // and it did before: this install goes on being the device it was.
      return saved;
    }

    _logger.info('The device has no id to give, falling back');
    final fallbackId = await (_fallback ??= _createFallback()).getId();
    // Marked, so that the next start asks the device again instead of taking
    // this id for one an earlier version left.
    await prefs.setString(_appIdSourceKey, _appIdSourceFallback);
    return fallbackId;
  }

  /// Emits only on the fallback: an id taken from the device, or kept from an
  /// earlier version, does not change while the app runs.
  @override
  Stream<String> get onIdChange => _fallback?.onIdChange ?? const Stream.empty();

  /// The id this install already goes by.
  ///
  /// An install made before the id was taken from the device is known to the
  /// backend under the id it generated then. Sending another one from the same
  /// phone would make it a new device there, so that id stays for as long as it
  /// is still saved, and the device id is used from the first clean install on.
  /// Such an id is told by having nothing saved about where it came from.
  @Deprecated(
    'Kept since 1.18.0 for installs made by an earlier version. Removing it moves every such install '
    'that was never reinstalled to the device id at once: one more device, and one device switch, per install.',
  )
  String _idKeptByEarlierVersion(String saved) => saved;

  @override
  Future<void> dispose() async {
    final fallback = _fallback;
    if (fallback case final Disposable disposable) await disposable.dispose();
  }
}

/// AppIdProvider implementation using SharedPreferences. This is used when the app ID is already provided
/// in the main isolate and is shared across other isolates for consistency.
class SharedPreferencesAppIdProvider implements AppIdProvider {
  const SharedPreferencesAppIdProvider();

  @override
  Future<String> getId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_appIdKey) ?? 'Undefine';
    } catch (e) {
      _logger.severe(e);
      return 'Undefine';
    }
  }

  @override
  Stream<String> get onIdChange => const Stream.empty();
}
