import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/data/feature_access.dart';
import 'package:webtrit_phone/features/voicemail/voicemail.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';

class _FeatureAccess extends Mock implements FeatureAccess {}

class _RemotePush extends Mock implements RemotePushRepository {}

class _LocalPush extends Mock implements LocalPushRepository {}

class _VoicemailRepository extends Mock implements VoicemailRepository {}

class _PollingService extends Mock implements PollingService {}

class _PollingTaskHandle extends Mock implements PollingTaskHandle {}

class _FakePollingRegistration extends Fake implements PollingRegistration {}

// The server saying the voicemail box changed reaches the mailbox read the
// same way a new-message push does: the shell hands the change to the
// session's VoicemailSync, which defers one read of the box.
void main() {
  setUpAll(() {
    registerFallbackValue(_FakePollingRegistration());
    registerFallbackValue(Duration.zero);
  });

  late StreamController<void> boxChanges;
  late _PollingTaskHandle task;
  late VoicemailSync sync;
  late _FeatureAccess featureAccess;
  late _RemotePush remotePush;
  late _LocalPush localPush;

  setUp(() {
    boxChanges = StreamController<void>.broadcast();
    task = _PollingTaskHandle();
    when(() => task.isRegistered).thenReturn(true);
    final pollingService = _PollingService();
    when(() => pollingService.register(any())).thenReturn(task);
    final repository = _VoicemailRepository();
    when(() => repository.isActive).thenReturn(true);
    sync = VoicemailSync(
      worker: VoicemailSyncWorker(repository),
      pollingService: pollingService,
      interval: const Duration(seconds: 300),
    );
    featureAccess = _FeatureAccess();
    remotePush = _RemotePush();
    localPush = _LocalPush();
    when(() => remotePush.voicemailForegroundPushs).thenAnswer((_) => const Stream.empty());
    when(() => remotePush.voicemailOpenedPushs).thenAnswer((_) => const Stream.empty());
    when(() => localPush.voicemailActions).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    await sync.dispose();
    await boxChanges.close();
  });

  Widget shell({Stream<void>? changes}) => MultiProvider(
    providers: [
      Provider<FeatureAccess>.value(value: featureAccess),
      Provider<RemotePushRepository>.value(value: remotePush),
      Provider<LocalPushRepository>.value(value: localPush),
      Provider<VoicemailSync>.value(value: sync),
    ],
    child: VoicemailShell(boxChanges: changes ?? boxChanges.stream, child: const SizedBox()),
  );

  testWidgets('a change of the box asks the session for one deferred read of it', (tester) async {
    when(() => featureAccess.voicemailAvailable).thenReturn(true);
    await tester.pumpWidget(shell());

    boxChanges.add(null);
    await tester.pump();

    verify(() => task.invalidate(after: const Duration(seconds: 1))).called(1);
  });

  testWidgets('a session without voicemail takes no change in', (tester) async {
    when(() => featureAccess.voicemailAvailable).thenReturn(false);
    await tester.pumpWidget(shell());

    expect(boxChanges.hasListener, isFalse);
  });

  testWidgets('the same stream handed again is not listened to anew', (tester) async {
    when(() => featureAccess.voicemailAvailable).thenReturn(true);
    var listens = 0;
    final counted = boxChanges.stream.transform(
      StreamTransformer<void, void>.fromBind((stream) {
        listens++;
        return stream;
      }),
    );
    await tester.pumpWidget(shell(changes: counted));
    await tester.pumpWidget(shell(changes: counted));

    expect(listens, 1);
  });

  testWidgets('a new stream handed over replaces the old one', (tester) async {
    when(() => featureAccess.voicemailAvailable).thenReturn(true);
    final other = StreamController<void>.broadcast();
    addTearDown(other.close);
    await tester.pumpWidget(shell());
    await tester.pumpWidget(shell(changes: other.stream));

    expect(boxChanges.hasListener, isFalse);
    other.add(null);
    await tester.pump();

    verify(() => task.invalidate(after: const Duration(seconds: 1))).called(1);
  });

  testWidgets('the shell gone, a change asks for nothing', (tester) async {
    when(() => featureAccess.voicemailAvailable).thenReturn(true);
    await tester.pumpWidget(shell());
    await tester.pumpWidget(const SizedBox());

    expect(boxChanges.hasListener, isFalse);
    boxChanges.add(null);
    await tester.pump();

    verifyNever(() => task.invalidate(after: any(named: 'after')));
  });
}
