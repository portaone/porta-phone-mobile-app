import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/voicemail/bloc/voicemail_playback_controller.dart';
import 'package:webtrit_phone/features/voicemail/models/voicemail_screen_context.dart';
import 'package:webtrit_phone/features/voicemail/widgets/voicemail_tile.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../../helpers/helpers.dart';

class _MockPlaybackController extends Mock implements VoicemailPlaybackController {}

void main() {
  Voicemail message({bool? saved}) => Voicemail(
    id: 'vm-1',
    date: '2026-08-12T08:17:00Z',
    duration: 4.2,
    sender: '555002',
    displaySender: 'User 555002',
    receiver: '555001',
    status: ReadStatus.read,
    size: 17,
    type: 'voice',
    url: 'https://example.test/vm-1.mp3',
    saved: saved,
  );

  late _MockPlaybackController controller;

  setUp(() {
    controller = _MockPlaybackController();
    when(() => controller.activeId).thenReturn(null);
    when(() => controller.isLoading).thenReturn(false);
    when(() => controller.error).thenReturn(null);
    when(() => controller.addListener(any())).thenReturn(null);
    when(() => controller.removeListener(any())).thenReturn(null);
  });

  Widget wrap({
    VoidCallback? onLongPress,
    Voicemail? voicemail,
    bool saveSupported = false,
    bool trashSupported = false,
    bool forwardSupported = false,
    bool inTrash = false,
    void Function(Voicemail)? onToggleSavedStatus,
    void Function(Voicemail)? onForwarded,
    void Function(Voicemail)? onRestored,
    void Function(Voicemail)? onDeletedPermanently,
  }) {
    final item = voicemail ?? message();
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        // The avatar reads presence params from the tree, and the row is laid
        // out for a phone-sized surface.
        body: PresenceViewParams(
          hybridPresenceSupport: false,
          blfViaSipSupport: false,
          presenceViaSipSupport: false,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider<VoicemailPlaybackController>.value(value: controller),
              Provider<VoicemailScreenContext>.value(
                value: VoicemailScreenContext(
                  mediaCacheBasePath: '/tmp/vm-cache',
                  dateFormat: DateFormat('MMM d, y HH:mm'),
                  mediaHeaders: const {},
                ),
              ),
            ],
            child: VoicemailTile(
              voicemail: item,
              displayName: 'User 555002',
              selected: false,
              saveSupported: saveSupported,
              trashSupported: trashSupported,
              forwardSupported: forwardSupported,
              inTrash: inTrash,
              onCall: (_) {},
              onDeleted: (_) {},
              onToggleSeenStatus: (_) {},
              onToggleSavedStatus: (it) => onToggleSavedStatus?.call(it),
              onForwarded: (it) => onForwarded?.call(it),
              onRestored: (it) => onRestored?.call(it),
              onDeletedPermanently: (it) => onDeletedPermanently?.call(it),
              onLongPress: (_) => onLongPress?.call(),
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the actions menu is named, targetable by id and opens', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap());

    final menu = find.bySemanticsIdentifier(voicemailMenuId);
    expectTapTargetSemantics(tester, menu, label: 'More', identifier: voicemailMenuId, isButton: true);

    await tapViaSemantics(tester, menu);
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);

    handle.dispose();
  });

  testWidgets('long-pressing the menu shows its own name and does not start selecting messages', (tester) async {
    var selectionStarted = false;
    await tester.pumpWidget(wrap(onLongPress: () => selectionStarted = true));

    await tester.longPress(find.byIcon(Icons.more_vert));
    await tester.pump(const Duration(seconds: 1));

    // The row's long press means "select this message"; the menu button must
    // not fall through to it, and the tooltip must name the button itself.
    expect(selectionStarted, isFalse);
    expect(find.text('More'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  group('keeping a message', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('a mailbox that cannot keep anything does not offer to', (tester) async {
      await tester.pumpWidget(wrap(voicemail: message(saved: false)));

      await openMenu(tester);

      expect(find.text('Save'), findsNothing);
      expect(find.text('Unsave'), findsNothing);
    });

    testWidgets('a message that reports no flag does not offer it either', (tester) async {
      // No flag means the mailbox behind this message cannot hold one, which
      // is not the same as the message not being kept: offering to save it
      // would promise something that does not stay.
      await tester.pumpWidget(wrap(saveSupported: true, voicemail: message()));

      await openMenu(tester);

      expect(find.text('Save'), findsNothing);
      expect(find.text('Unsave'), findsNothing);
    });

    testWidgets('an unkept message offers Save, and reports it', (tester) async {
      Voicemail? toggled;
      await tester.pumpWidget(
        wrap(saveSupported: true, voicemail: message(saved: false), onToggleSavedStatus: (it) => toggled = it),
      );

      await openMenu(tester);
      expect(find.text('Unsave'), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(toggled?.id, 'vm-1');
    });

    testWidgets('a kept message offers Unsave instead', (tester) async {
      await tester.pumpWidget(wrap(saveSupported: true, voicemail: message(saved: true)));

      await openMenu(tester);

      expect(find.text('Save'), findsNothing);
      expect(find.text('Unsave'), findsOneWidget);
    });

    testWidgets('the mark is shown only on a kept message, and it is named', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(saveSupported: true, voicemail: message(saved: false)));

      expect(find.byIcon(Icons.bookmark), findsNothing);

      await tester.pumpWidget(wrap(saveSupported: true, voicemail: message(saved: true)));
      await tester.pump();

      // The mark is the only difference between a kept message and any other,
      // so a reader that cannot hear it cannot tell them apart. The row merges
      // its parts into one node, so the word is looked for inside that node's
      // name rather than as a name of its own.
      expect(find.byIcon(Icons.bookmark), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'\bSaved\b')), findsWidgets);

      handle.dispose();
    });
  });

  group('the trash', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('without a trash the delete action is named for being final', (tester) async {
      await tester.pumpWidget(wrap());

      await openMenu(tester);

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Move to trash'), findsNothing);
    });

    testWidgets('with a trash it is named for where the message goes', (tester) async {
      // The same gesture, but the message can be had back, and calling both
      // of them "Delete" would make the reversible one look as final as the
      // other.
      await tester.pumpWidget(wrap(trashSupported: true));

      await openMenu(tester);

      expect(find.text('Move to trash'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('a trashed message answers only to putting it back or finishing the job', (tester) async {
      await tester.pumpWidget(
        wrap(trashSupported: true, inTrash: true, saveSupported: true, voicemail: message(saved: true)),
      );

      await openMenu(tester);

      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Delete permanently'), findsOneWidget);
      // Calling, marking and keeping are about a message someone still has.
      expect(find.text('Call'), findsNothing);
      expect(find.text('Unsave'), findsNothing);
      expect(find.text('Move to trash'), findsNothing);
    });

    testWidgets('restore and delete permanently report the message', (tester) async {
      Voicemail? restored;
      Voicemail? deleted;
      await tester.pumpWidget(
        wrap(
          trashSupported: true,
          inTrash: true,
          onRestored: (it) => restored = it,
          onDeletedPermanently: (it) => deleted = it,
        ),
      );

      await openMenu(tester);
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(restored?.id, 'vm-1');

      await openMenu(tester);
      await tester.tap(find.text('Delete permanently'));
      await tester.pumpAndSettle();
      expect(deleted?.id, 'vm-1');
    });

    testWidgets('a trashed message is drawn back', (tester) async {
      await tester.pumpWidget(wrap(trashSupported: true));
      expect(find.byType(Opacity), findsNothing);

      await tester.pumpWidget(wrap(trashSupported: true, inTrash: true));
      await tester.pump();

      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.6);
    });
  });

  group('forwarding', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('a backend without forwarding does not offer it', (tester) async {
      await tester.pumpWidget(wrap());

      await openMenu(tester);

      expect(find.text('Forward'), findsNothing);
    });

    testWidgets('a backend with forwarding offers it and reports the message', (tester) async {
      Voicemail? forwarded;
      await tester.pumpWidget(wrap(forwardSupported: true, onForwarded: (it) => forwarded = it));

      await openMenu(tester);
      await tester.tap(find.text('Forward'));
      await tester.pumpAndSettle();

      expect(forwarded?.id, 'vm-1');
    });

    testWidgets('a trashed message is not forwarded', (tester) async {
      // It is on its way out of the mailbox; passing a copy of it on would be
      // a decision about a message the person has already made a decision
      // about.
      await tester.pumpWidget(wrap(forwardSupported: true, trashSupported: true, inTrash: true));

      await openMenu(tester);

      expect(find.text('Forward'), findsNothing);
    });
  });
}
