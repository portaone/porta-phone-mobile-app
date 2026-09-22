import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/features/call_center/call_center.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

import 'fake_call_queues_repository.dart';

class _MockPollingService extends Mock implements PollingService {}

class _MockPollingTaskHandle extends Mock implements PollingTaskHandle {}

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

  Future<void> pumpPage(WidgetTester tester, CallQueuesRepository repository) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MultiProvider(
          providers: [
            Provider<PollingService>.value(value: pollingService),
            RepositoryProvider<CallQueuesRepository>.value(value: repository),
          ],
          child: BlocProvider(create: (context) => CallQueuesCubit(repository), child: const CallCenterScreenPage()),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('the counters are polled while the screen is open and not after it closes', (tester) async {
    final repository = FakeCallQueuesRepository(initial: CallQueuesSnapshot(known: true, queues: [testQueue('0111')]));
    addTearDown(repository.dispose);

    await pumpPage(tester, repository);

    final registration = verify(() => pollingService.register(captureAny())).captured.single as PollingRegistration;
    expect(registration.listener, same(repository));
    expect(registration.interval, const Duration(seconds: 10));
    verifyNever(() => task.unregister());

    // Leaving the screen has to stop the task: every read reaches the PBX, and
    // nothing on any other screen shows these counters.
    await tester.pumpWidget(const SizedBox.shrink());

    verify(() => task.unregister()).called(1);
  });

  testWidgets('a deployment that stopped offering the feature is not polled at all', (tester) async {
    await pumpPage(tester, const EmptyCallQueuesRepository());

    verifyNever(() => pollingService.register(any()));
  });
}
