import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/contact/contact.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class MockContactsRepository extends Mock implements ContactsRepository {}

class MockFavoritesRepository extends Mock implements FavoritesRepository {}

class MockSipSubscriptionsRepository extends Mock implements SipSubscriptionsRepository {}

void main() {
  const contactId = 1;

  late MockContactsRepository contactsRepository;

  setUp(() {
    contactsRepository = MockContactsRepository();
  });

  ContactBloc build() => ContactBloc(
    contactId,
    contactsRepository: contactsRepository,
    favoritesRepository: MockFavoritesRepository(),
    sipSubscriptionsRepository: MockSipSubscriptionsRepository(),
  );

  Contact contactWrittenAt(DateTime updatedAt) => Contact(
    id: contactId,
    sourceType: ContactSourceType.external,
    kind: ContactKind.visible,
    sourceId: 'user-1',
    registered: true,
    updatedAt: updatedAt,
  );

  final firstRefresh = DateTime(2026, 11, 25, 12);
  final nextRefresh = DateTime(2026, 11, 25, 12, 5);

  blocTest<ContactBloc, ContactState>(
    'follows the age of the registration when a refresh rewrites the contact unchanged',
    // The contact is the same contact after a refresh that changed nothing,
    // since the time it was written is not part of its equality. The card
    // still has to say the registration was read again, so the state moves.
    setUp: () {
      when(() => contactsRepository.watchContact(contactId, includeSipSubscriptions: true))
          .thenAnswer((_) => Stream.fromIterable([contactWrittenAt(firstRefresh), contactWrittenAt(nextRefresh)]));
    },
    build: build,
    act: (bloc) => bloc.add(const ContactStarted()),
    expect: () => [
      isA<ContactState>()
          .having((s) => s.contact, 'contact', contactWrittenAt(firstRefresh))
          .having((s) => s.registeredAsOf, 'registeredAsOf', firstRefresh),
      isA<ContactState>()
          .having((s) => s.contact, 'contact', contactWrittenAt(firstRefresh))
          .having((s) => s.registeredAsOf, 'registeredAsOf', nextRefresh),
    ],
  );
}
