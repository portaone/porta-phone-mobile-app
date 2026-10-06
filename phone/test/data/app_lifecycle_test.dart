import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:webtrit_phone/data/app_lifecycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  // The lifecycle state is the binding's, shared by every test that runs after this one;
  // paused/detached also stop frames, so a later widget test would never build.
  tearDown(() => WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed));

  test('records the lifecycle state it observes', () async {
    final lifecycle = await AppLifecycle.initMaster();
    addTearDown(lifecycle.dispose);

    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await pumpEventQueue();

    expect(lifecycle.getLifecycleState(), AppLifecycleState.paused);
  });

  test('stops observing once released, so a retired instance records nothing', () async {
    final lifecycle = await AppLifecycle.initMaster();

    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await pumpEventQueue();
    await lifecycle.dispose();

    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await pumpEventQueue();

    expect(lifecycle.getLifecycleState(), AppLifecycleState.paused);
  });

  test('a background instance never observes anything', () async {
    final lifecycle = await AppLifecycle.initSlave();
    addTearDown(lifecycle.dispose);

    WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await pumpEventQueue();

    expect(lifecycle.getLifecycleState(), isNull);
  });
}
