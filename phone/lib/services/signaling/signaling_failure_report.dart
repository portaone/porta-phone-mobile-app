import 'package:logging/logging.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/utils/utils.dart';

import 'signaling_reconnect_controller.dart';

final _logger = Logger('SignalingFailureReport');

/// Logs and reports a signaling connection failure the reconnect policy gave
/// up waiting on; expected, self-healing ones are only logged.
void reportSignalingFailure(SignalingFailureInfo failure) {
  final (:knownCode, :systemCode, :systemReason) = failure;

  // Skip logging and notification for expected disconnect scenarios that trigger automatic reconnects without user impact.
  switch (knownCode) {
    case SignalingDisconnectCode.signalingKeepaliveTimeoutError:
    case SignalingDisconnectCode.controllerForceAttachClose:
    case SignalingDisconnectCode.appUnregisteredError:
      // Expected silent reconnect: keepalive timeout on lock-screen, duplicate-session
      // cleanup, or SIP unregistration after the user toggles Online off.
      _logger.fine('onConnectionFailed: silent reconnect for code=$knownCode');
      return;
    case SignalingDisconnectCode.controllerUnknownError:
      // controllerUnknownError (4400): the server-side Controller process died because
      // the Janus connection went down. The new WebSocket timed out (GenServer.call,
      // 5s default) waiting for the Controller to finish re-initializing (new Janus
      // session + SIP registration). The Controller continues initializing in the
      // background - the next reconnect attempt will succeed once it is ready.
      //
      // Silent reconnect: no user-visible notification needed.
      _logger.warning('onConnectionFailed: silent reconnect for code=$knownCode');
      return;
    default:
      break;
  }

  // Record unexpected disconnects with as much detail as possible to facilitate debugging and resolution.
  //
  // If you encounter a new disconnect code in the wild, add it to the above switch statement
  // and monitor its frequency and impact before deciding whether to log it as a warning or fine level.
  _logger.severe('onConnectionFailed: $failure');
  CrashlyticsUtils.recordError(
    'Signaling - onConnectionFailed ${knownCode?.name ?? 'unknown code'}',
    information: ['knownCode: $knownCode', 'systemCode: $systemCode', 'systemReason: $systemReason'],
  );
}
