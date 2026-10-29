import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/features/call/extensions/extensions.dart';
import 'package:webtrit_phone/app/notifications/models/error_field.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import 'linked_call.dart';

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class SignalingSessionMissedNotification extends ErrorNotification {
  SignalingSessionMissedNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_SignalingSessionMissed;
  }
}

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class SignalingConnectFailedNotification extends ErrorNotification {
  SignalingConnectFailedNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_SignalingConnectFailed;
  }
}

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class SignalingDisconnectNotification extends ErrorNotification {
  SignalingDisconnectNotification({required this.knownCode, this.systemCode, this.systemReason});

  final SignalingDisconnectCode knownCode;
  final int? systemCode;
  final String? systemReason;

  @override
  String l10n(BuildContext context) {
    if (systemReason != null) {
      return context.l10n.notifications_errorSnackBar_signalingDisconnectWithSystemReason(systemReason!);
    }
    return context.l10n.notifications_errorSnackBar_signalingDisconnectWithCodeName(knownCode.name);
  }

  @override
  SnackBarAction action(BuildContext context) {
    final title = l10n(context);
    final errorFields = [
      ErrorFieldModel(context.l10n.default_ErrorMessage, title),
      ErrorFieldModel(context.l10n.request_StatusName, knownCode.name),
      ErrorFieldModel(context.l10n.request_StatusCode, systemCode?.toString() ?? 'N/A'),
      ErrorFieldModel(context.l10n.default_ErrorDetails, systemReason ?? 'N/A'),
    ];

    return SnackBarAction(
      label: context.l10n.default_ErrorDetails,
      onPressed: () {
        context.router.push(ErrorDetailsScreenPageRoute(title: title, fields: errorFields));
      },
    );
  }
}

/// Where a missing microphone or camera is dealt with: the diagnostic screen shows
/// both with their state and asks for them again, or opens the system settings
/// once the system will not ask - the user is not thrown out of the app for it.
const _diagnosticRoute = SettingsRouterPageRoute(children: [DiagnosticScreenPageRoute()]);

final class CallUserMediaErrorNotification extends MessageNotification {
  const CallUserMediaErrorNotification();

  /// A call answered from the lock screen ends here with the app out of sight; without the
  /// shade the user would only see the call stop.
  @override
  Set<NotificationDelivery> deliveries() => const {NotificationDelivery.inApp, NotificationDelivery.shade};

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_callUserMedia;
  }

  @override
  SnackBarAction? action(BuildContext context) {
    return SnackBarAction(
      label: context.l10n.notifications_errorSnackBarAction_callUserMedia,
      onPressed: () => context.router.push(_diagnosticRoute),
    );
  }
}

/// Soft notification shown when an incoming video call is answered audio-only
/// because camera permission was denied. Unlike [CallUserMediaErrorNotification]
/// (a hard media error), this communicates a graceful fallback and offers a
/// shortcut to the diagnostic screen, where the permission is granted.
final class CallVideoDowngradedNotification extends MessageNotification {
  const CallVideoDowngradedNotification();

  /// Answered from the lock screen as often as from the app, so it may go to the shade too.
  @override
  Set<NotificationDelivery> deliveries() => const {NotificationDelivery.inApp, NotificationDelivery.shade};

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_messageSnackBar_callVideoDowngraded;
  }

  @override
  SnackBarAction? action(BuildContext context) {
    return SnackBarAction(
      label: context.l10n.notifications_messageSnackBarAction_callVideoDowngraded,
      onPressed: () => context.router.push(_diagnosticRoute),
    );
  }
}

final class CallMediaTrackSetupErrorNotification extends MessageNotification {
  const CallMediaTrackSetupErrorNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_callMediaTrackSetup;
  }

  @override
  SnackBarAction? action(BuildContext context) => null;
}

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class CallSdpConfigurationErrorNotification extends ErrorNotification {
  CallSdpConfigurationErrorNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBarAction_callSdpConfiguration;
  }
}

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class CallUndefinedLineNotification extends ErrorNotification {
  CallUndefinedLineNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_callUndefinedLine;
  }
}

final class CallServiceBusyLineNotification extends MessageNotification {
  const CallServiceBusyLineNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_callServiceBusyLine;
  }
}

final class CallWhileOfflineNotification extends MessageNotification {
  const CallWhileOfflineNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_callWhileOffline;
  }
}

final class CallWhileUnregisteredNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_callWhileUnregistered;
  }
}

final class CallNegotiationTimeoutNotification extends MessageNotification {
  const CallNegotiationTimeoutNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_callNegotiationTimeout;
  }
}

final class GeneralUnableToCallNotification extends MessageNotification {
  const GeneralUnableToCallNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_generalUnableToCall;
  }
}

final class CallRejectedNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.signalingResponseCode_rejected;
  }
}

final class CallUnwantedNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.signalingResponseCode_unwanted;
  }
}

final class CallUserNotExistNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.signalingResponseCode_userNotExist;
  }
}

