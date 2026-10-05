import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// WT-2056.
//
// A forwarded message names its forwarder by the user id the backend issued,
// which on PortaSwitch is an internal account id nobody has ever seen. The
// address book is what turns it into something a person recognises - and a
// colleague in it is not always a colleague with a name: an account may carry
// a number and nothing else.
void main() {
  const userId = '1001712';
  const number = '12065550100';

  late AppDatabase appDatabase;
  late VoicemailRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(api.VoicemailFolder.inbox);
  });

  Future<void> storeColleague({String? firstName, String? lastName}) async {
    final contact = await appDatabase.contactsDao.insertOnUniqueConflictUpdateContact(
      ContactDataCompanion.insert(
        sourceType: ContactSourceTypeEnum.external,
        sourceId: const Value(userId),
        firstName: Value(firstName),
        lastName: Value(lastName),
      ),
    );
    await appDatabase.contactPhonesDao.insertOnUniqueConflictUpdateContactPhone(
      ContactPhoneDataCompanion.insert(number: number, label: kContactMainLabel, contactId: contact.id),
    );
  }

  setUp(() async {
    appDatabase = AppDatabase(NativeDatabase.memory());
    final client = _Client();
    when(
      () => client.getUserVoicemailList(
        any(),
        folder: any(named: 'folder'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => const api.UserVoicemailListResponse(hasNewMessages: false, items: []));
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      trashSupported: false,
    );
    // Join the eager refresh the constructor starts, so a test does not race it.
    await pumpEventQueue();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  test('a colleague with a name is named', () async {
    await storeColleague(firstName: 'Iryna', lastName: 'Shevchuk');

    expect(await repository.resolveForwarderNames([userId]), {userId: 'Iryna Shevchuk'});
  });

  test('a colleague without a name is shown by their number', () async {
    await storeColleague();

    // The contact is found and its number is known, so the id is the one thing
    // there is no reason to fall back to.
    expect(await repository.resolveForwarderNames([userId]), {userId: number});
  });

  test('a colleague the address book does not know is left unresolved', () async {
    expect(await repository.resolveForwarderNames([userId]), isEmpty);
  });
}

class _Client extends Mock implements api.WebtritApiClient {}
