import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/contacts/contacts.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

/// The preferences the app keeps about what the contacts section was left
/// showing, with nothing behind them.
class _Remembered implements ActiveContactSourceTypeRepository {
  _Remembered({this.sourceType = ContactSourceType.external, this.favorites = false});

  ContactSourceType sourceType;
  bool favorites;
  bool cleared = false;

  @override
  ContactSourceType getActiveContactSourceType({ContactSourceType defaultValue = ContactSourceType.external}) =>
      sourceType;

  @override
  Future<void> setActiveContactSourceType(ContactSourceType value) async => sourceType = value;

  @override
  bool getFavoritesPicked({bool defaultValue = false}) => favorites;

  @override
  Future<void> setFavoritesPicked(bool value) async => favorites = value;

  @override
  Future<void> clear() async => cleared = true;
}

void main() {
  group('ContactsBloc - what the contacts section was left showing', () {
    test('starts on what was remembered, the address book and the pick alike', () {
      final remembered = _Remembered(sourceType: ContactSourceType.local, favorites: true);

      final bloc = ContactsBloc(activeContactSourceTypeRepository: remembered);
      addTearDown(bloc.close);

      expect(bloc.state.sourceType, ContactSourceType.local);
      expect(bloc.state.favorites, isTrue);
    });

    test('a section nobody has chosen anything in starts on an address book', () {
      final bloc = ContactsBloc(activeContactSourceTypeRepository: _Remembered());
      addTearDown(bloc.close);

      expect(bloc.state.favorites, isFalse);
    });

    test('picking the favourites is remembered', () async {
      final remembered = _Remembered();
      final bloc = ContactsBloc(activeContactSourceTypeRepository: remembered);
      addTearDown(bloc.close);

      bloc.add(const ContactsListSelectionChanged(ContactsFavoritesSelection()));
      await expectLater(bloc.stream, emits(predicate<ContactsState>((state) => state.favorites)));

      expect(remembered.favorites, isTrue);
    });

    test('picking an address book leaves the favourites, and says so to both', () async {
      // WT-1924: the chooser offers one list at a time, so a book and the
      // favourites cannot both be the answer - and the next start must open
      // on the book.
      final remembered = _Remembered(favorites: true);
      final bloc = ContactsBloc(activeContactSourceTypeRepository: remembered);
      addTearDown(bloc.close);

      bloc.add(const ContactsListSelectionChanged(ContactsSourceSelection(ContactSourceType.local)));
      await expectLater(
        bloc.stream,
        emits(predicate<ContactsState>((state) => state.sourceType == ContactSourceType.local && !state.favorites)),
      );

      expect(remembered.sourceType, ContactSourceType.local);
      expect(remembered.favorites, isFalse);
    });

    test('picking the favourites keeps the address book to come back to', () async {
      final remembered = _Remembered(sourceType: ContactSourceType.local);
      final bloc = ContactsBloc(activeContactSourceTypeRepository: remembered);
      addTearDown(bloc.close);

      bloc.add(const ContactsListSelectionChanged(ContactsFavoritesSelection()));
      await expectLater(bloc.stream, emits(predicate<ContactsState>((state) => state.favorites)));

      expect(bloc.state.sourceType, ContactSourceType.local);
      expect(remembered.sourceType, ContactSourceType.local);
    });

    test('the pick is shown before it is written down, not after', () {
      // A menu entry is a tap, not typing: the list under a chooser that has
      // already closed must not wait on the device's storage.
      final bloc = ContactsBloc(activeContactSourceTypeRepository: _Remembered());
      addTearDown(bloc.close);

      bloc.add(const ContactsListSelectionChanged(ContactsFavoritesSelection()));

      return expectLater(
        bloc.stream.first.timeout(const Duration(milliseconds: 100)),
        completion(predicate<ContactsState>((state) => state.favorites)),
      );
    });

    test('the arrangement with favourites elsewhere leaves the pick alone', () async {
      // The tabbed screen has no favourites entry to pick, so its own event
      // states an address book and nothing more.
      final remembered = _Remembered(favorites: true);
      final bloc = ContactsBloc(activeContactSourceTypeRepository: remembered);
      addTearDown(bloc.close);

      bloc.add(const ContactsSourceTypeChanged(ContactSourceType.local));
      await expectLater(
        bloc.stream,
        emits(predicate<ContactsState>((state) => state.sourceType == ContactSourceType.local)),
      );

      expect(remembered.favorites, isTrue);
    });
  });
}
