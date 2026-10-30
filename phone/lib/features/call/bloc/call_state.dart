part of 'call_bloc.dart';

// DiagnosticableTreeMixin counts as a custom toString to freezed 4; ask for its own.
@Freezed(toStringOverride: true)
class CallState with DiagnosticableTreeMixin, _$CallState {
  const CallState({
    this.callServiceState = const CallServiceState(),
    this.currentAppLifecycleState,
    this.linesCount = 0,
    this.activeCalls = const [],
    this.minimized,
    this.audioDevice,
    this.audioDeviceRequest,
    this.availableAudioDevices = const [],
    this.selectedCallId,
    this.placedCallFocus,
    this.conference = const ConferenceState(),
    this.linkedCall,
  });

  final CallServiceState callServiceState;

  final AppLifecycleState? currentAppLifecycleState;

  final int linesCount;

  final List<ActiveCall> activeCalls;

  final bool? minimized;

  /// The route in use, as the platform last reported it.
  final CallAudioDevice? audioDevice;

  /// A device the person asked for that the platform has not confirmed yet; null when
  /// nothing is asked for, and always null where the platform reports only a route it
  /// moved to.
  final AudioDeviceRequest? audioDeviceRequest;

  /// The device the person takes the call to be on: the one asked for while the
  /// platform is still moving the audio, the route in use otherwise.
  CallAudioDevice? get shownAudioDevice => audioDeviceRequest?.device ?? audioDevice;

  final List<CallAudioDevice> availableAudioDevices;

  /// The call the user has explicitly focused (e.g. tapped in the call list).
  ///
  /// `null` means no explicit selection - consumers fall back to the derived
  /// [ActiveCallIterableExtension.current]. This is the foundation for the
  /// list-based call screen, where one bottom action area acts on the focused
  /// call. Always read it through [focusedCall], which clamps a stale id back
  /// to `current`.
  final String? selectedCallId;

  /// The call the person placed that holds the focus (see
  /// [copyWithFocusOnPlacedCall]), with the selection it took over: the focus
  /// goes back to that one when the call ends or joins the room. Null when no
  /// placed call holds the focus.
  final ({String callId, String? returnsTo})? placedCallFocus;

  /// The conference room this client hosts; an empty one when there is none.
  final ConferenceState conference;

  /// The call being placed on behalf of another one - a consultation before a
  /// transfer - while it is being placed; null when there is none.
  final LinkedCall? linkedCall;

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

  /// The main lines no call is on, in [lines] order.
  Iterable<int> _idleLinesAmong(Iterable<int> lines) =>
      lines.where((line) => !activeCalls.any((activeCall) => activeCall.line == line));

  /// Whether a main line is free for one more call.
  ///
  /// Counted, not taken: [retrieveIdleLine] also moves the line rotation, and a
  /// control asking whether it can be pressed must not change which line the
  /// next call gets.
  bool get hasIdleMainLine => _idleLinesAmong(List.generate(linesCount, (index) => index)).isNotEmpty;

  /// Whether a call can be placed on behalf of [anchorCallId] for [purpose]
  /// now: the anchor can have one ([_canAnchor]), no other linked call is
  /// under way, and a main line is free for the new call.
  ///
  /// [isConferenceEnabled] says whether the server builds rooms, which a
  /// call placed to join needs; a consultation does not.
  bool canLinkCallTo(String anchorCallId, {required LinkedCallPurpose purpose, required bool isConferenceEnabled}) =>
      (purpose != LinkedCallPurpose.join || isConferenceEnabled) &&
      linkedCall == null &&
      hasIdleMainLine &&
      _canAnchor(anchorCallId, purpose);

