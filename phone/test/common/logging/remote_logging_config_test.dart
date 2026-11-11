import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/common/logging/logging.dart';
import 'package:webtrit_phone/models/models.dart';

import '../../mocks/mocks.dart';

void main() {
  final tenantUrl = Uri.parse('https://core.example.com/tenant/t1');
  final expiresAt = DateTime.utc(2026, 11, 12);

  MobileRemoteLoggingInfo info({bool enabled = true, String? level = 'FINE', String? path = '/mobile-logs'}) =>
      MobileRemoteLoggingInfo(
        available: true,
        enabled: enabled,
        level: level,
        anonymization: false,
        expiresAt: expiresAt,
        path: path,
      );

  group('RemoteLoggingConfig.fromCore', () {
    test('takes every setting of an enabled block', () {
      final config = RemoteLoggingConfig.fromCore(info(), tenantUrl);

      expect(config.enabled, isTrue);
      expect(config.level, Level.FINE);
      expect(config.anonymization, isFalse);
      expect(config.expiresAt, expiresAt);
      expect(config.endpoint, Uri.parse('https://core.example.com/tenant/t1/mobile-logs'));
    });

    test('an absent block, a disabled one or one without a path is disabled', () {
      expect(RemoteLoggingConfig.fromCore(null, tenantUrl), RemoteLoggingConfig.disabled);
      expect(RemoteLoggingConfig.fromCore(info(enabled: false), tenantUrl), RemoteLoggingConfig.disabled);
      expect(RemoteLoggingConfig.fromCore(info(path: null), tenantUrl), RemoteLoggingConfig.disabled);
      expect(RemoteLoggingConfig.fromCore(info(path: ''), tenantUrl), RemoteLoggingConfig.disabled);
    });

    test('an unknown or missing level leaves the choice to the app', () {
      expect(RemoteLoggingConfig.fromCore(info(level: 'LOUD'), tenantUrl).level, isNull);
      expect(RemoteLoggingConfig.fromCore(info(level: null), tenantUrl).level, isNull);
      expect(RemoteLoggingConfig.fromCore(info(level: 'warning'), tenantUrl).level, Level.WARNING);
    });
  });

  group('RemoteLoggingConfig.buildEndpoint', () {
    test('appends the path to a core without a tenant', () {
      expect(
        RemoteLoggingConfig.buildEndpoint(Uri.parse('https://core.example.com'), '/mobile-logs'),
        Uri.parse('https://core.example.com/mobile-logs'),
      );
    });

    test('keeps the port and the base path, drops the query', () {
      expect(
        RemoteLoggingConfig.buildEndpoint(Uri.parse('http://10.0.0.1:4000/base/tenant/t1/?a=b'), 'mobile-logs/'),
        Uri.parse('http://10.0.0.1:4000/base/tenant/t1/mobile-logs'),
      );
    });
  });

  group('RemoteLoggingConfig.isActiveAt', () {
    final config = RemoteLoggingConfig.fromCore(info(), tenantUrl);

    test('is active before the end and not from it on', () {
      expect(config.isActiveAt(expiresAt.subtract(const Duration(seconds: 1))), isTrue);
      expect(config.isActiveAt(expiresAt), isFalse);
    });

    test('a disabled config is never active', () {
      expect(RemoteLoggingConfig.disabled.isActiveAt(DateTime.utc(2000)), isFalse);
    });
  });

  group('RemoteLoggingConfigPrefsStore', () {
    test('round-trips a config', () async {
      final prefs = MockAppPreferences();
      final store = RemoteLoggingConfigPrefsStore(prefs);
      final config = RemoteLoggingConfig.fromCore(info(), tenantUrl);

      await store.write(config);

      expect(store.read(), config);
      expect(jsonDecode(prefs.getString(RemoteLoggingConfigPrefsStore.key)!), containsPair('level', 'FINE'));
    });

    test('reads nothing from an empty or unreadable entry', () async {
      final prefs = MockAppPreferences();
      final store = RemoteLoggingConfigPrefsStore(prefs);
      expect(store.read(), isNull);

      await prefs.setString(RemoteLoggingConfigPrefsStore.key, 'not json');
      expect(store.read(), isNull);
    });
  });
}
