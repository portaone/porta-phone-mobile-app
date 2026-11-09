import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/router/main_shell.dart';
import 'package:webtrit_phone/data/data.dart';

import 'main_shell_harness.dart';

// The shell makes the session's reconnect policy in initState, before any
// feature listens to signaling, and closes it first when the session goes: a
// policy left listening would schedule reconnects on a module being torn down.
void main() {
  setUpAll(registerHarnessFallbacks);

  testWidgets('the reconnect policy listens first and lets go when the shell goes, before the module is through', (
    tester,
  ) async {
    final appTime = await AppTime.init();
    final harness = MainShellHarness(initialSupported: ['extensions']);
    addTearDown(harness.dispose);

    await tester.pumpWidget(harness.build(appTime));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MainShell), findsOneWidget);
    final module = harness.signalingFactory.created.single;
    expect(module.listening.length, greaterThan(1), reason: 'the policy and the call feature listen');
    expect(module.listening.first, isTrue);

    final teardown = Completer<void>();
    module.disposeGate = teardown;
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    final policyListensWhileTearingDown = module.listening.first;

    teardown.complete();
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(seconds: 5));
    }

    expect(policyListensWhileTearingDown, isFalse);
  });
}
