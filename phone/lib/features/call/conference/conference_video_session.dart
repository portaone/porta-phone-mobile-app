import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:logging/logging.dart';

import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/extensions/rtc_peer_connection_extension.dart';
import 'package:webtrit_phone/features/call/models/conference_request_result.dart';
import 'package:webtrit_phone/features/call/utils/peer_connection_factory.dart';
import 'package:webtrit_phone/features/call/utils/user_media_builder.dart';
import 'package:webtrit_phone/utils/serial_queue.dart';

final _logger = Logger('ConferenceVideoSession');

/// Sends one conference video request and says what became of it: the
/// owner's signalling, so that this class never touches the socket.
typedef ConferenceVideoSend = Future<ConferenceRequestResult> Function(Request request);

/// Told whenever the video this client receives changes: a stream arrived or
/// went, or the room said which participant a stream belongs to.
typedef ConferenceVideoFeedsChanged = void Function(List<ConferenceVideoFeed> feeds);

/// One video stream of one participant, as this client receives it.
class ConferenceVideoFeed {
  const ConferenceVideoFeed({required this.feed, required this.kind, required this.stream});

  /// The participant, as `conference_video_updated` numbers them: the host is
  /// 1, the far end of the host's line N is N + 2.
  final int feed;

  /// A camera or a shared screen.
  final ConferenceVideoKind kind;

  /// What a renderer shows.
  final MediaStream stream;
}

/// One participant's video in a conference: the two video-only peer
/// connections next to the mixer's audio one (protocol section 18).
///
/// - The **subscriber** receives everyone else's video. The room offers,
///   through Core; this class answers. Every offer is answered on the same
///   connection, except the first one after a subscribe and one that comes
///   while the connection is spent - Core sends that one unasked after Janus
///   hung the subscriber up, for a new connection.
/// - The **publisher** sends this client's camera. This class offers, Core
///   answers; the first publish joins the room, a later one renegotiates the
///   same publication (an ICE restart). It carries no audio: audio stays in
///   the mixer.
///
/// It knows the protocol and nothing of the bloc: requests go out through
/// [send], and the owner hands in the events that concern it. Candidates a
/// connection gathers before Core has acknowledged the request that made it
/// would be refused with `no_peer_connection`, so they wait for the
/// acknowledgement here.
///
/// Every operation runs on one queue, one at a time, as in
/// [ConferencePeerConnection]: opening a connection takes several awaits, and
/// a teardown arriving in between must find it to close it.
class ConferenceVideoSession {
  ConferenceVideoSession({
    required PeerConnectionFactory factory,
    required UserMediaBuilder userMediaBuilder,
    required ConferenceVideoSend send,
    required this.onFeedsChanged,
    this.callsWantCamera,
    this.retryDelay = const Duration(seconds: 2),
  }) : _factory = factory,
       _userMediaBuilder = userMediaBuilder,
       _send = send;

  final PeerConnectionFactory _factory;
  final UserMediaBuilder _userMediaBuilder;
  final ConferenceVideoSend _send;
  final ConferenceVideoFeedsChanged onFeedsChanged;

  /// Whether the calls that share the camera track want it on, asked when
  /// the room lets the track go: they may have changed their mind while the
  /// room held it. Without it the track goes back as the room found it.
  final bool Function()? callsWantCamera;

  /// How long a request the room could not take yet (`attach_failed`) waits
  /// before it is asked again.
  final Duration retryDelay;

  final SerialQueue _operations = SerialQueue();

  final _Side _subscriber = _Side(ConferenceVideoPc.subscriber);
  final _Side _publisher = _Side(ConferenceVideoPc.publisher);

  /// The camera stream the publisher sends; it also holds a reference to the
  /// shared microphone, given back with it.
  MediaStream? _camera;

  /// Whether the shared camera track was on before the room took it, so that
  /// a call that had it off gets it back off.
  bool _cameraWasEnabled = true;

  /// Whether this client means to publish its camera, kept across a failed or
  /// restarted publisher so that it can be put back.
  bool _publishing = false;

  /// Which camera the owner asked for, kept for a publication made again.
  bool? _frontCamera;

