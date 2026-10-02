import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signaling/signaling.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';
import 'package:webtrit_phone/features/call/call.dart';

import 'call_bloc_harness.dart';

/// Leaving the call screen only changes how the call is shown. The proximity
/// sensor is not turned off for it: on iOS that is done by a session mode that
/// also moves the call to the loudspeaker, which put a private call on the
/// speaker the moment the user pressed back. Nor does coming back choose an
/// audio device: the one in use when the screen was left may have been
/// changed since, from the system's own call screen.
void main() {
  late CallBlocHarness h;
  late _EventLog events;
  late BlocObserver previousObserver;

  final speaker = CallkeepAudioDevice(type: CallkeepAudioDeviceType.speaker, name: 'Speaker');
  final earpiece = CallkeepAudioDevice(type: CallkeepAudioDeviceType.earpiece, name: 'Earpiece');

  setUp(() {
    previousObserver = Bloc.observer;
    Bloc.observer = events = _EventLog();
    h = CallBlocHarness();
  });
  tearDown(() async {
    await h.close();
    Bloc.observer = previousObserver;
  });

  /// An established call with both built-in devices known and [current] in use.
  Future<void> seedCallOn(CallkeepAudioDevice current) async {
    h.seedEstablishedCall('a');
    await h.bloc.performAudioDevicesUpdate('a', [earpiece, speaker]);
    await h.bloc.performAudioDeviceSet('a', current);
    await pumpEventQueue();
    events.clear();
  }

  group('leaving the call screen', () {
    test('reports no proximity change', () async {
      h.seedEstablishedCall('a');

      h.bloc.add(const CallScreenEvent.didPop());
      await pumpEventQueue();

      expect(h.bloc.state.minimized, isTrue);
      expect(h.callkeep.proximityUpdates, isEmpty);
    });

    test('reports no proximity change with the speaker on', () async {
      await seedCallOn(speaker);

      h.bloc.add(const CallScreenEvent.didPop());
      await pumpEventQueue();

      expect(h.bloc.state.minimized, isTrue);
      expect(h.callkeep.proximityUpdates, isEmpty);
      expect(h.bloc.state.audioDevice?.type, CallAudioDeviceType.speaker);
      expect(events.audioDeviceRequests, isEmpty);
    });
  });

  group('coming back to the call screen', () {
    // The one report that stays: an incoming call gets its proximity flag from the screen
    // opening, so the value is repeated for a call that already has it.
    test('reports the sensor on, never off', () async {
      h.seedEstablishedCall('a');

      h.bloc.add(const CallScreenEvent.didPop());
      h.bloc.add(const CallScreenEvent.didPush());
      await pumpEventQueue();

      expect(h.bloc.state.minimized, isFalse);
      expect(h.callkeep.proximityUpdates, [(callId: 'a', enabled: true)]);
    });

    for (final device in [speaker, earpiece]) {
      test('asks for no audio device when the call is on the ${device.type.name}', () async {
        await seedCallOn(device);

        h.bloc.add(const CallScreenEvent.didPop());
        h.bloc.add(const CallScreenEvent.didPush());
        await pumpEventQueue();

        expect(h.bloc.state.minimized, isFalse);
        expect(events.audioDeviceRequests, isEmpty);
        expect(h.bloc.state.audioDevice?.type, CallAudioDevice.fromCallkeep(device).type);
      });
    }

    test('leaves a device chosen while the screen was away', () async {
      await seedCallOn(speaker);

      h.bloc.add(const CallScreenEvent.didPop());
      await pumpEventQueue();
      await h.bloc.performAudioDeviceSet('a', earpiece);
      await pumpEventQueue();
      events.clear();

      h.bloc.add(const CallScreenEvent.didPush());
      await pumpEventQueue();

      expect(events.audioDeviceRequests, isEmpty, reason: 'the speaker must not be forced back');
      expect(h.bloc.state.audioDevice?.type, CallAudioDeviceType.earpiece);
    });
  });

  test('submitting a blind transfer reports no proximity change', () async {
    h.seedEstablishedCall('a');

    h.bloc.add(const CallControlEvent.blindTransferInitiated('a'));
    await pumpEventQueue();
    h.bloc.add(const CallControlEvent.blindTransferSubmitted(number: '200'));
    await pumpEventQueue();

    expect(h.signaling.requests.whereType<TransferRequest>(), hasLength(1));
    expect(h.bloc.state.minimized, isFalse);
    expect(h.callkeep.proximityUpdates, isEmpty);
  });

  group('starting a transfer', () {
    test('blind: minimizes and reports no proximity change', () async {
      h.seedEstablishedCall('a');

      h.bloc.add(const CallControlEvent.blindTransferInitiated('a'));
      await pumpEventQueue();

      expect(h.bloc.state.minimized, isTrue);
      expect(h.callkeep.proximityUpdates, isEmpty);
    });

    test('attended: minimizes and reports no proximity change', () async {
      h.seedEstablishedCall('a');

      h.bloc.add(const CallControlEvent.attendedTransferInitiated('a'));
      await pumpEventQueue();

      expect(h.bloc.state.minimized, isTrue);
      expect(h.callkeep.proximityUpdates, isEmpty);
    });

    for (final (kind, start) in [
      ('blind', const CallControlEvent.blindTransferInitiated('a')),
      ('attended', const CallControlEvent.attendedTransferInitiated('a')),
    ]) {
      test('$kind with the speaker on: asks for no audio device on return', () async {
        await seedCallOn(speaker);

        h.bloc.add(start);
        h.bloc.add(const CallScreenEvent.didPush());
        await pumpEventQueue();

        expect(h.bloc.state.minimized, isFalse);
        expect(events.audioDeviceRequests, isEmpty);
        expect(h.bloc.state.audioDevice?.type, CallAudioDeviceType.speaker);
      });
    }
  });
}

/// Every event the call bloc was given. The host platform is neither Android
/// nor iOS, so an audio device request never reaches a fake - the request
/// itself is what a test can see.
class _EventLog extends BlocObserver {
  final List<Object?> _events = [];

  Iterable<Object?> get audioDeviceRequests =>
      _events.where((e) => '${e.runtimeType}'.contains('ControlEventAudioDeviceSet'));

  void clear() => _events.clear();

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _events.add(event);
  }
}
