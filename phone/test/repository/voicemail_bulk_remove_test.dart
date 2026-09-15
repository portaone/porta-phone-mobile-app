import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/voicemails_fixture_factory.dart';

// Bulk removal goes message by message and the server may refuse some of
// them. These tests pin what a partial outcome leaves behind: the real DAO
// against a client whose DELETE answers per message.
void main() {
  late AppDatabase appDatabase;
  late _Client client;
  late _Guard guard;
  late VoicemailRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const api.RequestOptions());
  });

  setUp(() {
    appDatabase = AppDatabase(NativeDatabase.memory());
    client = _Client();
    guard = _Guard();
    when(() => client.getUserVoicemailList(any(), locale: any(named: 'locale')))
        .thenAnswer((_) async => api.UserVoicemailListResponse(hasNewMessages: false, items: const []));
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: appDatabase,
      sessionGuard: guard,
    );
  });

  tearDown(() async {
    await appDatabase.close();
  });

  Future<void> insert(List<String> ids) async {
    for (final id in ids) {
      await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: id));
    }
  }

  Future<List<String>> storedIds() async =>
      (await appDatabase.voicemailDao.getAllVoicemails()).map((voicemail) => voicemail.id).toList();

  void deleteAnswers(Map<String, Object?> outcomes) {
    when(
      () => client.deleteUserVoicemail(
        any(),
        any(),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) {
      final id = invocation.positionalArguments[1] as String;
      final outcome = outcomes[id];
      return outcome == null ? Future.value() : Future.error(outcome);
    });
  }

  api.RequestFailure refused() => api.RequestFailure(url: Uri(), requestId: 'request', statusCode: 500);

  api.UnauthorizedException unauthorized() =>
      api.UnauthorizedException(url: Uri(), requestId: 'request', statusCode: 401);

  group('removeMultipleVoicemails', () {
    test('deletes locally what the server deleted', () async {
      await insert(['1', '2', '3']);
      deleteAnswers({});

      await repository.removeMultipleVoicemails(['1', '3']);

      expect(await storedIds(), ['2']);
    });

    test('a refused message stays, the rest go, and the failure is rethrown', () async {
      await insert(['1', '2', '3']);
      final error = refused();
      deleteAnswers({'2': error});

      await expectLater(repository.removeMultipleVoicemails(['1', '2', '3']), throwsA(same(error)));

      expect(await storedIds(), ['2']);
      verify(() => client.deleteUserVoicemail('token', '3', options: any(named: 'options'))).called(1);
      expect(guard.errors, isEmpty);
    });

    test('the first of several failures is the one rethrown', () async {
      await insert(['1', '2', '3']);
      final first = refused();
      final second = refused();
      deleteAnswers({'1': first, '3': second});

      await expectLater(repository.removeMultipleVoicemails(['1', '2', '3']), throwsA(same(first)));

      expect(await storedIds(), ['1', '3']);
    });

    test('a session that went missing stops the loop instead of being skipped', () async {
      await insert(['1', '2', '3']);
      final error = api.SessionMissingException(url: Uri(), requestId: 'request', statusCode: 401);
      deleteAnswers({'2': error});

      await expectLater(repository.removeMultipleVoicemails(['1', '2', '3']), throwsA(same(error)));

      expect(await storedIds(), ['2', '3']);
      verifyNever(() => client.deleteUserVoicemail('token', '3', options: any(named: 'options')));
    });

    test('voicemail being switched off stops the loop', () async {
      await insert(['1', '2', '3']);
      final error = api.VoicemailNotConfiguredException(url: Uri(), requestId: 'request', statusCode: 422);
      deleteAnswers({'2': error});

      await expectLater(repository.removeMultipleVoicemails(['1', '2', '3']), throwsA(same(error)));

      expect(await storedIds(), ['2', '3']);
      verifyNever(() => client.deleteUserVoicemail('token', '3', options: any(named: 'options')));
    });

    test('a request that never reached the server stops the loop', () async {
      await insert(['1', '2', '3']);
      final error = TimeoutException('no route to host');
      deleteAnswers({'2': error});

      await expectLater(repository.removeMultipleVoicemails(['1', '2', '3']), throwsA(same(error)));

      expect(await storedIds(), ['2', '3']);
      verifyNever(() => client.deleteUserVoicemail('token', '3', options: any(named: 'options')));
    });

    test('a 401 stops the loop, reaches the session guard and is rethrown', () async {
      await insert(['1', '2', '3']);
      final error = unauthorized();
      deleteAnswers({'2': error});

      await expectLater(repository.removeMultipleVoicemails(['1', '2', '3']), throwsA(same(error)));

      expect(await storedIds(), ['2', '3']);
      verifyNever(() => client.deleteUserVoicemail('token', '3', options: any(named: 'options')));
      expect(guard.errors, [same(error)]);
    });
  });

  group('removeAllVoicemails', () {
    test('removes every stored message', () async {
      await insert(['1', '2']);
      deleteAnswers({});

      await repository.removeAllVoicemails();

      expect(await storedIds(), isEmpty);
    });

    test('keeps what the server refused and rethrows', () async {
      await insert(['1', '2']);
      final error = refused();
      deleteAnswers({'1': error});

      await expectLater(repository.removeAllVoicemails(), throwsA(same(error)));

      expect(await storedIds(), ['1']);
    });
  });
}

class _Client extends Mock implements api.WebtritApiClient {}

class _Guard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
