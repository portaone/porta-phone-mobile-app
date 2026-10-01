import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:signaling_service_platform_interface/signaling_service_platform_interface.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/call/utils/contact_resolver.dart';
import 'package:webtrit_phone/models/models.dart';

import 'call_bloc_harness.dart';

/// The platform presents a call the bloc does not hold (an Android replay on a slow cold start,
/// an iOS push registration) while the server has already hung it up. The hangup lands on a
/// call the bloc never held and is reported to callkeep; callkeep keeps that fact for the app.
/// The bloc holds no list of its own: it asks callkeep before it shows a presentation it
/// received earlier and waited on, and a presentation still on its way is dropped by callkeep
/// before it gets here (covered in the plugin's own tests).
class _Connections extends Fake implements CallkeepConnections {
  final entered = Completer<void>();
  final release = Completer<List<CallkeepConnection>>();

  @override
  Future<List<CallkeepConnection>> getConnections() {
    if (!entered.isCompleted) entered.complete();
    return release.future;
  }

  @override
  Future<CallkeepConnection?> getConnection(String callId) async => null;
}

/// A contact lookup the test releases by hand: the window between a presentation received and a
/// placeholder shown, which a hangup can fall into.
class _DelayedContacts implements ContactResolver {
  final entered = Completer<void>();
  final released = Completer<Contact?>();

  @override
  Future<Contact?> resolve(String? number) {
    if (!entered.isCompleted) entered.complete();
    return released.future;
  }
}

const _offer = {'type': 'offer', 'sdp': 'v=0\r\no=- 1 1 IN IP4 127.0.0.1\r\nm=audio 9 RTP/AVP 0\r\n'};
const _hangup = HangupEvent(line: 0, callId: 'call', code: 487, reason: 'Request Terminated');
const _incoming = IncomingCallEvent(line: 0, callId: 'call', caller: '100', callee: '200', jsep: _offer);

StateHandshake _ringing({required String callId}) {
  final buffer = SignalingEventBuffer();
  buffer.onEvent(
    SignalingHandshakeReceived(
      handshake: const StateHandshake(
        keepaliveInterval: Duration(seconds: 30),
        timestamp: 1,
        registration: Registration(status: RegistrationStatus.registered),
        lines: [null],
        presenceInfos: [],
        dialogInfos: [],
        guestLine: null,
      ),
    ),
  );
  buffer.onEvent(
    SignalingProtocolEvent(
      event: IncomingCallEvent(line: 0, callId: callId, caller: '100', callee: '200', jsep: _offer),
    ),
  );
  return buffer.snapshot.whereType<SignalingHandshakeReceived>().single.handshake;
}

