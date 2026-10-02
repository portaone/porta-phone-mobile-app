import 'package:flutter_test/flutter_test.dart';
import 'package:webtrit_phone/features/call/call.dart';

void main() {
  const earpiece = CallAudioDevice(type: CallAudioDeviceType.earpiece, name: 'Earpiece');
  const speaker = CallAudioDevice(type: CallAudioDeviceType.speaker, name: 'Speaker');
  const bluetooth = CallAudioDevice(type: CallAudioDeviceType.bluetooth, name: 'Buds');
  const wired = CallAudioDevice(type: CallAudioDeviceType.wiredHeadset, name: 'Headset');
  const builtIn = [earpiece, speaker];

  var enabled = true;
  late SpeakerOnMinimize rule;

  setUp(() {
    enabled = true;
    rule = SpeakerOnMinimize(isEnabled: () => enabled);
  });

  CallAudioDevice? leave({
    String callId = 'a',
    bool video = false,
    CallAudioDevice? current = earpiece,
    List<CallAudioDevice> available = builtIn,
  }) => rule.onCallScreenLeft(callId: callId, video: video, current: current, available: available);

  group('leaving the call screen', () {
    test('moves an audio call on the earpiece to the speaker', () {
      expect(leave(), speaker);
    });

    test('takes a device not reported yet for the earpiece', () {
      expect(leave(current: null), speaker);
    });

    test('does nothing when the option is off', () {
      enabled = false;
      expect(leave(), isNull);
    });

    test('leaves a video call alone', () {
      expect(leave(video: true), isNull);
    });

    for (final device in [speaker, bluetooth, wired]) {
      test('leaves a call on the ${device.type.name} alone', () {
        expect(leave(current: device, available: [earpiece, speaker, device]), isNull);
      });
    }

    test('does nothing when the platform reports no speaker', () {
      expect(leave(available: [earpiece]), isNull);
    });
  });

  group('coming back', () {
    test('returns the call to the earpiece it was taken off', () {
      leave();
      expect(rule.onCallScreenReturned(callId: 'a', current: speaker), earpiece);
    });

    test('returns it even when the switch to the speaker was never reported', () {
      leave();
      expect(rule.onCallScreenReturned(callId: 'a', current: earpiece), earpiece);
      leave();
      expect(rule.onCallScreenReturned(callId: 'a', current: null), earpiece);
    });

    test('keeps a device the person chose while the screen was away', () {
      leave();
      expect(rule.onCallScreenReturned(callId: 'a', current: bluetooth), isNull);
    });

    test('does nothing for a call it did not move', () {
      expect(rule.onCallScreenReturned(callId: 'a', current: speaker), isNull);

      leave(current: speaker);
      expect(
        rule.onCallScreenReturned(callId: 'a', current: speaker),
        isNull,
        reason: 'the speaker was the choice',
      );
    });

    test('does nothing for another call', () {
      leave(callId: 'a');
      expect(rule.onCallScreenReturned(callId: 'b', current: speaker), isNull);
    });

    test('moves a call back once', () {
      leave();
      rule.onCallScreenReturned(callId: 'a', current: speaker);
      expect(rule.onCallScreenReturned(callId: 'a', current: speaker), isNull);
    });

    test('a leave with the option switched off forgets an earlier move', () {
      leave();
      enabled = false;
      leave();
      expect(rule.onCallScreenReturned(callId: 'a', current: speaker), isNull);
    });
  });
}
