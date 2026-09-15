import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/voicemails_fixture_factory.dart';

// The trash is read on demand and never stored, so what these pin is the two
// halves of that: what reaches the caller, and what does NOT reach the stored
// inbox. A trashed message that landed in the database would come back as an
// inbox message on the next screen that reads it.
void main() {
  late AppDatabase appDatabase;
  late _Client client;
  late _Guard guard;
  late VoicemailRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
    registerFallbackValue(api.VoicemailFolder.inbox);
  });

  api.UserVoicemailSummary summary(String id, {bool? saved, String? forwardedBy}) => api.UserVoicemailSummary(
    id: id,
    date: '2026-09-15T10:00:00Z',
    duration: 12,
    seen: true,
    size: 100,
    type: 'audio',
    saved: saved,
    forwardedBy: forwardedBy,
  );

  api.UserVoicemail details(String id, {String sender = '1000'}) => api.UserVoicemail(
    id: id,
    date: '2026-09-15T10:00:00Z',
    duration: 12,
    sender: sender,
    receiver: '2000',
    seen: true,
    size: 100,
    type: 'audio',
    attachments: const [],
  );

  // The inbox listing the constructor's eager fetch runs into. Kept empty so a
  // test's own expectations are about the trash and nothing else.
  void inboxIsEmpty() {
    when(
      () => client.getUserVoicemailList(
        any(),
        folder: any(named: 'folder'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => const api.UserVoicemailListResponse(hasNewMessages: false, items: []));
  }

  void trashHolds(List<api.UserVoicemailSummary> items) {
    when(
      () => client.getUserVoicemailList(
        any(),
        folder: api.VoicemailFolder.trash,
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => api.UserVoicemailListResponse(hasNewMessages: false, items: items));
  }

  setUp(() async {
    appDatabase = AppDatabase(NativeDatabase.memory());
    client = _Client();
    guard = _Guard();
    inboxIsEmpty();
    when(() => client.getVoicemailAttachmentUrl(any(), fileFormat: any(named: 'fileFormat'))).thenReturn('url');
    when(
      () => client.getUserVoicemail(
        any(),
        any(),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async => details(invocation.positionalArguments[1] as String));
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      trashSupported: true,
      sessionGuard: guard,
    );
    // Join the eager refresh the constructor starts, so a test does not race it.
    await pumpEventQueue();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<List<String>> storedIds() async =>
      (await appDatabase.voicemailDao.getAllVoicemails()).map((voicemail) => voicemail.id).toList();

  test('asks for the trash and not for the inbox', () async {
    trashHolds([summary('trashed-1')]);

    await repository.fetchTrashedVoicemails();

    verify(
      () => client.getUserVoicemailList(
        'token',
        folder: api.VoicemailFolder.trash,
        locale: any(named: 'locale'),
      ),
    ).called(1);
  });

  test('an empty trash is an empty list', () async {
    trashHolds([]);

    expect(await repository.fetchTrashedVoicemails(), isEmpty);
    verifyNever(() => client.getUserVoicemail(any(), any(), locale: any(named: 'locale')));
  });

  test('a message is built from the listing and its own details', () async {
    trashHolds([summary('trashed-1', saved: true, forwardedBy: 'colleague')]);

    final trashed = await repository.fetchTrashedVoicemails();

    expect(trashed, hasLength(1));
    // The listing carries neither sender nor receiver, so a message that has
    // them proves the per-message fetch happened and was mapped in.
    expect(trashed.single.id, 'trashed-1');
    expect(trashed.single.sender, '1000');
    expect(trashed.single.receiver, '2000');
    expect(trashed.single.saved, isTrue);
    expect(trashed.single.forwardedBy, 'colleague');
  });

  test('a stored contact names the sender', () async {
    await _storeContact(appDatabase, number: '1000', firstName: 'Ada', lastName: 'Byron');
    trashHolds([summary('trashed-1')]);

    final trashed = await repository.fetchTrashedVoicemails();

    expect(trashed.single.displaySender, 'Ada Byron');
  });

  test('an unknown number stands in for the name', () async {
    await _storeContact(appDatabase, number: '9999', firstName: 'Ada', lastName: 'Byron');
    trashHolds([summary('trashed-1')]);

    final trashed = await repository.fetchTrashedVoicemails();

    expect(trashed.single.displaySender, '1000');
  });

  test('nothing about the trash is stored', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: 'inbox-1'));
    trashHolds([summary('trashed-1'), summary('trashed-2')]);

    await repository.fetchTrashedVoicemails();

    // Both halves matter: the trashed messages did not arrive, and the message
    // that is legitimately in the inbox was not swept out by reading the trash.
    expect(await storedIds(), ['inbox-1']);
  });

  test('the locale reaches the listing and every message read for it', () async {
    trashHolds([summary('trashed-1')]);

    await repository.fetchTrashedVoicemails(localeCode: 'uk');

    verify(() => client.getUserVoicemailList('token', folder: api.VoicemailFolder.trash, locale: 'uk')).called(1);
    verify(() => client.getUserVoicemail('token', 'trashed-1', locale: 'uk')).called(1);
  });

  test('a 401 reaches the session guard and is rethrown', () async {
    final error = api.UnauthorizedException(url: Uri(), requestId: 'request', statusCode: 401);
    when(
      () => client.getUserVoicemailList(
        any(),
        folder: api.VoicemailFolder.trash,
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) => Future.error(error));

    await expectLater(repository.fetchTrashedVoicemails(), throwsA(same(error)));

    expect(guard.errors, [same(error)]);
  });

  test('a failure on one message fails the read rather than hiding it', () async {
    final error = api.RequestFailure(url: Uri(), requestId: 'request', statusCode: 500);
    trashHolds([summary('trashed-1')]);
    when(() => client.getUserVoicemail('token', 'trashed-1', locale: any(named: 'locale')))
        .thenAnswer((_) => Future.error(error));

    // A trash screen showing a short list is worse than one showing an error:
    // the missing message is exactly the one the user came to recover.
    await expectLater(repository.fetchTrashedVoicemails(), throwsA(same(error)));
  });
}

Future<void> _storeContact(
  AppDatabase appDatabase, {
  required String number,
  required String firstName,
  required String lastName,
}) async {
  final contact = await appDatabase.contactsDao.insertOnUniqueConflictUpdateContact(
    ContactDataCompanion.insert(
      sourceType: ContactSourceTypeEnum.external,
      sourceId: Value(number),
      firstName: Value(firstName),
      lastName: Value(lastName),
    ),
  );
  await appDatabase.contactPhonesDao.insertOnUniqueConflictUpdateContactPhone(
    ContactPhoneDataCompanion.insert(number: number, label: 'work', contactId: contact.id),
  );
}

class _Client extends Mock implements api.WebtritApiClient {}

class _Guard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
