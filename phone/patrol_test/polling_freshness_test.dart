import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/repositories/user_info/user_repository.dart';
import 'package:webtrit_phone/services/services.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../test/mocks/fake_connectivity_service.dart';
import '../test/repository/user_repository_integration_harness.dart';
import 'subsequences/pump_for.dart';
import 'subsequences/wait_until.dart';
import 'subsequences/with_network_disabled.dart';

/// Device integration: real timers, API mapping, repository and native storage.
/// The HTTP boundary is controlled; two scenarios also drive Android itself.
void main() {
  patrolTest('10-second polling keeps its deadline through flaps every 6 seconds', ($) async {
    final fixture = await _Fixture.create($, interval: const Duration(seconds: 10));
    await fixture.waitForSuccess($, count: 1);
    final firstCompletion = fixture.handle.state.lastSuccessAt!;
    var flaps = 0;
    final timer = Timer.periodic(const Duration(seconds: 6), (_) {
      fixture.fake.setConnected(false);
      scheduleMicrotask(() => fixture.fake.setConnected(true));
      flaps++;
    });
    addTearDown(timer.cancel);

    await fixture.waitForSuccess($, count: 4, timeout: const Duration(seconds: 35));
    timer.cancel();
    fixture.handle.unregister();
    expect(flaps, greaterThanOrEqualTo(5));
    expect(fixture.starts, hasLength(4));
    for (var index = 1; index < fixture.starts.length; index++) {
      final gap = fixture.starts[index].difference(fixture.successes[index - 1]);
      expect(gap, greaterThanOrEqualTo(const Duration(milliseconds: 9900)));
      expect(gap, lessThan(const Duration(seconds: 12)), reason: 'flaps must not postpone the periodic deadline');
    }
    expect(fixture.starts[1].difference(firstCompletion), lessThan(const Duration(seconds: 12)));
    await fixture.expectNativeUser();
    fixture.trace('10s interval, 6s flaps: $flaps');
  });

  patrolTest('real Android network recovery skips fresh data and refreshes aged data once', ($) async {
    final network = RestorableNetwork($);
    addTearDown(network.restore);
    await network.enableWifi();
    final connectivity = await ConnectivityServiceImpl.create(connectivityChecker: _OnlineChecker());
    final online = <bool>[];
    final subscription = connectivity.connectionStream.listen(online.add);
    addTearDown(subscription.cancel);
    final fixture = await _Fixture.create($, connectivity: connectivity);
    await fixture.waitForSuccess($, count: 1);
    final completed = fixture.handle.state;

    await network.disable();
    await _wait($, () => online.lastOrNull == false, 'Android offline event did not reach polling');
    expect(connectivity.currentConnectivityResult, ConnectivityResult.none);
    expect(fixture.handle.state.phase, PollingTaskPhase.waitingForConnectivity);
    await network.enableWifi();
    await _wait($, () => online.lastOrNull == true, 'Android Wi-Fi recovery did not reach polling');
    await _wait($, () => fixture.handle.state.phase == PollingTaskPhase.succeeded, 'fresh state was not restored');
    expect(DateTime.now().difference(completed.lastSuccessAt!), lessThan(const Duration(seconds: 30)));
    await pumpFor(const Duration(seconds: 1), $);
    expect(fixture.starts, hasLength(1));
    expect(fixture.handle.state, same(completed));

    await network.disable();
    await _wait($, () => online.lastOrNull == false, 'second offline transition was not observed');
    await _wait(
      $,
      () => DateTime.now().difference(completed.lastSuccessAt!) >= const Duration(seconds: 31),
      'the last successful user refresh did not age past the cap',
      timeout: const Duration(seconds: 35),
    );
    expect(fixture.starts, hasLength(1), reason: 'offline polling must stay paused');
    await network.enableWifi();
    await fixture.waitForSuccess($, count: 2);
    await pumpFor(const Duration(seconds: 1), $);
    expect(fixture.starts, hasLength(2));
    expect(online.where((value) => !value).length, greaterThanOrEqualTo(2));
    await fixture.expectNativeUser();
    fixture.trace('real Android Wi-Fi recovery');
  });

  patrolTest('real Android resume skips fresh data and refreshes after the cap expires', ($) async {
    final lifecycle = _LifecycleRecorder();
    WidgetsBinding.instance.addObserver(lifecycle);
    addTearDown(() => WidgetsBinding.instance.removeObserver(lifecycle));
    final fixture = await _Fixture.create($, cap: const Duration(seconds: 15));
    await fixture.waitForSuccess($, count: 1);
    final completed = fixture.handle.state;
    await $.platformAutomator.mobile.pressHome();
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(lifecycle.states, contains(AppLifecycleState.paused));
    await $.platformAutomator.mobile.openApp();
    await _wait($, () => lifecycle.states.lastOrNull == AppLifecycleState.resumed, 'Android did not resume the app');
    await pumpFor(const Duration(seconds: 1), $);
    expect(DateTime.now().difference(completed.lastSuccessAt!), lessThan(const Duration(seconds: 15)));
    expect(fixture.starts, hasLength(1));
    expect(fixture.handle.state.lastSuccessAt, completed.lastSuccessAt);

    await $.platformAutomator.mobile.pressHome();
    final age = DateTime.now().difference(completed.lastSuccessAt!);
    final remaining = const Duration(seconds: 16) - age;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    expect(fixture.starts, hasLength(1));
    await $.platformAutomator.mobile.openApp();
    await fixture.waitForSuccess($, count: 2);
    await pumpFor(const Duration(seconds: 1), $);
    expect(fixture.starts, hasLength(2));
    expect(lifecycle.states.where((state) => state == AppLifecycleState.paused).length, 2);
    await fixture.expectNativeUser();
    fixture.trace('real Android background/resume');
  });

  patrolTest('failed refresh, runNow and due invalidations bypass recent success', ($) async {
    final fixture = await _Fixture.create($);
    await fixture.waitForSuccess($, count: 1);
    final initialSuccess = fixture.handle.state.lastSuccessAt;
    fixture.failNext = true;
    await expectLater(fixture.handle.runNow(), throwsException);
    expect(fixture.handle.state.phase, PollingTaskPhase.failed);
    expect(fixture.handle.state.lastSuccessAt, initialSuccess);
    expect(fixture.starts, hasLength(2));
    await fixture.flap($);
    await fixture.waitForSuccess($, count: 3);

    await fixture.handle.runNow();
    expect(fixture.starts, hasLength(4));
    fixture.handle.invalidate(after: const Duration(seconds: 2));
    await fixture.flap($);
    await pumpFor(const Duration(milliseconds: 500), $);
    expect(fixture.starts, hasLength(4), reason: 'a future invalidation must not run early on reconnect');
    await fixture.waitForSuccess($, count: 5);

    fixture.fake.setConnected(false);
    await _wait(
      $,
      () => fixture.handle.state.phase == PollingTaskPhase.waitingForConnectivity,
      'offline state missing',
    );
    fixture.handle.invalidate();
    await pumpFor(const Duration(milliseconds: 300), $);
    expect(fixture.starts, hasLength(5));
    fixture.fake.setConnected(true);
    await fixture.waitForSuccess($, count: 6);
    await pumpFor(const Duration(milliseconds: 500), $);
    expect(fixture.starts, hasLength(6));
    await fixture.expectNativeUser();
    fixture.trace('failure recovery and explicit refreshes');
  });

  patrolTest('in-flight recovery preserves trailing invalidation and uses completion freshness', ($) async {
    final fixture = await _Fixture.create($, cap: const Duration(seconds: 2));
    await fixture.waitForSuccess($, count: 1);
    fixture.blocked = Completer<http.Response>();
    final manual = fixture.handle.runNow();
    await _wait($, () => fixture.starts.length == 2, 'manual HTTP request did not start');
    final started = fixture.starts.last;
    fixture.fake.setConnected(false);
    await $.pump();
    fixture.handle.invalidate();
    await pumpFor(const Duration(seconds: 3), $);
    expect(fixture.starts, hasLength(2));
    fixture.releaseResponse();
    await manual;
    expect(fixture.handle.state.lastSuccessAt!.difference(started), greaterThan(const Duration(seconds: 2)));
    fixture.fake.setConnected(true);
    await fixture.waitForSuccess($, count: 3);
    expect(fixture.starts, hasLength(3), reason: 'one trailing invalidation must survive the in-flight cycle');

    // An old start time must not defeat freshness of a recently completed request.
    fixture.blocked = Completer<http.Response>();
    final secondManual = fixture.handle.runNow();
    await _wait($, () => fixture.starts.length == 4, 'second manual request did not start');
    fixture.fake.setConnected(false);
    await pumpFor(const Duration(seconds: 3), $);
    fixture.releaseResponse();
    await secondManual;
    final completed = fixture.handle.state.lastSuccessAt;
    fixture.fake.setConnected(true);
    await pumpFor(const Duration(milliseconds: 500), $);
    expect(fixture.starts, hasLength(4));
    expect(fixture.handle.state.lastSuccessAt, completed);
    await fixture.expectNativeUser();
    fixture.trace('in-flight completion and trailing invalidation');
  });

  patrolTest('zero env cap disables leading freshness for the created service', ($) async {
    EnvironmentConfig.applyOverrides({EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS__NAME: '0'});
    addTearDown(EnvironmentConfig.clearOverrides);
    final fixture = await _Fixture.create(
      $,
      cap: Duration(seconds: EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS),
    );
    await fixture.waitForSuccess($, count: 1);
    EnvironmentConfig.applyOverrides({EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS__NAME: '120'});
    await fixture.flap($);
    await fixture.waitForSuccess($, count: 2);
    await fixture.flap($);
    await fixture.waitForSuccess($, count: 3);
    expect(fixture.starts, hasLength(3));
    await fixture.expectNativeUser();
    fixture.trace('disabled gate, immutable options');
  });
}

