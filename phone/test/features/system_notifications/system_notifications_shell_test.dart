import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';

import 'package:webtrit_phone/data/feature_access.dart';
import 'package:webtrit_phone/features/system_notifications/system_notifications.dart';

import '../../helpers/feature_access_factories.dart';

/// The shell reads its configuration once, at mount.
///
/// It used to re-read it every second in case the flags moved, and they cannot:
/// [MainShell] pins one `FeatureAccess` snapshot for the whole session, and the
/// shell captures both the snapshot and the flags off it in `late final` fields.
/// The loop could therefore only ever compute the same two booleans - while
/// keeping a timer alive for as long as the session lasted.
///
/// The test framework is the assertion here: a widget test fails if a timer is
/// still pending when the tree comes down, so a returning watcher fails this
/// even though nothing about it is observable from the outside.
void main() {
  Future<void> pumpShell(WidgetTester tester, {required bool notificationsSupported}) {
    final featureAccess = featureAccessFor(
      systemInfoWithSupported(notificationsSupported ? const ['notifications'] : const []),
    );
    expect(featureAccess.systemNotificationsConfig.systemNotificationsSupport, notificationsSupported);

    return tester.pumpWidget(
      Provider<FeatureAccess>.value(
        value: featureAccess,
        child: const SystemNotificationsShell(child: SizedBox.shrink()),
      ),
    );
  }

  testWidgets('leaves no timer running behind it', (tester) async {
    // Notifications off: the shell starts no services, so a pending timer can
    // only come from the shell itself.
    await pumpShell(tester, notificationsSupported: false);

    await tester.pump(const Duration(seconds: 5));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
