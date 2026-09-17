import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/voicemail/extensions/extensions.dart';
import 'package:webtrit_phone/models/models.dart';

// Who a voicemail may be forwarded to. Forwarding addresses a user on the
// backend, not a phone number, so a row that merely looks like a colleague is
// not one - and the cost of getting this wrong is a message sent to the wrong
// place, or to oneself.
void main() {
  Contact contact({
    ContactSourceType sourceType = ContactSourceType.external,
    String? sourceId = 'user-7',
    bool? isCurrentUser = false,
  }) => Contact(
    id: 1,
    sourceType: sourceType,
    kind: ContactKind.visible,
    sourceId: sourceId,
    isCurrentUser: isCurrentUser,
  );

  test('a colleague from the backend with an id of their own can receive a forward', () {
    expect(contact().canReceiveForwardedVoicemail, isTrue);
  });

  test('a contact from the phone cannot', () {
    // A device contact has no account on the backend, so there is nothing to
    // address even when the person behind it is a colleague.
    expect(contact(sourceType: ContactSourceType.local).canReceiveForwardedVoicemail, isFalse);
  });

  test('a contact the app gave an id to cannot', () {
    // The prefixed forms are what this app invents when the server sent no id.
    // Sending one of them as a user id addresses nobody.
    for (final sourceId in ['number_1001', 'email_ada@example.test', 'hash_-12345']) {
      expect(contact(sourceId: sourceId).canReceiveForwardedVoicemail, isFalse, reason: sourceId);
    }
  });

  test('a contact with no id at all cannot', () {
    expect(contact(sourceId: null).canReceiveForwardedVoicemail, isFalse);
    expect(contact(sourceId: '').canReceiveForwardedVoicemail, isFalse);
  });

  test('the person doing the forwarding cannot', () {
    // The backend accepts it and answers with a second copy in the same
    // mailbox, counted against the same quota.
    expect(contact(isCurrentUser: true).canReceiveForwardedVoicemail, isFalse);
  });

  test('a backend that does not say who the user is hides everyone', () {
    // Strict `== false`: without the flag there is no way to rule out
    // forwarding to oneself, and an absent row is a smaller failure than a
    // duplicate nobody asked for.
    expect(contact(isCurrentUser: null).canReceiveForwardedVoicemail, isFalse);
  });

  test('the synthetic prefixes are the ones the model actually produces', () {
    // The predicate reads these off the model rather than repeating them, so
    // this pins the two halves together: a new branch in safeSourceId that
    // invents another prefix has to be declared here too.
    expect(ExternalContact.syntheticSourceIdPrefixes, ['number_', 'email_', 'hash_']);
    expect(const ExternalContact(number: '1001').safeSourceId, startsWith('number_'));
    expect(const ExternalContact(email: 'ada@example.test').safeSourceId, startsWith('email_'));
    expect(const ExternalContact(firstName: 'Ada').safeSourceId, startsWith('hash_'));
    expect(const ExternalContact(id: 'user-7').safeSourceId, 'user-7');
  });
}
