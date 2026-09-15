import 'package:flutter_test/flutter_test.dart';

// ignore: depend_on_referenced_packages
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../mocks/voicemails_fixture_factory.dart';

// Forwarding is the one operation that writes into somebody else's mailbox, so
// what it must NOT do locally matters as much as what it sends.
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
      trashSupported: true,
      sessionGuard: guard,
    );
    await pumpEventQueue();
  });

  tearDown(() async {
    await appDatabase.close();
  });

  void forwardAnswers(Future<String> Function() answer) {
    when(
      () => client.forwardUserVoicemail(
        any(),
        any(),
        toUserId: any(named: 'toUserId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((_) => answer());
  }

  test('answers with the id the message has in the recipient list', () async {
    forwardAnswers(() async => 'fwd_5f1c');

    final id = await repository.forwardVoicemail('vm-1', toUserId: '123009');

    expect(id, 'fwd_5f1c');
    verify(
      () => client.forwardUserVoicemail(
        'token',
        'vm-1',
        toUserId: '123009',
        idempotencyKey: any(named: 'idempotencyKey'),
        locale: null,
      ),
    ).called(1);
  });

  test('the sender keeps their own copy and gains nothing', () async {
    await appDatabase.voicemailDao.insertOrUpdateVoicemail(VoicemailsFixtureFactory.createVoicemail(id: 'vm-1'));
    forwardAnswers(() async => 'fwd_5f1c');

    await repository.forwardVoicemail('vm-1', toUserId: '123009');

    // The copy is in the other mailbox; nothing here changes.
    final stored = await appDatabase.voicemailDao.getAllVoicemails();
    expect(stored.map((voicemail) => voicemail.id), ['vm-1']);
  });

  test('each forward carries a key of its own', () async {
    final keys = <String>[];
    when(
      () => client.forwardUserVoicemail(
        any(),
        any(),
        toUserId: any(named: 'toUserId'),
        idempotencyKey: any(named: 'idempotencyKey'),
        locale: any(named: 'locale'),
        options: any(named: 'options'),
      ),
    ).thenAnswer((invocation) async {
      keys.add(invocation.namedArguments[#idempotencyKey] as String);
      return 'fwd_1';
    });

    await repository.forwardVoicemail('vm-1', toUserId: '1');
    await repository.forwardVoicemail('vm-1', toUserId: '2');

    // Two deliberate forwards are two messages, so they must not share a key -
    // reusing one is how a retry is told apart from a new send.
    expect(keys, hasLength(2));
    expect(keys.first, isNotEmpty);
    expect(keys.first, isNot(keys.last));
  });

  test('a refusal reaches the caller as it is', () async {
    final error = api.VoicemailForwardRecipientNotFoundException(url: Uri(), requestId: 'request', statusCode: 404);
    forwardAnswers(() => Future.error(error));

    await expectLater(repository.forwardVoicemail('vm-1', toUserId: 'nobody'), throwsA(same(error)));
  });

  test('a 401 reaches the session guard and is rethrown', () async {
    final error = api.UnauthorizedException(url: Uri(), requestId: 'request', statusCode: 401);
    forwardAnswers(() => Future.error(error));

    await expectLater(repository.forwardVoicemail('vm-1', toUserId: '1'), throwsA(same(error)));

    expect(guard.errors, [same(error)]);
  });
}

class _Client extends Mock implements api.WebtritApiClient {}

class _Guard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
