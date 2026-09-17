import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/models/models.dart';

class _Purpose implements DestinationPickPurpose {
  const _Purpose({this.precedence = DestinationPickPrecedence.ordinary, this.name = 'ordinary'});

  final String name;

  @override
  final DestinationPickPrecedence precedence;

  @override
  String get announcement => name;

  @override
  bool get cancellable => true;

  @override
  bool get closedByChoice => true;

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => true;

  @override
  IconData get pickIcon => Icons.person;

  @override
  String pickLabel(DestinationCandidate candidate) => name;

  @override
  void submit(DestinationCandidate candidate) {}
}

class _OtherPurpose extends _Purpose {
  const _OtherPurpose() : super(name: 'other');
}

// Where a feature leaves its request for somebody to be chosen, so the screen
// above the sections can read one state instead of asking each feature whether
// it wants one.
void main() {
  late DestinationPickingCubit cubit;

  setUp(() => cubit = DestinationPickingCubit());
  tearDown(() async => cubit.close());

  test('nobody is choosing until somebody asks', () {
    expect(cubit.state.purpose, isNull);
  });

  test('a request takes the floor', () {
    expect(cubit.ask(const _Purpose()), isTrue);

    expect(cubit.state.purpose, isA<_Purpose>());
  });

  group('two features asking at once', () {
    test('a live one takes the floor from one that can wait', () {
      cubit.ask(const _Purpose());

      expect(cubit.ask(const _Purpose(precedence: DestinationPickPrecedence.live, name: 'live')), isTrue);
      expect(cubit.state.purpose?.announcement, 'live');
    });

    test('one that can wait is refused while a live one holds it', () {
      // Somebody is on the line: they cannot wait while a message finds a
      // recipient. The refusal is the answer, so the feature leaves the person
      // where they are instead of sending them to the lists.
      cubit.ask(const _Purpose(precedence: DestinationPickPrecedence.live, name: 'live'));

      expect(cubit.ask(const _Purpose()), isFalse);
      expect(cubit.state.purpose?.announcement, 'live');
    });

    test('an equal one does not push the first off', () {
      cubit.ask(const _Purpose(name: 'first'));

      expect(cubit.ask(const _Purpose(name: 'second')), isFalse);
      expect(cubit.state.purpose?.announcement, 'first');
    });
  });

  group('taking a request back', () {
    test('a feature withdraws its own', () {
      cubit.ask(const _Purpose());

      cubit.withdraw<_Purpose>();

      expect(cubit.state.purpose, isNull);
    });

    test('and cannot withdraw somebody else s', () {
      // A feature knows what it asked for, not what is in force by now: an
      // edge arriving late must not take the floor from whoever holds it.
      cubit.ask(const _OtherPurpose());

      cubit.withdraw<_LoneStranger>();

      expect(cubit.state.purpose, isA<_OtherPurpose>());
    });
  });

  test('a choice closes the request', () {
    const purpose = _Purpose();
    cubit.ask(purpose);

    cubit.finish(purpose);

    expect(cubit.state.purpose, isNull);
  });

  test('the person giving up closes it too', () {
    cubit.ask(const _Purpose());

    cubit.cancel();

    expect(cubit.state.purpose, isNull);
  });

  group('what came of it', () {
    test('outlives the request that produced it', () {
      // The sentence arrives when the choosing is over and the person is
      // somewhere else entirely; a state that cleared one with the other would
      // lose it on the way.
      const purpose = _Purpose();
      cubit.ask(purpose);
      cubit.finish(purpose);

      cubit.announce(const DestinationPickReport(message: 'Forwarded to Iryna'));

      expect(cubit.state.report?.message, 'Forwarded to Iryna');
      expect(cubit.state.purpose, isNull);
    });

    test('is said once and then forgotten', () {
      cubit.announce(const DestinationPickReport(message: 'Forwarded to Iryna'));

      cubit.reportShown();

      expect(cubit.state.report, isNull);
    });

    test('does not disturb a request that is still open', () {
      cubit.ask(const _Purpose());

      cubit.announce(const DestinationPickReport(message: 'Forwarded to Iryna'));

      expect(cubit.state.purpose, isA<_Purpose>());
    });
  });
}

class _LoneStranger implements DestinationPickPurpose {
  const _LoneStranger();

  @override
  String get announcement => 'nobody asks this';

  @override
  bool get closedByChoice => true;

  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  @override
  bool get cancellable => false;

  @override
  bool offeredBy(MainFlavor flavor) => false;

  @override
  bool accepts(DestinationCandidate candidate) => false;

  @override
  IconData get pickIcon => Icons.person;

  @override
  String pickLabel(DestinationCandidate candidate) => '';

  @override
  void submit(DestinationCandidate candidate) {}
}
