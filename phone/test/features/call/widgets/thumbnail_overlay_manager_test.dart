import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

/// The floating thumbnail tells where it is on the screen while shown, so what lies under it can
/// step aside; hidden, it tells nothing.
void main() {
  testWidgets('the shown thumbnail tells its area, after a drag its new one, hidden none', (tester) async {
    final manager = ThumbnailOverlayManager(stickyPadding: kStickyOverlayPadding);
    addTearDown(manager.dispose);
    late BuildContext overlayContext;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            overlayContext = context;
            return const SizedBox.expand();
          },
        ),
      ),
    );

    manager.show(overlayContext, child: const SizedBox(key: Key('window'), width: 90, height: 160));
    await tester.pumpAndSettle();
    expect(floatingThumbnailArea.value, tester.getRect(find.byKey(const Key('window'))));

    await tester.drag(find.byKey(const Key('window')), const Offset(-100, 200));
    await tester.pumpAndSettle();
    expect(floatingThumbnailArea.value, tester.getRect(find.byKey(const Key('window'))));

    manager.hide();
    await tester.pumpAndSettle();
    expect(floatingThumbnailArea.value, isNull);
  });
}
