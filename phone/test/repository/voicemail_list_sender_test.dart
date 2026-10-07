import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _Client extends Mock implements api.WebtritApiClient {}

// A read of the mailbox is the list and nothing else. Who left a message is
// taken off the list item; the request for a single message, which a read used
// to make for every one of them - about two seconds each on a real PBX - is not
// made at all. The real repository and DAO against a client that has no answer
// for that request, so a test that provoked it would fail on the missing stub.
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

  /// A list item; without [from] it is one the backend could not name the
  /// sender of.
  api.UserVoicemailSummary listed(String id, {String? from, bool seen = true}) => api.UserVoicemailSummary(
    id: id,
    date: '2026-09-15T10:00:00Z',
    duration: 12,
    seen: seen,
    size: 100,
    type: 'audio',
    sender: from,
    receiver: from == null ? null : '2000',
  );

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

  Future<Map<String, String>> storedSenders() async => {
    for (final row in await appDatabase.voicemailDao.getAllVoicemails()) row.id: row.sender,
  };

  void expectNoMessageWasAskedFor() {
    verifyNever(() => client.getUserVoicemail(any(), any(), locale: any(named: 'locale')));
  }

  test('a read stores who left each message as the list names them, and asks about none', () async {
    inbox = [listed('1', from: '1001'), listed('2', from: '1002'), listed('3', from: '1003')];

    await repository.fetchVoicemails();

    expect(await storedSenders(), {'1': '1001', '2': '1002', '3': '1003'});
    expectNoMessageWasAskedFor();
  });

  test('a read repeated asks about no message either', () async {
    // Polling reads the mailbox every few minutes; each read is one request.
    inbox = [listed('1', from: '1001'), listed('2', from: '1002')];

    await repository.fetchVoicemails();
    await repository.fetchVoicemails();

    verify(() => client.getUserVoicemailList(any(), locale: any(named: 'locale'))).called(3);
    expectNoMessageWasAskedFor();
  });

  test('the trash is read the same way', () async {
    trash = [listed('7', from: '1007'), listed('8', from: '1008')];

    final trashed = await repository.fetchTrashedVoicemails();

    expect(trashed.map((voicemail) => voicemail.sender), ['1007', '1008']);
    expectNoMessageWasAskedFor();
  });

  group('a message the backend lists without a sender', () {
    // It could not read that message's headers, and lists it without them
    // rather than failing the whole list.

    test('is stored all the same, with nobody known to have left it', () async {
      inbox = [listed('1', from: '1001'), listed('2'), listed('3', from: '1003')];

      await repository.fetchVoicemails();

      expect(await storedSenders(), {'1': '1001', '2': '', '3': '1003'});
      expectNoMessageWasAskedFor();
    });

    test('reaches the screen as a message that has no sender', () async {
      inbox = [listed('1', from: '1001'), listed('2')];
      final listing = repository.watchVoicemails().firstWhere((items) => items.length == 2);

      await repository.fetchVoicemails();
      final byId = {for (final voicemail in await listing) voicemail.id: voicemail};

      expect(byId['1']!.hasSender, isTrue);
      expect(byId['2']!.hasSender, isFalse);
      expect(byId['2']!.displaySender, isEmpty);
    });

    test('a backend too old to list senders gives a mailbox of such messages, and is asked about none', () async {
      // Voicemail still runs against it, every caller unknown. Asking it about
      // each message instead is what made the mailbox slow.
      inbox = [listed('1'), listed('2'), listed('3')];

      await repository.fetchVoicemails();

      expect(await storedSenders(), {'1': '', '2': '', '3': ''});
      expectNoMessageWasAskedFor();
    });

    test('is listed in the trash too', () async {
      trash = [listed('7')];

      final trashed = await repository.fetchTrashedVoicemails();

      expect(trashed.single.hasSender, isFalse);
      expectNoMessageWasAskedFor();
    });
  });
}
