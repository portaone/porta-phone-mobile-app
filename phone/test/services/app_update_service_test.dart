import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:in_app_update/in_app_update.dart';

import 'package:webtrit_phone/services/services.dart';

import '../mocks/app_update_info.dart';

void main() {
  late List<String> calls;
  late AppUpdateInfo info;
  late AppUpdateResult flexibleResult;

  AppUpdateService buildService({CanProceedWithUpdate? canProceed}) {
    return AppUpdateService(
      canProceed: canProceed,
      checkForUpdate: () async {
        calls.add('check');
        return info;
      },
      performImmediateUpdate: () async {
        calls.add('immediate');
        return AppUpdateResult.success;
      },
      startFlexibleUpdate: () async {
        calls.add('startFlexible');
        return flexibleResult;
      },
      completeFlexibleUpdate: () async {
        calls.add('completeFlexible');
      },
    );
  }

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls = [];
    info = appUpdateInfo();
    flexibleResult = AppUpdateResult.success;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('no-op on non-Android platforms', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await buildService().check();

    expect(calls, isEmpty);
  });

  test('no update available results in check only', () async {
    final finished = await buildService().check();

    expect(finished, isTrue);
    expect(calls, ['check']);
  });

  test('default priority runs the flexible flow and installs on success', () async {
    info = appUpdateInfo(
      updateAvailability: UpdateAvailability.updateAvailable,
      immediateUpdateAllowed: true,
      flexibleUpdateAllowed: true,
      availableVersionCode: 42,
    );

    await buildService().check();

    expect(calls, ['check', 'startFlexible', 'completeFlexible']);
  });

  test('priority at the threshold escalates to the immediate flow', () async {
    info = appUpdateInfo(
      updateAvailability: UpdateAvailability.updateAvailable,
      immediateUpdateAllowed: true,
      flexibleUpdateAllowed: true,
      updatePriority: 4,
    );

    await buildService().check();

    expect(calls, ['check', 'immediate']);
  });

  test('immediate is used when flexible is not allowed regardless of priority', () async {
    info = appUpdateInfo(
      updateAvailability: UpdateAvailability.updateAvailable,
      immediateUpdateAllowed: true,
      flexibleUpdateAllowed: false,
    );

    await buildService().check();

    expect(calls, ['check', 'immediate']);
  });

  test('a declined flexible update ends the check', () async {
    info = appUpdateInfo(
      updateAvailability: UpdateAvailability.updateAvailable,
      flexibleUpdateAllowed: true,
      availableVersionCode: 42,
    );
    flexibleResult = AppUpdateResult.userDeniedUpdate;

    final finished = await buildService().check();

    expect(finished, isTrue);
    expect(calls, ['check', 'startFlexible']);
  });

  test('failed flexible update neither installs nor suppresses future prompts', () async {
    final service = buildService();
    info = appUpdateInfo(
      updateAvailability: UpdateAvailability.updateAvailable,
      flexibleUpdateAllowed: true,
      availableVersionCode: 42,
    );
    flexibleResult = AppUpdateResult.inAppUpdateFailed;

    await service.check();
    await service.check();

    expect(calls, ['check', 'startFlexible', 'check', 'startFlexible']);
    expect(calls, isNot(contains('completeFlexible')));
  });

  test('download completed while away triggers install without a new prompt', () async {
    info = appUpdateInfo(installStatus: InstallStatus.downloaded);

    await buildService().check();

    expect(calls, ['check', 'completeFlexible']);
  });

  test('interrupted immediate update is resumed', () async {
    info = appUpdateInfo(updateAvailability: UpdateAvailability.developerTriggeredUpdateInProgress);

    await buildService().check();

    expect(calls, ['check', 'immediate']);
  });

  test('platform errors are swallowed and the next check still runs', () async {
    var shouldThrow = true;
    final service = AppUpdateService(
      checkForUpdate: () async {
        calls.add('check');
        if (shouldThrow) throw PlatformException(code: 'API_NOT_AVAILABLE');
        return info;
      },
      performImmediateUpdate: () async => AppUpdateResult.success,
      startFlexibleUpdate: () async => flexibleResult,
      completeFlexibleUpdate: () async {},
    );

    expect(await service.check(), isTrue, reason: 'a Play failure is not worth repeating');

    shouldThrow = false;
    await service.check();

    expect(calls, ['check', 'check']);
  });

  group('when an update may not take the screen', () {
    setUp(() {
      info = appUpdateInfo(
        updateAvailability: UpdateAvailability.updateAvailable,
        immediateUpdateAllowed: true,
        flexibleUpdateAllowed: true,
        availableVersionCode: 2,
      );
    });

    test('Play is not asked at all, and the check is worth repeating', () async {
      final finished = await buildService(canProceed: () async => false).check();

      expect(finished, isFalse);
      expect(calls, isEmpty);
    });

    test('an update found is not shown when the answer changes while Play is asked', () async {
      final answers = [true, false];

      await buildService(canProceed: () async => answers.removeAt(0)).check();

      expect(calls, ['check']);
    });

    test('an immediate update is not shown either', () async {
      info = appUpdateInfo(
        updateAvailability: UpdateAvailability.updateAvailable,
        immediateUpdateAllowed: true,
        updatePriority: 5,
      );
      final answers = [true, false];

      await buildService(canProceed: () async => answers.removeAt(0)).check();

      expect(calls, ['check']);
    });

    test('a downloaded update is not installed', () async {
      info = appUpdateInfo(installStatus: InstallStatus.downloaded);
      final answers = [true, false];

      await buildService(canProceed: () async => answers.removeAt(0)).check();

      expect(calls, ['check']);
    });

    test('an interrupted immediate update is not resumed', () async {
      info = appUpdateInfo(updateAvailability: UpdateAvailability.developerTriggeredUpdateInProgress);
      final answers = [true, false];

      await buildService(canProceed: () async => answers.removeAt(0)).check();

      expect(calls, ['check']);
    });

    test('a download that ends after the answer changed is left for the next check to install', () async {
      var allowed = true;
      final download = Completer<AppUpdateResult>();
      final service = AppUpdateService(
        canProceed: () async => allowed,
        checkForUpdate: () async {
          calls.add('check');
          return info;
        },
        startFlexibleUpdate: () {
          calls.add('startFlexible');
          return download.future;
        },
        completeFlexibleUpdate: () async {
          calls.add('completeFlexible');
        },
      );

      final check = service.check();
      await pumpEventQueue();
      allowed = false;
      download.complete(AppUpdateResult.success);

      expect(await check, isFalse);
      expect(calls, ['check', 'startFlexible']);

      allowed = true;
      info = appUpdateInfo(installStatus: InstallStatus.downloaded);

      expect(await service.check(), isTrue);

      expect(calls, ['check', 'startFlexible', 'check', 'completeFlexible']);
    });

    test('the next check asks again and prompts', () async {
      var allowed = false;
      final service = buildService(canProceed: () async => allowed);

      await service.check();
      allowed = true;
      await service.check();

      expect(calls, ['check', 'startFlexible', 'completeFlexible']);
    });

    test('a failing answer is swallowed and the next check still runs', () async {
      var shouldThrow = true;
      final service = buildService(
        canProceed: () async {
          if (shouldThrow) {
            throw StateError('no activity');
          }
          return true;
        },
      );

      await service.check();
      shouldThrow = false;
      await service.check();

      expect(calls, ['check', 'startFlexible', 'completeFlexible']);
    });
  });
}
