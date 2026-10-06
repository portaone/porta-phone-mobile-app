import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:app_database/app_database.dart';
import 'package:app_database/src/daos/contact_search.dart';

void main() {
  late AppDatabase database;

  Future<void> insertContact(
    String firstName,
    String lastName,
    String number, {
    String? email,
    String? secondNumber,
  }) async {
    final contact = await database.contactsDao.insertOnUniqueConflictUpdateContact(
      ContactDataCompanion(
        sourceType: const Value(ContactSourceTypeEnum.external),
        sourceId: Value('$firstName-$lastName'),
        firstName: Value(firstName),
        lastName: Value(lastName),
      ),
    );
    for (final contactNumber in [number, ?secondNumber]) {
      await database.contactPhonesDao.insertOnUniqueConflictUpdateContactPhone(
        ContactPhoneDataCompanion(
          contactId: Value(contact.id),
          number: Value(contactNumber),
          label: const Value('ext'),
        ),
      );
    }
    if (email != null) {
      await database.contactEmailsDao.insertOnUniqueConflictUpdateContactEmail(
        ContactEmailDataCompanion(contactId: Value(contact.id), address: Value(email), label: const Value('work')),
      );
    }
  }

  /// The names a search lists, in order. The query is split into words the way
  /// `ContactsRepository.watchContacts` splits it.
  Future<List<String>> search(String query) async {
    final searchBits = query.split(' ').where((value) => value.isNotEmpty);
    final contacts = await database.contactsDao.watchAllContacts(searchBits).first;
    return contacts.map((data) => '${data.contact.firstName} ${data.contact.lastName}').toList();
  }

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());

    await insertContact('Yevhen', 'Dovhopol', '1001', email: 'y.d@example.com');
    // Carries "dov" in the email only.
    await insertContact('Yevhen', 'Dem', '1002', email: 'dovzhyk@example.com');
    await insertContact('Yevhenia', 'Bondar', '1003');
    await insertContact('Andriy', 'Yevtushenko', '1004');
    // Carries "yev" in the email only.
    await insertContact('Bohdan', 'Petrenko', '1005', email: 'yev@example.com');
    await insertContact('Oleh', 'Dovzhenko', '1006');
    // Carries "yev" in the middle of the last name.
    await insertContact('Serhiy', 'Kyevsky', '1007');
    await insertContact('Zoya', 'Melnyk', '2001', secondNumber: '2002');
  });

  tearDown(() async {
    await database.close();
  });

  group('contact search relevance', () {
    test('a first name starting with the query comes first, then a last name', () async {
      expect(await search('Yev'), [
        'Yevhen Dem',
        'Yevhen Dovhopol',
        'Yevhenia Bondar',
        'Andriy Yevtushenko',
        'Serhiy Kyevsky',
        'Bohdan Petrenko',
      ]);
    });

    test('a second word narrows the result to contacts carrying both', () async {
      // Yevhen Dem carries "do" in the email, so it stays - below the name match.
      expect(await search('Yevhen Do'), ['Yevhen Dovhopol', 'Yevhen Dem']);
    });

    test('a full name lists that contact alone', () async {
      expect(await search('Yevhen Dovhopol'), ['Yevhen Dovhopol']);
    });

    test('a match in the name is above a match in the email alone', () async {
      expect(await search('dov'), ['Oleh Dovzhenko', 'Yevhen Dovhopol', 'Yevhen Dem']);
    });
  });

  group('a contact found by a search', () {
    test('keeps every number when one of them matched', () async {
      final contacts = await database.contactsDao.watchAllContacts(['2002']).first;

      expect(contacts.single.phones.map((phone) => phone.number), unorderedEquals(['2001', '2002']));
    });
  });

  group('the database and the ranking agree on what is found', () {
    // The database keeps and the ranking orders. Both read a word through one
    // pattern, so the contacts the database keeps have to be exactly the ones
    // the ranking can place.
    setUp(() async {
      await insertContact('Тарас', 'Шевченко', '3001', email: 'KOBZAR@example.com');
      await insertContact('  Anna', 'Acme (HQ)', '+380 (50) 300-20-02');
      await insertContact('C++', 'Developer', '3003', email: 'c.plus@example.com');
    });

    for (final query in [
      'yev',
      'YEV',
      'ШЕВ',
      'шевч',
      'kobzar',
      '(hq)',
      'c++',
      '.*',
      '+380',
      '(50)',
      'anna acme',
      'yevhen do',
      'Yevhen 1001',
      'тарас kobzar 3001',
      'zzzz',
    ]) {
      test('for "$query"', () async {
        final words = query.split(' ');
        final everyContact = await database.contactsDao.watchAllContacts().first;
        final search = ContactSearch(words);
        final answering = everyContact.where((data) => search.matchOf(data) != null).toList();
        final ranked = search.rank(answering).map((data) => data.contact.id);

        final found = await database.contactsDao.watchAllContacts(words).first;

        expect(found.map((data) => data.contact.id), ranked);
      });
    }
  });
}
