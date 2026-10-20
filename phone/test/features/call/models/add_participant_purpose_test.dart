import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/call/bloc/call_bloc.dart';
import 'package:webtrit_phone/features/call/controllers/call_controller.dart';
import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/models/models.dart';

class _MockCallBloc extends Mock implements CallBloc {}

// Choosing somebody to call into a conversation: offered where a transfer is,
// since both need nothing but a number, and ended by the choice, since nothing
// about the call changes until the new call is placed.
void main() {
  late _MockCallBloc callBloc;
  late CallController controller;

  setUpAll(() {
    registerFallbackValue(const CallControlEvent.ended(''));
  });

  setUp(() {
    callBloc = _MockCallBloc();
    when(() => callBloc.add(any())).thenReturn(null);
    controller = CallController(callBloc: callBloc);
  });

  AddParticipantPurpose purpose({String anchorCallId = 'b'}) => AddParticipantPurpose(
    announcement: 'Choose who to add to the call',
    pickLabel: (number) => 'Add $number to the call',
    controller: controller,
    anchorCallId: anchorCallId,
  );

  test('is offered by the sections a number can be picked or dialled from, and nowhere else', () {
    for (final flavor in MainFlavor.values) {
      final expected = [
        MainFlavor.favorites,
        MainFlavor.recents,
        MainFlavor.contacts,
        MainFlavor.keypad,
      ].contains(flavor);
      expect(purpose().offeredBy(flavor), expected, reason: flavor.name);
    }
  });

  test('takes anything with a number', () {
    expect(purpose().accepts(const DestinationCandidate()), isFalse);
    expect(purpose().accepts(const DestinationCandidate(number: '200')), isTrue);
  });

  test('opens a chooser instead of taking a contact with several numbers', () {
    const candidate = DestinationCandidate(number: '200', numbers: ['200', '201']);

    expect(purpose().accepts(candidate), isFalse);
    expect(purpose().acceptsFallback(candidate), isTrue);
  });

  test('a contact whose numbers come down to one is taken at once', () {
    const candidate = DestinationCandidate(number: '200', numbers: ['200']);

    expect(purpose().accepts(candidate), isTrue);
    expect(purpose().acceptsFallback(candidate), isFalse);
  });

  test('is ended by the choice and can be given up from the banner', () {
    expect(purpose().closedByChoice, isTrue);
    expect(purpose().cancellable, isTrue);
  });

  test('names the number the control would call in', () {
    expect(purpose().pickLabel(const DestinationCandidate(number: '200')), 'Add 200 to the call');
  });

  test('names a contact with several numbers rather than the number its row shows', () {
    final candidate = DestinationCandidate(number: '200', numbers: const ['200', '201'], contact: _clara());

    expect(purpose().pickLabel(candidate), 'Add ${_clara().displayTitle} to the call');
  });

  test('a choice places the call into the conversation it was asked for', () {
    purpose().submit(const DestinationCandidate(number: '200'));

    verify(() => callBloc.add(const CallControlEvent.participantCallPlaced(anchorCallId: 'b', number: '200')))
        .called(1);
  });

  test('a choice from a contact carries the name the ringing call is shown under', () {
    final contact = _clara();
    purpose().submit(DestinationCandidate(number: '200', contact: contact));

    verify(
      () => callBloc.add(
        CallControlEvent.participantCallPlaced(anchorCallId: 'b', number: '200', displayName: contact.displayTitle),
      ),
    ).called(1);
    expect(contact.displayTitle, contains('Clara'));
  });

  test('two requests for the same conversation are the same request', () {
    expect(purpose(), purpose());
    expect(purpose(), isNot(purpose(anchorCallId: 'd')));
  });
}

Contact _clara() => Contact(
  id: 1,
  sourceType: ContactSourceType.external,
  sourceId: 'contact-1',
  kind: ContactKind.visible,
  firstName: 'Clara',
  lastName: 'Diaz',
);
