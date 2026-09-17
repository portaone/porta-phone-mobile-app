import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// A leg of the conference room is never held or resumed on its own: the
/// server would refuse it as line_in_conference, and the plugin already
/// answers such a request with callIsGrouped. The bloc is the second line.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a hold for a conference leg sends nothing and changes nothing', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.seedEstablishedCall('leg', line: 0);
    h.seedEstablishedCall('outside', line: 1);
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(
      h.bloc.state.copyWith(
        conference: const ConferenceState(room: 1, phase: ConferencePhase.active, legs: {'leg': 0}),
      ),
    );

    await h.bloc.performSetHeld('leg', true);
    await pumpEventQueue();

    expect(h.signaling.requests, isEmpty);
    expect(h.bloc.state.retrieveActiveCall('leg')?.held, isFalse);

    await h.bloc.performSetHeld('outside', true);
    await pumpEventQueue();

    expect(h.signaling.requests.single, isA<HoldRequest>(), reason: 'a call outside the room is held as before');
    expect(h.bloc.state.retrieveActiveCall('outside')?.held, isTrue);
  });
}
