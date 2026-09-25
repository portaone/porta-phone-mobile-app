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
/// libwebrtc verifies that certificate against a root list compiled into the
/// library rather than the platform store, and that list carries no Let's
/// Encrypt root - so a TURN server secured the way most deployments secure
/// everything else is refused with `unknown_ca`, no relay candidate is
/// gathered, and nothing reports an error. [auto] is the cure when the
/// deployment serves its own trust anchors; [disabled] is the blunt instrument
/// for when it does not and calls are needed now.
enum TurnCertificateVerification {
  /// Verify, using whatever anchors the deployment serves beside its ICE
  /// servers, and leaving libwebrtc's own decision in place when it serves
  /// none. The default, and the only value that changes nothing.
  auto,

  /// Verify, and say so explicitly: `tlsCertPolicy: secure`. Differs from
  /// [auto] only in that it states the policy rather than leaving it unset.
  enabled,

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
