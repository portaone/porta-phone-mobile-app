import 'dart:async';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/features/call/utils/frame_analysis_worker.dart';
import 'package:webtrit_phone/features/call/utils/remote_frame_probe.dart';

/// A worker whose verdict the test dictates: no isolate, no decoding.
class _Judge extends FrameAnalysisWorker {
  bool black = false;
  int analysed = 0;
  bool disposed = false;

  @override
  void start() {}

  @override
  Future<bool> analyzeFrame(Uint8List frameBytes) async {
    analysed++;
    return black;
  }

  @override
  void dispose() => disposed = true;
}

/// A track whose captures complete when the test says - at once, later, or
/// never - and counts how often it was asked.
class _Track extends Fake implements MediaStreamTrack {
  _Track({this.immediate = true});

  final bool immediate;
  final pending = <Completer<ByteBuffer>>[];
  int captures = 0;

  @override
  Future<ByteBuffer> captureFrame() {
    captures++;
    if (immediate) return Future.value(Uint8List(4).buffer);
    final completer = Completer<ByteBuffer>();
    pending.add(completer);
    return completer.future;
  }
}

class _Stream extends Fake implements MediaStream {
  _Stream(this.track);

  MediaStreamTrack? track;

  @override
  List<MediaStreamTrack> getVideoTracks() => [?track];
}

void main() {
  late _Judge judge;
  late RemoteFrameProbe probe;
  late int notified;

  setUp(() {
    judge = _Judge();
    probe = RemoteFrameProbe(worker: judge)..addListener(() => notified++);
    notified = 0;
  });

  tearDown(() => probe.dispose());

  group('RemoteFrameProbe', () {
    test('starts unprobed and shows nothing until a frame has been looked at', () {
      fakeAsync((async) {
        final track = _Track();
        probe
          ..stream = _Stream(track)
          ..start();
        expect(probe.renderable, isFalse);

        // The first probe is a zero-delay timer; flushing microtasks does not fire it.
        async.elapse(Duration.zero);
        expect(track.captures, 1, reason: 'the first probe runs at once');
        expect(probe.renderable, isTrue);
        expect(notified, 1);
      });
    });

    test('keeps looking every interval and reports black when it comes', () {
      fakeAsync((async) {
        final track = _Track();
        probe
          ..stream = _Stream(track)
          ..start();
        // The first probe is a zero-delay timer; flushing microtasks does not fire it.
        async.elapse(Duration.zero);
        expect(probe.renderable, isTrue);

        judge.black = true;
        async.elapse(probe.interval);
        expect(track.captures, 2);
        expect(probe.renderable, isFalse);
        expect(notified, 2);
      });
    });

    test('a capture that fails counts as a picture', () {
      fakeAsync((async) {
        final track = _Track(immediate: false);
        probe
          ..stream = _Stream(track)
          ..start();
        // The first probe is a zero-delay timer; flushing microtasks does not fire it.
        async.elapse(Duration.zero);
        track.pending.single.completeError(StateError('no frame'));
        async.flushMicrotasks();
        expect(probe.renderable, isTrue);
        expect(judge.analysed, 0);
      });
    });

    test('a capture that never completes counts as a picture after the timeout', () {
      fakeAsync((async) {
        final track = _Track(immediate: false);
        probe
          ..stream = _Stream(track)
          ..start();
        // The first probe is a zero-delay timer; flushing microtasks does not fire it.
        async.elapse(Duration.zero);
        async.elapse(probe.captureTimeout - const Duration(seconds: 1));
        expect(probe.renderable, isFalse);
        async.elapse(const Duration(seconds: 1));
        expect(probe.renderable, isTrue);
      });
    });

    test('with no track there is nothing to show, and it keeps checking for one', () {
      fakeAsync((async) {
        final stream = _Stream(null);
        probe
          ..stream = stream
          ..start();
        // The first probe is a zero-delay timer; flushing microtasks does not fire it.
        async.elapse(Duration.zero);
        expect(probe.renderable, isFalse);

        final track = _Track();
        stream.track = track;
        async.elapse(probe.interval);
        expect(track.captures, 1);
        expect(probe.renderable, isTrue);
      });
    });

    test('dispose stops the probing and the worker', () {
      fakeAsync((async) {
        final track = _Track();
        probe
          ..stream = _Stream(track)
          ..start();
        // The first probe is a zero-delay timer; flushing microtasks does not fire it.
        async.elapse(Duration.zero);
        probe.dispose();
        expect(judge.disposed, isTrue);
        async.elapse(probe.interval * 3);
        expect(track.captures, 1);
        // tearDown disposes again; a second dispose of a ChangeNotifier is an
        // error, so hand it a fresh one.
        probe = RemoteFrameProbe(worker: _Judge());
      });
    });
  });
}
