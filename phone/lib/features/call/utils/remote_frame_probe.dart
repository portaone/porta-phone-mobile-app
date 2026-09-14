import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'frame_analysis_worker.dart';

final _logger = Logger('RemoteFrameProbe');

/// Watches the remote video of a call and answers one question: does it show
/// a picture right now, or only black or empty frames?
///
/// A far side can announce video and send nothing worth showing - a muted
/// camera delivering black, a track that has not started yet - and the only
/// way to know is to look at a frame. The probe captures one from the first
/// video track of [stream] every [interval] and has [FrameAnalysisWorker]
/// judge it off the UI thread; [renderable] is the verdict, and listeners hear
/// when it changes.
///
/// Where frames cannot be analysed (see [FrameAnalysisWorker.isSupported])
/// nothing is ever probed and [renderable] stays true: the video is shown
/// rather than hidden for the whole call.
class RemoteFrameProbe extends ChangeNotifier {
  RemoteFrameProbe({
    FrameAnalysisWorker? worker,
    this.interval = const Duration(seconds: 1),
    this.captureTimeout = const Duration(seconds: 10),
  }) : _worker = worker ?? FrameAnalysisWorker();

  /// What [renderable] is before any frame has been probed: nothing to show,
  /// unless nothing can be analysed.
  static const bool showsUnprobed = !FrameAnalysisWorker.isSupported;

  /// How long after a verdict the next frame is looked at.
  final Duration interval;

  /// How long one capture may take before it counts as failed.
  final Duration captureTimeout;

  final FrameAnalysisWorker _worker;

  MediaStream? _stream;
  bool _renderable = showsUnprobed;
  Timer? _timer;
  bool _disposed = false;

  /// Whether the last probed frame had something in it.
  bool get renderable => _renderable;

  /// The stream to watch - the remote stream of the call on screen. Hand over
  /// the new one whenever that call changes.
  set stream(MediaStream? value) => _stream = value;

  /// Starts the worker and the first probe. Once, after construction.
  void start() {
    _worker.start();
    _schedule(Duration.zero);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _worker.dispose();
    super.dispose();
  }

  MediaStreamTrack? get _currentTrack {
    final tracks = _stream?.getVideoTracks();
    return (tracks == null || tracks.isEmpty) ? null : tracks.first;
  }

  void _setRenderable(bool value, {required String reason}) {
    if (_renderable == value) return;
    _renderable = value;
    _logger.fine('$reason: renderable=$_renderable');
    notifyListeners();
  }

  void _schedule(Duration delay) {
    if (_disposed || !FrameAnalysisWorker.isSupported) return;
    _timer?.cancel();
    _timer = Timer(delay, _probe);
  }

  Future<void> _probe() async {
    if (_disposed) return;

    final track = _currentTrack;
    if (track == null) {
      _schedule(interval);
      return;
    }

    final startTime = DateTime.now();
    bool renderable;
    try {
      renderable = !await _isFrameBlackOrEmpty(track).timeout(captureTimeout);
    } catch (_) {
      // A frame that could not be captured or analysed is shown rather than
      // hidden: the probe exists to catch black, not to second-guess errors.
      renderable = true;
    }
    final elapsed = DateTime.now().difference(startTime);

    if (_disposed) return;
    _setRenderable(renderable, reason: 'probe done in ${elapsed.inMilliseconds}ms');
    _schedule(interval);
  }

  Future<bool> _isFrameBlackOrEmpty(MediaStreamTrack track) async {
    final frame = await track.captureFrame();
    return _worker.analyzeFrame(frame.asUint8List());
  }
}
