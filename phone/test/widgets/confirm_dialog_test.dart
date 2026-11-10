import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../helpers/helpers.dart';
import '../helpers/screen_presets.dart';

void main() {
  /// Opens the dialog and hands back what the caller is left holding. The
  /// answer is captured by the button that opened it, so it can only be read
  /// after the dialog is gone - which is the whole point of asserting it.
  Future<Future<bool?> Function()> open(
    WidgetTester tester, {
    String? content,
    bool dangerous = false,
    ThemeData? theme,
  }) async {
    bool? answer;
    var answered = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                answer = dangerous
                    ? await ConfirmDialog.showDangerous(context, title: 'Leave this group?', content: content)
                    : await ConfirmDialog.show(context, title: 'Leave this group?', content: content);
                answered = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    return () async {
      await tester.pumpAndSettle();
      expect(answered, isTrue, reason: 'the dialog never came back to the caller');
      return answer;
    };
  }

  testWidgets('a question that stands on its own is shown without a second line', (tester) async {
    // The dialog the messaging screens used to carry had a question and nothing
    // else; asking them to repeat it in smaller type below would read worse.
    await open(tester);

    expect(find.text('Leave this group?'), findsOneWidget);
    expect(tester.widget<AlertDialog>(find.byType(AlertDialog)).content, isNull);
  });

  testWidgets('a question that needs saying more keeps its second line', (tester) async {
    await open(tester, content: 'It will be removed from the account.');

    expect(find.text('Leave this group?'), findsOneWidget);
    expect(find.text('It will be removed from the account.'), findsOneWidget);
  });

  testWidgets('yes comes back as yes and no as no', (tester) async {
    // Both buttons pop, so "the dialog closed" says nothing about which of them
    // was pressed - the answer is what the caller acts on.
    for (final (button, expected) in [(confirmDialogYesButtonKey, true), (confirmDialogNoButtonKey, false)]) {
      final answer = await open(tester, dangerous: true);

      await tester.tap(find.byKey(button));

      expect(await answer(), expected);
      expect(find.byType(AlertDialog), findsNothing);
    }
  });

  testWidgets('dismissing it answers nothing at all', (tester) async {
    // Tapping outside is neither yes nor no, and every caller checks for that.
    final answer = await open(tester);

    await tester.tapAt(const Offset(10, 10));

    expect(await answer(), isNull);
  });

  testWidgets('yes and no can be found and pressed by their identifiers', (tester) async {
    final handle = tester.ensureSemantics();

    for (final (id, label, expected) in [
      (confirmDialogYesButtonId, 'Yes', true),
      (confirmDialogNoButtonId, 'No', false),
    ]) {
      final answer = await open(tester, dangerous: true);

      final button = find.bySemanticsIdentifier(id);
      expect(tester.getSemantics(button).getSemanticsData().label, label);

      await tapViaSemantics(tester, button);

      expect(await answer(), expected);
    }

    handle.dispose();
  });

  for (final preset in watchPresets) {
    testWidgets('on $preset the question takes the whole face and still answers yes and no', (tester) async {
      preset.apply(tester);
      for (final (button, expected) in [(confirmDialogYesButtonKey, true), (confirmDialogNoButtonKey, false)]) {
        final answer = await open(tester, dangerous: true, content: 'It will be removed from the account.');

        expect(find.byType(AlertDialog), findsNothing);
        expect(find.byType(WatchConfirm), findsOneWidget);
        expect(find.text('Leave this group?'), findsOneWidget);
        expect(find.text('It will be removed from the account.'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(button));

        expect(await answer(), expected);
        expect(find.byType(WatchConfirm), findsNothing);
      }
    });

    testWidgets('on $preset yes and no can be found and pressed by their identifiers', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();

      for (final (id, label, expected) in [
        (confirmDialogYesButtonId, 'Yes', true),
        (confirmDialogNoButtonId, 'No', false),
      ]) {
        final answer = await open(tester, dangerous: true);

        final button = find.bySemanticsIdentifier(id);
        expect(tester.getSemantics(button).getSemanticsData().label, label);

        await tapViaSemantics(tester, button);

        expect(await answer(), expected);
      }

      handle.dispose();
    });

    testWidgets('on $preset going back answers nothing at all', (tester) async {
      // The face leaves nothing outside the dialog to tap: a watch dismisses it
      // with the back swipe, and that is neither yes nor no.
      preset.apply(tester);
      final answer = await open(tester);

      await tester.binding.handlePopRoute();

      expect(await answer(), isNull);
      expect(find.byType(WatchConfirm), findsNothing);
    });

    testWidgets('on $preset a destructive yes keeps the colour the theme gives such actions', (tester) async {
      preset.apply(tester);
      const brand = Color(0xFFE65100);
      await open(
        tester,
        dangerous: true,
        theme: ThemeData(
          extensions: [
            ConfirmDialogStyles(
              primary: ConfirmDialogStyle(activeButtonStyle2: TextButton.styleFrom(foregroundColor: brand)),
            ),
          ],
        ),
      );

      final yes = tester.widget<ButtonStyleButton>(
        find.descendant(of: find.byKey(confirmDialogYesButtonKey), matching: find.bySubtype<ButtonStyleButton>()).first,
      );
      expect(yes.style?.backgroundColor?.resolve(const {}), brand);
    });

    testWidgets('on $preset the face takes the dialog theme surface and text colours', (tester) async {
      preset.apply(tester);
      await open(
        tester,
        content: 'It will be removed from the account.',
        theme: ThemeData(
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF202020),
            titleTextStyle: TextStyle(color: Color(0xFFFFFFFF)),
            contentTextStyle: TextStyle(color: Color(0xFFCCCCCC)),
          ),
        ),
      );

      expect(tester.widget<Dialog>(find.byType(Dialog)).backgroundColor, const Color(0xFF202020));
      expect(tester.widget<Text>(find.text('Leave this group?')).style?.color, const Color(0xFFFFFFFF));
      expect(
        tester.widget<Text>(find.text('It will be removed from the account.')).style?.color,
        const Color(0xFFCCCCCC),
      );
    });

    testWidgets('on $preset a plain yes keeps the colour the theme gives it', (tester) async {
      preset.apply(tester);
      const brand = Color(0xFF1565C0);
      await open(
        tester,
        theme: ThemeData(
          extensions: [
            ConfirmDialogStyles(
              primary: ConfirmDialogStyle(defaultButtonStyle: TextButton.styleFrom(foregroundColor: brand)),
            ),
          ],
        ),
      );

      final yes = tester.widget<ButtonStyleButton>(
        find.descendant(of: find.byKey(confirmDialogYesButtonKey), matching: find.bySubtype<ButtonStyleButton>()).first,
      );
      expect(yes.style?.backgroundColor?.resolve(const {}), brand);
    });

    testWidgets('on $preset on Apple platforms the question, not "Alert", names the face', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      await open(tester, theme: ThemeData(platform: TargetPlatform.iOS));

      final route = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.namesRoute == true && widget.properties.scopesRoute == true,
      );
      expect(tester.widget<Semantics>(route).properties.label, isNull);
      handle.dispose();
    });

    testWidgets('on $preset the face is announced as an alert, as the phone card is', (tester) async {
      preset.apply(tester);
      final handle = tester.ensureSemantics();
      await open(tester);

      final route = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.namesRoute == true && widget.properties.scopesRoute == true,
      );
      expect(route, findsOneWidget);
      expect(tester.widget<Semantics>(route).properties.label, const DefaultMaterialLocalizations().alertDialogLabel);
      expect(tester.widget<Dialog>(find.byType(Dialog)).semanticsRole, SemanticsRole.alertDialog);
      handle.dispose();
    });
  }
}
