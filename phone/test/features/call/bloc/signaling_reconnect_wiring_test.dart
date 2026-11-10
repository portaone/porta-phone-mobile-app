import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/services/services.dart';

import 'call_bloc_harness.dart';

/// What the bloc tells the session's reconnect policy reaches the policy the
/// shell gave it: since the policy left the bloc, this is the only line
/// between the two.
class _RecordingReconnect implements SignalingReconnect {
  final calls = <String>[];

  @override
  void notifyAppResumed() => calls.add('resumed');

  @override
  void notifyAppPaused({required bool hasActiveCalls}) => calls.add('paused hasActiveCalls=$hasActiveCalls');

  @override
  void notifyForceReconnect() => calls.add('force');

  @override
  void notifyHasActiveCalls({required bool hasActiveCalls}) => calls.add('active=$hasActiveCalls');

  @override
  void notifyNetworkAvailable() => calls.add('network up');

  @override
  void notifyNetworkUnavailable() => calls.add('network down');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingReconnect reconnect;
  late CallBlocHarness h;
  setUp(() {
    reconnect = _RecordingReconnect();
    h = CallBlocHarness(signalingReconnect: reconnect);
  });
  tearDown(() => h.close());

  test('the app going to the background is told to the policy, with no calls', () async {
    h.bloc.didChangeAppLifecycleState(AppLifecycleState.paused);
    await h.settle(() => reconnect.calls.isNotEmpty);

    expect(reconnect.calls, ['paused hasActiveCalls=false']);
  });

  test('the app coming back is told to the policy', () async {
    h.bloc.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await h.settle(() => reconnect.calls.isNotEmpty);

    expect(reconnect.calls, ['resumed']);
  });

  test('the bloc closing leaves the policy alone: the shell owns it', () async {
    await h.close();

    expect(reconnect.calls, isEmpty);
  });
}
