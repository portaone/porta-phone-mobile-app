import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

void main() {
  const local = ContactsSourceSelection(ContactSourceType.local);
  const external = ContactsSourceSelection(ContactSourceType.external);
  const favorites = ContactsFavoritesSelection();

  group('which address book is shown', () {
    test('the one that was remembered, when it is still offered', () {
      expect(
        [ContactSourceType.local, ContactSourceType.external].shown(ContactSourceType.external),
        ContactSourceType.external,
      );
    });

    test('the first one, when what was remembered is no longer offered', () {
      // The choice outlives a change of configuration, and it starts out as a
      // default nobody made.
      expect([ContactSourceType.external].shown(ContactSourceType.local), ContactSourceType.external);
    });

    test('none, when no address book is offered at all', () {
      expect(<ContactSourceType>[].shown(ContactSourceType.local), isNull);
    });
  });

  group('which list is shown', () {
    test('the favourites, when they were picked and are offered', () {
      expect([local, external, favorites].shown(remembered: ContactSourceType.local, favorites: true), favorites);
    });

    test('the remembered book, when the favourites were not picked', () {
      expect([local, external, favorites].shown(remembered: ContactSourceType.local, favorites: false), local);
    });

    test('an address book, when the favourites were picked but are no longer offered', () {
      // A section that stopped carrying favourites must not open on a list it
      // does not offer.
      expect([local, external].shown(remembered: ContactSourceType.external, favorites: true), external);
    });

    test('the first book, when the remembered one is no longer offered', () {
      expect([external, favorites].shown(remembered: ContactSourceType.local, favorites: false), external);
    });

    test('the first BOOK rather than the first entry, when favourites come first', () {
      // Favourites hold only the people someone has starred, so opening on
      // them when nothing was chosen would greet a new account with an empty
      // screen.
      expect([favorites, external].shown(remembered: ContactSourceType.local, favorites: false), external);
    });

    test('the favourites, when they are all there is', () {
      // Reachable without anyone meaning it: a tab configured for extensions,
      // on a core that does not carry them, loses its only book.
      expect([favorites].shown(remembered: ContactSourceType.external, favorites: false), favorites);
    });

    test('the favourites, when nothing at all is offered', () {
      // A tab configured with no lists shows an empty screen, exactly as the
      // tabbed arrangement does with no address books.
      expect(<ContactsListSelection>[].shown(remembered: ContactSourceType.external, favorites: false), favorites);
    });
  });

  group('what the entries offer', () {
    test('the address books among them, in the order they are offered', () {
      expect([favorites, external, local].sourceTypes, [ContactSourceType.external, ContactSourceType.local]);
    });

    test('whether the favourites are one of them', () {
      expect([local, favorites].offersFavorites, isTrue);
      expect([local, external].offersFavorites, isFalse);
      expect(<ContactsListSelection>[].offersFavorites, isFalse);
    });
  });
}
