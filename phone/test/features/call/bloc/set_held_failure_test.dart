import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'package:signaling/signaling.dart';
import 'package:signaling_service/signaling_service.dart';

/// Which failures of a hold or unhold transaction leave the call alive.
///
/// The call carries audio whether or not the hold lands, so ending it over a
/// refused control would turn a control that did not work into a call that
/// dropped. The one refusal that must still end things is the server saying the
/// call is gone, because then there is nothing left to keep.
void main() {
  group('CallBloc.isSurvivableSetHeldFailure', () {
    test('a disconnected socket leaves the call alive', () {
      expect(CallBloc.isSurvivableSetHeldFailure(NotConnectedException()), isTrue);
    });

    test('a transaction that timed out leaves the call alive', () {
      expect(
        CallBloc.isSurvivableSetHeldFailure(const WebtritSignalingTransactionTimeoutException(1, 'transaction-1')),
        isTrue,
      );
    });

    test('a server refusal leaves the call alive', () {
      // The shape a conference produces: the server declines to hold one leg of
      // a room, which is an answer rather than a fault.
      expect(
        CallBloc.isSurvivableSetHeldFailure(const WebtritSignalingErrorException(1, 403, 'line_in_conference')),
        isTrue,
      );
    });

    test('a refusal with any other code still leaves the call alive', () {
      expect(CallBloc.isSurvivableSetHeldFailure(const WebtritSignalingErrorException(1, 500, 'internal')), isTrue);
    });

    test('the call being gone does not leave it alive', () {
      // 410 does not say the hold failed, it says there is no call to hold.
      expect(
        CallBloc.isSurvivableSetHeldFailure(const WebtritSignalingErrorException(1, 410, 'call not found')),
        isFalse,
      );
    });

    test('a failure in this client still ends the call', () {
      expect(CallBloc.isSurvivableSetHeldFailure(StateError('bad state')), isFalse);
    });

    test('an unrelated signaling exception still ends the call', () {
      // Only the three named outcomes survive; every other signaling failure is
      // treated as a fault in this client rather than a refused request.
      expect(CallBloc.isSurvivableSetHeldFailure(const WebtritSignalingDisconnectedException(1)), isFalse);
    });
  });
}
