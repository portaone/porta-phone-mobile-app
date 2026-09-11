import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/router/main_shell_services.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/features/contacts/contacts.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/services/services.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../../helpers/feature_access_factories.dart';
import '../../mocks/fake_connectivity_service.dart';
import '../../mocks/feature_access_mocks.dart';
import '../../mocks/mock_refreshable_repository.dart';

class _UserRepository extends Mock implements UserRepository {}

class _SystemInfoRepository extends Mock implements SystemInfoRepository {}

class _CallerIdSettingsRepository extends Fake implements CallerIdSettingsRepository {}

class _FavoritesRepository extends Fake implements FavoritesRepository {}

class _SipSubscriptionsRepository extends Fake implements SipSubscriptionsRepository {}

class _IceServersRepository extends Fake implements IceServersRepository {}

class _ExternalContactsRepository extends Mock implements ExternalContactsRepository {}

class _SystemNotificationsLocalRepository extends Mock implements SystemNotificationsLocalRepository {}

class _SystemNotificationsRemoteRepository extends Mock implements SystemNotificationsRemoteRepository {}

class _ContactsRepository extends Mock implements ContactsRepository {}

final _userInfo = UserInfo(
  numbers: Numbers(main: '1000', additional: []),
  balance: Balance(amount: 0, currency: 'USD'),
);

/// A session whose core supports the external directory and whose presence
/// mode is [hybridPresence]: the two inputs the contacts registration reads.
FeatureAccess _featureAccessWithContacts({required bool hybridPresence}) {
  // Hybrid presence needs a core that is aware of it (>= 0.28.0-alpha.1).
  final systemInfo = systemInfoWithSupported([kExtensionsFeatureFlag], coreVersion: Version(0, 28, 0));

  final snapshot = MockRemoteConfigSnapshot();
  when(() => snapshot.getBool(any())).thenReturn(null);
  when(() => snapshot.getBool(FeatureOverridesFactory.hybridPresenceEnabledKey)).thenReturn(hybridPresence);

  return FeatureAccess.create(
    createMockAppConfig(),
    [createMockTermsResource()],
    CoreSupportFactory.create(systemInfo),
    systemInfo,
    FeatureOverridesFactory.create(snapshot),
  );
}

