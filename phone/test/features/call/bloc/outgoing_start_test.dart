import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Placing an outgoing call, up to handing it to the platform: which line it
/// takes, what happens to the calls already up, and when it is not placed at
/// all. The signalling side that follows the platform's perform callback is
/// not part of this.
CallBlocHarness _harness({int lines = 2}) {
  final h = CallBlocHarness();
  // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
  h.bloc.emit(h.bloc.state.copyWith(linesCount: lines));
  return h;
}

/// Pumps until [done], or gives up after enough turns for anything the bloc
/// queues in response to one event.
Future<void> _settle(bool Function() done) async {
  for (var turn = 0; turn < 50 && !done(); turn++) {
    await pumpEventQueue();
  }
}

/// The calls the test placed, apart from the ones it seeded ('b').
List<ActiveCall> _outgoing(CallBlocHarness h) => h.bloc.state.activeCalls.where((call) => call.callId != 'b').toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CallBlocHarness h;
  tearDown(() => h.close());

  test('a call is placed on the first idle main line and the call screen comes up', () async {
    h = _harness();

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await _settle(() => h.callkeep.startCalls.isNotEmpty);

    final call = _outgoing(h).single;
    expect(h.callkeep.startCalls, [call.callId]);
    expect(call.line, 0);
    expect(call.handle, const CallkeepHandle.number('200'));
    expect(call.processingStatus, CallProcessingStatus.outgoingCreated);
    expect(h.bloc.state.minimized, isFalse);
  });

  test('a live call is put on hold before the new one is handed to the platform', () async {
    // Two calls off hold at once are not allowed: the platform would end one.
    h = _harness();
    h.seedEstablishedCall('b', line: 0);
    final holding = Completer<void>();
    h.callkeep.holdGate = holding;

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await _settle(() => h.callkeep.held.isNotEmpty);

    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
    expect(h.callkeep.startCalls, isEmpty);

    holding.complete();
    await _settle(() => h.callkeep.startCalls.isNotEmpty);

    expect(_outgoing(h).single.line, 1);
  });

  test('a call already on hold is not held again', () async {
    h = _harness();
    h.seedEstablishedCall('b', line: 0, held: true);

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await _settle(() => h.callkeep.startCalls.isNotEmpty);

    expect(h.callkeep.held, isEmpty);
  });

  test('a second tap on the same number while the first is still being placed places nothing', () async {
    h = _harness();

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await _settle(() => h.callkeep.startCalls.isNotEmpty);
    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await _settle(() => false);

    expect(h.callkeep.startCalls, hasLength(1));
    expect(_outgoing(h), hasLength(1));
  });

  test('with every main line taken nothing is placed or held, and the person is told', () async {
    h = _harness(lines: 1);
    h.seedEstablishedCall('b', line: 0);

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await _settle(() => h.notifications.isNotEmpty);

    expect(h.notifications.whereType<GeneralUnableToCallNotification>(), hasLength(1));
    expect(h.callkeep.startCalls, isEmpty);
    expect(h.callkeep.held, isEmpty);
    expect(_outgoing(h), isEmpty);
  });

  test('a call the platform refuses to place is taken off the screen again', () async {
    h = _harness();
    h.seedEstablishedCall('b', line: 0);
    h.callkeep.startError = CallkeepCallRequestError.internal;

    h.bloc.add(const CallControlEvent.started(number: '200', video: false));
    await _settle(() => h.callkeep.startCalls.isNotEmpty && _outgoing(h).isEmpty);

    expect(h.bloc.state.activeCalls.map((call) => call.callId), ['b']);
    // What happens to the call put on hold for it today: it stays on hold.
    expect(h.callkeep.held, [(callId: 'b', onHold: true)]);
  });
}
