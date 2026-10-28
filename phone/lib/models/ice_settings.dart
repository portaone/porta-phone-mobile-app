import 'package:equatable/equatable.dart';

class IceSettings extends Equatable {
  const IceSettings({this.iceTransportFilter, this.iceNetworkFilter, this.certificateVerification});

  final IceTransportFilter? iceTransportFilter;
  final IceNetworkFilter? iceNetworkFilter;

  /// How a `turns:` certificate is verified, or null to follow the value the
  /// deployment was built with.
  ///
  /// Null is not a third policy: it is the absence of a choice on this device,
  /// which is what lets a later release move everyone who never touched the
  /// setting while leaving everyone who did alone.
  final TurnCertificateVerification? certificateVerification;

  factory IceSettings.blank() => const IceSettings();

  IceSettings copyWithTransportFilter(IceTransportFilter? iceTransportFilter) {
    return IceSettings(
      iceTransportFilter: iceTransportFilter,
      iceNetworkFilter: iceNetworkFilter,
      certificateVerification: certificateVerification,
    );
  }

  IceSettings copyWithNetworkFilter(IceNetworkFilter? iceNetworkFilter) {
    return IceSettings(
      iceTransportFilter: iceTransportFilter,
      iceNetworkFilter: iceNetworkFilter,
      certificateVerification: certificateVerification,
    );
  }

  IceSettings copyWithCertificateVerification(TurnCertificateVerification? certificateVerification) {
    return IceSettings(
      iceTransportFilter: iceTransportFilter,
      iceNetworkFilter: iceNetworkFilter,
      certificateVerification: certificateVerification,
    );
  }

  @override
  List<Object?> get props => [iceTransportFilter, iceNetworkFilter, certificateVerification];

  @override
  String toString() {
    return 'IceSettings(iceTransportFilter: $iceTransportFilter, iceNetworkFilter: $iceNetworkFilter, '
        'certificateVerification: $certificateVerification)';
  }
}

enum IceTransportFilter { udp, tcp }

enum IceNetworkFilter { ipv4, ipv6 }

/// What the app does about the certificate a `turns:` server presents.
///
/// libwebrtc checks that certificate against a root list compiled into the
/// library, which carries no Let's Encrypt root, and then falls back to the
/// platform trust store, asking it with the TURN hostname. So [verify] accepts
/// a certificate the system trusts; [disabled] is the blunt instrument for one
/// it does not - self-signed, or from a private CA - when calls are needed now.
///
/// Two values rather than three. A third that states `tlsCertPolicy: secure`
/// would be indistinguishable from [verify]: the native builder already
/// initialises that field to TLS_CERT_POLICY_SECURE, read out of
/// `android-150.7871.01.aar`, so writing it says nothing new.
enum TurnCertificateVerification {
  /// Verify, leaving libwebrtc's own decision in place. The default, and the
  /// only value that changes nothing.
  ///
  /// A certificate that neither the compiled-in list nor the system trusts is
  /// refused: no relay candidate is gathered, and nothing reports an error.
  verify,

  /// Do not verify: `tlsCertPolicy: insecure_no_check`.
  ///
  /// Measured, and wider than it reads: this drops the hostname check as well
  /// as the chain, so any certificate for any name is accepted. Media stays
  /// protected by DTLS-SRTP, but the TURN credentials on that connection are
  /// exposed to anyone on the path.
  disabled;

  static TurnCertificateVerification? tryParse(String? value) {
    if (value == null) return null;
    return TurnCertificateVerification.values.where((v) => v.name == value).firstOrNull;
  }
}
