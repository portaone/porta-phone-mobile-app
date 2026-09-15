part of 'call_bloc.dart';

@freezed
class CallState with _$CallState {
  const CallState({
    this.callServiceState = const CallServiceState(),
    this.currentAppLifecycleState,
    this.linesCount = 0,
    this.activeCalls = const [],
    this.minimized,
    this.audioDevice,
    this.availableAudioDevices = const [],
    this.selectedCallId,
    this.conference = const ConferenceState(),
  });

  @override
  final CallServiceState callServiceState;

  @override
  final AppLifecycleState? currentAppLifecycleState;

  @override
  final int linesCount;

  @override
  final List<ActiveCall> activeCalls;

  @override
  final bool? minimized;

  @override
  final CallAudioDevice? audioDevice;

  @override
  final List<CallAudioDevice> availableAudioDevices;

  /// The call the user has explicitly focused (e.g. tapped in the call list).
  ///
  /// `null` means no explicit selection - consumers fall back to the derived
  /// [ActiveCallIterableExtension.current]. This is the foundation for the
  /// list-based call screen, where one bottom action area acts on the focused
  /// call. Always read it through [focusedCall], which clamps a stale id back
  /// to `current`.
  @override
  final String? selectedCallId;

  /// The conference room this client hosts; an empty one when there is none.
  @override
  final ConferenceState conference;

  CallStatus get status => callServiceState.status;

  /// Whether [callId] is a leg of the conference room.
  bool isConferenced(String callId) => conference.isLeg(callId);

  /// The active calls that are legs of the room, in list order.
  List<String> get conferencedCallIds => [
    for (final call in activeCalls)
      if (isConferenced(call.callId)) call.callId,
  ];

  /// The accepted calls a merge can take: answered, audio, on a numbered
  /// line (the server names a leg by line), not being transferred, not
  /// already in the room.
  List<String> get mergeableCallIds => [
    for (final call in activeCalls)
      if (call.wasAccepted && !call.video && call.line != null && call.transfer == null && !isConferenced(call.callId))
        call.callId,
  ];

  /// The calls among [callIds] that can join a room, each with its line -
  /// the server names a leg by line.
  Map<String, int> mergeableLegs(Iterable<String> callIds) => {
    for (final call in activeCalls)
      if (callIds.contains(call.callId) && mergeableCallIds.contains(call.callId))
        if (call.line case final int line) call.callId: line,
  };

  /// Whether the Merge control is available: the server supports rooms
  /// ([isConferenceEnabled]), none is up yet, and at least two calls can be
  /// merged. The server accepts a merge of a single line; the app asks for two.
  bool canMerge({required bool isConferenceEnabled}) =>
      isConferenceEnabled && !conference.isPresent && mergeableCallIds.length >= 2;

  /// Whether a call outside the room can be brought into it: the room is
  /// established - while it is still assembling its offer has not arrived and
  /// it is not this client's to add to yet - and at least one call can join.
  /// [mergeableCallIds] already leaves out the legs, so during a room it is
  /// exactly the calls outside it that qualify.
  bool canAdd({required bool isConferenceEnabled}) =>
      isConferenceEnabled && conference.phase == ConferencePhase.active && mergeableCallIds.isNotEmpty;

  /// The calls to put on hold before a new outgoing call is placed: every
  /// call not already held, except the room's legs - they stay in the mix,
  /// and the server would refuse the hold anyway.
  List<String> get callIdsToHoldBeforeOutgoing => [
    for (final call in activeCalls)
      if (!call.held && !isConferenced(call.callId)) call.callId,
  ];

  /// The call the action area should act on: the explicitly [selectedCallId]
  /// when it still maps to a live call, otherwise the derived `current`.
  ///
  /// Returns `null` only when there are no active calls. Behavior is identical
  /// to `activeCalls.current` until something dispatches
  /// [CallControlEvent.callSelected], so this is a no-op seam for existing UI.
  ActiveCall? get focusedCall {
    if (activeCalls.isEmpty) return null;
    final selected = selectedCallId == null ? null : retrieveActiveCall(selectedCallId!);
    return selected ?? _firstLeg ?? activeCalls.current;
  }

