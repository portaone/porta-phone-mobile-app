import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/destination_picking.dart';

// The one question every list now asks, in place of each knowing which feature
// wants somebody chosen and how to tell it.
void main() {
  testWidgets('a list outside any choice is told there is none', (tester) async {
    DestinationPickPurpose? seen;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          seen = DestinationPicking.of(context);
          return const SizedBox.shrink();
        },
      ),
    );

    expect(seen, isNull);
  });

  testWidgets('a list inside one is told what it is', (tester) async {
    final purpose = _Purpose();
    DestinationPickPurpose? seen;

    await tester.pumpWidget(
      DestinationPicking(
        purpose: purpose,
        child: Builder(
          builder: (context) {
            seen = DestinationPicking.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(seen, same(purpose));
  });

  group('the submission boundary', () {
    // The check lives here rather than at each place a person can be picked
    // from, because a screen that forgets it is exactly the failure this
    // mechanism exists to remove. Two screens did forget it.
    late DestinationPickingCubit picking;
    late BuildContext pickingContext;

    Future<void> pumpPicking(WidgetTester tester) async {
      picking = DestinationPickingCubit();
      await tester.pumpWidget(
        BlocProvider<DestinationPickingCubit>.value(
          value: picking,
          child: Builder(
            builder: (context) {
              pickingContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    testWidgets('a candidate the purpose takes is submitted', (tester) async {
      final purpose = _Purpose();
      await pumpPicking(tester);
      picking.ask(purpose);

      expect(submitDestination(pickingContext, purpose, const DestinationCandidate(number: '1001')), isTrue);

      expect(purpose.submitted.single.number, '1001');
    });

    testWidgets('and the request it answered is closed with it', (tester) async {
      // Closed here rather than by the feature: by now it is waiting on a
      // backend somewhere, and a request left standing keeps every list in
      // picking mode with nothing left to pick for.
      final purpose = _Purpose();
      await pumpPicking(tester);
      picking.ask(purpose);

      submitDestination(pickingContext, purpose, const DestinationCandidate(number: '1001'));

      expect(picking.state.purpose, isNull);
    });

    testWidgets('a request whose feature owns the mode outlives the choice', (tester) async {
      // A transfer is not over because a number was handed to it: the switch
      // may refuse the REFER, and the call is then still looking for a target.
      // Closing here would send the lists back to normal with nobody able to
      // choose again.
      final purpose = _Purpose(closedByChoice: false);
      await pumpPicking(tester);
      picking.ask(purpose);

      submitDestination(pickingContext, purpose, const DestinationCandidate(number: '1001'));

      expect(purpose.submitted.single.number, '1001');
      expect(picking.state.purpose, same(purpose));
    });

    testWidgets('a row of a request that has been pushed aside answers nothing', (tester) async {
      // A live request can take the floor between a row being built and the
      // tap landing on it. The stale callback must neither act for whoever was
      // pushed aside nor close the request that replaced them.
      final pushedAside = _Purpose();
      final holdsTheFloor = _Purpose(precedence: DestinationPickPrecedence.live);
      await pumpPicking(tester);
      picking.ask(pushedAside);
      picking.ask(holdsTheFloor);

      final took = submitDestination(pickingContext, pushedAside, const DestinationCandidate(number: '1001'));

      expect(took, isFalse);
      expect(pushedAside.submitted, isEmpty);
      expect(picking.state.purpose, same(holdsTheFloor));
    });

    testWidgets('a candidate it refuses is not, and says so', (tester) async {
      final purpose = _Purpose(takes: false);
      await pumpPicking(tester);
      picking.ask(purpose);

      expect(submitDestination(pickingContext, purpose, const DestinationCandidate(number: '1001')), isFalse);

      expect(purpose.submitted, isEmpty);
      // Nothing happened, so the person is still choosing.
      expect(picking.state.purpose, same(purpose));
    });
  });

  test('an unchanged purpose does not notify the lists', () {
    // The scope sits above every section and is rebuilt with the shell. A
    // purpose compared by identity would notify every row on the screen on
    // every frame of a call.
    const scope = DestinationPicking(purpose: _EqualPurpose(), child: SizedBox.shrink());

    expect(
      scope.updateShouldNotify(const DestinationPicking(purpose: _EqualPurpose(), child: SizedBox.shrink())),
      isFalse,
    );
  });

  test('a choice arriving or leaving does notify them', () {
    const picking = DestinationPicking(purpose: _EqualPurpose(), child: SizedBox.shrink());
    const idle = DestinationPicking(purpose: null, child: SizedBox.shrink());

    expect(picking.updateShouldNotify(idle), isTrue);
    expect(idle.updateShouldNotify(picking), isTrue);
  });
}

class _Purpose implements DestinationPickPurpose {
  _Purpose({this.takes = true, this.closedByChoice = true, this.precedence = DestinationPickPrecedence.ordinary});

  final bool takes;

  @override
  final bool closedByChoice;

  @override
  final DestinationPickPrecedence precedence;
  final submitted = <DestinationCandidate>[];

  @override
  String get announcement => 'Pick somebody';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => takes;

  @override
  bool get cancellable => false;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Choose ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) => submitted.add(candidate);
}

/// Two of these are equal, the way the real ones are.
class _EqualPurpose implements DestinationPickPurpose {
  const _EqualPurpose();

  @override
  String get announcement => 'Pick somebody';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => true;

  @override
  bool get closedByChoice => true;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get cancellable => false;

  @override
  IconData get pickIcon => Icons.phone_forwarded;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Transfer current call to ${candidate.number}';

  @override
  void submit(DestinationCandidate candidate) {}

  @override
  bool operator ==(Object other) => other is _EqualPurpose;

  @override
  int get hashCode => 0;
}
