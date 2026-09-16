import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/call/bloc/call_bloc.dart';
import 'package:webtrit_phone/features/call/controllers/call_controller.dart';
import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/models/models.dart';

class _MockCallBloc extends Mock implements CallBloc {}

// Handing a call to somebody else, expressed as one of several things a person
// can be chosen for rather than as the only one. What it accepts and where it
// is offered has to stay exactly what it was: this used to be spelled out in
// each of the lists, and the point of moving it here is that nothing about it
// changed on the way.
void main() {
  late _MockCallBloc callBloc;
  late CallController controller;
  late BlindTransferPurpose purpose;

  setUpAll(() {
    registerFallbackValue(const CallControlEvent.blindTransferSubmitted(number: ''));
  });

  setUp(() {
    callBloc = _MockCallBloc();
    when(() => callBloc.add(any())).thenReturn(null);
    controller = CallController(callBloc: callBloc);
    purpose = BlindTransferPurpose(
      announcement: 'Performing blind transfer',
      pickLabel: (destination) => 'Transfer current call to $destination',
      controller: controller,
    );
  });

  group('where it is offered', () {
    test('the sections a number can be picked or dialled from', () {
      // The same four the deleted extension listed, checked one at a time so a
      // change to the enum cannot quietly widen this.
      for (final flavor in [MainFlavor.favorites, MainFlavor.recents, MainFlavor.contacts, MainFlavor.keypad]) {
        expect(purpose.offeredBy(flavor), isTrue, reason: flavor.name);
      }
    });

    test('and nowhere else', () {
      // A conversation, an embedded page and a list of voice messages have
      // nobody to hand a call to.
      for (final flavor in [MainFlavor.messaging, MainFlavor.embedded, MainFlavor.voicemail]) {
        expect(purpose.offeredBy(flavor), isFalse, reason: flavor.name);
      }
    });

    test('every section is decided one way or the other', () {
      // A new section added to the enum must be classified rather than fall
      // through to a default.
      for (final flavor in MainFlavor.values) {
        expect(() => purpose.offeredBy(flavor), returnsNormally, reason: flavor.name);
      }
    });
  });

  group('what it accepts', () {
    test('anything with a number', () {
      expect(purpose.accepts(const DestinationCandidate(number: '1001')), isTrue);
    });

    test('and nothing without one, even when a person is known', () {
      // A transfer dials; a contact with no number on file is somebody it
      // cannot reach.
      expect(purpose.accepts(const DestinationCandidate()), isFalse);
    });
  });

  test('picking submits the number to the call', () {
    purpose.submit(const DestinationCandidate(number: '1001'));

    verify(() => callBloc.add(const CallControlEvent.blindTransferSubmitted(number: '1001'))).called(1);
  });

  test('two purposes over the same call are the same purpose', () {
    // The scope above the lists is rebuilt with the shell. Without value
    // equality every rebuild would look like a new purpose and redraw every
    // list on the screen.
    final other = BlindTransferPurpose(
      announcement: 'Performing blind transfer',
      pickLabel: (destination) => 'Transfer current call to $destination',
      controller: controller,
    );

    expect(purpose, other);
  });
}
