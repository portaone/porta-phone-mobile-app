import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide Notification;

import 'package:logging/logging.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/push_notification/push_notifications.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../models/notification.dart';

final _logger = Logger('NotificationPresenter');

/// Decides how each notification reaches the user and delivers it, one at a time.
///
/// A notification says where it may go ([Notification.deliveries]); this picks the way by
/// whether the user can see the app now: a snack bar while they can, the system shade as well
/// while they cannot. What the app can show and what it can see of the platform come in through
/// the constructor, so the decision is the same in a test as on a phone.
class NotificationPresenter {
  NotificationPresenter({
    required this.isOnScreen,
    required this.showInShade,
    required this.removeFromShade,
    required this.shadeAvailable,
    this.wait = const Duration(seconds: 3),
  });

  /// The presenter of the running app: the lifecycle and lock state of the phone, and the
  /// local notifications of `flutter_local_notifications`, which have no web platform. What it
  /// put into the shade goes when the app comes back on screen - the user is looking at the
  /// app then, where the same message waits.
  factory NotificationPresenter.platform(LocalPushRepository localPushRepository) {
    final presenter = NotificationPresenter(
      isOnScreen: _appOnScreen,
      showInShade: (text) => localPushRepository.displayPush(AppLocalPush.notice(text)),
      removeFromShade: (text) => localPushRepository.dissmissById(AppLocalPush.noticeIdOf(text)),
      shadeAvailable: !kIsWeb,
    );
    presenter._lifecycle = AppLifecycleListener(onResume: presenter.onAppResumed);
    return presenter;
  }

  /// Whether the user can see the app now.
  final Future<bool> Function() isOnScreen;

  /// Puts [text] into the system shade.
  final Future<void> Function(String text) showInShade;

  /// Takes [text] out of the system shade.
  final Future<void> Function(String text) removeFromShade;

  /// How long a platform call is waited for. One that never answers must not hold up every
  /// notification after it; the lock state read too late counts as out of sight, so the
  /// message goes to the shade as well rather than nowhere the user looks.
  final Duration wait;

  AppLifecycleListener? _lifecycle;

  /// What is in the shade from here, to take out once the app is back on screen.
  final _inShade = <String>{};

  /// Whether this platform has a shade at all; without one a notification stays in the app.
  final bool shadeAvailable;

  Future<void> _last = Future.value();

  /// The ways [notification] reaches the user; empty when it does not.
  ///
  /// In the app it goes only where it belongs ([inScope]), on screen or not: a bar put up out
  /// of sight waits for the user to come back. Out of sight it also goes to the shade when it
  /// may and the platform has one - the app may come up a moment later (a call answered from
  /// a notification opens it) or stay behind the lock screen, and the user sees one or the
  /// other. One that may only go to the shade goes there on screen too.
  static Set<NotificationDelivery> deliveriesOf(
    Notification notification, {
    required bool onScreen,
    required bool inScope,
    required bool shadeAvailable,
  }) {
    final allowed = {...notification.deliveries()};
    if (!shadeAvailable) allowed.remove(NotificationDelivery.shade);
    final inApp = allowed.contains(NotificationDelivery.inApp);
    final shade = allowed.contains(NotificationDelivery.shade) && (!onScreen || !inApp);
    return {if (inApp && inScope) NotificationDelivery.inApp, if (shade) NotificationDelivery.shade};
  }

  /// Delivers [notification] after every one presented before it, in the order they came:
  /// the lock state is read asynchronously, and without the queue a later notification
  /// could overtake an earlier one. [showInApp] belongs to the caller's screen and is called
  /// only when the notification goes that way; [text] is what the shade shows, read by the
  /// caller while its context is sure to be there. A failure is logged and does not hold up
  /// the ones after it.
  Future<void> present(
    Notification notification, {
    required bool inScope,
    required VoidCallback showInApp,
    required String text,
  }) {
    final next = _last.then((_) => _deliver(notification, inScope: inScope, showInApp: showInApp, text: text));
    _last = next.catchError((Object e, StackTrace s) => _logger.warning('notification not delivered', e, s));
    return _last;
  }

  Future<void> _deliver(
    Notification notification, {
    required bool inScope,
    required VoidCallback showInApp,
    required String text,
  }) async {
    // Only a notification that may go to the shade waits for the screen: for the rest the
    // answer changes nothing, and the platform call would only delay the bar.
    final mayShade = shadeAvailable && notification.deliveries().contains(NotificationDelivery.shade);
    final onScreen = mayShade ? await isOnScreen().timeout(wait, onTimeout: () => false) : true;
    final ways = deliveriesOf(notification, onScreen: onScreen, inScope: inScope, shadeAvailable: shadeAvailable);
    if (ways.contains(NotificationDelivery.inApp)) showInApp();
    if (ways.contains(NotificationDelivery.shade)) {
      _logger.info('out of sight, to the shade: ${notification.runtimeType}');
      _inShade.add(text);
      await showInShade(text).timeout(wait);
    }
  }

  /// The app is on screen again: what was put into the shade meanwhile is in the app too.
  Future<void> onAppResumed() async {
    final texts = [..._inShade];
    _inShade.clear();
    for (final text in texts) {
      try {
        await removeFromShade(text).timeout(wait);
      } catch (e) {
        _logger.warning('notice not taken out of the shade', e);
      }
    }
  }

  void dispose() => _lifecycle?.dispose();
}

/// Resumed is not enough on Android: a call screen shown over the lock screen keeps the app
/// resumed, and the keyguard is back over it as soon as the call ends.
Future<bool> _appOnScreen() async {
  if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return false;
  // The lock state is known on Android only; on iOS a call answered on the lock screen leaves
  // the app out of the foreground, which the lifecycle state already tells.
  if (!PlatformInfo.isAndroid) return true;
  try {
    return !await AndroidCallkeepUtils.activityControl.isDeviceLocked();
  } catch (e) {
    _logger.warning('lock state unknown, taking the app as on screen', e);
    return true;
  }
}
