import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/empty_session_guard.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/voicemails_fixture_factory.dart';

// The stored list is made to match what the mailbox reports, so a message
// deleted or trashed from somewhere else stops showing here. The dangerous half
// is the other one: a refresh that only half happened must decide nothing.
void main() {
  late AppDatabase appDatabase;
  late _Client client;
  late VoicemailRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
    registerFallbackValue(api.VoicemailFolder.inbox);
  });

  // The repository fetches eagerly from its own constructor, so everything it
  // reaches for has to answer before it is built - and that first cycle has to
  // be allowed to finish, or the shared in-flight future would hand a test the
  // result of a call it never set up.
  Future<void> buildRepository() async {
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      sessionGuard: const EmptySessionGuard(),
    );
    await pumpEventQueue();
  }

  setUp(() {
    appDatabase = AppDatabase(NativeDatabase.memory());
    client = _Client();
    when(() => client.getVoicemailAttachmentUrl(any(), fileFormat: any(named: 'fileFormat'))).thenReturn('url');
  });

  tearDown(() async {
    await appDatabase.close();
  });

  api.UserVoicemailSummary summary(String id) =>
      api.UserVoicemailSummary(id: id, date: '2026-09-15T10:00:00Z', duration: 1, seen: false, size: 1, type: 'voice');

  api.UserVoicemail details(String id) => api.UserVoicemail(
    id: id,
    date: '2026-09-15T10:00:00Z',
    duration: 1,
    sender: '1',
    receiver: '2',
    seen: false,
    size: 1,
    type: 'voice',
    attachments: const [],
  );

  void listReturns(List<String> ids) {
    when(
      () => client.getUserVoicemailList(
        any(),
        folder: any(named: 'folder'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => api.UserVoicemailListResponse(hasNewMessages: false, items: ids.map(summary).toList()));
  }

  void detailsReturn({String? failOn}) {
    when(() => client.getUserVoicemail(any(), any(), locale: any(named: 'locale'))).thenAnswer((invocation) async {
      final id = invocation.positionalArguments[1] as String;
      if (id == failOn) throw StateError('details unavailable');
      return details(id);
    });
  }

  Future<void> store(List<String> ids) async {
    for (final id in ids) {
      await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: id));
    }
  }

  Future<List<String>> storedIds() async =>
      (await appDatabase.voicemailDao.getAllVoicemails()).map((voicemail) => voicemail.id).toList();

  test('a message the mailbox no longer reports is dropped', () async {
    listReturns([]);
    detailsReturn();
    await buildRepository();

    await store(['gone', 'kept']);
    listReturns(['kept']);

    await repository.fetchVoicemails();

    expect(await storedIds(), ['kept']);
  });

  test('an empty mailbox empties the list', () async {
    listReturns([]);
    detailsReturn();
    await buildRepository();

    await store(['gone']);

    await repository.fetchVoicemails();

    expect(await storedIds(), isEmpty);
  });

  test('a half-finished refresh decides nothing', () async {
    // The listing arrives, then one message's details fail. The set is
    // incomplete, so nothing may be read as "the mailbox no longer has it".
    listReturns([]);
    detailsReturn();
    await buildRepository();

    await store(['stored-earlier']);
    listReturns(['a', 'b']);
    detailsReturn(failOn: 'b');

    await expectLater(repository.fetchVoicemails(), throwsA(isA<StateError>()));

    expect(await storedIds(), contains('stored-earlier'));
  });

  test('a listing that never arrived decides nothing', () async {
    await store(['stored-earlier']);
    when(
      () => client.getUserVoicemailList(
        any(),
        folder: any(named: 'folder'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) => Future.error(StateError('offline')));

    await expectLater(repository.fetchVoicemails(), throwsA(isA<StateError>()));

    expect(await storedIds(), ['stored-earlier']);
  });
}

class _Client extends Mock implements api.WebtritApiClient {}
