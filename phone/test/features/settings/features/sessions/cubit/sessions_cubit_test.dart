import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/settings/features/sessions/cubit/sessions_cubit.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockSessionsRepository extends Mock implements SessionsRepository {}

ActiveSession _session(String id, {bool current = false}) => ActiveSession(id: id, current: current);

void main() {
  group('SessionsCubit', () {
    late _MockSessionsRepository repository;

    setUp(() {
      repository = _MockSessionsRepository();
    });

    test('fetch exposes the sessions returned by the repository', () async {
      final sessions = [_session('a', current: true), _session('b')];
      when(() => repository.getSessions()).thenAnswer((_) async => SessionList(sessions: sessions));

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      expect(cubit.state.sessions, equals(sessions));
      expect(cubit.state.loading, isFalse);
      expect(cubit.state.failed, isFalse);
      await cubit.close();
    });

    test('fetch keeps the previously loaded sessions when it fails', () async {
      final sessions = [_session('a', current: true), _session('b')];
      when(() => repository.getSessions()).thenAnswer((_) async => SessionList(sessions: sessions));

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      when(() => repository.getSessions()).thenThrow(Exception('offline'));
      await cubit.fetch();

      expect(cubit.state.sessions, equals(sessions));
      expect(cubit.state.failed, isTrue);
      expect(cubit.state.loading, isFalse);
      await cubit.close();
    });

    test('revoke drops the revoked session from the list', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true), _session('b')]));
      when(() => repository.revokeSession('b')).thenAnswer((_) async {});

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      final succeeded = await cubit.revoke('b');

      expect(succeeded, isTrue);
      expect(cubit.state.sessions.map((s) => s.id), equals(['a']));
      expect(cubit.state.revoking, isEmpty);
      await cubit.close();
    });

    test('revoke keeps the session and reports failure when the request fails', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true), _session('b')]));
      when(() => repository.revokeSession('b')).thenThrow(Exception('offline'));

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      final succeeded = await cubit.revoke('b');

      expect(succeeded, isFalse);
      expect(cubit.state.sessions.map((s) => s.id), equals(['a', 'b']));
      expect(cubit.state.revoking, isEmpty);
      await cubit.close();
    });

    test('revokeAllOthers revokes every session but the current one', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true), _session('b'), _session('c')]));
      when(() => repository.revokeSession(any())).thenAnswer((_) async {});

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      final succeeded = await cubit.revokeAllOthers();

      expect(succeeded, isTrue);
      expect(cubit.state.sessions.map((s) => s.id), equals(['a']));
      verify(() => repository.revokeSession('b')).called(1);
      verify(() => repository.revokeSession('c')).called(1);
      verifyNever(() => repository.revokeSession('a'));
      await cubit.close();
    });

    test('revokeAllOthers keeps the sessions it could not revoke', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true), _session('b'), _session('c')]));
      when(() => repository.revokeSession('b')).thenAnswer((_) async {});
      when(() => repository.revokeSession('c')).thenThrow(Exception('offline'));

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      final succeeded = await cubit.revokeAllOthers();

      expect(succeeded, isFalse);
      expect(cubit.state.sessions.map((s) => s.id), equals(['a', 'c']));
      await cubit.close();
    });

    test('fetch exposes when idle sessions end, as the core said', () async {
      const autoTerminate = SessionAutoTerminate(inactivityTimeoutDays: 30, installationMaxDays: 90);
      when(() => repository.getSessions())
          .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true)], autoTerminate: autoTerminate));

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      expect(cubit.state.autoTerminate, autoTerminate);
      await cubit.close();
    });

    test('a core that stopped sending the period takes it off the screen', () async {
      when(() => repository.getSessions()).thenAnswer(
        (_) async => SessionList(
          sessions: [_session('a', current: true)],
          autoTerminate: const SessionAutoTerminate(inactivityTimeoutDays: 30, installationMaxDays: 90),
        ),
      );
      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      when(() => repository.getSessions())
          .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true)]));
      await cubit.fetch();

      expect(cubit.state.autoTerminate, isNull);
      await cubit.close();
    });

    group('setInactivityTimeout', () {
      const before = SessionAutoTerminate(inactivityTimeoutDays: 90, installationMaxDays: 90);

      Future<SessionsCubit> loaded() async {
        when(() => repository.getSessions())
            .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true)], autoTerminate: before));
        final cubit = SessionsCubit(repository);
        await cubit.fetch();
        return cubit;
      }

      test('shows what the core answered, and nothing before it answered', () async {
        const after = SessionAutoTerminate(inactivityTimeoutDays: 7, installationMaxDays: 90);
        final answer = Completer<SessionAutoTerminate>();
        when(() => repository.setInactivityTimeout(7)).thenAnswer((_) => answer.future);
        final cubit = await loaded();

        final pending = cubit.setInactivityTimeout(7);
        expect(cubit.state.savingAutoTerminate, isTrue);
        expect(cubit.state.autoTerminate, before);

        answer.complete(after);
        expect(await pending, SessionAutoTerminateSaveResult.saved);
        expect(cubit.state.autoTerminate, after);
        expect(cubit.state.savingAutoTerminate, isFalse);
        await cubit.close();
      });

      test('a fetch started before a save cannot restore its old period', () async {
        const after = SessionAutoTerminate(inactivityTimeoutDays: 7, installationMaxDays: 90);
        final staleFetch = Completer<SessionList>();
        final cubit = await loaded();
        when(() => repository.getSessions()).thenAnswer((_) => staleFetch.future);
        when(() => repository.setInactivityTimeout(7)).thenAnswer((_) async => after);

        final pendingFetch = cubit.fetch();
        expect(cubit.state.loading, isTrue);
        expect(await cubit.setInactivityTimeout(7), SessionAutoTerminateSaveResult.saved);
        expect(cubit.state.autoTerminate, after);

        staleFetch.complete(SessionList(sessions: [_session('a', current: true)], autoTerminate: before));
        await pendingFetch;

        expect(cubit.state.autoTerminate, after);
        expect(cubit.state.loading, isFalse);
        await cubit.close();
      });

      test('null is passed on as the way back to the installation period', () async {
        when(() => repository.setInactivityTimeout(null)).thenAnswer((_) async => before);
        final cubit = await loaded();

        expect(await cubit.setInactivityTimeout(null), SessionAutoTerminateSaveResult.saved);
        verify(() => repository.setInactivityTimeout(null)).called(1);
        await cubit.close();
      });

      test('a failure keeps the period that was in force', () async {
        when(() => repository.setInactivityTimeout(7)).thenThrow(Exception('503 external_api_issue'));
        final cubit = await loaded();

        expect(await cubit.setInactivityTimeout(7), SessionAutoTerminateSaveResult.failed);
        expect(cubit.state.autoTerminate, before);
        expect(cubit.state.savingAutoTerminate, isFalse);
        await cubit.close();
      });

      test('a limit lowered since the screen was read reloads it', () async {
        const lowered = SessionAutoTerminate(inactivityTimeoutDays: 14, installationMaxDays: 14);
        when(
          () => repository.setInactivityTimeout(30),
        ).thenThrow(const SessionAutoTerminateRefusedException(SessionAutoTerminateRefusal.exceedsInstallationLimit));
        final cubit = await loaded();
        when(() => repository.getSessions())
            .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true)], autoTerminate: lowered));

        expect(await cubit.setInactivityTimeout(30), SessionAutoTerminateSaveResult.exceedsInstallationLimit);
        expect(cubit.state.autoTerminate, lowered);
        await cubit.close();
      });

      test('a refusal whose required reload fails is a retryable failure', () async {
        when(
          () => repository.setInactivityTimeout(30),
        ).thenThrow(const SessionAutoTerminateRefusedException(SessionAutoTerminateRefusal.exceedsInstallationLimit));
        final cubit = await loaded();
        when(() => repository.getSessions()).thenThrow(Exception('offline'));

        expect(await cubit.setInactivityTimeout(30), SessionAutoTerminateSaveResult.failed);
        expect(cubit.state.autoTerminate, before);
        expect(cubit.state.failed, isTrue);
        expect(cubit.state.savingAutoTerminate, isFalse);
        await cubit.close();
      });

      test('a save is the latest until another one begins', () async {
        when(() => repository.setInactivityTimeout(any())).thenThrow(Exception('503 external_api_issue'));
        final cubit = await loaded();

        await cubit.setInactivityTimeout(7);
        final failed = cubit.latestSave;
        expect(cubit.isLatestSave(failed), isTrue);

        final pending = cubit.setInactivityTimeout(30);
        expect(cubit.isLatestSave(failed), isFalse, reason: 'the newer save began before it was answered');
        await pending;
        expect(cubit.isLatestSave(cubit.latestSave), isTrue);
        await cubit.close();
      });

      test('an answer that comes after the cubit was closed is dropped', () async {
        const after = SessionAutoTerminate(inactivityTimeoutDays: 7, installationMaxDays: 90);
        final answer = Completer<SessionAutoTerminate>();
        when(() => repository.setInactivityTimeout(7)).thenAnswer((_) => answer.future);
        final cubit = await loaded();

        final pending = cubit.setInactivityTimeout(7);
        await cubit.close();
        answer.complete(after);

        expect(await pending, SessionAutoTerminateSaveResult.saved);
        expect(cubit.state.autoTerminate, before);
      });

      test('a failure that comes after the cubit was closed is still reported', () async {
        final answer = Completer<SessionAutoTerminate>();
        when(() => repository.setInactivityTimeout(7)).thenAnswer((_) => answer.future);
        final cubit = await loaded();

        final pending = cubit.setInactivityTimeout(7);
        await cubit.close();
        answer.completeError(Exception('503 external_api_issue'));

        expect(await pending, SessionAutoTerminateSaveResult.failed);
      });

      test('a refusal that comes after the cubit was closed reloads nothing', () async {
        final answer = Completer<SessionAutoTerminate>();
        when(() => repository.setInactivityTimeout(30)).thenAnswer((_) => answer.future);
        final cubit = await loaded();

        final pending = cubit.setInactivityTimeout(30);
        await cubit.close();
        answer.completeError(
          const SessionAutoTerminateRefusedException(SessionAutoTerminateRefusal.exceedsInstallationLimit),
        );

        expect(await pending, SessionAutoTerminateSaveResult.exceedsInstallationLimit);
        verify(() => repository.getSessions()).called(1);
      });

      test('a capability withdrawn since the screen was read reloads it', () async {
        when(() => repository.setInactivityTimeout(7))
            .thenThrow(const SessionAutoTerminateRefusedException(SessionAutoTerminateRefusal.notSupported));
        final cubit = await loaded();

        expect(await cubit.setInactivityTimeout(7), SessionAutoTerminateSaveResult.notSupported);
        verify(() => repository.getSessions()).called(2);
        await cubit.close();
      });
    });

    test('hasOtherSessions is false when only the current session is left', () async {
      when(() => repository.getSessions())
          .thenAnswer((_) async => SessionList(sessions: [_session('a', current: true)]));

      final cubit = SessionsCubit(repository);
      await cubit.fetch();

      expect(cubit.state.hasOtherSessions, isFalse);
      await cubit.close();
    });
  });
}
