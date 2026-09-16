import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/call/call_tile.dart';

// What the trailing end of a row offers while somebody is being chosen. Before
// this, taking the dial button away left the overflow menu in its place, and
// that menu still offered to call, to message and to hand a call over - on a
// row the person was there to choose.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  CallTile tile({TilePick? pick, VoidCallback? onDialPressed}) => CallTile(
    leading: const SizedBox.square(dimension: 40),
    name: 'Iryna Shevchuk',
    callNumbers: const [],
    expanded: false,
    onTap: () {},
    onDialPressed: onDialPressed,
    pick: pick,
    onAudioCallPressed: () {},
    onVideoCallPressed: () {},
    onChatPressed: () {},
  );

  testWidgets('with no choice being made the row is unchanged', (tester) async {
    await tester.pumpWidget(wrap(tile(onDialPressed: () {})));

    expect(find.byIcon(Icons.call), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
  });

  testWidgets('a row nobody can dial falls back to its menu', (tester) async {
    // The behaviour that made the hole: no dial button, so the menu appeared.
    await tester.pumpWidget(wrap(tile()));

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('a row that answers the choice offers it and nothing else', (tester) async {
    await tester.pumpWidget(
      wrap(
        tile(
          pick: TilePick(icon: Icons.forward_to_inbox, label: 'Forward to Iryna', onPressed: () {}),
        ),
      ),
    );

    expect(find.byIcon(Icons.forward_to_inbox), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.call), findsNothing);
  });

  testWidgets('a row that does not answer it offers nothing at all', (tester) async {
    // Not the menu either: it was the only thing left to press on a row the
    // purpose had already refused.
    await tester.pumpWidget(
      wrap(
        tile(
          pick: const TilePick(icon: Icons.forward_to_inbox, label: 'Forward to Iryna'),
        ),
      ),
    );

    expect(find.byIcon(Icons.forward_to_inbox), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.call), findsNothing);
  });

  testWidgets('the mark and the name come from whoever is asking', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        tile(
          pick: TilePick(icon: Icons.forward_to_inbox, label: 'Forward to Iryna', onPressed: () {}),
        ),
      ),
    );

    // Handing a call on and passing a message along are not the same gesture,
    // so the row must not wear the phone icon for both.
    expect(find.byIcon(Icons.phone_forwarded), findsNothing);
    expect(find.bySemanticsLabel('Forward to Iryna'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('pressing it reports the choice', (tester) async {
    var called = false;
    await tester.pumpWidget(
      wrap(
        tile(
          pick: TilePick(icon: Icons.forward_to_inbox, label: 'Forward to Iryna', onPressed: () => called = true),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.forward_to_inbox));
    expect(called, isTrue);
  });
}
