import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/router/main_shell.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/features.dart';

import 'main_shell_harness.dart';
import '../../helpers/feature_access_factories.dart';

void main() {
  setUpAll(registerHarnessFallbacks);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Unmounts the shell and drains the one-shot delays its watchers armed
  /// (e.g. the messaging shell's 5-second sync loop).
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 5));
    }
  }

  /// The session has a network and the server has answered it: registered,
  /// no call on any line.
  void sessionKnown(MainShellHarness harness) {
    harness.connectivityService.setConnectivityResult(ConnectivityResult.wifi);
    harness.signalingFactory.created.last.handshake();
  }

  /// The session has a network, has tried the server and failed.
  void serverOutOfReach(MainShellHarness harness) {
    harness.connectivityService.setConnectivityResult(ConnectivityResult.wifi);
    harness.signalingFactory.created.last.emit(
      SignalingConnectionFailed(
        error: Exception('refused'),
        isRepeated: false,
        recommendedReconnectDelay: const Duration(seconds: 1),
      ),
    );
  }

  // WT-2067: the app starts on the system info it stored before and reads the
  // backend only once the session runs, so a capability the backend dropped
  // stayed in the app until the start after the next one.
  testWidgets('a session started on a configuration the backend dropped is started anew on the current one', (
    tester,
  ) async {
    final appTime = await AppTime.init();
    final harness = MainShellHarness(initialSupported: ['extensions']);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build(appTime));
    await settle(tester);
    expect(find.byType(MainShell), findsOneWidget);
    final callBlocBefore = tester.element(find.byType(CallShell)).read<CallBloc>();

    final offered = featureAccessFor(systemInfoWithSupported([]));
    harness.backendAnswers(offered);
    sessionKnown(harness);
    await settle(tester);

    expect(find.byType(MainShell), findsOneWidget);
    final shellContext = tester.element(find.byType(CallShell));
    final sessionFeatureAccess = shellContext.read<FeatureAccess>();
    final callBlocAfter = shellContext.read<CallBloc>();
    final modules = harness.signalingFactory.created;

    await unmount(tester);

    expect(sessionFeatureAccess, same(offered), reason: 'the new session must run on what the backend offers');
    expect(identical(callBlocBefore, callBlocAfter), isFalse, reason: 'the session was not replaced');
    expect(modules, hasLength(2));
    expect(modules.first.disposed, isTrue);
  });

  // Signaling is one service per process: a shell that connects while the
  // previous one is still disposing has its state wiped by the end of that
  // disposal.
  testWidgets('the new session is not started before the old one has let go of signaling', (tester) async {
    final appTime = await AppTime.init();
    final harness = MainShellHarness(initialSupported: ['extensions']);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build(appTime));
    await settle(tester);
    final teardown = Completer<void>();
    harness.signalingFactory.created.single.disposeGate = teardown;

    harness.backendAnswers(featureAccessFor(systemInfoWithSupported([])));
    sessionKnown(harness);
    await settle(tester);

    final shellsWhileTearingDown = find.byType(MainShell).evaluate().length;
    final modulesWhileTearingDown = harness.signalingFactory.created.length;
    final saidWhileTearingDown = find.text('Applying changes from the server...').evaluate().length;

    teardown.complete();
    await settle(tester);
    final shellsAfter = find.byType(MainShell).evaluate().length;
    final modulesAfter = harness.signalingFactory.created.length;

    await unmount(tester);

    expect(shellsWhileTearingDown, 0);
    expect(modulesWhileTearingDown, 1);
    expect(saidWhileTearingDown, 1, reason: 'the screen between two sessions must say why it is there');
    expect(shellsAfter, 1);
    expect(modulesAfter, 2);
  });

  // Call integration is one per process as well: on Android the end of its
  // teardown clears the calls the plugin tracks and stops its service, under
  // a session that had already set it up again.
  testWidgets('the new session is not started before the old one has let go of call integration', (tester) async {
    final appTime = await AppTime.init();
    final harness = MainShellHarness(initialSupported: ['extensions']);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build(appTime));
    await settle(tester);
    final teardown = Completer<void>();
    harness.callkeep.tearDownGate = teardown;

    harness.backendAnswers(featureAccessFor(systemInfoWithSupported([])));
    sessionKnown(harness);
    await settle(tester);

    final shellsWhileTearingDown = find.byType(MainShell).evaluate().length;
    final setUpsWhileTearingDown = harness.callkeep.setUps;

    teardown.complete();
    await settle(tester);
    final shellsAfter = find.byType(MainShell).evaluate().length;
    final setUpsAfter = harness.callkeep.setUps;

    await unmount(tester);

    expect(shellsWhileTearingDown, 0);
    expect(setUpsWhileTearingDown, 1);
    expect(shellsAfter, 1);
    expect(setUpsAfter, 2);
  });

  // With the server out of reach nothing says whether a call is on its way:
  // one the platform presented is in the bloc's state only after the caller
  // has been looked up.
  testWidgets('a session that cannot reach the server is not replaced', (tester) async {
    final appTime = await AppTime.init();
    final harness = MainShellHarness(initialSupported: ['extensions']);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build(appTime));
    await settle(tester);
    final callBlocBefore = tester.element(find.byType(CallShell)).read<CallBloc>();

    harness.backendAnswers(featureAccessFor(systemInfoWithSupported([])));
    serverOutOfReach(harness);
    await settle(tester);

    final callBlocAfter = tester.element(find.byType(CallShell)).read<CallBloc>();
    final modules = harness.signalingFactory.created.length;

    await unmount(tester);

    expect(identical(callBlocBefore, callBlocAfter), isTrue);
    expect(modules, 1);
  });

  testWidgets('a session the backend agrees with keeps running', (tester) async {
    final appTime = await AppTime.init();
    final harness = MainShellHarness(initialSupported: ['extensions']);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build(appTime));
    await settle(tester);
    final callBlocBefore = tester.element(find.byType(CallShell)).read<CallBloc>();

    harness.systemInfoController.add(harness.initialSystemInfo);
    sessionKnown(harness);
    await settle(tester);

    final callBlocAfter = tester.element(find.byType(CallShell)).read<CallBloc>();
    final modules = harness.signalingFactory.created.length;

    await unmount(tester);

    expect(identical(callBlocBefore, callBlocAfter), isTrue);
    expect(modules, 1);
  });
}
