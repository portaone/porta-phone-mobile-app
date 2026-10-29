import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'call_bloc_harness.dart';

/// A call the user ends releases its microphone while the peer connection is
/// still open. On Android, stopping the track only disables it; WebRTC stops
/// the microphone when the disabled track is still on a sender. A call that
/// never started sending (cancelled while ringing) whose connection is closed
/// first keeps the microphone recording until the next call ends (WT-2110).
class _RecordingUserMediaBuilder extends FakeUserMediaBuilder {
  FakePeerConnection? peer;

  /// Thrown by every release when set.
  Object? releaseError;

  /// How many times [peer] had been closed when each stream was released.
  final List<int> closesAtRelease = [];

  @override
  Future<void> release(MediaStream stream) async {
    closesAtRelease.add(peer!.closes);
    if (releaseError case final error?) throw error;
    await super.release(stream);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a call the user ends releases its local stream before the peer connection closes', () async {
    final media = _RecordingUserMediaBuilder();
    final h = CallBlocHarness(userMediaBuilder: media);
    addTearDown(h.close);
    media.peer = h.seedEstablishedCall('call');

    await h.bloc.performEndCall('call', CallkeepEndedBy.user);
    await h.settle(() => h.bloc.state.activeCalls.isEmpty);

    expect(h.bloc.state.activeCalls, isEmpty);
    expect(media.closesAtRelease, [0], reason: 'the stream is released once, with the connection still open');
    expect(media.peer!.closes, greaterThan(0), reason: 'the connection is closed after the release');
  });

  test('a failed release of the local stream still closes the connection and ends the call', () async {
    final media = _RecordingUserMediaBuilder()..releaseError = StateError('release failed');
    final h = CallBlocHarness(userMediaBuilder: media);
    addTearDown(h.close);
    media.peer = h.seedEstablishedCall('call');

    await h.bloc.performEndCall('call', CallkeepEndedBy.user);
    await h.settle(() => h.bloc.state.activeCalls.isEmpty);

    expect(h.bloc.state.activeCalls, isEmpty);
    expect(media.peer!.closes, greaterThan(0));
  });
}