  /// How many times in a row the room let a connection go - refused it,
  /// failed it, or could not take it yet; reset by an answer. One retry each,
  /// then the owner is left without that connection.
  int _publisherFailures = 0;
  int _subscriberFailures = 0;
  static const _retries = 1;

  /// Retries waiting for [retryDelay]; cancelled when the video is left.
  final Set<Timer> _pendingRetries = {};

  /// The session id of the subscriber's remote description (the `o=` line):
  /// a new one is a new subscription, for a new connection.
  String? _subscriberSession;

  /// Remote tracks by the `mid` of their m-line on the subscriber connection.
  final Map<String, MediaStream> _streamsByMid = {};

  /// What the room last said each `mid` carries.
  List<ConferenceVideoStream> _roomStreams = const [];

  /// The camera stream being published, for the owner's own tile.
  MediaStream? get camera => _camera;

  /// The camera track being published; the same track a video call of this
  /// client sends, since the camera is opened once and shared.
  MediaStreamTrack? get cameraTrack => _camera?.getVideoTracks().firstOrNull;

  /// Switches the published camera between the front and the rear, on the
  /// same publication. Returns whether the front one is in use now, `null`
  /// when nothing is published. The track is shared with the calls that send
  /// video, so their camera switches with it.
  Future<bool?> switchCamera() {
    return _operations.run(() async {
      final track = cameraTrack;
      if (track == null) return null;
      final front = await Helper.switchCamera(track);
      _frontCamera = front;
      return front;
    });
  }

  /// Whether the camera is published or on its way to it.
  bool get isPublishing => _publishing;

  /// Whether a subscription is up or asked for. Set and cleared as the owner
  /// asks, ahead of the queue, so that what is asked next sees it.
  bool get isSubscribed => _subscriber.requested;

  /// Asks the room for everyone else's video, from scratch: the subscriber
  /// connection there is is closed first, and the next offer gets a new one.
  /// Returns whether Core took the request.
  Future<bool> subscribe() {
    _subscriber.requested = true;
    _subscriberFailures = 0;
    return _operations.run(_subscribe);
  }

  Future<bool> _subscribe() async {
    if (!_subscriber.requested) return false;
    await _closeSide(_subscriber);
    var result = await _send(ConferenceVideoSubscribeRequest(transaction: _transaction()));
    if (result.outcome == ConferenceRequestOutcome.unanswered) {
      // It may have been taken; a subscribe remakes the subscription from
      // scratch (protocol section 18.2), so asking again is safe either way.
      result = await _send(ConferenceVideoSubscribeRequest(transaction: _transaction()));
    }
    switch (result.outcome) {
      case ConferenceRequestOutcome.taken:
        _acknowledge(_subscriber);
        return true;
      case ConferenceRequestOutcome.unanswered:
      case ConferenceRequestOutcome.notSent:
        // Still wanted: an offer that comes is answered, and a reconnect of
        // the session asks again.
        _logger.warning('subscribe: ${result.outcome.name}, kept for the next offer or reconnect');
        return false;
      case ConferenceRequestOutcome.refused:
        _onSubscriberRefused(result.reason);
        return false;
    }
  }