  /// Whether somebody can be called into the conversation of [anchorCallId]:
  /// the call itself, or the room when it is a leg of one. Null [anchorCallId]
  /// is no conversation at all.
  ///
  /// Kept apart from [canLinkCallTo] for the control: with every main line
  /// taken it stays on the screen and says so, since nothing about the call
  /// explains why it does nothing.
  AddParticipantAvailability addParticipantAvailability({
    required bool isConferenceEnabled,
    required String? anchorCallId,
  }) {
    if (!isConferenceEnabled) return AddParticipantAvailability.hidden;
    if (anchorCallId == null || linkedCall != null || !_canAnchor(anchorCallId, LinkedCallPurpose.join)) {
      return AddParticipantAvailability.unavailable;
    }
    if (!hasIdleMainLine) return AddParticipantAvailability.noFreeLine;
    return AddParticipantAvailability.available;
  }

  /// Whether [anchorCallId] is a conversation a call can be placed for.
  ///
  /// A call has to be an answered audio call on a numbered line - the server
  /// merges and transfers calls by line - and not in a transfer or on its way
  /// out.
  ///
  /// A leg of the room stands for the room, and only a call that joins it can
  /// be placed for it: the server transfers no leg. The room has to be up, not
  /// assembling - a call is added to a room only once its offer is answered.
  /// With a room up, a call outside it is not one to join either: the server
  /// refuses a second room, and a call brought into the conversation goes into
  /// the room through one of its legs.
  bool _canAnchor(String anchorCallId, LinkedCallPurpose purpose) {
    final anchor = retrieveActiveCall(anchorCallId);
    if (anchor == null) return false;
    if (isConferenced(anchorCallId)) {
      return purpose == LinkedCallPurpose.join && conference.phase == ConferencePhase.active;
    }
    if (purpose == LinkedCallPurpose.join && conference.isPresent) return false;
    return anchor.wasAccepted &&
        !anchor.video &&
        anchor.line != null &&
        anchor.transfer == null &&
        !anchor.wasHungUp &&
        anchor.processingStatus != CallProcessingStatus.disconnecting;
  }

  /// Whether [referorCallId] can be handed over to [replaceCallId] by an
  /// attended transfer now: two different calls, each one a call could be
  /// placed for ([_canAnchor]) - answered, audio, on a line, in no transfer
  /// already, not on its way out and not a leg of the room.
  ///
  /// The menu lists by it and the bloc checks it again on the submit, with
  /// the calls as they are then: a second tap on an entry finds the call in
  /// the transfer the first one started, and a call that ended while the menu
  /// was open is not there at all.
  bool canHandOver(String referorCallId, String replaceCallId) =>
      referorCallId != replaceCallId &&
      _canAnchor(referorCallId, LinkedCallPurpose.attendedTransfer) &&
      _canAnchor(replaceCallId, LinkedCallPurpose.attendedTransfer);

  /// The hand-over the transfer menu of [focusedCallId] offers, or null when
  /// there is none.
  ///
  /// With a call linked, it is the call the attended transfer was started for,
  /// handed over to the linked call once that is answered, whichever row is
  /// focused: an incoming call grabs the selection at ring time, so the held
  /// original may stay focused through the whole transfer. A link of another
  /// purpose offers none, so the call it is about is not handed elsewhere
  /// halfway.
  ///
  /// With nothing linked - a second call dialled or answered the ordinary way -
  /// each entry is a call the person picks, connected "with this call", the
  /// focused one: with a live call on screen every held call is listed and
  /// handed over to it; with a held call on screen every other call is
  /// listed, live or held, and the held call on screen is handed over to the
  /// one picked. A held call is the one handed over, as in an attended
  /// transfer, and the pair is the person's choice - never guessed from which
  /// call happens to be live, which a third call answered meanwhile changes.
  HandOver? handOverFor(String focusedCallId) {
    final link = linkedCall;
    final List<HandOverEntry> entries;
    if (link != null) {
      final replaceCall = link.answeredTransferCallIn(activeCalls);
      entries = [
        if (replaceCall != null)
          for (final call in activeCalls)
            if (call.held && call.callId == link.anchorCallId && canHandOver(call.callId, replaceCall.callId))
              HandOverEntry(listedCall: call, referorCall: call, replaceCall: replaceCall),
      ];
    } else {
      final focused = retrieveActiveCall(focusedCallId);
      entries = [
        if (focused != null)
          for (final call in activeCalls)
            if ((focused.held || call.held) && canHandOver(call.callId, focused.callId))
              focused.held
                  ? HandOverEntry(listedCall: call, referorCall: focused, replaceCall: call)
                  : HandOverEntry(listedCall: call, referorCall: call, replaceCall: focused),
      ];
    }
    return entries.isEmpty ? null : HandOver(entries);
  }

