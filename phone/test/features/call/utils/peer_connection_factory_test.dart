import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/utils/peer_connection_factory.dart';
import 'package:webtrit_phone/models/models.dart';

void main() {
  IceServersConfig configWith({List<String> anchors = const []}) => IceServersConfig(
    servers: const [
      {
        'urls': ['turns:turn.example.com:5349'],
        'username': 'user',
        'credential': 'secret',
      },
    ],
    expiresAt: DateTime.utc(2030),
    trustedCertificates: anchors,
  );

  const anchor = '-----BEGIN CERTIFICATE-----\nanchor\n-----END CERTIFICATE-----';

  group('rtcConfigurationFrom', () {
    test('carries the anchors the deployment serves, as bytes', () {
      final rendered = rtcConfigurationFrom(configWith(anchors: [anchor]));

      expect(rendered['trustedCertificates'], hasLength(1));
      expect(utf8.decode((rendered['trustedCertificates'] as List).first as List<int>), anchor);
    });

    test('omits the key entirely when the deployment serves none', () {
      // An empty list must not reach the plugin: a verifier with no anchor of
      // its own replaces the library's verdict and would refuse what the
      // built-in root list accepts.
      final rendered = rtcConfigurationFrom(configWith());

      expect(rendered.containsKey('trustedCertificates'), isFalse);
    });

    test('passes the servers through untouched', () {
      final rendered = rtcConfigurationFrom(configWith(anchors: [anchor]));
      final server = (rendered['iceServers'] as List).single as Map<String, dynamic>;

      expect(server['urls'], ['turns:turn.example.com:5349']);
      expect(server['username'], 'user');
      expect(server['credential'], 'secret');
    });

    test('falls back to the public STUN server when the deployment offers none', () {
      final rendered = rtcConfigurationFrom(IceServersConfig(servers: const [], expiresAt: DateTime.utc(2030)));

      expect(rendered['iceServers'], kFallbackRtcIceServers);
    });
  });
}
