import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Client extends Mock implements api.WebtritApiClient {}

// Whether whoever left a message is in the address book, which a message
// carries as the card itself. A name could not say it: a contact may have none
// and is then shown by its number, exactly like a stranger. Both folders are
// here because they reach the address book differently - the mailbox through a
// join, the trash one number at a time - and must read the same.
void main() {
  late AppDatabase appDatabase;
  late _Client client;
  late VoicemailRepositoryImpl repository;
  late List<api.UserVoicemailSummary> inbox;
  late List<api.UserVoicemailSummary> trash;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
    registerFallbackValue(api.VoicemailFolder.inbox);
  });

  api.UserVoicemailSummary from(String number, {String id = 'vm-1'}) => api.UserVoicemailSummary(
    id: id,
    date: '2026-09-15T10:00:00Z',
    duration: 12,
    seen: true,
    size: 100,
    type: 'audio',
    sender: number,
    receiver: '2000',
  );

  /// A card in the address book whose main number is [number]; without [name]
  /// it is a contact the PBX lists by number alone. [extension] and
  /// [additional] are further numbers of the same contact.
  Future<int> contact(String number, {String? name, String? extension, String? additional}) async {
    final row = await appDatabase.contactsDao.insertOnUniqueConflictUpdateContact(
      ContactDataCompanion.insert(
        sourceType: ContactSourceTypeEnum.external,
        // The PBX's id of the user, which is not a number anybody dials.
        sourceId: Value('pbx-user-$number'),
        aliasName: Value(name),
      ),
    );
    for (final (phone, label) in [
      (number, kContactMainLabel),
      if (extension != null) (extension, kContactExtLabel),
      if (additional != null) (additional, kContactAdditionalLabel),
    ]) {
      await appDatabase.contactPhonesDao.insertOnUniqueConflictUpdateContactPhone(
        ContactPhoneDataCompanion.insert(number: phone, label: label, contactId: row.id),
      );
    }
    return row.id;
  }

  setUp(() async {
    appDatabase = AppDatabase(NativeDatabase.memory());
    client = _Client();
    inbox = [];
    trash = [];

    when(
      () => client.getUserVoicemailList(
        any(),
        folder: any(named: 'folder'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((invocation) async {
      final inTrash = invocation.namedArguments[#folder] == api.VoicemailFolder.trash;
      return api.UserVoicemailListResponse(hasNewMessages: false, items: [...inTrash ? trash : inbox]);
    });
    when(() => client.getVoicemailAttachmentUrl(any(), fileFormat: any(named: 'fileFormat'))).thenReturn('url');

    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      trashSupported: true,
    );
    await pumpEventQueue();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  /// The one message of the mailbox, as a screen would receive it.
  Future<Voicemail> inMailbox() async {
    final listing = repository.watchVoicemails().firstWhere((items) => items.isNotEmpty);
    await repository.fetchVoicemails();
    return (await listing).single;
  }

  /// The one message of the trash.
  Future<Voicemail> inTrash() async => (await repository.fetchTrashedVoicemails()).single;

  for (final (folder, read) in [('the mailbox', inMailbox), ('the trash', inTrash)]) {
    group('a message in $folder', () {
      void holds(api.UserVoicemailSummary message) => folder == 'the trash' ? trash = [message] : inbox = [message];

      test('from a contact with a name carries the card and is called by the name', () async {
        final id = await contact('1000', name: 'Ada Byron');
        holds(from('1000'));

        final message = await read();

        expect(message.isFromContact, isTrue);
        expect(message.senderContact?.id, id);
        expect(message.displaySender, 'Ada Byron');
      });

      test('from a contact without a name carries the card all the same, and is called by the number', () async {
        // What it is called and whether it is a contact are two questions. The
        // menu used to answer the second from the first, and so left "Open
        // contact" out for exactly this contact.
        final id = await contact('1000');
        holds(from('1000'));

        final message = await read();

        expect(message.isFromContact, isTrue);
        expect(message.senderContact?.id, id);
        expect(message.displaySender, '1000');
      });

      test('from a contact without a name is called as the address book titles it, by its extension', () async {
        // Not by the number the message came from: the same person would read
        // "101" in Contacts and "1000" here.
        await contact('1000', extension: '101');
        holds(from('1000'));

        final message = await read();

        expect(message.displaySender, '101');
      });

      test('left from an additional number of a nameless contact, still reads as that contact', () async {
        // The card is found through any of its numbers and titled by its main
        // one, which takes all of its numbers and not only the one matched.
        final id = await contact('1000', additional: '1777');
        holds(from('1777'));

        final message = await read();

        expect(message.senderContact?.id, id);
        expect(message.displaySender, '1000');
      });

      test('from a number the address book does not know carries no card', () async {
        await contact('9999', name: 'Ada Byron');
        holds(from('1000'));

        final message = await read();

        expect(message.isFromContact, isFalse);
        expect(message.displaySender, '1000');
      });
    });
  }
}