  /// Whether [callId] is the call placed by the current link.
  bool isLinkedCall(String callId) => linkedCall?.callId == callId;

  /// Whether the room must stand aside: the host has a call outside it, and a
  /// person talks to one party at a time.
  ///
  /// Without this the room carries the host's half of that call to every
  /// participant, and its own mix into his ear over the person he is talking
  /// to: the microphone is one pooled track lent to every connection, so
  /// nothing but the room's own channel can be silenced for it.
  ///
  /// An accepted call is the boundary, not a ringing one. Before the answer
  /// there is nobody on the other side to be private with, and standing aside
  /// for a ringing call would cut the room off for an incoming call the host
  /// may well decline.
  ///
  /// Derived, never commanded: four places mark a call accepted, the handshake
  /// restore after a reconnect among them, and a command from one of them that
  /// the others do not send would leave the room either silent for good or
  /// carrying a private conversation.
  bool get conferenceMustPark => conference.isPresent && liveCallsOutsideRoom.isNotEmpty;

  /// The calls outside the room that the host is actually in: answered, not
  /// held, and not on their way out.
  ///
  /// A held call is left out because the server stops its media: the host has
  /// stepped away from it, so the room is his again - which is also how he
  /// moves between the two, the same way he moves between two ordinary calls.
  ///
  /// So is a call the room has just released ([ActiveCall.leavingRoom]): it is
  /// on its way to being held and reading it as a call the host went off to
  /// would silence the conference for everyone still in it because somebody
  /// left. Once that hold resolves the flag is gone either way, so a hold the
  /// server refused leaves an ordinary live call the room does stand aside for.
  ///
  /// And so is a call held back silent until a resume
  /// ([CallTransition.releasedFromRoom]): nobody hears it and it hears nobody,
  /// so it is not a conversation the host is in, and a room standing aside for
  /// it would leave him hearing nothing at all.
  Iterable<ActiveCall> get liveCallsOutsideRoom => activeCalls.where(
    (call) =>
        !conference.isLeg(call.callId) &&
        call.wasAccepted &&
        !call.held &&
        call.transition == null &&
        !call.wasHungUp &&
        call.processingStatus != CallProcessingStatus.disconnecting,
  );

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
  /// With a room up, an accepted selection is not consulted. There the focus is
  /// not a preference but a fact - the conversation that is audible, the room
  /// or the call it stands aside for - and the two blocks on that screen frame
  /// themselves from the same rule. A selection would let the frame sit on a
  /// call held long before the room existed, or on one whose hold the server
  /// refused. A call that is still ringing - incoming, or placed and not yet
  /// answered - keeps the focus it was given: it is in neither conversation.
  ///
  /// Returns `null` only when there are no active calls.
  ActiveCall? get focusedCall {
    if (activeCalls.isEmpty) return null;
    final selected = selectedCallId == null ? null : retrieveActiveCall(selectedCallId!);
    if (selected != null && !(conference.isPresent && selected.wasAccepted)) return selected;
    return _callTheRoomIsParkedFor ?? _firstLeg ?? selected ?? activeCalls.current;
  }