  /// Answers a `conference_video_offer` on the subscriber connection.
  Future<void> handleOffer(Map<String, dynamic> jsep) {
    return _operations.run(() async {
      if (!_subscriber.requested) {
        // An offer nobody asked for since the session was left: answering it
        // would rejoin the room's video behind the owner's back.
        _logger.info('handleOffer: not subscribed, ignored');
        return;
      }
      final sdp = jsep['sdp'] as String?;
      final session = _sdpSession(sdp);
      var peerConnection = _subscriber.peerConnection;
      // A new subscription - the one Core offers unasked after Janus hung the
      // subscriber up - comes with a new session id, and its connection state
      // tells only later.
      final newSubscription = session != null && _subscriberSession != null && session != _subscriberSession;
      // The offer of a restart this client asked for is answered on the same
      // connection even if its ICE has failed: the restart is the remedy.
      final restartOffer =
          _subscriber.restarting &&
          !newSubscription &&
          peerConnection != null &&
          peerConnection.connectionState != RTCPeerConnectionState.RTCPeerConnectionStateClosed;
      _subscriber.restarting = false;
      if (peerConnection == null || newSubscription || !(restartOffer || peerConnection.isUsable)) {
        // Candidates that came with no connection at all are this offer's,
        // ahead of it; those of a spent connection went with it.
        final ahead = peerConnection == null ? List.of(_subscriber.pendingRemote) : const <RTCIceCandidate>[];
        if (peerConnection != null) {
          // The streams of a new subscription are numbered anew; what the
          // room said of the old ones does not name them. Core sends the new
          // list right after its offer.
          _roomStreams = const [];
        }
        await _closeSide(_subscriber);
        _subscriber.pendingRemote.addAll(ahead);
        peerConnection = await _openSubscriber();
      }
      await peerConnection.setRemoteDescription(RTCSessionDescription(sdp, jsep['type'] as String?));
      _subscriber.remoteDescribed = true;
      _subscriberSession = session;
      await _feedRemoteCandidates(_subscriber);
      final answer = await peerConnection.createAnswer({});
      await peerConnection.setLocalDescription(answer);
      final result = await _send(ConferenceVideoAnswerRequest(transaction: _transaction(), jsep: answer.toMap()));
      switch (result.outcome) {
        case ConferenceRequestOutcome.taken:
        case ConferenceRequestOutcome.unanswered:
          // The answer is what makes Core's connection; candidates gathered
          // before it may go now. One that went unanswered may have been
          // taken: the candidates go all the same, refused at worst, rather
          // than wait for an acknowledgement that will not come.
          _acknowledge(_subscriber);
          if (_subscriber.trickleRefused) _resendCandidates(_subscriber);
        case ConferenceRequestOutcome.refused:
          _onSubscriberRefused(result.reason);
        case ConferenceRequestOutcome.notSent:
          _logger.warning('handleOffer: the answer was not sent');
      }
    });
  }

  /// Asks the room for an ICE restart of the subscriber connection; the offer
  /// that follows is answered on the same connection.
  Future<bool> restartSubscriber() {
    return _operations.run(() async {
      if (!_subscriber.requested) return false;
      final result = await _send(ConferenceVideoRestartRequest(transaction: _transaction()));
      if (result.outcome == ConferenceRequestOutcome.refused) _onSubscriberRefused(result.reason);
      if (result.outcome != ConferenceRequestOutcome.taken) return false;
      // The candidates of the new ICE generation wait: the room's for the
      // restart's offer, this client's for its answer to be taken.
      _subscriber.newIceGeneration();
      _subscriber.restarting = true;
      return true;
    });
  }

  /// What a refusal of a subscriber request means (protocol section 10):
  /// `not_subscribed` asks for the subscription again, `attach_failed` asks
  /// again a little later, anything else ends it. Runs on the queue.
  void _onSubscriberRefused(String? reason) {
    _logger.warning('the subscriber request was refused ($reason)');
    if (!_subscriber.requested) return;
    if (_isRetryable(reason) && ++_subscriberFailures <= _retries) {
      if (reason == 'not_subscribed') {
        _inBackground(_subscribe);
      } else {
        _retryLater(_subscribe);
      }
      return;
    }
    _subscriber.requested = false;
    _inBackground(() => _closeSide(_subscriber));
  }

  /// Publishes the camera ([frontCamera] picks which one). Returns whether
  /// Core took the publication; the answer comes later as
  /// [handlePublisherAnswer]. Asked while already publishing, it renegotiates
  /// the same publication (protocol section 18.3).
  Future<bool> publish({bool? frontCamera}) {
    _publishing = true;
    _publisherFailures = 0;
    if (frontCamera != null) _frontCamera = frontCamera;
    return _operations.run(_publish);
  }

