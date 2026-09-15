import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/voicemails_fixture_factory.dart';

// Restoring, deleting for good and emptying the trash. Only two of the three
// touch the stored list, and which two is the point: a trashed message left it
// on its way there, so emptying has nothing local left to do.
void main() {
  late AppDatabase appDatabase;
  late _Client client;
  late _Guard guard;
  late VoicemailRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
    registerFallbackValue(api.VoicemailFolder.inbox);
  });

  setUp(() async {
    appDatabase = AppDatabase(NativeDatabase.memory());
    client = _Client();
    guard = _Guard();
    when(
      () => client.getUserVoicemailList(
        any(),
        folder: any(named: 'folder'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => const api.UserVoicemailListResponse(hasNewMessages: false, items: []));
    when(() => client.getVoicemailAttachmentUrl(any(), fileFormat: any(named: 'fileFormat'))).thenReturn('url');
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      trashSupported: true,
      sessionGuard: guard,
    );
    await pumpEventQueue();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<List<String>> storedIds() async =>
      (await appDatabase.voicemailDao.getAllVoicemails()).map((voicemail) => voicemail.id).toList();

  api.UnauthorizedException unauthorized() =>
      api.UnauthorizedException(url: Uri(), requestId: 'request', statusCode: 401);

  group('restore', () {
    test('asks the mailbox again rather than rebuilding the row', () async {
      when(
        () => client.restoreUserVoicemail(
          any(),
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => client.getUserVoicemailList(
          any(),
          folder: any(named: 'folder'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer(
        (_) async => api.UserVoicemailListResponse(
          hasNewMessages: false,
          items: [
            const api.UserVoicemailSummary(
              id: 'vm-1',
              date: '2026-09-15T10:00:00Z',
              duration: 1,
              seen: false,
              size: 1,
              type: 'voice',
            ),
          ],
        ),
      );
      when(() => client.getUserVoicemail(any(), any(), locale: any(named: 'locale'))).thenAnswer(
        (_) async => const api.UserVoicemail(
          id: 'vm-1',
          date: '2026-09-15T10:00:00Z',
          duration: 1,
          sender: '1',
          receiver: '2',
          seen: false,
          size: 1,
          type: 'voice',
          attachments: [],
        ),
      );

      await repository.restoreVoicemail('vm-1');

      expect(await storedIds(), ['vm-1']);
    });

    test('a 401 reaches the session guard and is rethrown', () async {
      final error = unauthorized();
      when(
        () => client.restoreUserVoicemail(
          any(),
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => Future.error(error));

      await expectLater(repository.restoreVoicemail('vm-1'), throwsA(same(error)));

      expect(guard.errors, [same(error)]);
    });
  });

  group('deleting for good', () {
    test('says permanent whether or not there is a trash, and drops the row', () async {
      await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: 'vm-1'));
      when(
        () => client.deleteUserVoicemail(
          any(),
          any(),
          permanent: any(named: 'permanent'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      await repository.removeVoicemailPermanently('vm-1');

      verify(() => client.deleteUserVoicemail('token', 'vm-1', permanent: true, options: any(named: 'options')))
          .called(1);
      expect(await storedIds(), isEmpty);
    });

    test('a refusal leaves the row where it was', () async {
      await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: 'vm-1'));
      when(
        () => client.deleteUserVoicemail(
          any(),
          any(),
          permanent: any(named: 'permanent'),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => Future.error(StateError('refused')));

      await expectLater(repository.removeVoicemailPermanently('vm-1'), throwsA(isA<StateError>()));

      expect(await storedIds(), ['vm-1']);
    });
  });

  group('emptying the trash', () {
    test('leaves the stored list alone, because the trash was never in it', () async {
      await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: 'inbox-1'));
      when(
        () => client.emptyUserVoicemailTrash(
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      await repository.emptyVoicemailTrash();

      expect(await storedIds(), ['inbox-1']);
    });

    test('a 401 reaches the session guard and is rethrown', () async {
      final error = unauthorized();
      when(
        () => client.emptyUserVoicemailTrash(
          any(),
          locale: any(named: 'locale'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) => Future.error(error));

      await expectLater(repository.emptyVoicemailTrash(), throwsA(same(error)));

      expect(guard.errors, [same(error)]);
    });
  });
}

class _Client extends Mock implements api.WebtritApiClient {}

class _Guard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
