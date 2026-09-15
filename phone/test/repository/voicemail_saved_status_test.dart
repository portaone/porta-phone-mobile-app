import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/voicemails_fixture_factory.dart';

// Keeping a message is a flag of its own: it must not disturb the seen flag,
// and a refused change must not leave the screen claiming something the mailbox
// did not take.
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
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      sessionGuard: guard,
    );
    await pumpEventQueue();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<VoicemailData?> stored(String id) => appDatabase.voicemailDao.getVoicemailById(id);

  Future<void> patchAnswers(Future<void> Function() answer) async {
    when(
      () => client.updateUserVoicemail(
        any(),
        any(),
        seen: any(named: 'seen'),
        saved: any(named: 'saved'),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) => answer());
  }

  test('keeping a message sends only that flag and leaves seen alone', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(
      VoicemailsFixtureFactory.createVoicemail(id: '1', seen: true, saved: false),
    );
    await patchAnswers(() async {});

    await repository.updateVoicemailSavedStatus('1', true);

    final row = await stored('1');
    expect(row!.saved, isTrue);
    expect(row.seen, isTrue, reason: 'the two flags are independent');
    verify(() => client.updateUserVoicemail('token', '1', saved: true, locale: null, options: any(named: 'options')))
        .called(1);
  });

  test('unsaving is the same call with the flag cleared', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(
      VoicemailsFixtureFactory.createVoicemail(id: '1', saved: true),
    );
    await patchAnswers(() async {});

    await repository.updateVoicemailSavedStatus('1', false);

    expect((await stored('1'))!.saved, isFalse);
  });

  test('a refused change goes back to what the mailbox had', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(
      VoicemailsFixtureFactory.createVoicemail(id: '1', saved: false),
    );
    final error = api.RequestFailure(url: Uri(), requestId: 'request', statusCode: 500);
    await patchAnswers(() => Future.error(error));

    await expectLater(repository.updateVoicemailSavedStatus('1', true), throwsA(same(error)));

    expect((await stored('1'))!.saved, isFalse);
    expect(guard.errors, isEmpty);
  });

  test('a message the mailbox cannot hold the flag for goes back to reporting nothing', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: '1'));
    await patchAnswers(() => Future.error(StateError('refused')));

    await expectLater(repository.updateVoicemailSavedStatus('1', true), throwsA(isA<StateError>()));

    // Null, not false: absent still means the control does not apply here.
    expect((await stored('1'))!.saved, isNull);
  });

  test('a 401 reverts, reaches the session guard and is rethrown', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(
      VoicemailsFixtureFactory.createVoicemail(id: '1', saved: false),
    );
    final error = api.UnauthorizedException(url: Uri(), requestId: 'request', statusCode: 401);
    await patchAnswers(() => Future.error(error));

    await expectLater(repository.updateVoicemailSavedStatus('1', true), throwsA(same(error)));

    expect((await stored('1'))!.saved, isFalse);
    expect(guard.errors, [same(error)]);
  });

  test('an unknown message is left alone and nothing is sent', () async {
    await patchAnswers(() async {});

    await repository.updateVoicemailSavedStatus('missing', true);

    verifyNever(() => client.updateUserVoicemail(any(), any(), saved: any(named: 'saved')));
  });
}

class _Client extends Mock implements api.WebtritApiClient {}

class _Guard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
