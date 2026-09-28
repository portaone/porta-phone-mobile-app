import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_bloc_harness.dart';

/// Whether the far end of [callId] is playing.
bool _audible(CallBlocHarness h, String callId) =>
    h.bloc.state.retrieveActiveCall(callId)!.remoteStream!.getAudioTracks().single.enabled;

/// Pumps until [done], or gives up after enough turns for anything the bloc
/// queues in response to one change.
Future<void> _settle(bool Function() done) async {
  for (var turn = 0; turn < 50 && !done(); turn++) {
    await pumpEventQueue();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // One rule, both directions: the sending direction is given up FIRST and
  // taken back LAST, so a change that fails halfway leaves a call quieter and
  // never louder - and a restore whose microphone fails leaves the user
  // hearing the far end instead of deaf as well. The order is only observable
  // while one of the two is still in flight, which is what the gate is for.
  group('the order a call\'s audio changes in', () {
    test('silencing takes the microphone off before it stops the far end', () async {
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      addTearDown(h.close);
      final a = h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);
      final gate = Completer<void>();
      a.fakeSenders.single.gate = gate;

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      await _settle(() => a.fakeSenders.single.replaced.isNotEmpty);

      expect(a.fakeSenders.single.replaced.last, isNull, reason: 'the microphone is asked to leave first');
      expect(_audible(h, 'a'), isTrue, reason: 'and the far end is still playing while it does');

      gate.complete();
      a.fakeSenders.single.gate = null;
      await _settle(() => !_audible(h, 'a'));

      expect(_audible(h, 'a'), isFalse, reason: 'both directions end up silent');
    });

    test('restoring plays the far end before it takes the microphone back', () async {
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      addTearDown(h.close);
      final a = h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      h.signaling.emit(
        const ConferenceOfferEvent(
          room: 7,
          jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          participants: [
            ConferenceParticipant(line: 0, callId: 'a'),
            ConferenceParticipant(line: 1, callId: 'b'),
          ],
        ),
      );
      await _settle(() => !_audible(h, 'a'));

      final gate = Completer<void>();
      final sender = a.fakeSenders.single;
      final silenced = sender.replaced.length;
      sender.gate = gate;

      // The room ends on the server and the calls survive it - the path that
      // gives a leg its audio back. (The host's own End ends the calls too.)
      h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
      await _settle(() => sender.replaced.length > silenced);

      expect(sender.replaced.last, isNotNull, reason: 'the microphone is asked back');
      expect(_audible(h, 'a'), isTrue, reason: 'and the far end already plays while it is still being asked');

      gate.complete();
      sender.gate = null;
      await pumpEventQueue();

      expect(sender.track, isNotNull, reason: 'the microphone lands too');
    });

    test('a muted call gets its far end back without waiting on its sender', () async {
      // A call muted while it was a leg comes back with its microphone still
      // off, so the sender has nothing to change - but confirming that is
      // still an operation on it, and a slow one must not keep the user deaf
      // to a call he has back.
      final h = CallBlocHarness(capabilities: const CallCapabilitiesConfig(isConferenceEnabled: true));
      addTearDown(h.close);
      final a = h.seedEstablishedCall('a', line: 0);
      h.seedEstablishedCall('b', line: 1);

      h.bloc.add(const CallControlEvent.merged(['a', 'b']));
      h.signaling.emit(
        const ConferenceOfferEvent(
          room: 7,
          jsep: {'type': 'offer', 'sdp': 'v=0\r\nm=audio 9 UDP/TLS/RTP/SAVPF 111\r\n'},
          participants: [
            ConferenceParticipant(line: 0, callId: 'a'),
            ConferenceParticipant(line: 1, callId: 'b'),
          ],
        ),
      );
      await _settle(() => h.bloc.state.conference.phase == ConferencePhase.active);
      h.bloc.add(const CallControlEvent.conferenceSelfMuted(true));
      await _settle(() => h.bloc.state.retrieveActiveCall('a')!.muted);

      final gate = Completer<void>();
      final sender = a.fakeSenders.single;
      final before = sender.replaced.length;
      sender.gate = gate;
      h.signaling.emit(const ConferenceTerminatedEvent(room: 7));
      await _settle(() => sender.replaced.length > before);

      expect(h.bloc.state.retrieveActiveCall('a')!.muted, isTrue);
      expect(_audible(h, 'a'), isTrue, reason: 'the far end plays while the sender is still being confirmed');

      gate.complete();
      sender.gate = null;
      await pumpEventQueue();

      expect(sender.track, isNull, reason: 'and the microphone stays off, as the user left it');
    });
  });
}
