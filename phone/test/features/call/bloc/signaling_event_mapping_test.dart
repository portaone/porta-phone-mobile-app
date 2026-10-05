import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Every event the signaling module hands the bloc becomes one bloc event, or
/// none. The events of the bloc are private, so what an event became is read
/// from the bloc's observer: the name of its class and its fields, in the
/// order the class lists them.
class _Recorder extends BlocObserver {
  final events = <Object?>[];

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    events.add(event);
    super.onEvent(bloc, event);
  }
}

class _Case {
  const _Case(this.event, this.becomes, [this.fields = const [], this.callOnLine = false]);

  final Event event;

  /// The class of the bloc event, null when the event has none.
  final String? becomes;
  final List<Object?> fields;

  /// Whether the bloc holds a call on line 0 when the event arrives.
  final bool callOnLine;
}

Matcher _jsep(String type, String sdp) {
  return isA<JsepValue>().having((j) => j.type, 'type', type).having((j) => j.sdp, 'sdp', sdp);
}

const _offer = {'type': 'offer', 'sdp': 'v=0'};
const _participants = [ConferenceParticipant(line: 0, callId: 'c1')];

final _cases = <_Case>[
  // A call from its first ring to its end.
  _Case(
    IncomingCallEvent(
      line: 0,
      callId: 'c1',
      callee: '200',
      caller: '100',
      callerDisplayName: 'Ann',
      referredBy: '300',
      replaceCallId: 'r1',
      isFocus: true,
      jsep: _offer,
    ),
    '_CallSignalingEventIncoming',
    [0, 'c1', '200', '100', 'Ann', '300', 'r1', true, _jsep('offer', 'v=0')],
  ),
  _Case(RingingEvent(line: 0, callId: 'c1'), '_CallSignalingEventRinging', [0, 'c1']),
  _Case(ProceedingEvent(line: 0, callId: 'c1', code: 183), '_CallSignalingEventProceeding', [0, 'c1', 183]),
  _Case(ProgressEvent(line: 0, callId: 'c1', callee: '200', jsep: _offer), '_CallSignalingEventProgress', [
    0,
    'c1',
    '200',
    _jsep('offer', 'v=0'),
  ]),
  _Case(AcceptedEvent(line: 0, callId: 'c1', callee: '200', jsep: _offer), '_CallSignalingEventAccepted', [
    0,
    'c1',
    '200',
    _jsep('offer', 'v=0'),
  ]),
  _Case(HangupEvent(line: 0, callId: 'c1', code: 487, reason: 'Terminated'), '_CallSignalingEventHangup', [
    0,
    'c1',
    487,
    'Terminated',
  ]),
  _Case(CallErrorEvent(line: 0, callId: 'c1', code: 491, reason: 'Pending'), '_CallSignalingEventCallError', [
    0,
    'c1',
    491,
    'Pending',
  ]),

  // A change of media in a call that is up.
  _Case(
    UpdatingCallEvent(
      line: 0,
      callId: 'c1',
      callee: '200',
      caller: '100',
      callerDisplayName: 'Ann',
      referredBy: '300',
      replaceCallId: 'r1',
      isFocus: true,
      jsep: _offer,
    ),
    '_CallSignalingEventCallUpdating',
    [0, 'c1', '200', '100', 'Ann', '300', 'r1', true, _jsep('offer', 'v=0')],
  ),
  _Case(UpdatingEvent(line: 0, callId: 'c1'), '_CallSignalingEventUpdating', [0, 'c1']),
  _Case(UpdatedEvent(line: 0, callId: 'c1'), '_CallSignalingEventUpdated', [0, 'c1']),

  // What the other party's app says about itself during a call.
  _Case(MediaStatePeerMessageEvent(line: 0, callId: 'c1', video: false), '_CallSignalingEventPeerMediaState', [
    0,
    'c1',
    false,
  ]),
  _Case(ConferenceMutePeerMessageEvent(line: 0, callId: 'c1', muted: true), '_CallSignalingEventPeerConferenceMute', [
    0,
    'c1',
    true,
  ]),
  _Case(
    ConferenceHostAwayPeerMessageEvent(line: 0, callId: 'c1', away: true),
    '_CallSignalingEventPeerConferenceHostAway',
    [0, 'c1', true],
  ),
  _Case(UnknownPeerMessageEvent(line: 0, callId: 'c1', type: 'later'), null),

  // A transfer.
  _Case(
    TransferEvent(line: 0, referId: 'ref1', referTo: '400', referredBy: '300', replaceCallId: 'r1'),
    '_CallSignalingEventTransfer',
    [0, 'ref1', '400', '300', 'r1'],
  ),
  _Case(TransferringEvent(line: 0, callId: 'c1'), '_CallSignalingEventTransferring', [0, 'c1']),
  _Case(TransferAcceptedEvent(line: 0, callId: 'c1', code: 202), '_CallSignalingEventTransferAccepted', [0, 'c1']),
  _Case(TransferFailedEvent(line: 0, callId: 'c1', code: 603), '_CallSignalingEventTransferFailed', [0, 'c1', 603]),

  // A SIP NOTIFY within a call.
  _Case(
    ReferNotifyEvent(line: 0, callId: 'c1', subscriptionState: SubscriptionState.active, state: const ReferAccepted()),
    '_CallSignalingEventNotifyRefer',
    [0, 'c1', null, SubscriptionState.active, const ReferAccepted()],
  ),
  _Case(
    UnknownNotifyEvent(
      line: 0,
      callId: 'c1',
      notify: 'dialog',
      subscriptionState: SubscriptionState.pending,
      contentType: 'text/plain',
      content: 'body',
    ),
    '_CallSignalingEventNotifyUnknown',
    [0, 'c1', 'dialog', SubscriptionState.pending, 'text/plain', 'body'],
  ),

  // The state of the account's SIP registration.
  _Case(RegisteringEvent(), '_CallSignalingEventRegistration', [RegistrationStatus.registering, null, null]),
  _Case(RegisteredEvent(), '_CallSignalingEventRegistration', [RegistrationStatus.registered, null, null]),
  _Case(RegistrationFailedEvent(code: 403, reason: 'Forbidden'), '_CallSignalingEventRegistration', [
    RegistrationStatus.registration_failed,
    403,
    'Forbidden',
  ]),
  _Case(UnregisteringEvent(), '_CallSignalingEventRegistration', [RegistrationStatus.unregistering, null, null]),
  _Case(UnregisteredEvent(), '_CallSignalingEventRegistration', [RegistrationStatus.unregistered, null, null]),

  // Presence and dialogs of the numbers the account watches.
  _Case(NumberPresenceUpdate(number: '100', presenceInfo: const []), '_GlobalEventNumberPresenceUpdate', [
    '100',
    const <SignalingPresenceInfo>[],
  ]),
  _Case(NumberDialogsUpdate(number: '100', dialogInfos: const []), '_GlobalEventNumberDialogsUpdate', [
    '100',
    const <SignalingDialogInfo>[],
  ]),

  // The conference room.
  _Case(ConferenceOfferEvent(room: 7, jsep: _offer, participants: _participants), '_CallMutationEventConferenceOffer', [
    7,
    _jsep('offer', 'v=0'),
    _participants,
  ]),
  _Case(
    ConferenceIceTrickleEvent(candidate: const {'candidate': 'cand', 'sdpMid': '0', 'sdpMLineIndex': 1}),
    '_CallMutationEventConferenceRemoteCandidate',
    [
      isA<RTCIceCandidate>()
          .having((c) => c.candidate, 'candidate', 'cand')
          .having((c) => c.sdpMid, 'sdpMid', '0')
          .having((c) => c.sdpMLineIndex, 'sdpMLineIndex', 1),
    ],
  ),
  _Case(ConferenceIceTrickleEvent(candidate: null), '_CallMutationEventConferenceRemoteCandidate', [null]),
  _Case(ConferenceUpdatedEvent(room: 7, participants: _participants), '_CallMutationEventConferenceUpdated', [
    7,
    _participants,
  ]),
  _Case(ConferenceFailedEvent(reason: 'busy', room: 7, detail: 'mixer'), '_CallMutationEventConferenceFailed', [
    7,
    'busy',
    'mixer',
  ]),
  _Case(ConferenceTerminatedEvent(room: 7), '_CallMutationEventConferenceTerminated', [7]),

  // Media quality of a line: the event names a line, the bloc event a call.
  _Case(
    IceSlowLinkEvent(line: 0, mid: '0', media: IceMediaType.audio, uplink: true, lost: 7),
    '_CallMutationEventSlowlinkDetected',
    ['c1', true, CallMediaKind.audio, 7],
    true,
  ),
  _Case(IceSlowLinkEvent(line: 0, mid: '0', media: IceMediaType.audio, uplink: true, lost: 7), null),

  // Said by the server about a request of ours that is on its way.
  _Case(CallingEvent(line: 0, callId: 'c1'), null),
  _Case(HangingupEvent(line: 0, callId: 'c1'), null),
  _Case(IceHangupEvent(line: 0, reason: 'DTLS alert'), null),

  // An event the bloc has no branch for.
  _Case(HoldingEvent(line: 0, callId: 'c1'), null),
];

