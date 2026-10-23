import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/voicemail/voicemail.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

class _VoicemailRepository extends Mock implements VoicemailRepository {}

class _PollingTaskHandle extends Mock implements PollingTaskHandle {}

class _PollingService extends Mock implements PollingService {}

class _FakePollingRegistration extends Fake implements PollingRegistration {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePollingRegistration());
    registerFallbackValue(Duration.zero);
  });

  late _VoicemailRepository repository;

  setUp(() => repository = _VoicemailRepository());

  group('VoicemailSyncWorker', () {
    test('a refresh reads the mailbox through the repository', () async {
      when(() => repository.refresh()).thenAnswer((_) async {});
      final worker = VoicemailSyncWorker(repository);

      await worker.refresh();

      verify(() => repository.refresh()).called(1);
    });

    test('follows the repository when it learns the session has no voicemail', () {
      when(() => repository.isActive).thenReturn(false);

      expect(VoicemailSyncWorker(repository).isActive, isFalse);
    });

    test('stops on dispose and leaves the repository alone', () async {
      when(() => repository.isActive).thenReturn(true);
      final worker = VoicemailSyncWorker(repository);

      await worker.dispose();

      expect(worker.isActive, isFalse);
      await expectLater(worker.refresh(), throwsStateError);
      verifyNever(() => repository.refresh());
    });
  });

  group('VoicemailSync', () {
    late _PollingService pollingService;
    late _PollingTaskHandle task;

    setUp(() {
      pollingService = _PollingService();
      task = _PollingTaskHandle();
      when(() => pollingService.register(any())).thenReturn(task);
    });

    test('registers the worker and unregisters it on dispose', () async {
      when(() => task.isRegistered).thenReturn(true);
      final worker = VoicemailSyncWorker(repository);
      final sync = VoicemailSync(
        worker: worker,
        pollingService: pollingService,
        interval: const Duration(seconds: 300),
      );

      final registration = verify(() => pollingService.register(captureAny())).captured.single as PollingRegistration;
      expect(registration.listener, same(worker));
      expect(registration.interval, const Duration(seconds: 300));

      await sync.dispose();
      verify(() => task.unregister()).called(1);
      expect(worker.isActive, isFalse);
    });

    test('turns a new-message request into one deferred read', () async {
      when(() => task.isRegistered).thenReturn(true);
      final sync = VoicemailSync(
        worker: VoicemailSyncWorker(repository),
        pollingService: pollingService,
        interval: const Duration(seconds: 300),
      );
      addTearDown(sync.dispose);

      sync.requestRefresh();

      verify(() => task.invalidate(after: const Duration(seconds: 1))).called(1);
    });

    test('ignores a request that comes after disposal', () async {
      final sync = VoicemailSync(
        worker: VoicemailSyncWorker(repository),
        pollingService: pollingService,
        interval: const Duration(seconds: 300),
      );

      await sync.dispose();

      expect(sync.requestRefresh, returnsNormally);
      verifyNever(() => task.invalidate(after: any(named: 'after')));
    });
  });
}