/// A session whose core does or does not offer system notifications: the one
/// input the notifications registration reads.
FeatureAccess _featureAccessWithSystemNotifications({required bool supported}) {
  final systemInfo = systemInfoWithSupported(
    supported ? [kSystemNotificationsFeatureFlag] : const [],
    coreVersion: Version(0, 28, 0),
  );

  final snapshot = MockRemoteConfigSnapshot();
  when(() => snapshot.getBool(any())).thenReturn(null);

  return FeatureAccess.create(
    createMockAppConfig(),
    [createMockTermsResource()],
    CoreSupportFactory.create(systemInfo),
    systemInfo,
    FeatureOverridesFactory.create(snapshot),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(_userInfo);
    registerFallbackValue(SnOutboxActionType.seen);
    registerFallbackValue(<SnOutboxState>[]);
    registerFallbackValue(const SystemNotificationOutboxEntry(notificationId: 0, actionType: SnOutboxActionType.seen));
  });
  tearDown(EnvironmentConfig.clearOverrides);

  for (final (hybridPresence, expectedSeconds) in <(bool, int)>[(true, 1800), (false, 300)]) {
    testWidgets('shell registers contacts at ${expectedSeconds}s when hybrid presence is $hybridPresence', (
      tester,
    ) async {
      final featureAccess = _featureAccessWithContacts(hybridPresence: hybridPresence);
      expect(featureAccess.sipPresenceConfig.hybridPresenceSupport, hybridPresence);
      expect(featureAccess.coreSupport.supportsExtensions, isTrue);

      final externalContacts = _ExternalContactsRepository();
      final contacts = _ContactsRepository();
      when(() => externalContacts.fetchContacts()).thenAnswer((_) async => const <ExternalContact>[]);
      when(() => contacts.syncExternalContacts(any())).thenAnswer((_) async {});

      final (connectivity, _) = await _pumpShell(
        tester,
        featureAccess: featureAccess,
        userInfo: _userInfo,
        extraProviders: [
          Provider<ExternalContactsRepository>.value(value: externalContacts),
          Provider<ContactsRepository>.value(value: contacts),
        ],
        readContactsSync: true,
      );

      // The leading refresh on connect is the first fetch; the next one must
      // arrive only after the registered base interval (plus its jitter).
      connectivity.setConnected(true);
      await tester.pump();
      verify(() => externalContacts.fetchContacts()).called(1);

      await tester.pump(Duration(seconds: expectedSeconds - 2));
      verifyNever(() => externalContacts.fetchContacts());

      final maximumJitter = Duration(milliseconds: (expectedSeconds * 1000 * 0.1).round());
      await tester.pump(const Duration(seconds: 2) + maximumJitter);
      verify(() => externalContacts.fetchContacts()).called(1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final supported in <bool>[true, false]) {
    testWidgets('shell ${supported ? 'polls' : 'does not poll'} system notifications when the core '
        '${supported ? 'offers' : 'omits'} them', (tester) async {
      final featureAccess = _featureAccessWithSystemNotifications(supported: supported);
      expect(featureAccess.systemNotificationsConfig.systemNotificationsSupport, supported);

      final local = _SystemNotificationsLocalRepository();
      final remote = _SystemNotificationsRemoteRepository();
      // An empty store: the first cycle fetches history rather than updates.
      when(() => local.getLastUpdate()).thenAnswer((_) async => null);
      when(
        () => local.upsertNotifications(
          any(),
          silent: any(named: 'silent'),
          initialData: any(named: 'initialData'),
        ),
      ).thenAnswer((_) async {});
      when(() => remote.getHistory(limit: any(named: 'limit'))).thenAnswer((_) async => const <SystemNotification>[]);
      // The same feature gate also registers the outbox, whose cycle runs on
      // the same leading refresh; an empty queue keeps it out of the way.
      when(() => local.eventBus).thenAnswer((_) => const Stream<SystemNotificationEvent>.empty());
      when(
        () => local.getOutboxNotifications(
          actionType: any(named: 'actionType'),
          states: any(named: 'states'),
        ),
      ).thenAnswer((_) async => const <SystemNotificationOutboxEntry>[]);

      final (connectivity, _) = await _pumpShell(
        tester,
        featureAccess: featureAccess,
        userInfo: _userInfo,
        extraProviders: [
          Provider<SystemNotificationsLocalRepository>.value(value: local),
          Provider<SystemNotificationsRemoteRepository>.value(value: remote),
        ],
      );

      connectivity.setConnected(true);
      await tester.pump();

      if (!supported) {
        // No registration at all, so the feature costs nothing when the core
        // does not offer it - not even the leading refresh on connect.
        verifyNever(() => remote.getHistory(limit: any(named: 'limit')));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
        return;
      }

      verify(() => remote.getHistory(limit: any(named: 'limit'))).called(1);

      final seconds = EnvironmentConfig.SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS;
      await tester.pump(Duration(seconds: seconds - 2));
      verifyNever(() => remote.getHistory(limit: any(named: 'limit')));
      final maximumJitter = Duration(milliseconds: (seconds * 1000 * 0.1).round());
      await tester.pump(const Duration(seconds: 2) + maximumJitter);
      verify(() => remote.getHistory(limit: any(named: 'limit'))).called(1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shell drains the notifications outbox on its own interval', (tester) async {
    final featureAccess = _featureAccessWithSystemNotifications(supported: true);
    final local = _SystemNotificationsLocalRepository();
    final remote = _SystemNotificationsRemoteRepository();
    const pending = SystemNotificationOutboxEntry(notificationId: 7, actionType: SnOutboxActionType.seen);
    when(() => local.getLastUpdate()).thenAnswer((_) async => null);
    when(
      () => local.upsertNotifications(
        any(),
        silent: any(named: 'silent'),
        initialData: any(named: 'initialData'),
      ),
    ).thenAnswer((_) async {});
    when(() => remote.getHistory(limit: any(named: 'limit'))).thenAnswer((_) async => const <SystemNotification>[]);
    when(() => local.eventBus).thenAnswer((_) => const Stream<SystemNotificationEvent>.empty());
    when(
      () => local.getOutboxNotifications(
        actionType: any(named: 'actionType'),
        states: any(named: 'states'),
      ),
    ).thenAnswer((_) async => const [pending]);
    when(() => local.upsertOutboxNotification(any())).thenAnswer((_) async {});
    when(() => remote.markSystemNotificationAsSeen(any())).thenAnswer((_) async {});

    final (connectivity, _) = await _pumpShell(
      tester,
      featureAccess: featureAccess,
      userInfo: _userInfo,
      extraProviders: [
        Provider<SystemNotificationsLocalRepository>.value(value: local),
        Provider<SystemNotificationsRemoteRepository>.value(value: remote),
      ],
    );

    connectivity.setConnected(true);
    await tester.pump();
    verify(() => remote.markSystemNotificationAsSeen(7)).called(1);

    // The outbox has an interval of its own: the notifications sync ticking
    // must not drag the queue along with it.
    final syncSeconds = EnvironmentConfig.SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS;
    final outboxSeconds = EnvironmentConfig.SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS;
    expect(outboxSeconds, greaterThan(syncSeconds));
    await tester.pump(Duration(seconds: syncSeconds * 2));
    verify(() => remote.getHistory(limit: any(named: 'limit'))).called(greaterThan(0));
    verifyNever(() => remote.markSystemNotificationAsSeen(any()));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shell polls user info through its owner at the user interval', (tester) async {
    final userRepository = _UserRepository();
    final (connectivity, _) = await _pumpShell(tester, userRepositoryMock: userRepository);

    // Exactly one registration: the constructor list must not carry /user
    // beside the owner. The repository is no longer Refreshable, so it cannot
    // be registered directly at all; a second registration of the owner would
    // show up as a second fetch on the leading refresh.
    connectivity.setConnected(true);
    await tester.pump();
    verify(() => userRepository.getRemoteInfo()).called(1);

    final seconds = EnvironmentConfig.USER_REPOSITORY_POLLING_INTERVAL_SECONDS;
    await tester.pump(Duration(seconds: seconds - 2));
    verifyNever(() => userRepository.getRemoteInfo());
    final maximumJitter = Duration(milliseconds: (seconds * 1000 * 0.1).round());
    await tester.pump(const Duration(seconds: 2) + maximumJitter);
    verify(() => userRepository.getRemoteInfo()).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final (ttl, tickProbes) in <(int, int)>[(3600, 0), (5, 3)]) {
    testWidgets('shell snapshots reachability ttl ${ttl}s: $tickProbes probes over 3 ticks', (tester) async {
      // A 10 s user interval with zero jitter makes the user task tick exactly
      // every 10 s, so the probe count depends only on the configured freshness
      // window: a one-hour cache is never refreshed by three 10 s ticks, a 5 s
      // cache is refreshed by all. (The default values themselves are covered by
      // the environment config tests.)
      EnvironmentConfig.applyOverrides({
        EnvironmentConfig.USER_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME: '10',
        EnvironmentConfig.POLLING_JITTER_PERCENT__NAME: '0',
        EnvironmentConfig.POLLING_REACHABILITY_TTL_SECONDS__NAME: '$ttl',
      });
      final userRepository = _UserRepository();
      final (connectivity, _) = await _pumpShell(tester, userRepositoryMock: userRepository);

      connectivity.setConnected(true);
      await tester.pump();
      final probesAfterConnect = connectivity.checkCalls;

      for (var tick = 0; tick < 3; tick++) {
        await tester.pump(const Duration(seconds: 10));
        await tester.pump(const Duration(milliseconds: 1));
      }
      expect(connectivity.checkCalls - probesAfterConnect, tickProbes);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final (percent, ratio) in <(int?, double)>[(0, 0.0), (null, 0.1)]) {
    testWidgets('shell snapshots jitter ${percent ?? 'default 10'}%: tick lands within the window', (tester) async {
      EnvironmentConfig.applyOverrides({
        if (percent != null) EnvironmentConfig.POLLING_JITTER_PERCENT__NAME: '$percent',
      });
      final userRepository = _UserRepository();
      final (connectivity, _) = await _pumpShell(tester, userRepositoryMock: userRepository);

      connectivity.setConnected(true);
      await tester.pump();
      verify(() => userRepository.getRemoteInfo()).called(1);

      // Never before the base interval; with zero jitter exactly at it, with the
      // default within the extra 10 percent.
      final seconds = EnvironmentConfig.USER_REPOSITORY_POLLING_INTERVAL_SECONDS;
      final window = Duration(milliseconds: (seconds * 1000 * ratio).round());
      await tester.pump(Duration(seconds: seconds) - const Duration(milliseconds: 1));
      verifyNever(() => userRepository.getRemoteInfo());
      await tester.pump(const Duration(milliseconds: 1) + window);
      verify(() => userRepository.getRemoteInfo()).called(1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  for (final override in <int?>[null, 1800]) {
    testWidgets('shell uses ${override ?? 'default 900'}s cap and snapshots it at creation', (tester) async {
      const name = EnvironmentConfig.POLLING_MAX_BACKOFF_SECONDS__NAME;
      if (override != null) EnvironmentConfig.applyOverrides({name: '$override'});

      final (connectivity, polling) = await _pumpShell(tester);

      final task = MockRefreshableRepository(now: tester.binding.clock.now)..failTimes = 4;
      polling.register(PollingRegistration(listener: task, interval: const Duration(seconds: 300)));
      connectivity.setConnected(true);
      await tester.pump();
      expect(task.callCount, 1);

      // Later override updates do not mutate this service's immutable options.
      EnvironmentConfig.applyOverrides({name: '3600'});
      final delays = override == null ? [600, 900, 900, 900, 300] : [600, 1200, 1800, 1800, 300];
      var calls = 1;
      for (final seconds in delays) {
        // Check on either side of the full production delay, including its
        // proportional jitter, relative to the actual previous call. This
        // avoids accumulating the slack used by earlier pumps.
        final beforeDeadline = task.callTimestamps.last.add(Duration(seconds: seconds - 1));
        await tester.pump(beforeDeadline.difference(tester.binding.clock.now()));
        expect(task.callCount, calls);
        final maximumJitter = Duration(milliseconds: (seconds * 1000 * 0.1).round());
        await tester.pump(const Duration(seconds: 1) + maximumJitter);
        expect(task.callCount, ++calls);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
  for (final override in <int?>[null, 5, 0]) {
    testWidgets('shell snapshots leading min-age cap ${override ?? 'default 30'}s', (tester) async {
      await withClock(Clock(tester.binding.clock.now), () async {
        const name = EnvironmentConfig.POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS__NAME;
        EnvironmentConfig.applyOverrides(override == null ? {} : {name: '$override'});
        final (connectivity, polling) = await _pumpShell(tester);
        final task = MockRefreshableRepository();
        polling.register(PollingRegistration(listener: task, interval: const Duration(minutes: 5)));
        connectivity.setConnected(true);
        await tester.pump();
        expect(task.calls, 1);
        EnvironmentConfig.applyOverrides({name: '120'});
        final cap = override ?? 30;
        if (cap > 0) {
          await tester.pump(Duration(seconds: cap) - const Duration(milliseconds: 1));
          connectivity.setConnected(false);
          await tester.pump();
          connectivity.setConnected(true);
          await tester.pump();
          expect(task.calls, 1);
          await tester.pump(const Duration(milliseconds: 1));
        }
        connectivity.setConnected(false);
        await tester.pump();
        connectivity.setConnected(true);
        await tester.pump();
        expect(task.calls, 2);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    });
  }
}

/// Pumps the shell services. [extraProviders] supply repositories a registration
/// under test needs; [readContactsSync] forces the contacts registration to be
/// created even if its provider is lazy; [userInfo] lets the contacts worker
/// filter by the current user instead of waiting on the user stream.
Future<(FakeConnectivityService, PollingService)> _pumpShell(
  WidgetTester tester, {
  FeatureAccess? featureAccess,
  UserInfo? userInfo,
  List<SingleChildWidget> extraProviders = const [],
  bool readContactsSync = false,
  _UserRepository? userRepositoryMock,
}) async {
  final connectivity = FakeConnectivityService();
  addTearDown(connectivity.dispose);
  final userRepository = userRepositoryMock ?? _UserRepository();
  final systemInfoRepository = _SystemInfoRepository();
  // The user task is owned by UserInfoSync and runs the worker cycle against
  // this mock; the repository itself is only the store behind that cycle.
  when(() => userRepository.getLocalInfo()).thenReturn(userInfo);
  when(() => userRepository.getRemoteInfo()).thenAnswer((_) async => _userInfo);
  when(() => userRepository.storeInfo(any())).thenAnswer((_) async {});
  when(() => systemInfoRepository.isActive).thenReturn(false);
  late PollingService polling;

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<FeatureAccess>.value(value: featureAccess ?? featureAccessFor(createMockSystemInfo())),
        Provider<ConnectivityService>.value(value: connectivity),
        Provider<UserRepository>.value(value: userRepository),
        Provider<SystemInfoRepository>.value(value: systemInfoRepository),
        Provider<CallerIdSettingsRepository>.value(value: _CallerIdSettingsRepository()),
        Provider<FavoritesRepository>.value(value: _FavoritesRepository()),
        Provider<SipSubscriptionsRepository>.value(value: _SipSubscriptionsRepository()),
        Provider<IceServersRepository>.value(value: _IceServersRepository()),
        ...extraProviders,
      ],
      child: MainShellServices(
        child: Builder(
          builder: (context) {
            polling = context.read<PollingService>();
            if (readContactsSync) context.read<ExternalContactsSync>();
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );

  return (connectivity, polling);
}
