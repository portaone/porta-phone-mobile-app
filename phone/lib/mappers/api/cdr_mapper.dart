import 'package:api/api.dart' as api;

import 'package:webtrit_phone/extensions/string.dart';
import 'package:webtrit_phone/models/models.dart';

mixin CdrApiMapper {
  CdrRecord cdrFromApi(api.CdrRecord cdrRecord) {
    return CdrRecord(
      callId: cdrRecord.callId,
      direction: _directionFromApi(cdrRecord.direction),
      status: _statusFromApi(cdrRecord.status),
      callee: cdrRecord.callee,
      calleeNumber: cdrRecord.callee.extractNumber,
      caller: cdrRecord.caller,
      callerNumber: cdrRecord.caller.extractNumber,
      connectTime: cdrRecord.connectTime,
      disconnectTime: cdrRecord.disconnectTime,
      disconnectReason: cdrRecord.disconnectReason,
      duration: Duration(seconds: cdrRecord.duration),
      recordingId: cdrRecord.recordingId,
    );
  }

  // Both translations are exhaustive switches on purpose. The api package
  // already absorbed whatever the wire carried, so nothing here can throw; what
  // these guard instead is the next value the contract grows - it lands as a
  // compile error in this file rather than as a silent fallback nobody notices,
  // which is how `failed` and `completed_elsewhere` spent years reported as
  // `error`.
  CallDirection _directionFromApi(api.CdrDirection direction) => switch (direction) {
    api.CdrDirection.incoming => CallDirection.incoming,
    api.CdrDirection.outgoing => CallDirection.outgoing,
    api.CdrDirection.forwarded => CallDirection.forwarded,
    api.CdrDirection.unknown => CallDirection.unknown,
    api.CdrDirection.unrecognized => CallDirection.unrecognized,
  };

  CdrStatus _statusFromApi(api.CdrStatus status) => switch (status) {
    api.CdrStatus.accepted => CdrStatus.accepted,
    api.CdrStatus.declined => CdrStatus.declined,
    api.CdrStatus.missed => CdrStatus.missed,
    api.CdrStatus.failed => CdrStatus.failed,
    api.CdrStatus.completedElsewhere => CdrStatus.completedElsewhere,
    api.CdrStatus.error => CdrStatus.error,
    api.CdrStatus.unrecognized => CdrStatus.unrecognized,
  };
}