  /// With a room up, the call the action area acts on by default is the
  /// room's first leg by line: the legs are what the user is in.
  ActiveCall? get _firstLeg {
    if (!conference.isPresent) return null;
    final legs = activeCalls.where((call) => isConferenced(call.callId)).toList()
      ..sort((a, b) => (a.line ?? 0).compareTo(b.line ?? 0));
    return legs.firstOrNull;
  }

  /// Indicates that the handshake phase has completed and registration status is available.
  bool get isHandshakeEstablished => callServiceState.registration?.status != null;

  /// Indicates that the signaling connection to the server is successfully established.
  bool get isSignalingEstablished => callServiceState.signalingClientStatus.isConnect;

  /// True when every precondition for placing an outgoing call is satisfied:
  ///   - the signaling client is connected;
  ///   - the handshake has been received;
  ///   - the SIP REGISTER has succeeded;
  ///   - the line config has arrived (`linesCount > 0`).
  ///
  /// Used to decide whether a dispatched outgoing call can proceed to INVITE
  /// or must be parked in [CallProcessingStatus.outgoingConnectingToSignaling]
  /// while the missing precondition resolves.
  bool get isReadyForOutgoingCall =>
      isHandshakeEstablished &&
      isSignalingEstablished &&
      callServiceState.registration?.status.isRegistered == true &&
      linesCount > 0;

  /// Computes the [LinesState] that reflects the current lines and active calls.
  ///
  /// Returns [LinesState.blank] when [linesCount] is 0 and the signaling
  /// handshake has not yet been received ([isHandshakeEstablished] is false),
  /// keeping [CallRoutingCubit] in the unready state until server config arrives.
  ///
  /// After the handshake, [linesCount] == 0 is a valid server configuration
  /// (no main lines), so a real [LinesState] is computed to allow guest-line calls.
  LinesState toLinesState() {
    if (linesCount == 0 && !isHandshakeEstablished) return LinesState.blank();

    final List<LineState> mainLinesState = [];
    for (var i = 0; i < linesCount; i++) {
      final lineCall = activeCalls.firstWhereOrNull((e) => e.line == i);
      if (lineCall != null) {
        mainLinesState.add(LineState.inUse(callId: lineCall.callId));
      } else {
        mainLinesState.add(LineState.idle());
      }
    }
    final guestLineCall = activeCalls.firstWhereOrNull((e) => e.line == null);
    final guestLineState = guestLineCall != null ? LineState.inUse(callId: guestLineCall.callId) : LineState.idle();
    return LinesState(mainLines: mainLinesState, guestLine: guestLineState);
  }

  static int? lastUsedLine;

  /// Retrieves an idle line number with rotation
  int? retrieveIdleLine() {
    final linesList = List.generate(linesCount, (index) => index)
      ..sort((a, b) {
        if (a == lastUsedLine) return 1;
        if (b == lastUsedLine) return -1;
        return 0;
      });

    final idleLines = linesList.where((line) => !activeCalls.any((activeCall) => activeCall.line == line));
    final choosenLine = idleLines.firstOrNull;
    if (choosenLine != null) {
      lastUsedLine = choosenLine;
    }
    return choosenLine;
  }

  /// Picks a main line for an outgoing call.
  ///
  /// Three outcomes:
  ///   - real line index when an idle main line is available;
  ///   - [_kUndefinedLine] when `linesCount == 0` (cold start: the signaling
  ///     handshake has not arrived yet, so line config is unknown - the
  ///     caller should park the call and resolve the real line once lines
  ///     are known);
  ///   - `null` when lines are known but all main lines are in use - the
  ///     caller should fail with [GeneralUnableToCallNotification].
  int? pickOutgoingMainLine() {
    final idle = retrieveIdleLine();
    if (idle != null) return idle;
    if (linesCount == 0) return _kUndefinedLine;
    return null;
  }

  CallDisplay get display {
    if (activeCalls.isEmpty) {
      if (minimized == false) {
        return CallDisplay.noneScreen;
      } else {
        return CallDisplay.none;
      }
    } else {
      if (minimized == true) {
        return CallDisplay.overlay;
      } else {
        return CallDisplay.screen;
      }
    }
  }

  bool get isActive => activeCalls.isNotEmpty;

  bool get isVoiceChat => activeCalls.current.video == false;

  bool get isBlingTransferInitiated => activeCalls.blindTransferInitiated != null;

