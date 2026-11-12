part of 'call_bloc.dart';

/// An offer of the client ready to go: a fresh one, or the kept one that is
/// sent again ([replay]), already installed on the peer connection.
typedef _ClientOfferDraft = ({RTCSessionDescription offer, bool replay});

/// How the server took an offer of the client.
enum _ClientOfferReply {
  /// Taken and done (`updated`).
  completed,

  /// Taken; the answer comes later as an accepted event (`updating`).
  awaitingAnswer,

  /// Refused (a call error): rolled back, or kept for the retry.
  refused,
}

/// The offer of the client, the one way every offer of it is made, sent and
/// settled: a renegotiation of its own, and the offer an update of the far
/// end without one asks for.
extension _ClientOffers on CallBloc {
  /// Makes the offer to send, or takes the kept one that is to be sent again;
  /// null when the peer connection cannot take an offer now.
  ///
  /// The move to the conference codecs decides first: a move whose offer was
  /// answered after all has nothing to send, one whose answer never came is
  /// taken back, and an offer kept from before a move is withdrawn for one on
  /// the conference codecs.
  Future<_ClientOfferDraft?> _draftClientOffer(
    RTCPeerConnection pc,
    String callId,
    Emitter<CallState> emit, {
    required String tag,
  }) async {
    // pc.signalingState is a Dart-side cache populated only after the first
    // native state event. On a freshly created PC the event may not have
    // arrived yet; force a platform round-trip in that case so the guard
    // gets the real native state instead of guessing what null means.
    // A kept offer makes the cache untrustworthy too: it is updated only after
    // setLocalDescription has completed natively, so a reconnect that follows
    // a transport failure quickly can still read stable while the native side
    // is in have-local-offer. Creating another offer then would fail in the
    // wrong state and end the call this replay is meant to keep. An offer
    // whose answer is still awaited is kept as well: no second offer goes
    // over it.
    var pendingOffer = _renegotiationCoordinator.replayableOffer(callId);
    final cachedSigState = pc.signalingState;
    var sigState = (cachedSigState == null || _renegotiationCoordinator.hasKeptOffer(callId))
        ? await pc.getSignalingState()
        : cachedSigState;
    _logger.info('$tag: sigState=$sigState (cache=$cachedSigState)');
    if (_roomCodecs.takeBackSkipped(callId)) {
      _logger.info('$tag: the move\'s offer of $callId was answered after all, nothing to take back');
      return null;
    }
    if (_roomCodecs.takesBack(callId)) {
      // The answer to the move's offer never came. Waiting on stays updating
      // for good; rolled back, the call is usable again, and since the server
      // may have applied the answer that was lost, the two ends are brought
      // back to one description with a fresh offer below. That offer is
      // sendrecv, so a held call is held again once it is answered.
      _logger.warning('$tag: taking back the move\'s offer of $callId, its answer did not come');
      if (await pc.getSignalingState() == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        try {
          await pc.setLocalDescription(RTCSessionDescription('', 'rollback'));
        } catch (er) {
          _logger.warning('$tag: rolling back the move\'s offer of $callId failed: $er');
        }
      }
      _renegotiationCoordinator.offerCompleted(callId);
      _renegotiationCoordinator.updatingSettled(callId);
      emit(_updateSettled(callId));
      if (state.retrieveActiveCall(callId)?.held ?? false) _roomCodecs.holdAfterResync(callId);
      pendingOffer = null;
      sigState = await pc.getSignalingState();
    }
    if (pendingOffer != null && _roomCodecs.withdrawsKeptOffer(callId)) {
      _logger.info('$tag: withdrawing the offer kept for $callId to move it to the conference codecs');
      if (sigState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
        try {
          await pc.setLocalDescription(RTCSessionDescription('', 'rollback'));
        } catch (er) {
          _logger.warning('$tag: rolling back the kept offer of $callId failed: $er');
        }
      }
      _renegotiationCoordinator.offerCompleted(callId);
      pendingOffer = null;
      sigState = await pc.getSignalingState();
    }
    final canReplayPendingOffer = pendingOffer != null && sigState == RTCSignalingState.RTCSignalingStateHaveLocalOffer;
    if (sigState != RTCSignalingState.RTCSignalingStateStable && !canReplayPendingOffer) {
      _logger.fine(() => '$tag: pc signalingState is $sigState, no offer is made');
      return null;
    }
    if (canReplayPendingOffer) return (offer: pendingOffer, replay: true);

    // The constraints of the offer follow the media policy; see _createClientOffer.
    final hasVideo = state.retrieveActiveCall(callId)?.video ?? false;
    return (offer: await _createClientOffer(pc, callId: callId, hasVideo: hasVideo), replay: false);
  }

