import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:in_app_update/in_app_update.dart';
import 'package:logging/logging.dart';

final _logger = Logger('AppUpdateService');

/// Function handles over the static [InAppUpdate] API, injectable for tests.
typedef CheckForUpdate = Future<AppUpdateInfo> Function();
typedef PerformImmediateUpdate = Future<AppUpdateResult> Function();
typedef StartFlexibleUpdate = Future<AppUpdateResult> Function();
typedef CompleteFlexibleUpdate = Future<void> Function();

/// Whether an update may take the screen right now. Every step of an update
/// either opens a Play activity on top of the app's or restarts the app, so the
/// caller answers false while something must stay visible - a call above all.
typedef CanProceedWithUpdate = Future<bool> Function();

/// Prompts the user to update the app via the Play Core in-app updates API.
///
/// Android only: [check] is a silent no-op on other platforms, on devices
/// without Google Play services, and on builds not installed from Google Play
/// (the underlying Play Core call fails there and the failure is swallowed).
///
/// All update UI is native Play Core - no in-app dialogs. The update type is
/// driven by the publish-time priority (Google Play Developer API
/// `inAppUpdatePriority`): below [immediatePriorityThreshold] the update runs
/// as a flexible (background download, restart on completion) prompt, at or
/// above it as an immediate (blocking full-screen) flow. The priority defaults
/// to 0 on publish, so regular releases surface as a soft ask.
class AppUpdateService {
  AppUpdateService({
    this.immediatePriorityThreshold = 4,
    CanProceedWithUpdate? canProceed,
    CheckForUpdate? checkForUpdate,
    PerformImmediateUpdate? performImmediateUpdate,
    StartFlexibleUpdate? startFlexibleUpdate,
    CompleteFlexibleUpdate? completeFlexibleUpdate,
  }) : _canProceed = canProceed ?? _always,
       _checkForUpdate = checkForUpdate ?? InAppUpdate.checkForUpdate,
       _performImmediateUpdate = performImmediateUpdate ?? InAppUpdate.performImmediateUpdate,
       _startFlexibleUpdate = startFlexibleUpdate ?? InAppUpdate.startFlexibleUpdate,
       _completeFlexibleUpdate = completeFlexibleUpdate ?? InAppUpdate.completeFlexibleUpdate;

  /// Minimum publish-time update priority (0-5) that escalates the update
  /// from a flexible prompt to the blocking immediate flow.
  final int immediatePriorityThreshold;

  final CanProceedWithUpdate _canProceed;
  final CheckForUpdate _checkForUpdate;
  final PerformImmediateUpdate _performImmediateUpdate;
  final StartFlexibleUpdate _startFlexibleUpdate;
  final CompleteFlexibleUpdate _completeFlexibleUpdate;

  static Future<bool> _always() async => true;

  bool get _isSupportedPlatform => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Checks Google Play for an available update and drives the native flow.
  ///
  /// [CanProceedWithUpdate] is asked before every step that shows Play's UI or
  /// installs. Returns false when it refused one: the check stopped there and
  /// is worth repeating once the update may proceed - an update already
  /// downloaded is installed by that repeat. Returns true when nothing is left
  /// to do: no update, the user answered Play's prompt, or Play failed.
  ///
  /// The service keeps no state between calls; one check at a time and when to
  /// repeat it are the caller's (see `AppUpdateCheck`).
  Future<bool> check() async {
    if (!_isSupportedPlatform) {
      return true;
    }
    try {
      return await _check();
    } catch (e, stackTrace) {
      // Expected on devices without Play services and on sideloaded builds.
      _logger.fine('check failed - ignore', e, stackTrace);
      return true;
    }
  }

  Future<bool> _check() async {
    if (!await _canProceed()) {
      return false;
    }
    final info = await _checkForUpdate();

    // Asked again: Play took its time to answer, and every branch below
    // either opens a Play activity or restarts the app.
    if (!await _canProceed()) {
      return false;
    }

    // An immediate update was interrupted (e.g. the app was restarted
    // mid-flow); Play requires the app to resume it.
    if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
      await _performImmediateUpdate();
      return true;
    }

    // A flexible download finished while the app was away - install it now,
    // otherwise the user keeps running the old version until a cold restart.
    if (info.installStatus == InstallStatus.downloaded) {
      await _completeFlexibleUpdate();
      return true;
    }

    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return true;
    }

    final immediate =
        info.immediateUpdateAllowed &&
        (info.updatePriority >= immediatePriorityThreshold || !info.flexibleUpdateAllowed);
    if (immediate) {
      await _performImmediateUpdate();
    } else if (info.flexibleUpdateAllowed) {
      return _runFlexibleUpdate(info);
    }
    return true;
  }

  Future<bool> _runFlexibleUpdate(AppUpdateInfo info) async {
    final result = await _startFlexibleUpdate();
    switch (result) {
      case AppUpdateResult.success:
        // The download ran for as long as it took, and installing restarts
        // the app. Left downloaded, the update is installed by the repeat.
        if (!await _canProceed()) {
          return false;
        }
        await _completeFlexibleUpdate();
      case AppUpdateResult.userDeniedUpdate:
        break;
      case AppUpdateResult.inAppUpdateFailed:
        _logger.warning('flexible update failed for version code ${info.availableVersionCode}');
    }
    return true;
  }
}
