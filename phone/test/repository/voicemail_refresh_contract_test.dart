import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart' as api;
import 'package:app_database/app_database.dart';

import 'package:webtrit_phone/app/session/session_guard.dart';
import 'package:webtrit_phone/repositories/voicemail/voicemail_repository.dart';
import 'package:webtrit_phone/services/polling_service.dart';
import 'package:webtrit_phone/services/polling_task_handle.dart';

import '../mocks/fake_connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Fixture fixture;

  setUp(() async {
    fixture = _Fixture();
    await fixture.repository.refresh(); // Join the constructor's eager fetch.
    clearInteractions(fixture.client);
  });

  test('refresh and direct fetch share one completion and one request', () async {
    final response = Completer<api.UserVoicemailListResponse>();
    when(() => fixture.client.getUserVoicemailList(any(), locale: any(named: 'locale')))
        .thenAnswer((_) => response.future);
    final first = fixture.repository.fetchVoicemails(localeCode: 'en');
    final joined = fixture.repository.refresh();
    var completed = false;
    final observed = joined.then((_) => completed = true);
    await pumpEventQueue();
    expect(completed, isFalse);
    verify(() => fixture.client.getUserVoicemailList('token', locale: 'en')).called(1);
    response.complete(_empty);
    await Future.wait([first, observed]);
    expect(completed, isTrue);
  });

  for (final unauthorized in [true, false]) {
    test(
      '${unauthorized ? '401' : 'remote failure'} completes every joiner with the original error and stack',
      () async {
        final error = unauthorized ? _unauthorized() : StateError('remote failure');
        final stack = StackTrace.fromString('voicemail request origin');
        final response = Completer<api.UserVoicemailListResponse>();
        when(() => fixture.client.getUserVoicemailList(any())).thenAnswer((_) => response.future);
        final first = _expectFailure(fixture.repository.refresh(), error, stack);
        final joined = _expectFailure(fixture.repository.refresh(), error, stack);
        await pumpEventQueue();
        response.completeError(error, stack);
        await Future.wait([first, joined]).timeout(const Duration(seconds: 1));
        verify(() => fixture.client.getUserVoicemailList('token')).called(1);
        expect(fixture.guard.errors, unauthorized ? [same(error)] : isEmpty);

        when(() => fixture.client.getUserVoicemailList(any())).thenAnswer((_) async => _empty);
        await fixture.repository.refresh();
        expect(fixture.repository.isActive, isTrue);
      },
    );
  }

  test('a failed fallback cache read neither replaces the error nor strands joiners', () async {
    final error = StateError('remote failure');
    final stack = StackTrace.fromString('original request stack');
    final response = Completer<api.UserVoicemailListResponse>();
    when(() => fixture.client.getUserVoicemailList(any())).thenAnswer((_) => response.future);
    final first = _expectFailure(fixture.repository.refresh(), error, stack);
    final joined = _expectFailure(fixture.repository.fetchVoicemails(), error, stack);
    await pumpEventQueue();
    when(() => fixture.dao.getVoicemailsWithContacts()).thenThrow(StateError('fallback unavailable'));
    response.completeError(error, stack);
    await Future.wait([first, joined]).timeout(const Duration(seconds: 1));
  });

  test('a failed initial cache read is still a failed refresh without a remote attempt', () async {
    final error = StateError('database unavailable');
    final stack = StackTrace.fromString('cache read origin');
    when(() => fixture.dao.getVoicemailsWithContacts()).thenAnswer((_) => Future.error(error, stack));
    await Future.wait([
      _expectFailure(fixture.repository.refresh(), error, stack),
      _expectFailure(fixture.repository.refresh(), error, stack),
    ]).timeout(const Duration(seconds: 1));
    verifyNever(() => fixture.client.getUserVoicemailList(any()));
  });

  for (final unsupported in [false, true]) {
    test(
      '${unsupported ? 'unsupported endpoint' : 'unconfigured mailbox'} fails once then stops remote work',
      () async {
        final error = unsupported
            ? api.EndpointNotSupportedException(
                url: Uri(),
                requestId: 'request',
                statusCode: 501,
                recognizedNotSupportedCodes: ['501'],
              )
            : api.VoicemailNotConfiguredException(url: Uri(), requestId: 'request', statusCode: 422);
        final stack = StackTrace.fromString('feature unavailable');
        final fallback = Completer<List<VoicemailWithContact>>();
        final response = Completer<api.UserVoicemailListResponse>();
        when(() => fixture.client.getUserVoicemailList(any())).thenAnswer((_) => response.future);
        final first = _expectFailure(fixture.repository.refresh(), error, stack);
        await pumpEventQueue();
        when(() => fixture.dao.getVoicemailsWithContacts()).thenAnswer((_) => fallback.future);
        response.completeError(error, stack);
        await pumpEventQueue();
        expect(fixture.repository.isActive, isFalse);
        // Even after the capability changes, an existing flight keeps its outcome.
        final joined = _expectFailure(fixture.repository.refresh(), error, stack);
        fallback.complete([]);
        await Future.wait([first, joined]);
        await fixture.repository.refresh();
        verify(() => fixture.client.getUserVoicemailList('token')).called(1);
      },
    );
  }

  for (final operation in ['remove', 'removeAll', 'removeMultiple', 'seen']) {
    test('$operation waiting for a refresh fails promptly instead of hanging on 401', () async {
      final error = _unauthorized();
      final stack = StackTrace.fromString('shared auth failure');
      final response = Completer<api.UserVoicemailListResponse>();
      when(() => fixture.client.getUserVoicemailList(any())).thenAnswer((_) => response.future);
      final first = _expectFailure(fixture.repository.refresh(), error, stack);
      final mutation = switch (operation) {
        'remove' => fixture.repository.removeVoicemail('message'),
        'removeAll' => fixture.repository.removeAllVoicemails(),
        'removeMultiple' => fixture.repository.removeMultipleVoicemails(['message']),
        _ => fixture.repository.updateVoicemailSeenStatus('message', true),
      };
      final waiting = _expectFailure(mutation, error, stack);
      response.completeError(error, stack);
      await Future.wait([first, waiting]).timeout(const Duration(seconds: 1));
      verifyNever(() => fixture.dao.getAllVoicemails());
      verifyNever(() => fixture.dao.getVoicemailById(any()));
      expect(fixture.guard.errors, [same(error)]);
    });
  }

  test('eager fetch owns its detached failure without hiding it from a polling joiner', () {
    fakeAsync((async) {
      final error = _unauthorized();
      final stack = StackTrace.fromString('startup auth failure');
      final starting = _Fixture();
      final response = Completer<api.UserVoicemailListResponse>();
      when(() => starting.client.getUserVoicemailList(any())).thenAnswer((_) => response.future);
      final task = _register(starting.repository);
      async.flushMicrotasks();
      expect(task.state.phase, PollingTaskPhase.running);
      response.completeError(error, stack);
      async.flushMicrotasks();
      expect(task.state.phase, PollingTaskPhase.failed);
      expect(task.state.error, same(error));
      expect(task.state.stackTrace, same(stack));
      expect(starting.guard.errors, [same(error)]);
    });
  });

  test('shared failures back off and recovery restores the normal interval', () {
    fakeAsync((async) {
      var attempts = 0;
      when(() => fixture.client.getUserVoicemailList(any())).thenAnswer((_) async {
        if (++attempts <= 2) throw StateError('remote failure');
        return _empty;
      });
      final task = _register(fixture.repository);
      async.flushMicrotasks();
      expect(task.state.phase, PollingTaskPhase.failed);
      async.elapse(const Duration(seconds: 19));
      expect(attempts, 1);
      async.elapse(const Duration(seconds: 1));
      expect(attempts, 2);
      expect(task.state.phase, PollingTaskPhase.failed);
      async.elapse(const Duration(seconds: 39));
      expect(attempts, 2);
      async.elapse(const Duration(seconds: 1));
      expect(task.state.phase, PollingTaskPhase.succeeded);
      expect(attempts, 3);
      async.elapse(const Duration(seconds: 9));
      expect(attempts, 3);
      async.elapse(const Duration(seconds: 1));
      expect(attempts, 4);
    });
  });

  test('unavailable voicemail is stopped by polling after the failed attempt', () {
    fakeAsync((async) {
      when(() => fixture.client.getUserVoicemailList(any())).thenAnswer(
        (_) async => throw api.VoicemailNotConfiguredException(url: Uri(), requestId: 'request', statusCode: 422),
      );
      final task = _register(fixture.repository);
      async.flushMicrotasks();
      expect(task.state.phase, PollingTaskPhase.failed);
      async.elapse(const Duration(seconds: 20));
      expect(task.state.phase, PollingTaskPhase.stopped);
      async.elapse(const Duration(minutes: 10));
      verify(() => fixture.client.getUserVoicemailList('token')).called(1);
    });
  });
}

