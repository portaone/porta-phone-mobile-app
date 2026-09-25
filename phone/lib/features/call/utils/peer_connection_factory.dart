import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/models/models.dart';

/// Supplies the ICE servers for a peer connection about to be created.
///
/// Resolved per connection rather than captured once, so a connection created
/// after the deployment's TURN credentials were renewed uses the new ones.
typedef IceServersResolver = Future<IceServersConfig> Function();

/// Supplies the certificate policy in force when a peer connection is about to
/// be created.
///
/// Read per connection rather than captured once, for the same reason the ICE
/// candidate filters are: the person may change it between two calls, and the
/// point of the setting is to take effect without restarting the app.
typedef TurnCertificateVerificationResolver = TurnCertificateVerification Function();

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
/// [verification] is the other half of the same decision, and the two are
/// independent mechanisms rather than one scale. Under
/// [TurnCertificateVerification.disabled] the anchors are left out entirely:
/// not for tidiness, but because they would be misleading - with the policy set
/// there is no verification for them to take part in, and a reader of the logs
/// should not see anchors installed on a connection that checks nothing.
Map<String, dynamic> rtcConfigurationFrom(
  IceServersConfig config, {
  TurnCertificateVerification verification = TurnCertificateVerification.verify,
}) {
  final servers = config.servers.isEmpty ? kFallbackRtcIceServers : config.servers;
  final policy = _tlsCertPolicyOf(verification);

  return <String, dynamic>{
    'iceServers': policy == null
        ? servers
        // `tlsCertPolicy` is a member of one RTCIceServer, not of the
        // configuration, so a stated policy has to be written on every entry.
        : servers.map((server) => <String, dynamic>{...server, 'tlsCertPolicy': policy}).toList(),
    if (verification != TurnCertificateVerification.disabled && config.trustedCertificates.isNotEmpty)
      'trustedCertificates': config.trustedCertificates.map((pem) => Uint8List.fromList(utf8.encode(pem))).toList(),
  };
}

/// Null for [TurnCertificateVerification.verify]: saying nothing is what leaves
/// the native default alone, and that default already verifies.
String? _tlsCertPolicyOf(TurnCertificateVerification verification) => switch (verification) {
  TurnCertificateVerification.verify => null,
  TurnCertificateVerification.disabled => 'insecure_no_check',
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
  final TurnCertificateVerificationResolver? _certificateVerificationResolver;

  const DefaultPeerConnectionFactory({
    Map<String, dynamic> defaultConfiguration = _defaultIceConfiguration,
    IceServersResolver? iceServersResolver,
    TurnCertificateVerificationResolver? certificateVerificationResolver,
  }) : _defaultConfiguration = defaultConfiguration,
       _iceServersResolver = iceServersResolver,
       _certificateVerificationResolver = certificateVerificationResolver;

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

    return {
      ..._defaultConfiguration,
      ...rtcConfigurationFrom(
        await resolver(),
        verification: _certificateVerificationResolver?.call() ?? TurnCertificateVerification.verify,
      ),
    };
  }
}
