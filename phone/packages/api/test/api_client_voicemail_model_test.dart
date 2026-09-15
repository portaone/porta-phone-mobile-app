import 'package:test/test.dart';

import 'package:api/api.dart';

// WT-1878 adds two fields that are meaningful by their ABSENCE, so these pin the
// three shapes a message can arrive in rather than only the happy one.
void main() {
  Map<String, dynamic> item(Map<String, dynamic> extra) => {
    'id': 'vm-1',
    'date': '2026-09-15T10:00:00Z',
    'duration': 3.45,
    'seen': false,
    'size': 5,
    'type': 'voice',
    ...extra,
  };

  group('UserVoicemailItem', () {
    test('a mailbox message that can be kept reports the flag', () {
      final parsed = UserVoicemailItem.fromJson(item({'saved': true}));

      expect(parsed.saved, isTrue);
      expect(parsed.forwardedBy, isNull);
    });

    test('a mailbox that cannot keep messages omits the flag, which is not false', () {
      final parsed = UserVoicemailItem.fromJson(item({}));

      expect(parsed.saved, isNull);
    });

    test('a forwarded message names who passed it on', () {
      final parsed = UserVoicemailItem.fromJson(item({'saved': false, 'forwarded_by': '123044'}));

      expect(parsed.forwardedBy, '123044');
      expect(parsed.saved, isFalse);
    });
  });

  group('UserVoicemail', () {
    Map<String, dynamic> details(Map<String, dynamic> extra) => {
      ...item({}),
      'sender': 'Caller <123010@sip.webtrit.com>',
      'receiver': '123009 <123009@sip.webtrit.com>',
      'attachments': const <Map<String, dynamic>>[],
      ...extra,
    };

    test('carries both fields when the backend sends them', () {
      final parsed = UserVoicemail.fromJson(details({'saved': true, 'forwarded_by': '123044'}));

      expect(parsed.saved, isTrue);
      expect(parsed.forwardedBy, '123044');
    });

    test('leaves both null when the backend omits them', () {
      final parsed = UserVoicemail.fromJson(details({}));

      expect(parsed.saved, isNull);
      expect(parsed.forwardedBy, isNull);
    });
  });

  test('a list response carries the items through', () {
    final parsed = UserVoicemailListResponse.fromJson({
      'has_new_messages': true,
      'items': [
        item({'saved': true}),
        item({'forwarded_by': '123044'}),
      ],
    });

    expect(parsed.items.map((i) => i.saved), [true, null]);
    expect(parsed.items.map((i) => i.forwardedBy), [null, '123044']);
  });
}
