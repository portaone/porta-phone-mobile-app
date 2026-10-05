part of 'call_bloc.dart';

/// Turns a signaling event into the bloc event that carries it, field by
/// field, and logs it as it passes.
///
/// Null for an event the bloc has nothing to do with; the log line says which
/// and why. The families the signaling package seals - peer messages,
/// notifies, global events - are switched over without a default, so a new
/// member of one does not compile until it is mapped here.
///
/// The name of the event in a log line is written out, not taken from
/// `runtimeType`: that one stops being readable in an obfuscated build.
extension _SignalingEventMapping on Event {
  /// [activeCalls] are the calls the bloc has now: an event that names a line
  /// and not a call is matched to the call on that line.
  CallEvent? toCallEvent({required List<ActiveCall> activeCalls}) {
    final event = this;
    switch (event) {
      // A call from its first ring to its end.
      case IncomingCallEvent():
        _logger.info(
          'toCallEvent: IncomingCallEvent callId=${event.callId} caller=${event.caller} callee=${event.callee}',
        );
        return _IncomingCallEventMapping(event).toCallEvent();
      case RingingEvent():
        _logger.info('toCallEvent: RingingEvent');
        return _CallSignalingEvent.ringing(line: event.line, callId: event.callId);
      case ProceedingEvent():
        _logger.info('toCallEvent: ProceedingEvent');
        return _CallSignalingEvent.proceeding(line: event.line, callId: event.callId, code: event.code);
      case ProgressEvent():
        _logger.info('toCallEvent: ProgressEvent');
        return _CallSignalingEvent.progress(
          line: event.line,
          callId: event.callId,
          callee: event.callee,
          jsep: JsepValue.fromOptional(event.jsep),
        );
      case AcceptedEvent():
        _logger.info('toCallEvent: AcceptedEvent');
        return _CallSignalingEvent.accepted(
          line: event.line,
          callId: event.callId,
          callee: event.callee,
          jsep: JsepValue.fromOptional(event.jsep),
        );
      case HangupEvent():
        _logger.info('toCallEvent: HangupEvent callId=${event.callId} code=${event.code} reason="${event.reason}"');
        return _CallSignalingEvent.hangup(
          line: event.line,
          callId: event.callId,
          code: event.code,
          reason: event.reason,
        );
      case CallErrorEvent():
        _logger.info('toCallEvent: CallErrorEvent');
        return _CallSignalingEvent.callError(
          line: event.line,
          callId: event.callId,
          code: event.code,
          reason: event.reason,
        );

      // A change of media in a call that is up: the far end's offer and the
      // server's replies to ours.
      case UpdatingCallEvent():
        _logger.info('toCallEvent: UpdatingCallEvent');
        return _CallSignalingEvent.callUpdating(
          line: event.line,
          callId: event.callId,
          callee: event.callee,
          caller: event.caller,
          callerDisplayName: event.callerDisplayName,
          referredBy: event.referredBy,
          replaceCallId: event.replaceCallId,
          isFocus: event.isFocus,
          jsep: JsepValue.fromOptional(event.jsep),
        );
      case UpdatingEvent():
        _logger.info('toCallEvent: UpdatingEvent');
        return _CallSignalingEvent.updating(line: event.line, callId: event.callId);
      case UpdatedEvent():
        _logger.info('toCallEvent: UpdatedEvent');
        return _CallSignalingEvent.updated(line: event.line, callId: event.callId);

      // What the other party's app says about itself during a call. Sealed:
      // no default. A message of an unknown type has no bloc event.
      case PeerMessageEvent():
        switch (event) {
          case MediaStatePeerMessageEvent():
            _logger.info('toCallEvent: MediaStatePeerMessageEvent');
            return _CallSignalingEvent.peerMediaState(line: event.line, callId: event.callId, video: event.video);
          case ConferenceMutePeerMessageEvent():
            _logger.info('toCallEvent: ConferenceMutePeerMessageEvent');
            return _CallSignalingEvent.peerConferenceMute(line: event.line, callId: event.callId, muted: event.muted);
          case ConferenceHostAwayPeerMessageEvent():
            _logger.info('toCallEvent: ConferenceHostAwayPeerMessageEvent');
            return _CallSignalingEvent.peerConferenceHostAway(line: event.line, callId: event.callId, away: event.away);
          case UnknownPeerMessageEvent():
            _logger.info('toCallEvent: UnknownPeerMessageEvent type="${event.type}" - ignored');
            return null;
        }

      // A transfer: the request to be transferred and the progress of one we
      // asked for.
      case TransferEvent():
        _logger.info('toCallEvent: TransferEvent');
        return _CallSignalingEvent.transfer(
          line: event.line,
          referId: event.referId,
          referTo: event.referTo,
          referredBy: event.referredBy,
          replaceCallId: event.replaceCallId,
        );
      case TransferringEvent():
        _logger.info('toCallEvent: TransferringEvent');
        return _CallSignalingEvent.transferring(line: event.line, callId: event.callId);
      case TransferAcceptedEvent():
        _logger.info('toCallEvent: TransferAcceptedEvent');
        return _CallSignalingEvent.transferAccepted(line: event.line, callId: event.callId);
      case TransferFailedEvent():
        _logger.info('toCallEvent: TransferFailedEvent');
        return _CallSignalingEvent.transferFailed(line: event.line, callId: event.callId, code: event.code);

      // A SIP NOTIFY within a call. Sealed: no default.
      case NotifyEvent():
        switch (event) {
          case ReferNotifyEvent():
            _logger.info('toCallEvent: ReferNotifyEvent');
            return _CallSignalingEvent.notifyRefer(
              line: event.line,
              callId: event.callId,
              notify: event.notify,
              subscriptionState: event.subscriptionState,
              state: event.state,
            );
          case UnknownNotifyEvent():
            _logger.info('toCallEvent: UnknownNotifyEvent');
            return _CallSignalingEvent.notifyUnknown(
              line: event.line,
              callId: event.callId,
              notify: event.notify,
              subscriptionState: event.subscriptionState,
              contentType: event.contentType,
              content: event.content,
            );
        }

      // The state of the account's SIP registration.
      case RegisteringEvent():
        _logger.info('toCallEvent: RegisteringEvent');
        return const _CallSignalingEvent.registration(RegistrationStatus.registering);
      case RegisteredEvent():
        _logger.info('toCallEvent: RegisteredEvent');
        return const _CallSignalingEvent.registration(RegistrationStatus.registered);
      case RegistrationFailedEvent():
        _logger.info('toCallEvent: RegistrationFailedEvent');
        return _CallSignalingEvent.registration(
          RegistrationStatus.registration_failed,
          code: event.code,
          reason: event.reason,
        );
      case UnregisteringEvent():
        _logger.info('toCallEvent: UnregisteringEvent');
        return const _CallSignalingEvent.registration(RegistrationStatus.unregistering);
      case UnregisteredEvent():
        _logger.info('toCallEvent: UnregisteredEvent');
        return const _CallSignalingEvent.registration(RegistrationStatus.unregistered);

      // Presence and dialogs of the numbers the account watches. Sealed: no
      // default.
      case GlobalEvent():
        switch (event) {
          case NumberPresenceUpdate():
            _logger.info('toCallEvent: NumberPresenceUpdate');
            return _GlobalEvent.numberPresenceUpdate(number: event.number, presenceInfo: event.presenceInfo);
          case NumberDialogsUpdate():
            _logger.info('toCallEvent: NumberDialogsUpdate');
            return _GlobalEvent.numberDialogsUpdate(number: event.number, dialogInfos: event.dialogInfos);
        }

      // The conference room the account hosts or sits in.
      case ConferenceOfferEvent():
        _logger.info('toCallEvent: ConferenceOfferEvent');
        return _CallMutationEvent.conferenceOffer(
          room: event.room,
          jsep: JsepValue(event.jsep),
          participants: event.participants,
        );
      case ConferenceIceTrickleEvent():
        _logger.info('toCallEvent: ConferenceIceTrickleEvent');
        return _CallMutationEvent.conferenceRemoteCandidate(event.candidate?.toIceCandidate());
      case ConferenceUpdatedEvent():
        _logger.info('toCallEvent: ConferenceUpdatedEvent');
        return _CallMutationEvent.conferenceUpdated(room: event.room, participants: event.participants);
      case ConferenceFailedEvent():
        _logger.info('toCallEvent: ConferenceFailedEvent');
        return _CallMutationEvent.conferenceFailed(room: event.room, reason: event.reason, detail: event.detail);
      case ConferenceTerminatedEvent():
        _logger.info('toCallEvent: ConferenceTerminatedEvent');
        return _CallMutationEvent.conferenceTerminated(room: event.room);

      // Media quality of a line.
      case IceSlowLinkEvent():
        final call = activeCalls.firstWhereOrNull((call) => call.line == event.line);
        if (call == null) {
          _logger.info('toCallEvent: IceSlowLinkEvent line=${event.line} - no active call');
          return null;
        }
        _logger.info('toCallEvent: IceSlowLinkEvent line=${event.line}');
        return event.toCallEvent(callId: call.callId);

      // Said by the server about a request of ours that is on its way; the
      // bloc waits for what follows.
      case CallingEvent():
        _logger.info('toCallEvent: CallingEvent callId=${event.callId} line=${event.line} - remote is ringing');
        return null;
      case HangingupEvent():
        _logger.info('toCallEvent: HangingupEvent callId=${event.callId} line=${event.line} - hangup in progress');
        return null;
      case IceHangupEvent():
        _logger.info('toCallEvent: IceHangupEvent line=${event.line} reason="${event.reason}"');
        return null;

      default:
        _logger.warning('toCallEvent: unknown event $event - unhandled');
        return null;
    }
  }
}

// The two events below need something the event itself does not carry, so
// each takes it as a parameter.

extension _IncomingCallEventMapping on IncomingCallEvent {
  /// [remoteVideo] is the caller's camera as a log last reported it, which
  /// only a restored call has.
  CallEvent toCallEvent({bool? remoteVideo}) {
    return _CallSignalingEvent.incoming(
      line: line,
      callId: callId,
      callee: callee,
      caller: caller,
      callerDisplayName: callerDisplayName,
      referredBy: referredBy,
      replaceCallId: replaceCallId,
      isFocus: isFocus,
      jsep: JsepValue.fromOptional(jsep),
      remoteVideo: remoteVideo,
    );
  }
}

extension _IceSlowLinkEventMapping on IceSlowLinkEvent {
  /// The event names a line, not a call: [callId] is the call the bloc has
  /// on that line.
  CallEvent toCallEvent({required String callId}) {
    return _CallMutationEvent.slowlinkDetected(
      callId: callId,
      uplink: uplink,
      media: CallMediaKind.values.byName(media.name),
      lost: lost,
    );
  }
}