  Future<bool> _publish() async {
    if (!_publishing) return false;
    final existing = _publisher.peerConnection;
    if (existing != null && existing.isUsable) return _offer(existing, iceRestart: false, firstOffer: false);
    if (existing != null) {
      // A spent connection Core still holds a publication for: let go of
      // first, so that the room does not report it as a failure of the next.
      await _send(ConferenceVideoUnpublishRequest(transaction: _transaction()));
    }
    await _closeSide(_publisher);
    final RTCPeerConnection peerConnection;
    try {
      peerConnection = await _openPublisher(frontCamera: _frontCamera);
    } catch (e) {
      _logger.warning('publish: the camera or the connection could not be opened', e);
      _publishing = false;
      return false;
    }
    return _offer(peerConnection, iceRestart: false, firstOffer: true);
  }

  /// Restarts ICE on the publisher connection: a new offer through a new
  /// `conference_video_publish`, the same publication.
  Future<bool> restartPublisher() {
    return _operations.run(_restartPublisher);
  }

  Future<bool> _restartPublisher() async {
    final peerConnection = _publisher.peerConnection;
    if (!_publishing || peerConnection == null) return false;
    return _offer(peerConnection, iceRestart: true, firstOffer: false);
  }

  Future<bool> _offer(RTCPeerConnection peerConnection, {required bool iceRestart, required bool firstOffer}) async {
    // The candidates of a new ICE generation wait: Core's for its answer,
    // this client's for the publish that carries the new credentials.
    if (iceRestart) _publisher.newIceGeneration();
    final RTCSessionDescription offer;
    final List<ConferenceVideoDescription> descriptions;
    try {
      offer = await peerConnection.createOffer({if (iceRestart) 'iceRestart': true});
      await peerConnection.setLocalDescription(offer);
      _publisher.offerPending = true;
      descriptions = await _cameraDescriptions(peerConnection);
    } catch (e) {
      _logger.warning('publish: the offer could not be made', e);
      if (firstOffer) {
        _publishing = false;
        await _closeSide(_publisher);
      }
      return false;
    }
    ConferenceVideoPublishRequest request() =>
        ConferenceVideoPublishRequest(transaction: _transaction(), jsep: offer.toMap(), descriptions: descriptions);
    var result = await _send(request());
    if (result.outcome == ConferenceRequestOutcome.unanswered) {
      // It may have been taken; the same offer again either makes the
      // publication or renegotiates it with nothing changed.
      result = await _send(request());
    }
    switch (result.outcome) {
      case ConferenceRequestOutcome.taken:
        _acknowledge(_publisher);
        return true;
      case ConferenceRequestOutcome.unanswered:
        _logger.warning('publish: unanswered twice');
        if (firstOffer) {
          // Core may hold a publication this client no longer backs: undone
          // first, so that it is not left behind.
          await _send(ConferenceVideoUnpublishRequest(transaction: _transaction()));
          _publishing = false;
          await _closeSide(_publisher);
        }
        return false;
      case ConferenceRequestOutcome.notSent:
        // The session went: still wanted, made again on reconnect.
        _logger.warning('publish: not sent, kept for the reconnect');
        if (firstOffer) await _closeSide(_publisher);
        return false;
      case ConferenceRequestOutcome.refused:
        // The reason decides, for a first publication and for one being
        // renegotiated alike: the room has no place for the connection.
        _logger.warning('publish: refused (${result.reason})');
        await _closeSide(_publisher);
        _onPublisherRefused(result.reason);
        return false;
    }
  }

  /// What a refusal of the publication means (protocol section 10):
  /// `attach_failed` publishes again a little later, anything else leaves the
  /// camera unpublished. Runs on the queue, the publisher already closed.
  void _onPublisherRefused(String? reason) {
    if (!_publishing) return;
    if (_isRetryable(reason) && ++_publisherFailures <= _retries) {
      _retryLater(_publish);
      return;
    }
    _publishing = false;
  }

  /// Applies a `conference_video_publisher_answer`.
  Future<void> handlePublisherAnswer(Map<String, dynamic> jsep) {
    return _operations.run(() async {
      final peerConnection = _publisher.peerConnection;
      if (peerConnection == null) {
        _logger.info('handlePublisherAnswer: nothing published, ignored');
        return;
      }
      if (!_publisher.offerPending) {
        // A publish sent twice after going unanswered may be answered twice.
        _logger.info('handlePublisherAnswer: no offer waits for an answer, ignored');
        return;
      }
      _publisher.offerPending = false;
      await peerConnection.setRemoteDescription(RTCSessionDescription(jsep['sdp'] as String?, jsep['type'] as String?));
      _publisher.remoteDescribed = true;
      _publisherFailures = 0;
      await _feedRemoteCandidates(_publisher);
      if (_publisher.trickleRefused) _resendCandidates(_publisher);
    });
  }

