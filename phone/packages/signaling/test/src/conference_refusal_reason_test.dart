import 'package:test/test.dart';

import 'package:signaling/src/conference_refusal_reason.dart';

void main() {
  test('every reason Core sends maps to a value', () {
    const reasons = {
      'conference_disabled': ConferenceRefusalReason.conferenceDisabled,
      'conference_already_active': ConferenceRefusalReason.conferenceAlreadyActive,
      'not_enough_lines': ConferenceRefusalReason.notEnoughLines,
      'line_without_active_call': ConferenceRefusalReason.lineWithoutActiveCall,
      'no_conference': ConferenceRefusalReason.noConference,
      'line_already_in_conference': ConferenceRefusalReason.lineAlreadyInConference,
      'line_not_in_conference': ConferenceRefusalReason.lineNotInConference,
      'line_not_ready': ConferenceRefusalReason.lineNotReady,
      'invalid_muted': ConferenceRefusalReason.invalidMuted,
      'room_create_failed': ConferenceRefusalReason.roomCreateFailed,
      'attach_failed': ConferenceRefusalReason.attachFailed,
      'line_in_conference': ConferenceRefusalReason.lineInConference,
    };

    for (final entry in reasons.entries) {
      expect(ConferenceRefusalReason.fromReason(entry.key), entry.value, reason: entry.key);
    }
  });

  test('prefixed reasons keep their family, the diagnostic stays in the raw string', () {
    expect(
      ConferenceRefusalReason.fromReason('room_create_failed: {:error, :timeout}'),
      ConferenceRefusalReason.roomCreateFailed,
    );
    expect(
      ConferenceRefusalReason.fromReason(
        'attach_failed: the AudioBridge plugin could not be attached [458: No such plugin]',
      ),
      ConferenceRefusalReason.attachFailed,
    );
  });

  test('unrecognised and empty reasons map to unknown', () {
    expect(ConferenceRefusalReason.fromReason('something_new'), ConferenceRefusalReason.unknown);
    expect(ConferenceRefusalReason.fromReason('room_create_failed_v2'), ConferenceRefusalReason.unknown);
    expect(ConferenceRefusalReason.fromReason(''), ConferenceRefusalReason.unknown);
  });
}
