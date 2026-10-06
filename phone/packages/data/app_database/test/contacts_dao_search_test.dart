import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:app_database/app_database.dart';

void main() {
  late AppDatabase database;

  Future<void> insertContact(String firstName, String lastName, String number, {String? email}) async {
    final contact = await database.contactsDao.insertOnUniqueConflictUpdateContact(
      ContactDataCompanion(
        sourceType: const Value(ContactSourceTypeEnum.external),
        sourceId: Value('$firstName-$lastName'),
        firstName: Value(firstName),
        lastName: Value(lastName),
      ),
    );
    await database.contactPhonesDao.insertOnUniqueConflictUpdateContactPhone(
      ContactPhoneDataCompanion(contactId: Value(contact.id), number: Value(number), label: const Value('ext')),
    );
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
}
