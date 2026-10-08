import 'package:flutter/semantics.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/voicemail/bloc/voicemail_playback_controller.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/widgets/voicemail_tile.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/utils/utils.dart';

import '../../helpers/helpers.dart';

class _MockPlaybackController extends Mock implements VoicemailPlaybackController {}

void main() {
  /// The address book's card for the caller; [name] is left out for a contact
  /// that has none, which the address book shows by its number.
  Contact card({String? name = 'User 555002'}) => Contact(
    id: 7,
    sourceType: ContactSourceType.external,
    kind: ContactKind.visible,
    aliasName: name,
    phones: const [ContactPhone(id: 1, number: '555002', label: kContactMainLabel, favorite: false)],
  );

  final known = card();

  /// A message from 555002. [from] is the caller's card, null for a stranger.
  Voicemail message({bool? saved, String? forwardedBy, Contact? from}) => Voicemail(
    id: 'vm-1',
    date: '2026-08-12T08:17:00Z',
    duration: 4.2,
    sender: '555002',
    senderContact: from,
    receiver: '555001',
    status: ReadStatus.read,
    size: 17,
    type: 'voice',
    url: 'https://example.test/vm-1.mp3',
    saved: saved,
    forwardedBy: forwardedBy,
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
    VoicemailForward? forward,
    void Function(Voicemail, Contact)? onForwardRetried,
    String? forwardedByName,
    void Function(Voicemail)? onOpenContact,
    void Function(Voicemail)? onToggleSavedStatus,
    void Function(Voicemail)? onForwarded,
    void Function(Voicemail)? onRestored,
    void Function(Voicemail)? onDeletedPermanently,
    bool selected = false,
    bool picking = true,
    VoidCallback? onTap,
  }) {
    final item = voicemail ?? message(from: known);
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: appLocalizationsDelegates,
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
              selected: selected,
              selecting: picking,
              saveSupported: saveSupported,
              trashSupported: trashSupported,
              forwardSupported: forwardSupported,
              inTrash: inTrash,
              forward: forward,
              forwardedByName: forwardedByName,
              onCall: (_) {},
              onDeleted: (_) {},
              onToggleSeenStatus: (_) {},
              onToggleSavedStatus: (it) => onToggleSavedStatus?.call(it),
              onForwarded: (it) => onForwarded?.call(it),
              onForwardRetried: (it, recipient) => onForwardRetried?.call(it, recipient),
              onOpenContact: (it) => onOpenContact?.call(it),
              onRestored: (it) => onRestored?.call(it),
              onDeletedPermanently: (it) => onDeletedPermanently?.call(it),
              onLongPress: (_) => onLongPress?.call(),
              // The screen gives the tile a tap only while messages are being picked.
              onTap: picking ? (_) => onTap?.call() : null,
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

  testWidgets('a message being forwarded says so where its menu was', (tester) async {
    // In place of the menu rather than beside it: nothing the menu offers is
    // something to do to a message whose forward has not been answered yet.
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(wrap(forward: const VoicemailForwardSending()));

    expect(find.bySemanticsIdentifier(voicemailMenuId), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsIdentifier(voicemailForwardingId)),
      isSemantics(label: 'Forwarding', identifier: voicemailForwardingId, isLiveRegion: true),
    );

    handle.dispose();
  });

  group('a forward that did not go through', () {
    final colleague = Contact(
      id: 1,
      sourceType: ContactSourceType.external,
      kind: ContactKind.visible,
      sourceId: 'user-7',
      isCurrentUser: false,
      aliasName: 'Iryna Shevchuk',
    );

    VoicemailForwardFailed failed([VoicemailForwardOutcome outcome = VoicemailForwardOutcome.failed]) =>
        VoicemailForwardFailed(outcome: outcome, recipient: colleague);

    testWidgets('leaves a quiet mark: a badge on the avatar and who it was for', (tester) async {
      await tester.pumpWidget(wrap(forward: failed()));

      expect(find.byKey(voicemailForwardFailedBadgeKey), findsOneWidget);
      expect(find.text('Not forwarded · Iryna Shevchuk'), findsOneWidget);
      // Nothing to press in the row itself: the menu is where it is retried.
      expect(find.byType(TextButton), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('a message with no such forward carries no mark', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.byKey(voicemailForwardFailedBadgeKey), findsNothing);
      expect(find.textContaining('Not forwarded'), findsNothing);
    });

    testWidgets('is forwarded again from the menu, to the colleague it was for', (tester) async {
      Contact? retriedTo;
      Voicemail? forwarded;
      await tester.pumpWidget(
        wrap(
          forwardSupported: true,
          forward: failed(),
          onForwardRetried: (_, recipient) => retriedTo = recipient,
          onForwarded: (it) => forwarded = it,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      // Choosing somebody else stays on offer beside it.
      expect(find.text('Forward'), findsOneWidget);
      await tester.tap(find.text('Forward again'));
      await tester.pumpAndSettle();

      expect(retriedTo, colleague);
      expect(forwarded, isNull);
    });

    testWidgets('the menu offers no second try where nothing was refused', (tester) async {
      await tester.pumpWidget(wrap(forwardSupported: true));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Forward'), findsOneWidget);
      expect(find.text('Forward again'), findsNothing);
    });
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

  group('a message that was forwarded on', () {
    testWidgets('says who passed it along, without displacing the caller', (tester) async {
      await tester.pumpWidget(
        wrap(
          voicemail: message(forwardedBy: 'user-7', from: known),
          forwardedByName: 'Iryna Shevchuk',
        ),
      );

      // Both names are on the tile and they answer different questions: who
      // called, and how the recording reached this mailbox.
      expect(find.text('User 555002'), findsOneWidget);
      expect(find.text('Forwarded by Iryna Shevchuk'), findsOneWidget);
    });

    testWidgets('an ordinary message says nothing of the kind', (tester) async {
      await tester.pumpWidget(wrap());

      expect(find.textContaining('Forwarded by'), findsNothing);
    });
  });

  group('a message being picked, for a screen reader', () {
    // The tile draws a picked message with a tinted background, which says
    // nothing to somebody who does not see it. A picked row used to reach the
    // accessibility tree exactly like any other.
    Finder row() => find.byType(VoicemailTile);

    testWidgets('a picked message is read as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(selected: true));

      expect(tester.getSemantics(row()), isSemantics(hasSelectedState: true, isSelected: true));
      handle.dispose();
    });

    testWidgets('the others are read as not selected while messages are being picked', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(selected: false));

      expect(tester.getSemantics(row()), isSemantics(hasSelectedState: true, isSelected: false));
      handle.dispose();
    });

    testWidgets('an ordinary list says nothing about selection', (tester) async {
      // Otherwise every message of every mailbox would be read out as "not
      // selected".
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(selected: false, picking: false));

      expect(tester.getSemantics(row()), isSemantics(hasSelectedState: false));
      handle.dispose();
    });

    testWidgets('the row that says it is not selected is the one a double tap picks', (tester) async {
      // The state and the action have to sit on one node: a reader that hears
      // "not selected" activates that node, not a pointer position.
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(wrap(selected: false, onTap: () => taps++));

      await tapViaSemantics(tester, row());

      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a double tap and hold on an ordinary row starts picking', (tester) async {
      final handle = tester.ensureSemantics();
      var holds = 0;
      await tester.pumpWidget(wrap(picking: false, onLongPress: () => holds++));

      final node = tester.getSemantics(find.text('User 555002'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isTrue, reason: 'no long press on $node');
      node.owner!.performAction(node.id, SemanticsAction.longPress);
      await tester.pump();

      expect(holds, 1);
      handle.dispose();
    });

    testWidgets('a message on its way to somebody neither reads as pickable nor takes the press', (tester) async {
      // The mailbox refuses to pick it. A row that reads "not selected" and
      // answers a double tap with silence is what this change is here to end.
      final handle = tester.ensureSemantics();
      var taps = 0;
      var holds = 0;
      await tester.pumpWidget(
        wrap(forward: const VoicemailForwardSending(), onTap: () => taps++, onLongPress: () => holds++),
      );

      final data = tester.getSemantics(row()).getSemanticsData();
      expect(tester.getSemantics(row()), isSemantics(hasSelectedState: false));
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      expect(data.hasAction(SemanticsAction.longPress), isFalse);
      expect((taps, holds), (0, 0));
      handle.dispose();
    });
  });

  group('how long the message is, for a screen reader', () {
    testWidgets('the row of a message says its length before it was ever played', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(picking: false));

      expect(tester.getSemantics(find.text('User 555002')).label, contains('4 seconds'));
      handle.dispose();
    });
  });

  group('opening the caller', () {
    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('a caller the address book knows can be opened', (tester) async {
      Voicemail? opened;
      await tester.pumpWidget(wrap(onOpenContact: (it) => opened = it));

      await openMenu(tester);
      await tester.tap(find.text('Open contact'));
      await tester.pumpAndSettle();

      expect(opened?.id, 'vm-1');
    });

    testWidgets('a stranger cannot', (tester) async {
      // No contact was found for the number, and offering the action anyway
      // would lead to an empty screen.
      await tester.pumpWidget(wrap(voicemail: message()));

      await openMenu(tester);

      expect(find.text('555002'), findsOneWidget);
      expect(find.text('Open contact'), findsNothing);
    });

    testWidgets('a contact without a name can, although it is shown by its number', (tester) async {
      // Shown exactly like a stranger - which is what used to hide the action:
      // the tile read "is a contact" off the name differing from the number.
      Voicemail? opened;
      await tester.pumpWidget(
        wrap(
          voicemail: message(from: card(name: null)),
          onOpenContact: (it) => opened = it,
        ),
      );

      expect(find.text('555002'), findsOneWidget);
      await openMenu(tester);
      await tester.tap(find.text('Open contact'));
      await tester.pumpAndSettle();

      expect(opened?.senderContact?.id, 7);
    });
  });
}
