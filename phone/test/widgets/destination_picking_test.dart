import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
  final submitted = <DestinationCandidate>[];

  @override
  String get announcement => 'Pick somebody';

  @override
  bool offeredBy(MainFlavor flavor) => true;

  @override
  bool accepts(DestinationCandidate candidate) => true;

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
  void submit(DestinationCandidate candidate) {}

  @override
  bool operator ==(Object other) => other is _EqualPurpose;

  @override
  int get hashCode => 0;
}
