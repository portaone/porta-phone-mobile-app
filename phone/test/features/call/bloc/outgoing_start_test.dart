import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Placing an outgoing call, up to handing it to the platform: which line it
/// takes, what happens to the calls already up, and when it is not placed at
/// all. The signalling side that follows the platform's perform callback is
/// not part of this.

/// The calls the test placed, apart from the one it seeded ('b').
List<ActiveCall> _placed(CallBlocHarness h) => h.bloc.state.activeCalls.where((call) => call.callId != 'b').toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  tearDown(() => h.close());

  test('a call is placed on an idle main line and handed to the platform as asked', () async {
    h = CallBlocHarness(lines: 2);

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.callkeep.starts.isNotEmpty);

    final call = _placed(h).single;
    // The rotation starts from the first line; the harness resets it, so this
    // does not depend on what an earlier test left behind.
    expect(call.line, 0);
    expect(call.handle, const CallkeepHandle.number('200'));
    expect(call.processingStatus, CallProcessingStatus.outgoingCreated);
    expect(h.callkeep.starts, [
      (callId: call.callId, handle: const CallkeepHandle.number('200'), hasVideo: false, proximityEnabled: true),
    ]);
    expect(h.bloc.state.minimized, isFalse);
  });

  test('a video call is handed to the platform as one, without the proximity sensor', () async {
    h = CallBlocHarness(lines: 2);

    h.bloc.add(const CallControlEvent.started(number: '200', video: true));
    await h.settle(() => h.callkeep.starts.isNotEmpty);

    expect(h.callkeep.starts.single.hasVideo, isTrue);
    expect(h.callkeep.starts.single.proximityEnabled, isFalse);
  });

  test('a live call is put on hold before the new one is handed to the platform', () async {
    // Two calls off hold at once are not allowed: the platform would end one.
    h = CallBlocHarness(lines: 2);
    h.seedEstablishedCall('b', line: 0);
    final holding = Completer<void>();
    h.callkeep.holdGate = holding;

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.callkeep.held.isNotEmpty);

    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
    expect(h.callkeep.starts, isEmpty);

    holding.complete();
    await h.settle(() => h.callkeep.starts.isNotEmpty);

    expect(_placed(h).single.line, 1);
  });

  test('a call already on hold is not held again', () async {
    h = CallBlocHarness(lines: 2);
    h.seedEstablishedCall('b', line: 0, held: true);

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.callkeep.starts.isNotEmpty);

    expect(h.callkeep.starts, hasLength(1));
    expect(h.callkeep.held, isEmpty);
  });

  test('a second tap on the same number while the first is still being placed places nothing', () async {
    h = CallBlocHarness(lines: 2);

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.callkeep.starts.isNotEmpty);
    // The duplicate brings the call screen back, which is how its handling is
    // seen to have run.
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    h.bloc.emit(h.bloc.state.copyWith(minimized: true));
    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.bloc.state.minimized == false);

    expect(h.bloc.state.minimized, isFalse);
    expect(h.callkeep.starts, hasLength(1));
    expect(_placed(h), hasLength(1));
  });

  test('a second tap on the same number brings the focus back to the call being placed', () async {
    // The hangup acts on the focused call: left on the held one, it would end
    // that call while the one placed again goes on ringing.
    h = CallBlocHarness(lines: 2);
    h.seedEstablishedCall('b', line: 0);

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.callkeep.starts.isNotEmpty);
    final placed = _placed(h).single.callId;
    expect(h.bloc.state.focusedCall?.callId, placed);

    h.bloc.add(const CallControlEvent.callSelected('b'));
    await h.settle(() => h.bloc.state.selectedCallId == 'b');
    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.bloc.state.selectedCallId == placed);

    expect(h.bloc.state.focusedCall?.callId, placed);
    expect(h.callkeep.starts, hasLength(1));
  });

  test('with every main line taken nothing is placed or held, and the person is told', () async {
    h = CallBlocHarness(lines: 1);
    h.seedEstablishedCall('b', line: 0);

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.notifications.isNotEmpty);

    expect(h.notifications.whereType<GeneralUnableToCallNotification>(), hasLength(1));
    expect(h.callkeep.starts, isEmpty);
    expect(h.callkeep.held, isEmpty);
    expect(_placed(h), isEmpty);
  });

  test('a call the platform refuses to place is taken off the screen again', () async {
    h = CallBlocHarness(lines: 2);
    h.seedEstablishedCall('b', line: 0);
    h.callkeep.startError = CallkeepCallRequestError.internal;

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await h.settle(() => h.callkeep.starts.isNotEmpty && _placed(h).isEmpty);

    expect(h.callkeep.starts, hasLength(1));
    expect(h.bloc.state.activeCalls.map((call) => call.callId), ['b']);
    // A gap, pinned so changing it is a decision: the call put on hold for the
    // refused one stays on hold.
    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
  });
}
