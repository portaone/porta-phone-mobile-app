import 'package:flutter/widgets.dart' hide Notification;
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/notifications/models/notification.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/app/router/app_shell.dart';

class _AnyNotification extends MessageNotification {
  const _AnyNotification();

  @override
  String l10n(BuildContext context) => 'anything';
}

/// A notification is shown where the person is and nowhere else, and "where the
/// person is" is a stack rather than a single screen: settings leads on to a
/// dozen screens, and a person on one of them is still in settings.
void main() {
  bool Function(String) activeRoutes(Set<String> names) => names.contains;

  test('a settings sub-screen counts as being in the main part of the app', () {
    // The case that was silently dropping everything: voicemail is reached
    // through settings, so neither the main screen nor the settings screen
    // itself is what is on screen.
    final active = activeRoutes({MainShellRoute.name, SettingsRouterPageRoute.name, VoicemailScreenPageRoute.name});

    expect(AppShell.isNotificationInScope(const _AnyNotification(), active), isTrue);
  });

  test('so does the settings screen it starts from', () {
    final active = activeRoutes({MainShellRoute.name, SettingsRouterPageRoute.name, SettingsScreenPageRoute.name});

    expect(AppShell.isNotificationInScope(const _AnyNotification(), active), isTrue);
  });

  test('and so does a bottom-menu section', () {
    final active = activeRoutes({MainShellRoute.name, MainScreenPageRoute.name});

    expect(AppShell.isNotificationInScope(const _AnyNotification(), active), isTrue);
  });

  test('a route belonging to none of the scopes is not', () {
    // Nothing of the app's own is on screen - a notification here would land on
    // whatever the person is looking at instead.
    final active = activeRoutes({'SomeOtherPageRoute'});

    expect(AppShell.isNotificationInScope(const _AnyNotification(), active), isFalse);
  });
}