void main() {
  late BlocObserver observerBefore;
  late _Recorder recorder;

  setUp(() {
    observerBefore = Bloc.observer;
    recorder = _Recorder();
    Bloc.observer = recorder;
  });

  tearDown(() => Bloc.observer = observerBefore);

  for (final (index, c) in _cases.indexed) {
    final outcome = c.becomes ?? 'no bloc event';
    final suffix = c.callOnLine ? ' with a call on the line' : '';
    test('#$index ${c.event.runtimeType}$suffix becomes $outcome', () async {
      // The test is about what the event becomes, not about what its handler
      // then does with a bloc that holds no such call: whatever the handler
      // throws stays in this zone. The checks are made outside it.
      final seen = <Object?>[];
      await runZonedGuarded(() async {
        final h = CallBlocHarness();
        if (c.callOnLine) h.seedEstablishedCall('c1', line: 0);
        await pumpEventQueue();
        recorder.events.clear();

        h.signaling.emit(c.event);
        await pumpEventQueue();
        seen.addAll(recorder.events);
        await h.close();
      }, (_, _) {});

      if (c.becomes == null) {
        expect(seen, isEmpty);
        return;
      }
      expect(seen, isNotEmpty);
      final became = seen.first;
      expect(became.runtimeType.toString(), c.becomes);
      expect((became as Equatable).props, c.fields);
    });
  }
}
