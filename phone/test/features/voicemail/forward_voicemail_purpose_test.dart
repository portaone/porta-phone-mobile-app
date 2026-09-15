import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/models/models.dart';

// Passing a message to a colleague, as one of the reasons the app sends
// somebody to its own lists. What it will take is narrower than a transfer's:
// a forward addresses an account, not a number.
void main() {
  final picked = <Contact>[];

  ForwardVoicemailPurpose purpose() => ForwardVoicemailPurpose(
    announcement: 'Choose who to forward to',
    pickLabel: (name) => 'Forward to $name',
    messageId: 'vm-1',
    onPicked: picked.add,
  );

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
    aliasName: 'Iryna Shevchuk',
  );

  setUp(picked.clear);

  group('where it is offered', () {
    test('wherever a person can be recognised', () {
      for (final flavor in [MainFlavor.contacts, MainFlavor.favorites, MainFlavor.recents]) {
        expect(purpose().offeredBy(flavor), isTrue, reason: flavor.name);
      }
    });

    test('and not on the keypad, where only a number can be typed', () {
      // A forward addresses an account on the backend. Nothing typed is one,
      // so the pad would show a control that refused everything.
      expect(purpose().offeredBy(MainFlavor.keypad), isFalse);
    });

    test('nor anywhere with nobody in it', () {
      for (final flavor in [MainFlavor.messaging, MainFlavor.embedded, MainFlavor.voicemail]) {
        expect(purpose().offeredBy(flavor), isFalse, reason: flavor.name);
      }
    });
  });

  group('what it accepts', () {
    test('a colleague from the backend with an id of their own', () {
      expect(purpose().accepts(DestinationCandidate(contact: contact())), isTrue);
    });

    test('not a bare number, however dialable', () {
      // The difference from handing a call on: this one cannot use a number.
      expect(purpose().accepts(const DestinationCandidate(number: '1001')), isFalse);
    });

    test('not a contact from the phone, nor one the app gave an id to', () {
      expect(purpose().accepts(DestinationCandidate(contact: contact(sourceType: ContactSourceType.local))), isFalse);
      expect(purpose().accepts(DestinationCandidate(contact: contact(sourceId: 'number_1001'))), isFalse);
    });

    test('and not the person doing the forwarding', () {
      // The backend takes it and answers with a second copy in the same
      // mailbox, counted against the same quota.
      expect(purpose().accepts(DestinationCandidate(contact: contact(isCurrentUser: true))), isFalse);
    });
  });

  test('the control is named for the colleague and marked for the gesture', () {
    final it = purpose();

    expect(it.pickLabel(DestinationCandidate(contact: contact())), 'Forward to Iryna Shevchuk');
    // A phone icon would say this hands a call over, which it does not.
    expect(it.pickIcon, isNot(Icons.phone_forwarded));
  });

  test('choosing somebody reports them once', () {
    final chosen = contact();

    purpose().submit(DestinationCandidate(contact: chosen));

    expect(picked, [chosen]);
  });

  test('two messages are two purposes', () {
    // The scope above the lists compares them; a second forward that looked
    // like the first would leave the rows pointing at the message just sent.
    final first = purpose();
    final second = ForwardVoicemailPurpose(
      announcement: 'Choose who to forward to',
      pickLabel: (name) => 'Forward to $name',
      messageId: 'vm-2',
      onPicked: picked.add,
    );

    expect(first, isNot(second));
  });

  test('it offers a way out, because there is no other', () {
    // Handing a call over is left by returning to the call. A message looking
    // for a recipient has nothing of the kind: without this the only way to
    // stop would be to send it to somebody.
    expect(purpose().cancellable, isTrue);
  });

  test('and stands aside for a call in hand', () {
    // Somebody holding a call they are trying to hand on cannot wait while a
    // message finds a recipient.
    expect(purpose().precedence, DestinationPickPrecedence.ordinary);
  });
}