  /// Stops sending the camera: `conference_video_unpublish` first, then the
  /// connection is closed - in that order, so that the room does not report
  /// the closed connection as a failure.
  Future<void> unpublish() {
    _publishing = false;
    _publisherFailures = 0;
    return _operations.run(() async {
      if (_publisher.peerConnection == null) return;
      await _send(ConferenceVideoUnpublishRequest(transaction: _transaction()));
      await _closeSide(_publisher);
    });
  }

  /// Feeds a candidate from the room to the connection [pc] names; `null` is
  /// the end of its gathering. One ahead of its connection's remote
  /// description waits for it.
  Future<void> handleRemoteCandidate(ConferenceVideoPc pc, Map<String, dynamic>? candidate) {
    if (candidate == null) return Future<void>.value();
    final side = _side(pc);
    return _operations.run(() async {
      final rtcCandidate = RTCIceCandidate(
        candidate['candidate'] as String?,
        candidate['sdpMid'] as String?,
        candidate['sdpMLineIndex'] as int?,
      );
      final peerConnection = side.peerConnection;
      if (peerConnection == null || !side.remoteDescribed) {
        side.pendingRemote.add(rtcCandidate);
        return;
      }
      await _addCandidate(side, peerConnection, rtcCandidate);
    });
  }

  /// The room dropped the connection [pc] names (`conference_video_failed`).
  /// Core has let go of that handle, so the connection is closed and made
  /// again once in a row - a room that fails it again (the 100 publishers of
  /// `code` 432 among the reasons) leaves that connection gone.
  Future<void> handleFailed(ConferenceVideoPc pc, {int? code}) {
    return _operations.run(() async {
      switch (pc) {
        case ConferenceVideoPc.subscriber:
          await _closeSide(_subscriber);
          if (!_subscriber.requested) return;
          if (++_subscriberFailures > _retries) {
            _logger.warning('handleFailed: the room failed the subscriber again (code $code), left unsubscribed');
            _subscriber.requested = false;
            return;
          }
          // Nothing resubscribes until the next feed change otherwise
          // (protocol section 18.2).
          await _subscribe();
        case ConferenceVideoPc.publisher:
          await _closeSide(_publisher);
          if (!_publishing) return;
          if (++_publisherFailures > _retries) {
            _logger.warning('handleFailed: the room refused the camera again (code $code), left unpublished');
            _publishing = false;
            return;
          }
          await _publish();
      }
    });
  }

  /// The host's controller refused a request this client sent as an invited
  /// far end (`conference_video_failed` naming the request, protocol section
  /// 19). Its own controller had taken it, so nothing else will come; the
  /// reason says what to do (protocol section 10): `not_subscribed` asks for
  /// the subscription again, `attach_failed` asks again a little later, and
  /// the rest (`not_in_conference` among them) ends that connection. A
  /// request that belongs to neither connection is ignored.
  Future<void> handleRefused(String request, {required String reason}) {
    final pc = switch (request) {
      'conference_video_subscribe' ||
      'conference_video_answer' ||
      'conference_video_restart' => ConferenceVideoPc.subscriber,
      'conference_video_publish' => ConferenceVideoPc.publisher,
      _ => null,
    };
    if (request == 'conference_video_ice_trickle') {
      // The event does not say whose candidate it was. An invited far end's
      // candidates go on its own controller's word, which may be ahead of
      // the host's making the connection: they are sent once more when the
      // connection is known to be there.
      _logger.warning('handleRefused: a candidate was refused ($reason)');
      return _operations.run(() async {
        for (final side in [_subscriber, _publisher]) {
          if (side.peerConnection == null || side.resent) continue;
          side.trickleRefused = true;
          if (side.remoteDescribed) _resendCandidates(side);
        }
      });
    }
    if (pc == null) {
      _logger.info('handleRefused: $request refused ($reason), nothing to close');
      return Future<void>.value();
    }
    _logger.warning('handleRefused: $request refused ($reason)');
    return _operations.run(() async {
      switch (pc) {
        case ConferenceVideoPc.subscriber:
          _onSubscriberRefused(reason);
        case ConferenceVideoPc.publisher:
          await _closeSide(_publisher);
          _onPublisherRefused(reason);
      }
    });
  }