const _empty = api.UserVoicemailListResponse(hasNewMessages: false, items: []);

api.UnauthorizedException _unauthorized() =>
    api.UnauthorizedException(url: Uri(), requestId: 'request', statusCode: 401);

Future<void> _expectFailure(Future<void> future, Object error, StackTrace stack) => future.then<void>(
  (_) => fail('A failed refresh must not complete normally.'),
  onError: (Object actualError, StackTrace actualStack) {
    expect(actualError, same(error));
    expect(actualStack, same(stack));
  },
);

PollingTaskHandle _register(VoicemailRepository repository) {
  final connectivity = FakeConnectivityService(initialConnected: true);
  addTearDown(connectivity.dispose);
  final polling = PollingService(connectivityService: connectivity, options: const PollingOptions(jitterRatio: 0));
  addTearDown(polling.dispose);
  return polling.register(PollingRegistration(listener: repository, interval: const Duration(seconds: 10)));
}

class _Fixture {
  _Fixture() {
    when(() => database.voicemailDao).thenReturn(dao);
    when(() => dao.getVoicemailsWithContacts()).thenAnswer((_) async => []);
    // A completed refresh now makes the stored list match what the mailbox
    // reported; these tests care about the refresh contract, not the store.
    when(() => dao.deleteVoicemailsNotIn(any())).thenAnswer((_) async => 0);
    when(() => client.getUserVoicemailList(any())).thenAnswer((_) async => _empty);
    repository = VoicemailRepositoryImpl(
      webtritApiClient: client,
      token: 'token',
      appDatabase: database,
      trashSupported: true,
      sessionGuard: guard,
    );
  }

  final client = _Client();
  final database = _Database();
  final dao = _Dao();
  final guard = _Guard();
  late final VoicemailRepositoryImpl repository;
}

class _Client extends Mock implements api.WebtritApiClient {}

class _Database extends Mock implements AppDatabase {}

class _Dao extends Mock implements VoicemailDao {}

class _Guard implements SessionGuard {
  final errors = <Exception>[];
  @override
  void onUnauthorized(Exception e) => errors.add(e);
}