  /// What the server's [participants] list means for the room: the membership
  /// after it, and every difference from what this client holds.
  ///
  /// Pure counting, kept apart from acting on it, because the order the
  /// results are acted on in is a rule of its own - the group is re-declared
  /// before any hold, since a hold on a member is refused and a leg can only
  /// leave a group declared without it.
  ConferenceMembershipPlan membershipFrom(List<ConferenceParticipant> participants) {
    final listed = {for (final participant in participants) participant.callId};
    final vanished = conference.legIds.where((callId) => !listed.contains(callId)).toList();
    // The server un-holds a leg as it joins, so the flag on the call follows
    // it; nothing is asked of the operating system for this.
    final unheld = [
      for (final call in activeCalls)
        if (listed.contains(call.callId) && call.held) call.callId,
    ];
    // The list is the server's account of the room; the legs are this client's
    // own record, and it records only calls it has. A participant whose call
    // this client no longer holds would otherwise become a leg with nothing
    // behind it: a nameless row whose controls do nothing, and a call id the
    // OS does not know in the group this client declares, which fails the
    // grouping for every other leg with it.
    final legs = {
      for (final entry in conference.legs.entries)
        if (listed.contains(entry.key)) entry.key: entry.value,
      for (final participant in participants)
        if (retrieveActiveCall(participant.callId) != null) participant.callId: participant.line,
    };
    return ConferenceMembershipPlan(
      legs: legs,
      adopted: legs.keys.where((callId) => !conference.legs.containsKey(callId)).toList(),
      vanished: vanished,
      unheld: unheld,
      muteChanges: {
        for (final participant in participants)
          if (participant.muted != conference.participantMuted(participant.callId) ||
              !conference.isReady(participant.callId) && participant.muted)
            participant.callId: participant.muted,
        // A leg that is no longer in the room is no longer muted by it.
        for (final callId in vanished)
          if (conference.participantMuted(callId)) callId: false,
      },
    );
  }

  /// What the room's own connection is to carry, in both directions.
  ///
  /// Two independent reasons meet here and nowhere else: the host's own mute,
  /// which is his to set and the panel to show, and the room standing aside
  /// for a call outside it, which silences both directions rather than one.
  /// The room speaks only when neither holds it back, so a mute set before an
  /// outside call outlives it with nothing to restore.
  CallAudio get roomAudio =>
      CallAudio(microphone: !conference.selfMuted && !conferenceMustPark, audible: !conferenceMustPark);

  /// What [callId]'s own connection is to carry, in both directions.
  ///
  /// The one rule for who is heard, read off the state rather than commanded
  /// where the state changes: the same call is silenced and restored from
  /// several paths - joining a room, being dropped from one, a mute, a room
  /// given up - and a path that forgot would leave a connection carrying what
  /// nobody meant it to.
  ///
  /// A call the room handed back and nobody has resumed yet carries nothing
  /// either ([CallTransition.releasedFromRoom]): the room is gone but the host
  /// is still on a call outside it, so the leg stays silent until the resume
  /// lands.
  CallAudio audioFor(String callId) {
    final call = retrieveActiveCall(callId);
    if (call == null) return const CallAudio.silent();
    if (call.transition == CallTransition.releasedFromRoom) return const CallAudio.silent();
    // A leg speaks and listens through the room's connection; its own one
    // carries nothing, or the host would be heard twice and hear himself.
    if (isConferenced(callId)) return const CallAudio.silent();
    return CallAudio(microphone: !call.muted, audible: true);
  }

  /// While the room stands aside for a call outside it, that call is what the
  /// action area acts on: its microphone, its hold, its hangup. Left on a leg,
  /// the grid would offer a mute of a room nobody can hear, and a hangup that
  /// ends the room while the host is talking to somebody else.
  ///
  /// The most recent one, as `current` reads a set of calls elsewhere.
  ActiveCall? get _callTheRoomIsParkedFor => conferenceMustPark ? liveCallsOutsideRoom.lastOrNull : null;

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

