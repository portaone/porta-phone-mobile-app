import 'package:flutter_test/flutter_test.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/mappers/mappers.dart';

import '../mocks/voicemails_fixture_factory.dart';

class _Mapper with VoicemailMapper {}

// The two WT-1878 flags have to survive both directions, and `saved` has to
// keep its third state: absent is not false.
void main() {
  final mapper = _Mapper();

  UserVoicemailSummary summary({
    bool? saved,
    String? forwardedBy,
    String? sender = '123010',
    double? duration = 3.45,
  }) => UserVoicemailSummary(
    id: 'vm-1',
    date: '2026-09-15T10:00:00Z',
    duration: duration,
    seen: false,
    size: 5,
    type: 'voice',
    saved: saved,
    forwardedBy: forwardedBy,
    sender: sender,
    receiver: sender == null ? null : '123009',
  );

  VoicemailData row(UserVoicemailSummary item) => mapper.voicemailToDrift(item, 'https://a/vm-1.mp3');

  group('into the database', () {
    test('carries both flags when the backend reported them', () {
      final stored = row(summary(saved: true, forwardedBy: '123044'));

      expect(stored.saved, isTrue);
      expect(stored.forwardedBy, '123044');
    });

    test('keeps a mailbox that cannot hold the flag distinct from one that says no', () {
      expect(row(summary()).saved, isNull);
      expect(row(summary(saved: false)).saved, isFalse);
    });

    test('takes who the message is from and to off the list item', () {
      final stored = row(summary());

      expect(stored.sender, '123010');
      expect(stored.receiver, '123009');
    });

    test('stores a message the backend listed without a sender, with an empty one', () {
      // Left out, its recording could not be heard at all.
      final stored = row(summary(sender: null));

      expect(stored.sender, isEmpty);
      expect(stored.receiver, isEmpty);
    });

    test('a message listed without its length is stored, and its length reads as not known', () {
      // The length is optional on the backend. Parsed as required, one such
      // message cost the whole list.
      final stored = row(summary(duration: null));

      expect(mapper.voicemailFromDrift(stored, null).length, isNull);
    });

    test('a listed length comes back as the message said it', () {
      final stored = row(summary(duration: 10.783));

      expect(mapper.voicemailFromDrift(stored, null).length, const Duration(milliseconds: 10783));
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
