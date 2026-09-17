import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// WT-1818, reported as PortaOne-32807.
//
// The PBX numbering plan is <main number> + <extension>, so an employee's
// number CONTAINS the company main number as a prefix. Calling the main number
// used to label the history row with the name of whichever extension holder
// sorted first.
//
// The DAO has its own tests for the ending match. This exercises the chain the
// report actually walks: an exact lookup that misses, the national significant
// number the repository derives from the dialled number, and the ending lookup
// it then asks for.
void main() {
  const mainNumber = '18667478647';
  const lowestExtension = '186674786477003';
  const otherExtension = '186674786477619';

  late AppDatabase appDatabase;
  late ContactsRepository repository;

  Future<void> seedContact(int id, String sourceId, String name, String number) async {
    await appDatabase.contactsDao.insertOnUniqueConflictUpdateContact(
      ContactDataCompanion(
        sourceType: const Value(ContactSourceTypeEnum.external),
        sourceId: Value(sourceId),
        lastName: Value(name),
      ),
    );
    await appDatabase.contactPhonesDao.insertOnUniqueConflictUpdateContactPhone(
      ContactPhoneDataCompanion(contactId: Value(id), number: Value(number), label: const Value('Work')),
    );
  }

  setUp(() async {
    appDatabase = AppDatabase(NativeDatabase.memory());
    repository = ContactsRepository(
      appDatabase: appDatabase,
      contactsRemoteDataSource: null,
      contactsLocalDataSource: null,
    );

    // Every employee's number contains the main number, exactly as the report
    // describes. The main number itself is nobody: it is the auto-attendant,
    // which is why the exact lookup misses and the fallback runs at all.
    await seedContact(1, 'ext7003', 'Lowest Extension', lowestExtension);
    await seedContact(2, 'ext7619', 'Other Extension', otherExtension);
  });

  tearDown(() async => appDatabase.close());

  test('the company main number resolves to nobody', () async {
    expect(await repository.watchContactByPhoneNumber(mainNumber).first, isNull);
  });

  test('an extension holder is still found by their own number', () async {
    final lowest = await repository.watchContactByPhoneNumber(lowestExtension).first;
    final other = await repository.watchContactByPhoneNumber(otherExtension).first;

    expect(lowest?.lastName, 'Lowest Extension');
    expect(other?.lastName, 'Other Extension');
  });

  test('the fallback the lookup exists for still works', () async {
    // The PBX prefixes a country code the local phonebook entry does not carry,
    // so the dialled number is +380507259336 while the contact is saved as
    // 0507259336. This is the case the ending match was added for.
    await seedContact(3, 'kyiv', 'Kyiv Local', '0507259336');

    final contact = await repository.watchContactByPhoneNumber('+380507259336').first;

    expect(contact?.lastName, 'Kyiv Local');
  });
}