  /// Takes what the room says each stream carries
  /// (`conference_video_updated`).
  void handleUpdated(ConferenceVideoUpdatedEvent event) {
    _roomStreams = event.streams;
    _reportFeeds();
  }

  /// The signalling session came back: events sent while it was down are
  /// lost and the video is not in the handshake, so the subscription is made
  /// again from scratch and the publisher restarts ICE - or is published
  /// again, where the session went before it was.
  Future<void> reconnected() async {
    if (_subscriber.requested) await subscribe();
    if (_publishing) {
      await _operations.run(() => _publisher.peerConnection == null ? _publish() : _restartPublisher());
    }
  }

  /// Stops publishing and receiving (`conference_video_leave`) and closes both
  /// connections. The participant stays in the audio conference.
  Future<void> leave() {
    final wasActive = _subscriber.requested || _publishing;
    _stopWanting();
    return _operations.run(() async {
      if (wasActive) await _send(ConferenceVideoLeaveRequest(transaction: _transaction()));
      await _closeAll();
    });
  }

  /// Closes both connections without telling the room: the conference is over
  /// or the session has gone with it.
  Future<void> teardown() {
    _stopWanting();
    return _operations.run(_closeAll);
  }

  /// The owner wants no video any more: said at once, so that what is queued
  /// behind it - a retry, a resubscribe - finds nothing to make again.
  void _stopWanting() {
    _publishing = false;
    _subscriber.requested = false;
    for (final timer in _pendingRetries) {
      timer.cancel();
    }
    _pendingRetries.clear();
  }

  Future<void> _closeAll() async {
    await _closeSide(_subscriber);
    await _closeSide(_publisher);
    _roomStreams = const [];
    _publisherFailures = 0;
    _subscriberFailures = 0;
  }

  /// Runs [retry] on the queue after [retryDelay], unless the video is left
  /// first.
  void _retryLater(Future<Object?> Function() retry) {
    late final Timer timer;
    timer = Timer(retryDelay, () {
      _pendingRetries.remove(timer);
      _inBackground(retry);
    });
    _pendingRetries.add(timer);
  }

  /// Queues [operation] with nobody waiting for it: what it throws is
  /// logged here rather than left to the zone.
  void _inBackground(Future<Object?> Function() operation) {
    unawaited(
      _operations.run(operation).then<void>((_) {}).catchError((Object e) {
        _logger.warning('a queued operation failed', e);
      }),
    );
  }

  static bool _isRetryable(String? reason) =>
      reason == 'not_subscribed' || (reason != null && reason.startsWith('attach_failed'));

