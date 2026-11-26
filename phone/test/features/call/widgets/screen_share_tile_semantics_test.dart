import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import '../../../helpers/helpers.dart';

/// The tile that stands in for the camera preview while the screen is shown: it says so, and its
/// Stop is a named button the QA stand reaches by its id.
void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(alignment: Alignment.topRight, child: child),
      ),
    );
  }

  for (final orientation in Orientation.values) {
    testWidgets('$orientation: the tile says the screen is shared and its Stop stops it', (tester) async {
      final semantics = tester.ensureSemantics();
      var stops = 0;
      await tester.pumpWidget(wrap(ScreenShareTile(orientation: orientation, onStopPressed: () => stops++)));

      expect(find.bySemanticsIdentifier(callScreenShareTileId), findsOneWidget);
      expect(find.text('Sharing screen'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ScreenShareTile)),
        ThumbnailLayout.calcFrameSize(orientation: orientation),
        reason: 'the size of the camera preview it replaces',
      );

      final stop = find.bySemanticsIdentifier(callScreenShareStopId);
      expectTapTargetSemantics(tester, stop, label: 'Stop', identifier: callScreenShareStopId, isButton: true);
      await tapViaSemantics(tester, stop);
      expect(stops, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
