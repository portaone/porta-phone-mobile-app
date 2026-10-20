import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/call/bloc/call_bloc.dart';
import 'package:webtrit_phone/features/call/controllers/call_controller.dart';
import 'package:webtrit_phone/features/call/models/models.dart';
import 'package:webtrit_phone/models/models.dart';

class _MockCallBloc extends Mock implements CallBloc {}

// Choosing whom to call before handing a call over: offered where the blind
// transfer is, since both need nothing but a number, and ended by the choice,
// since nothing about the call changes until the second call is placed.
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

  AttendedTransferPurpose purpose({String anchorCallId = 'b'}) => AttendedTransferPurpose(
    announcement: 'Choose who to consult before transferring',
    pickLabel: (number) => 'Consult $number before transferring the call',
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
    expect(purpose().accepts(const DestinationCandidate(number: '300')), isTrue);
  });

  test('opens a chooser instead of taking a contact with several numbers', () {
    const candidate = DestinationCandidate(number: '300', numbers: ['300', '301']);

    expect(purpose().accepts(candidate), isFalse);
    expect(purpose().acceptsFallback(candidate), isTrue);
  });

  test('a contact whose numbers come down to one is taken at once', () {
    const candidate = DestinationCandidate(number: '300', numbers: ['300']);

    expect(purpose().accepts(candidate), isTrue);
    expect(purpose().acceptsFallback(candidate), isFalse);
  });

  test('names a contact with several numbers rather than the number its row shows', () {
    final contact = Contact(
      id: 1,
      sourceType: ContactSourceType.external,
      sourceId: 'contact-1',
      kind: ContactKind.visible,
      firstName: 'Clara',
    );
    final candidate = DestinationCandidate(number: '300', numbers: const ['300', '301'], contact: contact);

    expect(purpose().pickLabel(candidate), 'Consult ${contact.displayTitle} before transferring the call');
    expect(purpose().pickLabel(const DestinationCandidate(number: '300')), 'Consult 300 before transferring the call');
  });

  test('is ended by the choice and can be given up from the banner', () {
    expect(purpose().closedByChoice, isTrue);
    expect(purpose().cancellable, isTrue);
  });

  test('a choice places the second call for the call it was asked for', () {
    purpose().submit(const DestinationCandidate(number: '300'));

    verify(() => callBloc.add(const CallControlEvent.attendedTransferCallPlaced(anchorCallId: 'b', number: '300')))
        .called(1);
  });

  test('two requests for the same call are the same request', () {
    expect(purpose(), purpose());
    expect(purpose(), isNot(purpose(anchorCallId: 'd')));
  });
}