  Future<RTCPeerConnection> _openSubscriber() async {
    final peerConnection = await _factory.create();
    _wire(_subscriber, peerConnection);
    peerConnection.onTrack = (event) {
      if (!identical(_subscriber.peerConnection, peerConnection)) return;
      final mid = event.transceiver?.mid;
      final stream = event.streams.isEmpty ? null : event.streams.first;
      if (mid == null || stream == null || event.track.kind != 'video') return;
      _streamsByMid[mid] = stream;
      _reportFeeds();
    };
    // Connected is what says the subscription works; an acknowledged answer
    // does not, as an invited far end's own controller acknowledges ahead of
    // the host's.
    peerConnection.onConnectionState = (state) {
      if (!identical(_subscriber.peerConnection, peerConnection)) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) _subscriberFailures = 0;
    };
    _subscriber.peerConnection = peerConnection;
    return peerConnection;
  }

  Future<RTCPeerConnection> _openPublisher({bool? frontCamera}) async {
    final peerConnection = await _factory.create();
    try {
      final camera = await _userMediaBuilder.build(video: true, frontCamera: frontCamera);
      _camera = camera;
      final videoTracks = camera.getVideoTracks();
      if (videoTracks.isEmpty) throw StateError('no camera track');
      // The track is shared with the calls that send video; one of them may
      // have it turned off, and the room was asked for the camera. It goes
      // back as it was when the room lets it go.
      _cameraWasEnabled = videoTracks.first.enabled;
      videoTracks.first.enabled = true;
      // Video only: the microphone in this stream belongs to the mixer.
      await peerConnection.addTrack(videoTracks.first, camera);
      for (final transceiver in await peerConnection.getTransceivers()) {
        await transceiver.setDirection(TransceiverDirection.SendOnly);
      }
      _wire(_publisher, peerConnection);
      _publisher.peerConnection = peerConnection;
      _reportFeeds();
      return peerConnection;
    } catch (e) {
      _publisher.peerConnection = peerConnection;
      await _closeSide(_publisher);
      rethrow;
    }
  }

  /// The camera's m-line, named for Core; read after the local description,
  /// when the transceivers have their `mid`.
  Future<List<ConferenceVideoDescription>> _cameraDescriptions(RTCPeerConnection peerConnection) async {
    final descriptions = <ConferenceVideoDescription>[];
    for (final transceiver in await peerConnection.getTransceivers()) {
      final mid = transceiver.mid;
      if (mid.isEmpty) continue;
      descriptions.add(ConferenceVideoDescription(mid: mid, kind: ConferenceVideoKind.camera));
    }
    return descriptions;
  }

  /// Local candidates go out tagged with the connection, after Core has
  /// acknowledged it; earlier ones wait. Guarded by identity: a callback on
  /// its way when the connection was closed must not trickle into the next.
  void _wire(_Side side, RTCPeerConnection peerConnection) {
    peerConnection.onIceCandidate = (candidate) {
      if (identical(side.peerConnection, peerConnection)) _localCandidate(side, candidate);
    };
    peerConnection.onIceGatheringState = (state) {
      if (state != RTCIceGatheringState.RTCIceGatheringStateComplete) return;
      if (identical(side.peerConnection, peerConnection)) _localCandidate(side, null);
    };
  }

  void _localCandidate(_Side side, RTCIceCandidate? candidate) {
    if (!side.acknowledged) {
      side.pendingLocal.add(candidate);
      return;
    }
    unawaited(_trickle(side, candidate));
  }

  /// Core took the request behind [side]: the candidates waiting for it go
  /// out, in the order they were gathered and all at once, so that one
  /// gathered meanwhile - the end of gathering among them - cannot pass them.
  void _acknowledge(_Side side) {
    final pending = List.of(side.pendingLocal);
    side.pendingLocal.clear();
    side.acknowledged = true;
    for (final candidate in pending) {
      unawaited(_trickle(side, candidate));
    }
  }

  Future<void> _trickle(_Side side, RTCIceCandidate? candidate, {bool again = false}) async {
    if (!again) side.sentLocal.add(candidate);
    await _send(
      ConferenceVideoIceTrickleRequest(transaction: _transaction(), pc: side.pc, candidate: candidate?.toMap()),
    );
  }

  /// Sends the candidates of [side] once more, once per connection: some of
  /// them were refused for a connection that was not there yet.
  void _resendCandidates(_Side side) {
    side.trickleRefused = false;
    side.resent = true;
    for (final candidate in List.of(side.sentLocal)) {
      unawaited(_trickle(side, candidate, again: true));
    }
  }

  Future<void> _feedRemoteCandidates(_Side side) async {
    final peerConnection = side.peerConnection;
    if (peerConnection == null) return;
    final pending = List.of(side.pendingRemote);
    side.pendingRemote.clear();
    for (final candidate in pending) {
      await _addCandidate(side, peerConnection, candidate);
    }
  }

  /// A candidate the connection does not take - one of an earlier ICE
  /// generation - is let go rather than thrown at the caller.
  Future<void> _addCandidate(_Side side, RTCPeerConnection peerConnection, RTCIceCandidate candidate) async {
    try {
      await peerConnection.addCandidate(candidate);
    } catch (e) {
      _logger.warning('a ${side.pc.value} candidate was not taken', e);
    }
  }

  Future<void> _closeSide(_Side side) async {
    final peerConnection = side.peerConnection;
    side.reset();
    if (side.pc == ConferenceVideoPc.subscriber) {
      _subscriberSession = null;
      final hadStreams = _streamsByMid.isNotEmpty;
      _streamsByMid.clear();
      if (hadStreams) _reportFeeds();
    }
    if (peerConnection != null) {
      peerConnection.onIceCandidate = null;
      peerConnection.onIceGatheringState = null;
      peerConnection.onConnectionState = null;
      peerConnection.onTrack = null;
      try {
        await peerConnection.close();
        await peerConnection.dispose();
      } catch (e) {
        _logger.warning('closing the ${side.pc.value} connection failed', e);
      }
    }
    if (side.pc == ConferenceVideoPc.publisher) {
      final camera = _camera;
      _camera = null;
      if (camera != null) {
        // The shared track goes back as the calls want it now, or as the
        // room found it where nobody says.
        final enabled = callsWantCamera?.call() ?? _cameraWasEnabled;
        if (!enabled) camera.getVideoTracks().firstOrNull?.enabled = false;
        _cameraWasEnabled = true;
        _reportFeeds();
        try {
          await _userMediaBuilder.release(camera);
        } catch (e) {
          _logger.warning('releasing the camera failed', e);
        }
      }
    }
  }

  /// The streams received so far, named by the participant the room says each
  /// carries. A stream the room has not named yet, or one it no longer lists,
  /// is left out.
  void _reportFeeds() {
    final feeds = <ConferenceVideoFeed>[];
    for (final roomStream in _roomStreams) {
      final stream = _streamsByMid[roomStream.mid];
      if (stream == null) continue;
      feeds.add(ConferenceVideoFeed(feed: roomStream.feed, kind: roomStream.kind, stream: stream));
    }
    onFeedsChanged(List.unmodifiable(feeds));
  }

  _Side _side(ConferenceVideoPc pc) => switch (pc) {
    ConferenceVideoPc.subscriber => _subscriber,
    ConferenceVideoPc.publisher => _publisher,
  };

  static String _transaction() => WebtritSignalingClient.generateTransactionId();

  /// The session id of an SDP's `o=` line, `null` without one.
  static String? _sdpSession(String? sdp) {
    if (sdp == null) return null;
    final match = RegExp(r'^o=\S+ (\S+) ', multiLine: true).firstMatch(sdp);
    return match?.group(1);
  }
}