final class CallBusyNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.signalingResponseCode_userBusy;
  }
}

final class CallInvalidNumberNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.signalingResponseCode_invalidNumberFormat;
  }
}

/// Generic neutral fallback shown when an outgoing call fails for a reason we
/// do not surface with a specific message.
final class CallUnableToCompleteNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.signalingResponseCode_unableToComplete;
  }
}

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class SipRegistrationFailedNotification extends ErrorNotification {
  SipRegistrationFailedNotification({required this.knownCode, this.systemCode, this.systemReason});

  final SignalingRegistrationFailedCode knownCode;
  final int? systemCode;
  final String? systemReason;

  @override
  String l10n(BuildContext context) {
    switch (knownCode) {
      case SignalingRegistrationFailedCode.sipServerUnavailable:
        return context.l10n.notifications_errorSnackBar_sipRegistrationFailed_Unavailable;
      default:
        if (systemReason != null) {
          return context.l10n.notifications_errorSnackBar_sipRegistrationFailed_WithSystemReason(systemReason!);
        } else {
          return context.l10n.notifications_errorSnackBar_sipRegistrationFailed_Unexpected;
        }
    }
  }

  @override
  SnackBarAction action(BuildContext context) {
    final title = l10n(context);
    final errorFields = [
      ErrorFieldModel(context.l10n.default_ErrorMessage, title),
      ErrorFieldModel(context.l10n.request_StatusName, knownCode.name),
      ErrorFieldModel(context.l10n.request_StatusCode, systemCode?.toString() ?? 'N/A'),
      ErrorFieldModel(context.l10n.default_ErrorDetails, systemReason ?? 'N/A'),
    ];

    return SnackBarAction(
      label: context.l10n.default_ErrorDetails,
      onPressed: () {
        context.router.push(ErrorDetailsScreenPageRoute(title: title, fields: errorFields));
      },
    );
  }
}

// final class AppOfflineNotification extends MessageNotification {
//   @override
//   String l10n(BuildContext context) {
//     return context.l10n.notifications_messageSnackBar_appOffline;
//   }

//   @override
//   List<NotificationScope> scopes() => [NotificationScope.main];
// }

// final class AppOnlineNotification extends SuccessNotification {
//   @override
//   String l10n(BuildContext context) {
//     return context.l10n.notifications_successSnackBar_appOnline;
//   }

//   @override
//   List<NotificationScope> scopes() => [NotificationScope.main];
// }

final class ActiveLineBlindTransferWarningNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_activeLineBlindTransferWarning;
  }
}

final class BlindTransferFailedNotification extends MessageNotification {
  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_errorSnackBar_blindTransferFailed;
  }
}

/// The party a call was placed on behalf of another did not come, and that
/// call is back. Said only for the endings the hangup itself does not
/// announce.
final class LinkedCallFailedNotification extends MessageNotification {
  const LinkedCallFailedNotification(this.failure);

  final LinkedCallFailure failure;

  @override
  String l10n(BuildContext context) => switch (failure) {
    LinkedCallFailure.declined => context.l10n.notifications_errorSnackBar_attendedTransferDeclined,
    _ => context.l10n.notifications_errorSnackBar_attendedTransferUnanswered,
  };
}

/// The server refused to build the room, or to add a call to it.
///
/// The wire reason is kept for the log and turned into words at the moment of
/// showing; what the server calls `conference_already_active` is not a
/// sentence to put in front of a person.
final class ConferenceRefusedNotification extends MessageNotification {
  const ConferenceRefusedNotification(this.reason);

  final String reason;

  @override
  String l10n(BuildContext context) => ConferenceRefusalReason.fromReason(reason).l10n(context);
}

/// The room could not be built and the calls are ordinary calls again.
///
/// Today the server refuses for one reason only, a video call among the
/// legs, and that one the user can act on; anything else is reported as a
/// conference that could not be set up.
final class ConferenceFailedNotification extends MessageNotification {
  const ConferenceFailedNotification({required this.reason});

  final String reason;

  @override
  String l10n(BuildContext context) {
    if (reason == _videoNotSupported) return context.l10n.notifications_messageSnackBar_conferenceVideoLeg;
    return context.l10n.notifications_messageSnackBar_conferenceFailed;
  }

  static const _videoNotSupported = 'video_not_supported';
}

/// The room ended on the server's side while calls were still up; they go
/// on as ordinary calls.
final class ConferenceEndedNotification extends MessageNotification {
  const ConferenceEndedNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.notifications_messageSnackBar_conferenceEnded;
  }
}

@Deprecated.instantiate('will be removed, (see [app/notifications/models/notification.dart] for details)')
final class CallErrorRegisteringSelfManagedPhoneAccountNotification extends ErrorNotification {
  CallErrorRegisteringSelfManagedPhoneAccountNotification();

  @override
  String l10n(BuildContext context) {
    return context.l10n.call_errorRegisteringSelfManagedPhoneAccount;
  }
}
