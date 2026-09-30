import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

import 'package:webtrit_phone/common/common.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/push_notification/push_notifications.dart';

import 'isolate_manager.dart';

export 'package:signaling_service/signaling_service.dart'
    show
        SignalingModule,
        SignalingModuleEvent,
        SignalingModuleFactory,
        SignalingConnecting,
        SignalingConnected,
        SignalingConnectionFailed,
        SignalingDisconnecting,
        SignalingDisconnected,
        SignalingHandshakeReceived,
        SignalingProtocolEvent;

// When false, push fallback on persistent-session devices is suppressed entirely
// and only logged. Flip to false to isolate FGS recovery behavior during testing.
const _kPersistentPushFallbackEnabled = true;

final _logger = Logger('BackgroundCallIsolate');

// Lazily-initialised isolate-level manager.
PushNotificationIsolateManager? _manager;

// Resolves an arbitrary persisted locale to a locale that lookupAppLocalizations
// can handle. Falls back to the first supported locale (EN) when the stored value
// is the 'und' sentinel (no locale ever selected) or any other unsupported tag.
// [supported] is what the build carries: AppLocalizations.supportedLocales.
Locale _effectiveLocale(Locale locale, List<Locale> supported) {
  if (supported.contains(locale)) return locale;
  final byLanguage = supported.where((s) => s.languageCode == locale.languageCode).firstOrNull;
  return byLanguage ?? supported.first;
}

// The languages this build carries, which is all there is to say: the build
// wrote only the ones the brand enables. This used to read and parse the app
// config asset to intersect the two, on a separate Dart VM woken by a push -
// work that could only ever agree with what was already on disk.

/// Returns the isolate-level manager, reusing an existing instance if already
/// initialised. Accepts an already-constructed [PushIsolateContext] so the
/// caller controls when heavy resources (DB, certificates) are opened.
///
/// [PushIsolateContext] is kept separate from [PushNotificationIsolateManager]
/// because the manager depends on feature-layer imports that must not be pulled
/// into [lib/common]. Both are torn down together by [_disposeContext].
Future<PushNotificationIsolateManager> _getOrInit(PushIsolateContext context) async {
  if (_manager != null) return _manager!;

  // The push isolate is a separate Dart VM - it never receives the setModuleFactory()
  // call made in bootstrap.dart (Activity isolate). Register the factory here so
  // _startDirect() can create a SignalingModule when connect() is called from run().
  await WebtritSignalingService.setModuleFactory(createSignalingModule);
  WebtritSignalingService.setHandoffCallback(() => _manager?.notifyActivityTookOver());
  _logger.info('_getOrInit: module factory and handoff callback registered');

  final l10n = lookupAppLocalizations(_effectiveLocale(context.locale, AppLocalizations.supportedLocales));
  final localPushRepository = context.localPushRepository;
  _manager = PushNotificationIsolateManager(
    callLogsRepository: context.callLogsRepository,
    callkeep: BackgroundPushSessionCallkeep(),
    createSignaling: () => WebtritSignalingService(
      config: SignalingServiceConfig(
        coreUrl: context.secureStorage.readCoreUrl() ?? '',
        tenantId: context.secureStorage.readTenantId() ?? '',
        token: context.secureStorage.readToken() ?? '',
        trustedCertificates: context.appCertificates.trustedCertificates,
      ),
      mode: SignalingServiceMode.pushBound,
    ),
    logger: Logger('PushNotificationIsolateManager'),
    onMissedCall: (callId, callerName) => localPushRepository.displayPush(
      AppLocalPush.missedCall(
        callId,
        l10n.notifications_missedCall_title,
        callerName ?? l10n.notifications_missedCall_unknownCaller,
      ),
    ),
  );
  // init() constructs WebtritSignalingService and wires up the event subscription.
  // The WebSocket connection starts in connect(), which is called from run().
  _logger.info('_getOrInit: initialising signaling module...');
  _manager!.init();
  _logger.info('_getOrInit: init complete');

  return _manager!;
}

/// Closes the manager and releases all isolate-level resources.
///
/// Must be called when [CallkeepPushNotificationSyncStatus.releaseResources]
/// is received so the isolate does not hold open database connections or
/// active signaling sessions after the OS reclaims the background process.
Future<void> _disposeContext(PushIsolateContext context) async {
  await _manager?.close();
  await context.dispose();
  _manager = null;
}