Future<void> _wait(
  PatrolIntegrationTester $,
  bool Function() condition,
  String description, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  await waitUntil($, condition, timeout: timeout, description: description);
}

class _Fixture {
  _Fixture(this.harness, this.connectivity, this.preferences, this.previousUser);

  static Future<_Fixture> create(
    PatrolIntegrationTester $, {
    Duration interval = const Duration(seconds: 60),
    Duration cap = const Duration(seconds: 30),
    ConnectivityService? connectivity,
  }) async {
    await $.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Polling freshness integration'))),
      ),
    );
    final preferences = await AppPreferencesImpl.init();
    final previousUser = preferences.getString('user-info');
    final harness = UserRepositoryIntegrationHarness(preferences);
    final fixture = _Fixture(
      harness,
      connectivity ?? FakeConnectivityService(initialConnected: true),
      preferences,
      previousUser,
    );
    addTearDown(fixture.dispose);
    await harness.local.setInfo(UserRepositoryIntegrationHarness.cachedUser);
    harness.respond = fixture.respond;
    fixture.polling = PollingService(
      connectivityService: fixture.connectivity,
      options: PollingOptions(jitterRatio: 0, leadingRefreshMinAgeCap: cap),
    );
    fixture.handle = fixture.polling.register(PollingRegistration(listener: harness.worker, interval: interval));
    fixture.subscription = fixture.handle.states.listen(fixture.recordState);
    return fixture;
  }

  final UserRepositoryIntegrationHarness harness;
  final ConnectivityService connectivity;
  final AppPreferences preferences;
  final String? previousUser;
  late final PollingService polling;
  late final PollingTaskHandle handle;
  late final StreamSubscription<PollingTaskState> subscription;
  final starts = <DateTime>[];
  final successes = <DateTime>[];
  bool failNext = false;
  Completer<http.Response>? blocked;

  FakeConnectivityService get fake => connectivity as FakeConnectivityService;

  Future<http.Response> respond(http.Request request) async {
    starts.add(DateTime.now());
    if (blocked case final response?) return response.future;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (failNext) {
      failNext = false;
      return http.Response('adapter unavailable', 503);
    }
    return UserRepositoryIntegrationHarness.successResponse();
  }

  void releaseResponse() {
    final response = blocked;
    blocked = null;
    if (response != null && !response.isCompleted) {
      response.complete(UserRepositoryIntegrationHarness.successResponse());
    }
  }

  void recordState(PollingTaskState state) {
    if (state.phase == PollingTaskPhase.failed) {
      debugPrint('freshness_failure error=${state.error}');
    }
    if (state.phase == PollingTaskPhase.succeeded && successes.lastOrNull != state.lastSuccessAt) {
      successes.add(state.lastSuccessAt!);
    }
  }

  Future<void> waitForSuccess(PatrolIntegrationTester $, {required int count, Duration? timeout}) => _wait(
    $,
    () => starts.length >= count && handle.state.phase == PollingTaskPhase.succeeded,
    'expected $count requests and a completed successful refresh; got ${starts.length}',
    timeout: timeout ?? const Duration(seconds: 15),
  );

  Future<void> flap(PatrolIntegrationTester $) async {
    fake.setConnected(false);
    await $.pump();
    fake.setConnected(true);
    await $.pump();
  }

  Future<void> expectNativeUser() async {
    final native = await SharedPreferences.getInstance();
    await native.reload();
    final reopened = UserLocalDatasourcePrefsImpl(await AppPreferencesImpl.init());
    expect(reopened.getInfo(), UserRepositoryIntegrationHarness.updatedUser);
    expect(harness.sessionGuard.errors, isEmpty);
  }

  void trace(String scenario) {
    final origin = starts.first;
    debugPrint(
      'freshness_trace scenario="$scenario" requests_ms=${starts.map((t) => t.difference(origin).inMilliseconds).toList()} '
      'success_ms=${successes.map((t) => t.difference(origin).inMilliseconds).toList()}',
    );
  }

  Future<void> dispose() async {
    final pending = handle.state.phase == PollingTaskPhase.running ? handle.runNow().catchError((Object _) {}) : null;
    releaseResponse();
    await pending;
    await polling.dispose();
    await subscription.cancel();
    await connectivity.dispose();
    await harness.dispose();
    if (previousUser == null) {
      await preferences.remove('user-info');
    } else {
      await preferences.setString('user-info', previousUser!);
    }
  }
}

class _OnlineChecker implements ConnectivityChecker {
  @override
  Future<bool> checkConnection() async => true;

  @override
  Future<void> dispose() async {}
}

class _LifecycleRecorder with WidgetsBindingObserver {
  final states = <AppLifecycleState>[];

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    states.add(state);
    debugPrint('freshness_lifecycle state=${state.name} at=${DateTime.now().toIso8601String()}');
  }
}
