import 'package:equatable/equatable.dart';

import '../ice_settings.dart';

/// What the deployment decided about `turns:` certificate verification at build
/// time, and whether it lets the person using the app change that decision.
///
/// Both halves default to the safe answer: verify as before, and do not offer
/// the control. A deployment that needs the escape hatch turns it on
/// deliberately - it is not something to leave lying around in every build,
/// because the value that makes calls work in an outage is also the value that
/// stops the TURN connection being verified at all.
class IceConfig extends Equatable {
  const IceConfig({
    this.certificateVerification = TurnCertificateVerification.verify,
    this.certificateVerificationConfigurable = false,
  });

  /// The policy a device uses until someone changes it here.
  final TurnCertificateVerification certificateVerification;

  /// Whether the media settings screen shows the control at all.
  final bool certificateVerificationConfigurable;

  @override
  List<Object?> get props => [certificateVerification, certificateVerificationConfigurable];
}