void _present(CallBlocHarness h, String callId) =>
    h.bloc.didPresentIncomingCall(const CallkeepHandle.number('100'), null, false, callId, null);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a presentation of a call heard hung up before it was held is not shown', () async {
    final connections = _Connections();
    final h = CallBlocHarness(callkeepConnections: connections);
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing(callId: 'call'));
    await connections.entered.future.timeout(const Duration(seconds: 2));

    h.signaling.emit(_hangup);
    await pumpEventQueue();
    connections.release.complete(const []);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);
    expect(h.callkeep.ended, ['call'], reason: 'the end was reported when the hangup landed');
    expect(h.callkeep.endedUnseen, {'call'}, reason: 'callkeep keeps it for the app');

    _present(h, 'call');
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, isEmpty, reason: 'the server hung this call up; nothing is shown');
    expect(h.callkeep.ended, ['call'], reason: 'the report already made is not repeated');
  });

  test('a presentation received before the hangup and applied after it is not shown', () async {
    // The window the bloc covers itself: the presentation got past callkeep before the end was
    // reported, the contact lookup is still running when the hangup lands, and the placeholder
    // would be created afterwards. Same on both platforms.
    final contacts = _DelayedContacts();
    final h = CallBlocHarness(contactResolver: contacts);
    addTearDown(h.close);
    _present(h, 'call');
    await contacts.entered.future.timeout(const Duration(seconds: 2));
    expect(h.bloc.state.activeCalls, isEmpty, reason: 'nothing is shown while the contact is looked up');

    h.signaling.emit(_hangup);
    await pumpEventQueue();
    expect(h.callkeep.ended, ['call']);

    contacts.released.complete(null);
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, isEmpty, reason: 'the end reported during the lookup is asked for before showing');
  });

  test('a second unknown call hung up while the first report is in flight is known at once', () async {
    // The order seen on the M32: two calls hang up together, the report of the first takes
    // seconds to cross to the platform, and the platform presents the second meanwhile. The
    // hangup handler runs sequentially; it must not wait for the platform between the two.
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.callkeep.endReportGate = Completer();
    h.signaling.emit(const HangupEvent(line: 1, callId: 'other', code: 487, reason: 'Request Terminated'));
    h.signaling.emit(_hangup);
    await pumpEventQueue();

    expect(h.callkeep.endedUnseen, {
      'other',
      'call',
    }, reason: 'both ends are known while the first report is still in flight');

    _present(h, 'call');
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);

    h.callkeep.endReportGate!.complete();
    await pumpEventQueue();
  });

  test('a presentation of a call never heard of is shown', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emit(_hangup);
    await pumpEventQueue();

    _present(h, 'another');
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['another']);
  });

  test('a call the bloc held and saw end is presented again under the same id', () async {
    // A transfer back reuses the id of a call the app knew. Its end was the bloc's own
    // knowledge, not an end reported unseen, so callkeep records nothing and the id stays free.
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing(callId: 'call'));
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);

    h.signaling.emit(_hangup);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);
    expect(h.callkeep.endedUnseen, isEmpty, reason: 'the bloc held this call; its end is its own');

    _present(h, 'call');
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);
  });

  test('a call ended from this side whose server hangup lands after it left is not an unseen end', () async {
    // Seen on the M32: the user ends a held call, the server confirms with a hangup while the
    // call is still in state, and by the time that hangup's mutation runs performEnd has popped
    // the call. That is a call the app held, not one it never saw: nothing is reported as
    // missedWhileConnecting, and its id stays free for a transfer back.
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emitHandshake(_ringing(callId: 'call'));
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);

    h.signaling.gate = Completer();
    final ended = h.bloc.performEndCall('call');
    await pumpEventQueue();
    expect(h.signaling.requests.whereType<DeclineRequest>(), hasLength(1), reason: 'performEnd is at its request');
    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call'], reason: 'not popped yet');

    h.signaling.emit(_hangup);
    await pumpEventQueue();
    h.signaling.gate!.complete();
    await ended;
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls, isEmpty);
    expect(h.callkeep.ended, isEmpty, reason: 'callkeep ended this call itself; nothing to report');
    expect(h.callkeep.endedUnseen, isEmpty, reason: 'the app held this call');
  });

  test('the same id offered again by the server is live again', () async {
    // The server's offer is what says the call is live: it goes through signaling, not through
    // the presentation callkeep guards, and is shown as any other.
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emit(_hangup);
    await pumpEventQueue();
    expect(h.callkeep.endedUnseen, {'call'});

    h.signaling.emit(_incoming);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);

    h.signaling.emit(_hangup);
    await pumpEventQueue();
    expect(h.bloc.state.activeCalls, isEmpty);
  });

  test('a handshake listing the id presents it as any other', () async {
    final h = CallBlocHarness();
    addTearDown(h.close);
    h.signaling.emit(_hangup);
    await pumpEventQueue();

    h.signaling.emitHandshake(_ringing(callId: 'call'));
    await pumpEventQueue();

    expect(h.bloc.state.activeCalls.map((c) => c.callId), ['call']);
  });
}
