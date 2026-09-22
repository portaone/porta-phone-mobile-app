import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

import 'fake_call_queues_repository.dart';

class _MockPollingService extends Mock implements PollingService {}

class _MockPollingTaskHandle extends Mock implements PollingTaskHandle {}

// Both placements of the screen read one repository, and a polling task is
// keyed by its listener - so the reads have to last as long as the LAST screen
// showing them, not the first one to close.
void main() {
  late _MockPollingService pollingService;
  late _MockPollingTaskHandle task;

  setUpAll(() {
    registerFallbackValue(PollingRegistration(listener: FakeCallQueuesRepository(), interval: Duration.zero));
  });

  setUp(() {
    pollingService = _MockPollingService();
    task = _MockPollingTaskHandle();
    when(() => pollingService.register(any())).thenReturn(task);
    when(() => task.unregister()).thenReturn(null);
  });

  CallQueuesPollingOwner ownerOver(CallQueuesRepository repository) => CallQueuesPollingOwner(
    pollingService: pollingService,
    repository: repository,
    interval: const Duration(seconds: 10),
  );

  Future<void> pumpScreens(WidgetTester tester, CallQueuesPollingOwner owner, {required int count}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<CallQueuesPollingOwner>.value(
          value: owner,
          child: Column(children: [for (var i = 0; i < count; i++) const CallCenterPolling(child: SizedBox.shrink())]),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a screen showing the queues starts the reads and closing it stops them', (tester) async {
    final repository = FakeCallQueuesRepository(initial: CallQueuesSnapshot(known: true, queues: [testQueue('0111')]));
    addTearDown(repository.dispose);
    final owner = ownerOver(repository);

    await pumpScreens(tester, owner, count: 1);

    final registration = verify(() => pollingService.register(captureAny())).captured.single as PollingRegistration;
    expect(registration.listener, same(repository));
    expect(registration.interval, const Duration(seconds: 10));
    verifyNever(() => task.unregister());

    await tester.pumpWidget(const SizedBox.shrink());

    verify(() => task.unregister()).called(1);
  });

  testWidgets('a second screen does not start a second task, and the first to close does not stop it', (tester) async {
    final repository = FakeCallQueuesRepository(initial: CallQueuesSnapshot(known: true, queues: [testQueue('0111')]));
    addTearDown(repository.dispose);
    final owner = ownerOver(repository);

    await pumpScreens(tester, owner, count: 2);
    verify(() => pollingService.register(any())).called(1);

    // The settings screen closes while the bottom-menu section stays mounted:
    // its counters must keep moving, and it will not run initState again.
    await pumpScreens(tester, owner, count: 1);
    verifyNever(() => task.unregister());

    await tester.pumpWidget(const SizedBox.shrink());
    verify(() => task.unregister()).called(1);
  });

  testWidgets('a deployment that stopped offering the feature is not polled at all', (tester) async {
    await pumpScreens(tester, ownerOver(const EmptyCallQueuesRepository()), count: 1);

    verifyNever(() => pollingService.register(any()));
  });
}
