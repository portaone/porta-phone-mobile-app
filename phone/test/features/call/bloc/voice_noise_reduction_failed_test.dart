import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'call_bloc_harness.dart';

/// The call screen says the noise reduction did not start from the bloc's state, which follows
/// the microphone: every call shares it, so this is no call's own field.
void main() {
  late ValueNotifier<bool> failed;
  late CallBlocHarness h;

  setUp(() {
    failed = ValueNotifier(false);
    h = CallBlocHarness(voiceNoiseReductionFailed: failed);
  });

  tearDown(() => h.close());

  test('follows the microphone in both directions', () async {
    expect(h.bloc.state.voiceNoiseReductionFailed, isFalse);

    failed.value = true;
    await pumpEventQueue();
    expect(h.bloc.state.voiceNoiseReductionFailed, isTrue);

    failed.value = false;
    await pumpEventQueue();
    expect(h.bloc.state.voiceNoiseReductionFailed, isFalse);
  });

  test('stops listening when the bloc closes', () async {
    await h.close();

    failed.value = true;
    await pumpEventQueue();

    expect(h.bloc.state.voiceNoiseReductionFailed, isFalse, reason: 'a closed bloc takes no event');
  });
}
