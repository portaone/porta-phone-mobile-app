import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/models/models.dart';

/// Supplies the ICE servers for a peer connection about to be created.
///
/// Resolved per connection rather than captured once, so a connection created
/// after the deployment's TURN credentials were renewed uses the new ones.
typedef IceServersResolver = Future<IceServersConfig> Function();

/// Renders the deployment's configuration as the map `createPeerConnection`
/// takes.
///
/// [IceServersConfig.trustedCertificates] becomes `trustedCertificates`, which
/// the plugin installs as an Android `SSLCertificateVerifier` for `turns:`.
/// libwebrtc otherwise verifies against a root list compiled into itself, and
/// that list carries no Let's Encrypt root, so a TURN server secured that way
/// is refused with `unknown_ca` and no relay candidate is ever gathered.
///
/// The key is written only when the deployment sent certificates. An empty list
/// must not reach the plugin: a verifier holding no anchor of its own REPLACES
/// the library's verdict and would refuse what the built-in list accepts.
Map<String, dynamic> rtcConfigurationFrom(IceServersConfig config) => <String, dynamic>{
  'iceServers': config.servers.isEmpty ? kFallbackRtcIceServers : config.servers,
  if (config.trustedCertificates.isNotEmpty)
    'trustedCertificates': config.trustedCertificates.map((pem) => Uint8List.fromList(utf8.encode(pem))).toList(),
};

/// Abstract factory to create [RTCPeerConnection] instances.
abstract interface class PeerConnectionFactory {
  Future<RTCPeerConnection> create([
    Map<String, dynamic> configuration = const {},
    Map<String, dynamic> constraints = const {},
  ]);
}

/// Default implementation using the actual Flutter WebRTC plugin.
class DefaultPeerConnectionFactory implements PeerConnectionFactory {
  static const Map<String, dynamic> _defaultIceConfiguration = {'iceServers': kFallbackRtcIceServers};

  final Map<String, dynamic> _defaultConfiguration;
  final IceServersResolver? _iceServersResolver;

  const DefaultPeerConnectionFactory({
    Map<String, dynamic> defaultConfiguration = _defaultIceConfiguration,
    IceServersResolver? iceServersResolver,
  }) : _defaultConfiguration = defaultConfiguration,
       _iceServersResolver = iceServersResolver;

  @override
  Future<RTCPeerConnection> create([
    Map<String, dynamic> configuration = const {},
    Map<String, dynamic> constraints = const {},
  ]) async {
    // Use default configuration only if the provided one is empty.
    // This allows passing specific configurations when needed.
    final effectiveConfiguration = configuration.isEmpty ? await _resolveDefaultConfiguration() : configuration;

    return createPeerConnection(effectiveConfiguration, constraints);
  }

  Future<Map<String, dynamic>> _resolveDefaultConfiguration() async {
    final resolver = _iceServersResolver;
    if (resolver == null) return _defaultConfiguration;

    return {..._defaultConfiguration, ...rtcConfigurationFrom(await resolver())};
  }
}