  /// Installs a fresh offer on the peer connection; a replayed one is
  /// installed already.
  Future<void> _installClientOffer(
    RTCPeerConnection pc,
    String callId,
    _ClientOfferDraft draft, {
    required String sdpTag,
    required String tag,
  }) async {
    if (draft.replay) {
      _logger.info('$tag: replaying the pending local offer for callId=$callId');
      return;
    }
    _logger.infoPretty(draft.offer.sdp, tag: sdpTag);
    await pc.setLocalDescription(draft.offer);
    _roomCodecs.offerSent(callId);
  }

  /// Settles the reply of the server to an offer of the client; throws a
  /// reply that is none of the three.
  Future<_ClientOfferReply> _settleClientOfferReply(
    RTCPeerConnection pc,
    String callId,
    RTCSessionDescription offer,
    Event result,
    Emitter<CallState> emit, {
    required String tag,
  }) async {
    _logger.info('$tag: received response for update request: $result');

    if (result is CallErrorEvent && _roomCodecs.offerFailed(callId, result.code) == RoomOfferError.rollBack) {
      // Sent again it would be turned down again, or move the call for a
      // room nobody waits for: the call goes back to what it had.
      _logger.warning(
        '$tag: the move of $callId to the conference codecs failed: code=${result.code} reason="${result.reason}"',
      );
      try {
        await pc.setLocalDescription(RTCSessionDescription('', 'rollback'));
      } catch (er) {
        _logger.warning('$tag: rolling back the offer of $callId failed: $er');
      }
      _renegotiationCoordinator.offerCompleted(callId);
      emit(_updateSettled(callId));
      return _ClientOfferReply.refused;
    }
    if (result is UpdatedEvent) {
      _renegotiationCoordinator.offerCompleted(callId);
      emit(_updateSettled(callId));
      // Not only during a move: the offer that resyncs a taken-back held
      // call may be answered this way too.
      final stable = await pc.getSignalingState() == RTCSignalingState.RTCSignalingStateStable;
      _roomCodecs.updated(callId, stable: stable);
      return _ClientOfferReply.completed;
    }
    if (result is UpdatingEvent) {
      // Only an interim acknowledgement: the answer comes later through the
      // accepted event, so the offer stays kept until then.
      _renegotiationCoordinator.awaitAnswer(callId, offer);
      emit(state.copyWithMappedActiveCall(callId, (call) => call.copyWith(updating: true)));
      _roomCodecs.acknowledged(callId);
      return _ClientOfferReply.awaitingAnswer;
    }
    if (result is CallErrorEvent) {
      _logger.warning(
        '__onCallSignalingEventCallError: received CallErrorEvent for update request: code=${result.code} reason="${result.reason}"',
      );
      emit(_updateSettled(callId));
      // May help to recover from the error by renegotiating the call again
      // According to sip 491 error resolution spec, randomize the delay before retrying to avoid potential collision
      //
      // The rejected offer is still installed: nothing has answered or rolled
      // it back, so the peer connection stays in have-local-offer and a fresh
      // offer could not be made. The retry sends this same offer again.
      final delaySeconds = 2 + Random().nextInt(8);
      _renegotiationCoordinator.keepOffer(
        callId,
        offer,
        signalingConnected: true,
        retryDelay: Duration(seconds: delaySeconds),
      );
      _logger.info('__onCallSignalingEventCallError: dispatch renegotiation after (delay: $delaySeconds)');
      return _ClientOfferReply.refused;
    }
    throw result;
  }

