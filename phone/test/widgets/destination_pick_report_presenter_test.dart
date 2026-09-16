import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class _MockPicking extends MockCubit<DestinationPickingState> implements DestinationPickingCubit {}

// What a feature has to say once the choice it asked for is over. It is said
// above the sections because by then the person is wherever the lists left
// them, and the screen that asked is long gone.
void main() {
  late _MockPicking picking;
  late StreamController<DestinationPickingState> states;

  setUp(() {
    picking = _MockPicking();
    states = StreamController<DestinationPickingState>.broadcast(sync: true);
    when(() => picking.reportShown()).thenReturn(null);
    whenListen(picking, states.stream, initialState: const DestinationPickingState());
  });

  tearDown(() async => states.close());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<DestinationPickingCubit>.value(
          value: picking,
          child: const DestinationPickReportPresenter(child: Scaffold(body: SizedBox.expand())),
        ),
      ),
    );
  }

  testWidgets('a confirmation is shown as the feature wrote it', (tester) async {
    await pump(tester);

    states.add(const DestinationPickingState(report: DestinationPickReport(message: 'Forwarded to Iryna Shevchuk')));
    await tester.pump();

    expect(find.text('Forwarded to Iryna Shevchuk'), findsOneWidget);
  });

  testWidgets('a failure that can be tried again offers the feature s own retry', (tester) async {
    var retried = 0;
    await pump(tester);

    states.add(
      DestinationPickingState(
        report: DestinationPickReport(
          message: 'Forwarding is not available',
          isFailure: true,
          retryLabel: 'Try again',
          onRetry: () => retried++,
        ),
      ),
    );
    // Let the bar finish sliding in: a tap on it mid-animation misses.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));

    await tester.tap(find.text('Try again'));

    expect(retried, 1);
  });

  testWidgets('a failure nothing can be done about offers nothing', (tester) async {
    await pump(tester);

    states.add(
      const DestinationPickingState(
        report: DestinationPickReport(message: 'Message too large to forward', isFailure: true),
      ),
    );
    await tester.pump();

    expect(find.text('Message too large to forward'), findsOneWidget);
    expect(find.byType(SnackBarAction), findsNothing);
  });

  testWidgets('a report already waiting when it arrives is still said', (tester) async {
    // A listener hears what happens next. An answer that landed while the
    // sections were being rebuilt would otherwise sit in the state, said to
    // nobody, with its retry out of reach.
    whenListen(
      picking,
      states.stream,
      initialState: const DestinationPickingState(report: DestinationPickReport(message: 'Forwarded to Iryna')),
    );

    await pump(tester);
    await tester.pump();

    expect(find.text('Forwarded to Iryna'), findsOneWidget);
    verify(() => picking.reportShown()).called(1);
  });

  testWidgets('and is said once, however the screen rebuilds', (tester) async {
    await pump(tester);

    states.add(const DestinationPickingState(report: DestinationPickReport(message: 'Forwarded to Iryna Shevchuk')));
    await tester.pump();

    verify(() => picking.reportShown()).called(1);
  });
}