  bool get shouldListenToProximity => isActive && isVoiceChat && minimized != true;

  List<ActiveCall> callsToTerminate(Set<String> activeLineCallIds) {
    final result = <ActiveCall>[];
    for (final activeCall in activeCalls) {
      if (activeLineCallIds.contains(activeCall.callId)) continue;
      if (activeCall.direction == CallDirection.outgoing &&
          activeCall.acceptedTime == null &&
          activeCall.hungUpTime == null &&
          activeCall.processingStatus.isPreOfferSent) {
        continue;
      }
      result.add(activeCall);
    }
    return result;
  }

  ActiveCall? retrieveActiveCall(String callId) {
    for (var activeCall in activeCalls) {
      if (activeCall.callId == callId) {
        return activeCall;
      }
    }
    return null;
  }

  FutureOr<T>? performOnActiveCall<T>(String callId, FutureOr<T>? Function(ActiveCall element) perform) {
    for (var activeCall in activeCalls) {
      if (activeCall.callId == callId) {
        return perform(activeCall);
      }
    }
    return null;
  }

  CallState copyWithMappedActiveCalls(ActiveCall Function(ActiveCall element) map) {
    final activeCalls = this.activeCalls.map(map).toList();
    return copyWith(activeCalls: activeCalls);
  }

  CallState copyWithMappedActiveCall(String callId, ActiveCall Function(ActiveCall element) map) {
    final activeCalls = this.activeCalls.map((activeCall) {
      if (activeCall.callId == callId) {
        return map(activeCall);
      } else {
        return activeCall;
      }
    }).toList();
    return copyWith(activeCalls: activeCalls);
  }

  CallState copyWithPushActiveCall(ActiveCall activeCall) {
    return copyWith(
      activeCalls: [...activeCalls, activeCall],
      // A new ringing incoming call demands a decision, so it grabs the focus;
      // any other call keeps the user's selection.
      selectedCallId: activeCall.isIncoming && !activeCall.wasAccepted ? activeCall.callId : selectedCallId,
    );
  }

  CallState copyWithPopActiveCall(String callId) {
    final activeCalls = this.activeCalls.where((activeCall) {
      return activeCall.callId != callId;
    }).toList();
    // When the focused call ends, prefer the next ringing incoming call (it
    // still demands a decision); otherwise clear so [focusedCall] falls back
    // to `current`. An unrelated selection is kept as is.
    final selectedCallId = this.selectedCallId == callId
        ? activeCalls.firstWhereOrNull((call) => call.isIncoming && !call.wasAccepted)?.callId
        : this.selectedCallId;
    // A leg that ends leaves the room; the server's next list says the same.
    final conference = this.conference.isLeg(callId)
        ? this.conference.copyWith(
            legs: {...this.conference.legs}..remove(callId),
            participants: this.conference.participants.where((participant) => participant.callId != callId).toList(),
          )
        : this.conference;
    return copyWith(
      activeCalls: activeCalls,
      minimized: activeCalls.isEmpty ? null : minimized,
      selectedCallId: selectedCallId,
      conference: conference,
    );
  }

  /// Focuses the call [callId] when it maps to a live call; otherwise returns
  /// the state unchanged. Keeps [selectedCallId] clamped to an existing call.
  CallState copyWithSelectedCall(String callId) {
    if (retrieveActiveCall(callId) == null) return this;
    return copyWith(selectedCallId: callId);
  }

  /// Ids of every active call except [callId] and the room's legs, in list
  /// order. Pure data query; the event layer (see the combined-action plans
  /// on [CallControlEvent]) turns these into the primitive events to dispatch.
  /// The legs are left out: they are in the mix, not calls to hold.
  List<String> otherCallIds(String callId) => [
    for (final call in activeCalls)
      if (call.callId != callId && !isConferenced(call.callId)) call.callId,
  ];

  /// Ids of every other answered, not-yet-held call - the ones that must be
  /// put on hold before resuming [callId] so only one call stays live. The
  /// room's legs are left out, as in [otherCallIds]. Pure data query for the
  /// event-layer plans.
  List<String> otherCallIdsToHold(String callId) => [
    for (final call in activeCalls)
      if (call.callId != callId && call.wasAccepted && !call.held && !isConferenced(call.callId)) call.callId,
  ];
}
