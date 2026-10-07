import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/voicemail/bloc/voicemail_cubit.dart';
import 'package:webtrit_phone/features/voicemail/cubits/cubits.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

// WT-2056.
//
// A forwarded message names its forwarder by the user id the backend issued,
// which on PortaSwitch is an internal account id nobody has ever seen. The
// address book is what turns it into something a person recognises - and a
// colleague in it is not always a colleague with a name: an account may carry
// a number and nothing else.
//
// The address book here is the real one over a database, not a double: what
// went wrong was a contact read without its numbers, and a double would have
// handed them over regardless.
void main() {
  const userId = '1001712';
  const number = '12065550100';

  late AppDatabase appDatabase;
  late StreamController<List<Voicemail>> voicemails;
  late VoicemailSessionCubit session;
  late VoicemailCubit cubit;

  final forwarded = Voicemail(
    id: 'fwd-1',
    date: '2026-09-15T10:00:00Z',
    duration: 1,
    sender: '101',
    receiver: '102',
    status: ReadStatus.unread,
    size: 1,
    type: 'voice',
    url: null,
    forwardedBy: userId,
  );

  Future<void> storeColleague({String? firstName, String? lastName, String? extension}) async {
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
    if (extension != null) {
      await appDatabase.contactPhonesDao.insertOnUniqueConflictUpdateContactPhone(
        ContactPhoneDataCompanion.insert(number: extension, label: kContactExtLabel, contactId: contact.id),
      );
    }
  }

  Future<String?> forwarderShown() async {
    voicemails.add([forwarded]);
    await pumpEventQueue();

    return cubit.view.forwarderOf(forwarded);
  }

  setUp(() {
    appDatabase = AppDatabase(NativeDatabase.memory());
    voicemails = StreamController<List<Voicemail>>.broadcast();
    final repository = _Repository();
    when(() => repository.isFeatureSupported).thenReturn(true);
    when(() => repository.watchVoicemails()).thenAnswer((_) => voicemails.stream);
    when(() => repository.watchUnreadVoicemailsCount()).thenAnswer((_) => const Stream.empty());
    when(() => repository.fetchVoicemails()).thenAnswer((_) async {});
    final contacts = ContactsRepository(
      appDatabase: appDatabase,
      contactsRemoteDataSource: null,
      contactsLocalDataSource: null,
    );
    // The names are looked up by the session, which owns the mailbox; the
    // screen shows what it found.
    session = VoicemailSessionCubit(repository: repository, contactsRepository: contacts)..init();
    cubit = VoicemailCubit(
      repository: repository,
      session: session,
      contactsRepository: contacts,
      onCallStarted: (_) {},
      onSubmitNotification: (_) {},
      saveSupported: true,
      trashSupported: true,
      forwardSupported: true,
    );
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
    await voicemails.close();
    await appDatabase.close();
  });

  test('a colleague with a name is named', () async {
    await storeColleague(firstName: 'Iryna', lastName: 'Shevchuk');

    expect(await forwarderShown(), 'Iryna Shevchuk');
  });

  test('a colleague without a name is shown by their number', () async {
    await storeColleague();

    // The contact is found and its number is known, so the id is the one thing
    // there is no reason to fall back to.
    expect(await forwarderShown(), number);
  });

  test('a colleague without a name is shown by their extension when they have one', () async {
    await storeColleague(extension: '101');

    // The same order the address book lists them in, so the forwarder reads
    // here as the person does there.
    expect(await forwarderShown(), '101');
  });

  test('a colleague the address book does not know is shown by their id', () async {
    expect(await forwarderShown(), userId);
  });
}

class _Repository extends Mock implements VoicemailRepository {}
