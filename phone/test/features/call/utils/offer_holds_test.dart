import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/utils/utils.dart';

void main() {
  late OfferHolds holds;

  setUp(() => holds = OfferHolds());

  test('a call not held by its offer sends its hold and resume', () {
    expect(holds.onSetHeld('a', onHold: true, heldByOffer: false), OfferHoldStep.send);
    expect(holds.onSetHeld('a', onHold: false, heldByOffer: false), OfferHoldStep.send);
    expect(holds.takeUnhold('a'), isFalse);
  });

  test('a hold of a call held by its offer sends nothing', () {
    expect(holds.onSetHeld('a', onHold: true, heldByOffer: true), OfferHoldStep.nothing);
    expect(holds.takeUnhold('a'), isFalse);
  });

  test('a resume of a call held by its offer sends the unhold on the next answer, once', () {
    expect(holds.onSetHeld('a', onHold: false, heldByOffer: true), OfferHoldStep.resumeFirst);

    expect(holds.takeUnhold('b'), isFalse);
    expect(holds.takeUnhold('a'), isTrue);
    expect(holds.takeUnhold('a'), isFalse);
  });

  test('a removed call drops its waiting unhold', () {
    holds.onSetHeld('a', onHold: false, heldByOffer: true);
    holds.callRemoved('a');

    expect(holds.takeUnhold('a'), isFalse);
  });
}