    final choosenLine = _idleLinesAmong(linesList).firstOrNull;
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

  /// Whether the call screen is open plays no part: turning the sensor off is what moves an
  /// audio call to the loudspeaker on iOS, so leaving the screen must not do it.
  bool get shouldListenToProximity => isActive && isVoiceChat;

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

  /// Adds [activeCall]. A ringing incoming call takes the focus: it demands a
  /// decision. Any other call keeps the selection as it is - a call placed by
  /// the person is focused by whoever placed it (see
  /// [copyWithFocusOnPlacedCall]) - and so does a call restored after a
  /// reconnect: it was answered before, and is not yet known to be accepted
  /// only because the restore has not got that far.
  CallState copyWithPushActiveCall(ActiveCall activeCall) {
    final grabsFocus =
        activeCall.isIncomingRinging && activeCall.processingStatus != CallProcessingStatus.incomingRestoringMedia;
    return copyWith(
      activeCalls: [...activeCalls, activeCall],
      selectedCallId: grabsFocus ? activeCall.callId : selectedCallId,
    );
  }

  /// Focuses [callId], a call the person has just placed: it is the one they
  /// are now waiting on. Left on the call they placed it from, the hangup ended
  /// the conversation they meant to come back to - the held call, or the
  /// whole room - while the new call went on ringing.
  ///
  /// The selection it replaces is kept and given back when the call ends (see
  /// [copyWithPopActiveCall]) or joins the room (see
  /// [copyWithPlacedCallFocusSettled]). A ringing incoming call keeps the
  /// focus: it still demands a decision.
  CallState copyWithFocusOnPlacedCall(String callId) {
    if (retrieveActiveCall(callId) == null || selectedCallId == callId) return this;
    if (focusedCall?.isIncomingRinging ?? false) return this;
    return copyWith(selectedCallId: callId, placedCallFocus: (callId: callId, returnsTo: selectedCallId));
  }

  /// Gives the selection back once the placed call that took it has joined
  /// the room. As a leg it no longer has the focus - the room has (see
  /// [focusedCall]) - but kept as the selection, it would take the focus back
  /// the moment the room is gone, picked by no one.
  CallState copyWithPlacedCallFocusSettled() {
    final placed = placedCallFocus;
    if (placed == null || !conference.isLeg(placed.callId)) return this;
    return copyWith(
      selectedCallId: selectedCallId == placed.callId ? _alive(placed.returnsTo) : selectedCallId,
      placedCallFocus: null,
    );
  }

  String? _alive(String? callId) => callId != null && retrieveActiveCall(callId) != null ? callId : null;

  CallState copyWithPopActiveCall(String callId) {
    final activeCalls = this.activeCalls.where((activeCall) {
      return activeCall.callId != callId;
    }).toList();
    // When the focused call ends, prefer the next ringing incoming call (it
    // still demands a decision); otherwise give the focus back to what was
    // selected before a placed call took it, or clear so [focusedCall] falls
    // back to `current`. An unrelated selection is kept as is.
    final placed = placedCallFocus;
    final returnsTo = placed?.returnsTo == callId ? null : placed?.returnsTo;
    final placedEnds = placed?.callId == callId;
    final selectedCallId = this.selectedCallId == callId
        ? activeCalls.firstWhereOrNull((call) => call.isIncomingRinging)?.callId ?? (placedEnds ? returnsTo : null)
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
      placedCallFocus: placed == null || placedEnds ? null : (callId: placed.callId, returnsTo: returnsTo),
      conference: conference,
    );
  }

  /// Focuses the call [callId] when it maps to a live call; otherwise returns
  /// the state unchanged. Keeps [selectedCallId] clamped to an existing call.
  CallState copyWithSelectedCall(String callId) {
    if (retrieveActiveCall(callId) == null) return this;
    // The person's own choice: nothing is given back to over it.
    return copyWith(selectedCallId: callId, placedCallFocus: null);
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
