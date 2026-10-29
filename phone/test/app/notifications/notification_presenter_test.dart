import 'dart:async';

import 'package:flutter/widgets.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/features/call/call.dart';

class _InAppOnly extends MessageNotification {
  const _InAppOnly();

  @override
  String l10n(BuildContext context) => 'in the app';
}

class _ShadeOnly extends MessageNotification {
  const _ShadeOnly();

  @override
  String l10n(BuildContext context) => 'in the shade';

  @override
  Set<NotificationDelivery> deliveries() => const {NotificationDelivery.shade};
}

const _mayReachShade = CallUserMediaErrorNotification();

/// A notification says where it may be delivered; the presenter picks the way by whether
/// the user can see the app. A snack bar under the lock screen waits unseen, so what may
/// go to the shade goes there while the app is out of sight.
void main() {
  group('the ways a notification goes', () {
    Set<NotificationDelivery> deliver(
      Notification n, {
      required bool onScreen,
      bool inScope = true,
      bool shade = true,
    }) => NotificationPresenter.deliveriesOf(n, onScreen: onScreen, inScope: inScope, shadeAvailable: shade);

    const inApp = NotificationDelivery.inApp;
    const shade = NotificationDelivery.shade;

    test('one for the app only is a snack bar where it belongs', () {
      expect(deliver(const _InAppOnly(), onScreen: true), {inApp});
    });

    test('one for the app only is put up out of sight as before, to wait for the user', () {
      expect(deliver(const _InAppOnly(), onScreen: false), {inApp});
    });

    test('one for the app only is not shown off its scope', () {
      expect(deliver(const _InAppOnly(), onScreen: true, inScope: false), isEmpty);
    });

    test('one that may reach the shade goes there out of sight, and waits in the app as well', () {
      // Answered from a notification on an unlocked phone, the app comes up a moment after
      // the failure: with the shade alone the user would see the app and no word of it.
      expect(deliver(_mayReachShade, onScreen: false), {inApp, shade});
    });

    test('out of its scope it still reaches the shade', () {
      expect(deliver(_mayReachShade, onScreen: false, inScope: false), {shade});
    });

    test('on screen it is a snack bar only', () {
      expect(deliver(_mayReachShade, onScreen: true), {inApp});
    });

    test('without a shade on the platform it stays in the app', () {
      expect(deliver(_mayReachShade, onScreen: false, shade: false), {inApp});
      expect(deliver(const _ShadeOnly(), onScreen: false, shade: false), isEmpty);
    });

    test('one for the shade only goes there even with the app on screen', () {
      expect(deliver(const _ShadeOnly(), onScreen: true), {shade});
    });
  });

  test('the call media notifications may reach the shade, the rest stay in the app', () {
    for (final n in [const CallUserMediaErrorNotification(), const CallVideoDowngradedNotification()]) {
      expect(n.deliveries(), {NotificationDelivery.inApp, NotificationDelivery.shade}, reason: '${n.runtimeType}');
    }
    expect(const CallMediaTrackSetupErrorNotification().deliveries(), {NotificationDelivery.inApp});
  });

  group('presenting', () {
    late List<String> shown;

    NotificationPresenter presenter({
      required Future<bool> Function() onScreen,
      bool shade = true,
      Future<void> Function(String text)? showInShade,
    }) => NotificationPresenter(
      isOnScreen: onScreen,
      showInShade: showInShade ?? (text) async => shown.add('shade: $text'),
      removeFromShade: (text) async => shown.add('removed: $text'),
      shadeAvailable: shade,
      wait: const Duration(milliseconds: 50),
    );

    Future<void> present(NotificationPresenter p, Notification n, String text) =>
        p.present(n, inScope: true, text: text, showInApp: () => shown.add('app: $text'));

    setUp(() => shown = []);

    test('puts the text in the shade, and the bar in the app, while the app is out of sight', () async {
      await present(presenter(onScreen: () async => false), _mayReachShade, 'no microphone');

      expect(shown, ['app: no microphone', 'shade: no microphone']);
    });

    test('shows the snack bar while the app is on screen', () async {
      await present(presenter(onScreen: () async => true), _mayReachShade, 'no microphone');

      expect(shown, ['app: no microphone']);
    });

    test('delivers in the order notifications came, however long the lock state takes', () async {
      final firstAnswer = Completer<bool>();
      var asked = 0;
      final p = presenter(onScreen: () => ++asked == 1 ? firstAnswer.future : Future.value(false));

      final first = present(p, const _ShadeOnly(), 'first');
      final second = present(p, const _ShadeOnly(), 'second');
      await Future<void>.delayed(Duration.zero);
      expect(shown, isEmpty, reason: 'the second waits for the first');

      firstAnswer.complete(false);
      await Future.wait([first, second]);

      expect(shown, ['shade: first', 'shade: second']);
    });

    test('a notification that fails does not hold up the next', () async {
      var asked = 0;
      final p = presenter(onScreen: () async => ++asked == 1 ? throw StateError('no lock state') : false);

      await present(p, const _ShadeOnly(), 'lost');
      await present(p, const _ShadeOnly(), 'next');

      expect(shown, ['shade: next']);
    });

    test('a notification for the app only does not wait for the screen', () async {
      var asked = 0;
      await present(presenter(onScreen: () async => ++asked > 0), const _InAppOnly(), 'saved');

      expect(shown, ['app: saved']);
      expect(asked, 0);
    });

    test('a screen that never answers counts as out of sight and holds up nothing', () async {
      final p = presenter(onScreen: () => Completer<bool>().future);

      await present(p, _mayReachShade, 'no microphone');
      await present(p, const _InAppOnly(), 'next');

      expect(shown, ['app: no microphone', 'shade: no microphone', 'app: next']);
    });

    test('a shade that never answers holds up nothing', () async {
      final p = presenter(onScreen: () async => false, showInShade: (_) => Completer<void>().future);

      await present(p, _mayReachShade, 'no microphone');
      await present(p, const _InAppOnly(), 'next');

      expect(shown, ['app: no microphone', 'app: next']);
    });

    test('what went to the shade is taken out once the app is back on screen', () async {
      final p = presenter(onScreen: () async => false);
      await present(p, _mayReachShade, 'no microphone');

      await p.onAppResumed();
      await p.onAppResumed();

      expect(shown, ['app: no microphone', 'shade: no microphone', 'removed: no microphone']);
    });
  });
}