  /// Answers an update of the far end that carries no offer with an offer of
  /// the client's own.
  ///
  /// The far end re-INVITEd the call without an SDP: it asked for an offer.
  /// Answering it with an offer is what the protocol asks for - the gateway
  /// puts that offer into the 200 OK of the re-INVITE, and the far end's
  /// answer comes back as an accepted event with an answer, which the handler
  /// of that event applies. Answering nothing leaves the re-INVITE without an
  /// answer until the far end gives it up, and the call is dropped.
  ///
  /// The offer is made, sent and settled the way every offer of the client is
  /// (see [_draftClientOffer]); only an offer lost with the signaling differs:
  /// it stays kept and the update owed, for the next session to hand over.
  Future<CallUpdateOutcome> _answerUpdateWithOwnOffer(String callId, Emitter<CallState> emit) async {
    const tag = '__onMutationSignalingCallUpdating';
    final pc = await _callPeerConnectionManager.retrieve(callId);
    if (pc == null) {
      _logger.warning('$tag: peerConnection is null - most likely some state issue');
      return const CallUpdateOutcome(answer: CallUpdateAnswer.notSent);
    }

    // An offer installed with nowhere to send it would leave the connection
    // in have-local-offer with nothing to replay: the update is owed until
    // the handshake of the next session hands it over again.
    if (!_callSignaling.isConnected) {
      _logger.info('$tag: signaling not connected, the offer is not made');
      return CallUpdateOutcome(answer: _answerLost());
    }

    final draft = await _draftClientOffer(pc, callId, emit, tag: tag);
    if (draft == null) return const CallUpdateOutcome(answer: CallUpdateAnswer.notSent);

    // The call may have left, or the signaling gone, while the offer was made.
    final line = state.retrieveActiveCall(callId)?.line;
    if (line == null || line == _kUndefinedLine) {
      _logger.info('$tag: the call is gone or has no line, the offer is not sent');
      return const CallUpdateOutcome(answer: CallUpdateAnswer.notSent);
    }
    if (!_callSignaling.isConnected) {
      _logger.info('$tag: signaling went down while the offer was made, it is not sent');
      return CallUpdateOutcome(answer: _answerLost());
    }

    final offer = draft.offer;
    await _installClientOffer(pc, callId, draft, sdpTag: '$tag created offer SDP', tag: tag);

    // The offer of the client says whether the call stays sendrecv: a call
    // held by its own offer is held again on the far end by it.
    final sendRecv = PulledCallResumer.offersSendRecv(offer.sdp);
    void keepLost() =>
        _renegotiationCoordinator.keepOffer(callId, offer, signalingConnected: _callSignaling.isConnected);

    final transaction = WebtritSignalingClient.generateTransactionId();
    final sentOn = _renegotiationCoordinator.connection;
    final acknowledgement = _callSignaling.execute(
      UpdateRequest(transaction: transaction, line: line, callId: callId, jsep: offer.toMap()),
    );
    if (acknowledgement == null) {
      // The socket went down on the way here. Nothing was sent and nothing
      // will come back for this transaction: the update stays unanswered, and
      // the handshake of the next connection hands it over again.
      _logger.warning('$tag: not connected, the offer was not sent');
      keepLost();
      return CallUpdateOutcome(answer: _answerLost(), sendRecv: sendRecv);
    }
    bool sessionLost() => !_callSignaling.isConnected || _renegotiationCoordinator.connection != sentOn;
    try {
      await acknowledgement;
    } catch (e) {
      if (!_renegotiationCoordinator.isTransientSignalingFailure(e) || !sessionLost()) rethrow;
      _logger.warning('$tag: the offer was lost with the signaling ($e)');
      keepLost();
      return CallUpdateOutcome(answer: _answerLost(), sendRecv: sendRecv);
    }

    final Event result;
    try {
      result = await _callSignaling.response(transaction, timeout: const Duration(seconds: 10));
    } on TimeoutException {
      // No reply because the session that carried the offer is gone: the call
      // is not lost, the update is still owed.
      if (!sessionLost()) rethrow;
      _logger.warning('$tag: the signaling went down before the offer was taken');
      keepLost();
      return CallUpdateOutcome(answer: _answerLost(), sendRecv: sendRecv);
    }

    final reply = await _settleClientOfferReply(pc, callId, offer, result, emit, tag: tag);
    return CallUpdateOutcome(
      answer: reply == _ClientOfferReply.refused ? CallUpdateAnswer.refused : CallUpdateAnswer.acknowledged,
      sendRecv: sendRecv,
    );
  }
}