/// What one of the two connections holds besides itself.
class _Side {
  _Side(this.pc);

  final ConferenceVideoPc pc;
  RTCPeerConnection? peerConnection;

  /// Whether Core took the request behind this connection, so its candidates
  /// may go.
  bool acknowledged = false;

  /// For the subscriber: whether this client wants the room's video at all.
  /// Outlives the connection: an unasked offer for a new one still belongs to
  /// the subscription.
  bool requested = false;

  bool remoteDescribed = false;

  /// For the subscriber: an ICE restart was asked for and its offer is due.
  bool restarting = false;

  /// For the publisher: an offer of this client waits for its answer.
  bool offerPending = false;

  final List<RTCIceCandidate?> pendingLocal = [];
  final List<RTCIceCandidate> pendingRemote = [];

  /// The local candidates sent for this connection's ICE generation, kept to
  /// send once more if some were refused ([trickleRefused]); [resent] once
  /// that was done.
  final List<RTCIceCandidate?> sentLocal = [];
  bool trickleRefused = false;
  bool resent = false;

  /// An ICE restart: the candidates of both ends start over and wait again,
  /// the remote ones for the description, the local ones for the request
  /// that carries the new credentials to be taken.
  void newIceGeneration() {
    acknowledged = false;
    remoteDescribed = false;
    sentLocal.clear();
    trickleRefused = false;
    resent = false;
  }

  void reset() {
    peerConnection = null;
    restarting = false;
    offerPending = false;
    pendingLocal.clear();
    pendingRemote.clear();
    newIceGeneration();
  }
}
