import 'package:flutter_test/flutter_test.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/mappers/mappers.dart';

import '../mocks/voicemails_fixture_factory.dart';

class _Mapper with VoicemailMapper {}

// The two WT-1878 flags have to survive both directions, and `saved` has to
// keep its third state: absent is not false.
void main() {
  final mapper = _Mapper();

  UserVoicemailSummary summary({bool? saved, String? forwardedBy}) => UserVoicemailSummary(
    id: 'vm-1',
    date: '2026-09-15T10:00:00Z',
    duration: 3.45,
    seen: false,
    size: 5,
    type: 'voice',
    saved: saved,
    forwardedBy: forwardedBy,
  );

  const details = UserVoicemail(
    id: 'vm-1',
    date: '2026-09-15T10:00:00Z',
    duration: 3.45,
    sender: '123010',
    receiver: '123009',
    seen: false,
    size: 5,
    type: 'voice',
    attachments: [],
  );

  group('into the database', () {
    test('carries both flags when the backend reported them', () {
      final row = mapper.voicemailToDrift(summary(saved: true, forwardedBy: '123044'), details, 'https://a/vm-1.mp3');

      expect(row.saved, isTrue);
      expect(row.forwardedBy, '123044');
    });

    test('keeps a mailbox that cannot hold the flag distinct from one that says no', () {
      expect(mapper.voicemailToDrift(summary(), details, 'url').saved, isNull);
      expect(mapper.voicemailToDrift(summary(saved: false), details, 'url').saved, isFalse);
    });
  });

  group('out of the database', () {
    test('carries both flags back', () {
      final row = VoicemailsFixtureFactory.createVoicemail(id: 'vm-1', saved: true, forwardedBy: '123044');

      final voicemail = mapper.voicemailFromDrift(row, null);

      expect(voicemail.saved, isTrue);
      expect(voicemail.forwardedBy, '123044');
      expect(voicemail.isForwarded, isTrue);
    });

    test('a message nobody forwarded says so', () {
      final voicemail = mapper.voicemailFromDrift(VoicemailsFixtureFactory.createVoicemail(id: 'vm-1'), null);

      expect(voicemail.forwardedBy, isNull);
      expect(voicemail.isForwarded, isFalse);
      expect(voicemail.saved, isNull);
    });
  });
}
