import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../helpers/semantics.dart';

void main() {
  late DestinationPickingCubit picking;
  late _Purpose purpose;
  String? selection;
  var closed = false;

  setUp(() {
    picking = DestinationPickingCubit();
    purpose = _Purpose();
    picking.ask(purpose);
    selection = null;
    closed = false;
  });

  tearDown(() => picking.close());

  Future<void> open(WidgetTester tester, List<NumberChoice> choices) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<DestinationPickingCubit>.value(
          value: picking,
          child: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  selection = await DestinationNumberPicker.show(context, purpose: purpose, choices: choices);
                  closed = true;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('numbers are named, reachable buttons with stable identifiers', (tester) async {
    await open(tester, const [
      NumberChoice(number: '1001', label: 'Extension'),
      NumberChoice(number: '+12025550123', label: 'Mobile'),
    ]);

    expect(find.bySemanticsIdentifier(destinationNumberPickerId), findsOneWidget);
    expect(find.text('Choose a number to call'), findsOneWidget);
    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(destinationNumberOptionId(0)),
      label: '1001\nExtension',
      identifier: destinationNumberOptionId(0),
      isButton: true,
    );
    expectTapTargetSemantics(
      tester,
      find.bySemanticsIdentifier(destinationNumberOptionId(1)),
      label: '+12025550123\nMobile',
      identifier: destinationNumberOptionId(1),
      isButton: true,
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    await tapViaSemantics(tester, find.bySemanticsIdentifier(destinationNumberOptionId(0)));
    await tester.pumpAndSettle();

    expect(selection, '1001');
  });

  testWidgets('a tall option list scrolls within the available sheet', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await open(tester, [
      for (var index = 0; index < 20; index++)
        NumberChoice(number: '10${index.toString().padLeft(2, '0')}', label: 'Line'),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('1000'), findsOneWidget);
    expect(find.text('1019'), findsNothing);

    await tester.scrollUntilVisible(find.text('1019'), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('1019'));
    await tester.pumpAndSettle();

    expect(selection, '1019');
  });

  testWidgets('the sheet goes with the request it was opened for', (tester) async {
    // The call can end, or another request take over, while the person is
    // still choosing; a number tapped then would answer nobody.
    await open(tester, const [NumberChoice(number: '1001'), NumberChoice(number: '1002')]);

    picking.finish(purpose);
    await tester.pumpAndSettle();

    expect(find.bySemanticsIdentifier(destinationNumberPickerId), findsNothing);
    expect(find.text('Open'), findsOneWidget);
    expect(closed, isTrue);
    expect(selection, isNull);
  });
}

class _Purpose implements DestinationPickPurpose {
  @override
  String get announcement => 'Pick somebody';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => true;

  @override
  bool get closedByChoice => true;

  @override
  bool get cancellable => false;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  IconData get pickIcon => Icons.call;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Choose ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) {}
}
