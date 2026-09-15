import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/voicemails_fixture_factory.dart';

// The seen flag is written locally first and sent to the server second. What the
// server answers decides whether the local write stays: these tests drive the
// real DAO against a client whose PATCH can fail.
void main() {
  late AppDatabase appDatabase;
  late _Client client;
  late _Guard guard;
  late VoicemailRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
  });

  setUp(() async {
    appDatabase = AppDatabase(NativeDatabase.memory());
    client = _Client();
    guard = _Guard();
    // The repository fetches eagerly on construction; an empty mailbox keeps
    // that out of the way of the rows each test inserts itself.
    when(() => client.getUserVoicemailList(any(), locale: any(named: 'locale')))
        .thenAnswer((_) async => api.UserVoicemailListResponse(hasNewMessages: false, items: const []));
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      sessionGuard: guard,
    );
    // Let the refresh the constructor starts finish before a test seeds or
    // asserts. It is detached (`.ignore()`), so without this a test races the
    // very cycle it is exercising: what it observes depends on which of the two
    // reaches the database first.
    await pumpEventQueue();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<bool> seenOf(String id) async => (await appDatabase.voicemailDao.getVoicemailById(id))!.seen;

  Future<void> patchAnswers(Future<void> Function() answer) async {
    when(
      () => client.updateUserVoicemail(
        any(),
        any(),
        seen: any(named: 'seen'),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) => answer());
  }

  test('a patch the server accepted keeps the local change', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: '1'));
    await patchAnswers(() async {});

    await repository.updateVoicemailSeenStatus('1', true);

    expect(await seenOf('1'), isTrue);
    verify(() => client.updateUserVoicemail('token', '1', seen: true, locale: null, options: any(named: 'options')))
        .called(1);
  });

  test('a patch the server refused reverts to the value the message had before', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(
      VoicemailsFixtureFactory.createVoicemail(id: '1', seen: true),
    );
    final error = api.RequestFailure(url: Uri(), requestId: 'request', statusCode: 500);
    await patchAnswers(() => Future.error(error));

    await expectLater(repository.updateVoicemailSeenStatus('1', false), throwsA(same(error)));

    expect(await seenOf('1'), isTrue);
    expect(guard.errors, isEmpty);
  });

  test('the revert waits for the server: the flag is not restored before the patch settles', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: '1'));
    var flipped = false;
    await patchAnswers(() async {
      // Observed while the request is in flight: the optimistic write is visible.
      flipped = await seenOf('1');
      throw StateError('network');
    });

    await expectLater(repository.updateVoicemailSeenStatus('1', true), throwsA(isA<StateError>()));

    expect(flipped, isTrue);
    expect(await seenOf('1'), isFalse);
  });

  test('a 401 reverts, reaches the session guard and is rethrown', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: '1'));
    final error = api.UnauthorizedException(url: Uri(), requestId: 'request', statusCode: 401);
    await patchAnswers(() => Future.error(error));

    await expectLater(repository.updateVoicemailSeenStatus('1', true), throwsA(same(error)));

    expect(await seenOf('1'), isFalse);
    expect(guard.errors, [same(error)]);
  });

  test('the patch is sent without retries', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: '1'));
    await patchAnswers(() async {});

    await repository.updateVoicemailSeenStatus('1', true);

    final options =
        verify(
              () => client.updateUserVoicemail(
                any(),
                any(),
                seen: any(named: 'seen'),
                locale: any(named: 'locale'),
                options: captureAny(named: 'options'),
              ),
            ).captured.single
            as api.RequestOptions;
    expect(options.retries, 0);
  });

  test('an unknown message is left alone and nothing is sent', () async {
    await repository.updateVoicemailSeenStatus('missing', true);

    verifyNever(
      () => client.updateUserVoicemail(
        any(),
        any(),
        seen: any(named: 'seen'),
        options: any(named: 'options'),
      ),
    );
  });
}

class _Client extends Mock implements api.WebtritApiClient {}

class _Guard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
