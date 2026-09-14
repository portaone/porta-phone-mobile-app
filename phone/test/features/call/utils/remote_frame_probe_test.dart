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
        expect(probe.probedTrack, same(track));
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

    group('the verdict belongs to its track', () {
      test('a new stream forgets the old picture at once', () {
        fakeAsync((async) {
          probe
            ..stream = _Stream(_Track())
            ..start();
          async.elapse(Duration.zero);
          expect(probe.renderable, isTrue);

          probe.stream = _Stream(_Track(immediate: false));
          expect(probe.renderable, isFalse, reason: 'forgotten before any probe, the moment the stream changes');
          expect(probe.probedTrack, isNull);
          expect(notified, 2);
        });
      });

      test('a track swapped inside the same stream is noticed by the next probe', () {
        fakeAsync((async) {
          final stream = _Stream(_Track());
          probe
            ..stream = stream
            ..start();
          async.elapse(Duration.zero);
          expect(probe.renderable, isTrue);

          final swapped = _Track(immediate: false);
          stream.track = swapped;
          expect(probe.renderable, isTrue, reason: 'nobody told the probe; it finds out on its own');
          async.elapse(probe.interval);
          expect(probe.renderable, isFalse);
          expect(swapped.captures, 1, reason: 'and the new track is probed in the same breath');
        });
      });

      test('a track removed from the stream takes its picture with it', () {
        fakeAsync((async) {
          final stream = _Stream(_Track());
          probe
            ..stream = stream
            ..start();
          async.elapse(Duration.zero);
          expect(probe.renderable, isTrue);

          stream.track = null;
          async.elapse(probe.interval);
          expect(probe.renderable, isFalse);
          expect(probe.probedTrack, isNull);
        });
      });

      test('an answer about a track no longer current is dropped, the current one probed at once', () {
        fakeAsync((async) {
          final old = _Track(immediate: false);
          probe
            ..stream = _Stream(old)
            ..start();
          async.elapse(Duration.zero);
          expect(old.captures, 1);

          final next = _Track(immediate: false);
          probe.stream = _Stream(next);
          // The old stream closes and its capture fails - the optimistic answer
          // is about the old track and must not become the new one's picture.
          old.pending.single.completeError(StateError('stream closed'));
          // Zero delay, not a microtask: the dropped answer schedules a timer.
          async.elapse(Duration.zero);
          expect(probe.renderable, isFalse);
          expect(next.captures, 1, reason: 'no interval wait after a dropped answer');

          // The new track's own answer still counts.
          next.pending.single.complete(Uint8List(4).buffer);
          async.flushMicrotasks();
          expect(probe.renderable, isTrue);
          expect(probe.probedTrack, same(next));
        });
      });

      test('a successful answer about an old track is dropped as well', () {
        fakeAsync((async) {
          final old = _Track(immediate: false);
          final stream = _Stream(old);
          probe
            ..stream = stream
            ..start();
          async.elapse(Duration.zero);

          stream.track = _Track(immediate: false);
          old.pending.single.complete(Uint8List(4).buffer);
          async.flushMicrotasks();
          expect(probe.renderable, isFalse);
          expect(probe.probedTrack, isNull);
        });
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
