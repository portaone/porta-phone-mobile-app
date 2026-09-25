import 'package:equatable/equatable.dart';

/// ICE servers used when the deployment bundles none of its own, or when its
/// configuration cannot be reached.
///
/// A public STUN server only helps a peer discover its own reflexive address,
/// so calls behind a symmetric NAT still fail - but this is what the app used
/// before deployments started bundling coturn, so it stays the fallback rather
/// than an empty list.
///
/// Uses the legacy singular `url` key on purpose: it is the exact value the
/// app has always shipped, and flutter_webrtc accepts both spellings.
const kFallbackRtcIceServers = <Map<String, dynamic>>[
  {'url': 'stun:stun.l.google.com:19302'},
];

/// The deployment's STUN/TURN configuration together with the moment its
/// credentials stop working.
class IceServersConfig extends Equatable {
  IceServersConfig({required this.servers, required DateTime expiresAt, this.trustedCertificates = const []})
    : expiresAt = expiresAt.toUtc();

  /// The compiled-in fallback: the public STUN server, no credentials and no
  /// anchors, dated so that the next poll replaces it.
  IceServersConfig.fallback()
    : servers = kFallbackRtcIceServers,
      trustedCertificates = const [],
      expiresAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// The servers as flutter_webrtc wants them - `RTCIceServer` dictionaries,
  /// ready to hand to a peer connection without further mapping.
  final List<Map<String, dynamic>> servers;

  /// When the credentials expire, in UTC.
  final DateTime expiresAt;

  /// Certificates the deployment asks this client to trust when verifying its
  /// TURN server, PEM encoded, one certificate per entry.
  ///
  /// Usually empty, and empty must stay harmless: it means "decide the way you
  /// always have", not "trust nothing". A deployment serves these when its
  /// `turns:` certificate comes from an authority libwebrtc's own compiled-in
  /// root list does not carry - Let's Encrypt being the case that prompted it.
  final List<String> trustedCertificates;

  /// How long before [expiresAt] the configuration is renewed.
  ///
  /// Renewing ahead of the deadline rather than at it keeps a call that starts
  /// near the boundary from picking up credentials that expire mid-setup, and
  /// leaves room for a failed attempt to be retried by the next poll.
  static const renewalLeadTime = Duration(minutes: 15);

  bool get isEmpty => servers.isEmpty;

  /// Whether this configuration should be replaced by a fresh fetch at [now].
  bool isDueForRefresh(DateTime now) => !now.toUtc().isBefore(expiresAt.subtract(renewalLeadTime));

  @override
  List<Object?> get props => [servers, expiresAt, trustedCertificates];

  @override
  bool get stringify => true;
}