/// Entry point for the CallKeep push-notification background isolate.
///
/// Runs the full incoming-call lifecycle (signaling, missed-call notification,
/// call log), then disposes all resources. The plugin keeps [IncomingCallService]
/// up until this future completes and stops it itself afterwards, so the work the
/// session starts is done while the service still has its rights.
/// Registered via [AndroidCallkeepServices.backgroundPushNotificationBootstrapService.initializeCallback].
///
/// ## Persistent-session devices
///
/// When [IncomingCallType.socket] is selected the FGS owns the persistent WebSocket.
/// A push arriving on such a device means the FGS was frozen or killed by the OEM --
/// the push is a fallback wake-up, not a signal to open a competing WebSocket.
/// Opening a direct WS here would race with the FGS reconnect and trigger a 4441
/// eviction loop. Instead, [restoreService] is called to restart the FGS if it was
/// killed (no-op when it is merely frozen), and the push isolate exits immediately.
///
/// ## pushBound devices - lifecycle and handoff
///
/// The push isolate opens its own WebSocket directly (no FGS). It runs until
/// one of three outcomes:
/// - **Missed call**: [HangupEvent] received before the user answers ->
///   `reportEndCall()` ends the [PhoneConnection] at once, the missed call is recorded while
///   [IncomingCallService] is still up, and the session completes once the record is done.
/// - **Answered via push UI**: `performAnswerCall` fires -> the call is remembered as
///   answered and the session completes; the plugin stops [IncomingCallService] without
///   terminating the connection, leaving the Activity to adopt the live call.
/// - **Activity took over**: the Activity opens its own WebSocket, the server sends
///   4441 (`controllerForceAttachClose`) to the push isolate, or the plugin detects
///   the Activity via [IsolateNameServer] and calls the handoff callback - whichever
///   arrives first completes the push lifecycle early via `notifyActivityTookOver()`.
///   A missed-call record another call started still finishes before the future completes.
@pragma('vm:entry-point')
Future<void> onPushNotificationSyncCallback(CallkeepIncomingCallMetadata? metadata) async {
  PushIsolateContext? context;
  try {
    context = await PushIsolateContext.init();
  } catch (e) {
    _logger.severe('onPushNotificationSyncCallback: context init failed, aborting: $e');
    return;
  }

  final incomingCallType = context.incomingCallTypeRepository.getIncomingCallType();

  if (incomingCallType == IncomingCallType.socket) {
    await context.dispose();
    if (!_kPersistentPushFallbackEnabled) {
      _logger.warning(
        'onPushNotificationSyncCallback: push fallback received on persistent-session device '
        '(callId=${metadata?.callId}) - fallback disabled by flag, skipping FGS recovery',
      );
      return;
    }
    _logger.info(
      'onPushNotificationSyncCallback: push fallback received on persistent-session device '
      '(callId=${metadata?.callId}) - FGS was likely frozen or killed by OEM; '
      'skipping direct WS, attempting FGS recovery via restoreService()',
    );
    try {
      await WebtritSignalingService.restoreService();
    } catch (e, st) {
      _logger.warning('onPushNotificationSyncCallback: restoreService() failed', e, st);
    }
    return;
  }

  // pushBound: run the direct-WS call lifecycle with the already-initialised context.
  // No timeout is applied here - the push isolate owns a direct WebSocket and its
  // lifecycle is driven by natural terminal events (HangupEvent, 4441 eviction, or
  // user answering on this device). The legacy 20-second timeout was an Android FGS
  // background-budget constraint that no longer applies in the pushBound architecture.
  try {
    final manager = await _getOrInit(context);
    // NOTE: the hard deadline for this call is enforced natively by
    // IncomingCallService.INDEPENDENT_SERVICE_TIMEOUT_MS (60 s). When it fires,
    // the Android side calls stopSelf() - onDestroy() cancels the notification
    // and stops vibration correctly.
    // TODO: consider moving all timeout constants (native + Dart) to a shared
    // setup/config location so they can be reviewed and adjusted in one place.
    await manager.run(metadata);
  } catch (e) {
    _logger.severe('onPushNotificationSyncCallback: error=$e');
  } finally {
    await _disposeContext(context);
  }
}

/// Called by the [WebtritSignalingService] plugin when a call-relevant signaling
/// event arrives via the persistent foreground-service WebSocket connection.
///
/// Runs inside the foreground-service background isolate. Must be a top-level
/// function annotated with [@pragma('vm:entry-point')] so that [PluginUtilities]
/// can serialise its handle.
///
/// Handles [IncomingCallEvent] (report call to Android Telecom so the system
/// call UI is shown) and [HangupEvent] (release the call so Telecom removes it
/// and the notification is dismissed). Other event types are logged and ignored.
@pragma('vm:entry-point')
Future<void> onSignalingBackgroundCallEvent(Event event) async {
  _logger.info('onSignalingBackgroundCallEvent: ${event.runtimeType}');

  switch (event) {
    case IncomingCallEvent():
      // The bootstrap channel here is registered on the FGS engine by
      // WebtritCallkeep.attachToEngine. While that engine is attached callkeep treats it as the
      // owner of background work, so it shows the incoming-call UI without starting its own push
      // isolate (no redundant WebSocket, no onPushNotificationSyncCallback side effect).
      final error = await AndroidCallkeepServices.backgroundPushNotificationBootstrapService
          .reportNewIncomingCall(
            event.callId,
            CallkeepHandle.number(event.caller),
            displayName: event.callerDisplayName?.isEmpty == true ? null : event.callerDisplayName,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              _logger.severe('onSignalingBackgroundCallEvent: reportNewIncomingCall timed out callId=${event.callId}');
              return null;
            },
          );

      if (error != null) {
        _logger.warning('onSignalingBackgroundCallEvent: reportNewIncomingCall error=$error callId=${event.callId}');
      }

    case HangupEvent():
      try {
        await AndroidCallkeepServices.backgroundPushNotificationService
            .releaseCall(event.callId)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                _logger.severe('onSignalingBackgroundCallEvent: releaseCall timed out callId=${event.callId}');
              },
            );
      } catch (e) {
        _logger.warning('onSignalingBackgroundCallEvent: releaseCall error=$e callId=${event.callId}');
      }

    default:
      _logger.warning('onSignalingBackgroundCallEvent: unhandled event ${event.runtimeType}');
  }
}
