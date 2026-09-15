# Conference

Merging the calls a person already holds into one room where everybody hears
everybody. The room is the server's - a Janus AudioBridge the backend builds
and owns - and this client asks for it, joins it, and follows what it says.
Last reviewed: 2026-09-17.

The wire format, every refusal reason and the obligations this client is held
to are in
[`packages/signaling/docs/conference_protocol.md`](../../packages/signaling/docs/conference_protocol.md).
This page is the app side: what holds the room's state, what happens to a call
that joins it, and how it is taken down.

## Where it lives

```
lib/features/call/
  conference/
    conference_peer_connection.dart   the client's own connection to the mixer
    leg_mute_sync.dart                keeps the platform's mute for each leg in step with the room's
  models/conference_state.dart        ConferenceState, ConferencePhase
  bloc/call_bloc.dart                 the handlers, in the "conference" section
  bloc/call_state.dart                the derivations: mergeableCallIds, mergeableLegs, canMerge, canAdd
  widgets/conference_panel.dart       the room on screen: the host, the participants, End
  widgets/call_list_action.dart       the Merge and Add controls in a roster header
```

## The model

A call in the room is a **leg**. Its own `RTCPeerConnection` stays open for as
long as the room lasts - closing one makes the server send a SIP BYE and ends
that call - but it carries no audio in either direction: the server takes the
far end's audio from the SIP side and mixes it, so the leg is **silenced, not
closed**.

The host is in the room through **one more connection**, next to the legs:
`ConferencePeerConnection`, carrying the microphone up and the mix down. It is
not a call, has no call id, and is not known to the operating system.

```
this client                                  the server
  PC per line  ---> line 0 --- SIP ---> far end B    microphone and inbound both off
               ---> line 1 --- SIP ---> far end C    microphone and inbound both off
  one more PC  ---> AudioBridge room                 microphone in, the mix out
```

Nothing is signalled to the far ends. For each of them it stays an ordinary
one-to-one call; they are told neither that a conference exists nor who else is
in it.

## The state

`CallState.conference` is a `ConferenceState`:

| field | what it is |
|---|---|
| `room` | the number the server assigned, from its offer; `null` before it |
| `phase` | `none` / `assembling` / `active` |
| `legs` | this client's own record: the calls it put in, by call id, with the line each is on |
| `participants` | the server's list as last sent; the host is never in it |
| `selfMuted` | whether the host's microphone is off towards the room |

`legs` and `participants` are deliberately two fields. `legs` is what this
client asked for and is filled from the merge's acknowledgement, before any
room exists; `participants` is what the server says the room contains. Between
the acknowledgement and the offer they differ, and each question is asked of
the right one: whether a call is a leg (`isLeg`) of the client's record,
whether the server will accept a mute for it (`isReady`) of the server's.

Membership is never a flag on `ActiveCall`. The call object is copied in dozens
of places, and a second source of truth would drift.

## A room's life

```
merge {lines}
  -> ack                      phase: assembling, legs recorded, every leg silenced NOW
     ...the server wires each leg into the mixer and un-holds it...
  <- conference_offer {room, jsep, participants}
  -> conference_answer {jsep}  phase: active; the host is in the room
 <-> conference_ice_trickle    both ways, many
```

Two details carry most of the correctness:

**The legs are silenced at the acknowledgement, not at the offer.** The
protocol requires it, and the record of what was silenced is exactly what a
failure between the two undoes.

**The client keeps a deadline of its own** (`conferenceAssemblyTimeout`,
20 s). The server has one too - 10 s - but announces its expiry as an *event*,
and events are not replayed across a dropped socket. Without a local deadline a
socket that dies in that window would leave two live calls silent in both
directions forever. The local one is deliberately the longer, so the server's
word wins whenever the socket is alive.

## Joining and leaving

A call outside the room joins with `conference_add`. **No new offer follows**:
the mix the host receives does not change shape when a participant is added, so
the connection to the mixer is untouched. The server announces the new member
with `conference_updated`, and that list is the membership.

The server's list is authoritative on every update:

- a leg no longer listed but still up becomes an ordinary call again - audio
  back, and on hold, because the room is what the host is listening to;
- a listed call is already off hold on the server's side (it un-holds a leg as
  it joins, with no event), so the local flag and the operating system follow;
- a listed call this client no longer has does **not** become a leg: a leg with
  no call behind it is a nameless row with dead controls, and a call id the
  operating system does not know fails the grouping for every other leg with
  it;
- a listed call this client did not record itself - an add whose acknowledgement
  was lost, or a list arriving after a reconnect - is silenced on adoption:
  membership and where a call's audio actually goes must not disagree.

There is no way out for the host alone. The room is ended for everybody, or one
participant is hung up; the protocol offers self-mute instead of stepping out.

## Mute

Two different things share one word, and the code keeps them apart:

| what | where it lives | how it is done |
|---|---|---|
| the host towards the room | `conference.selfMuted` | the microphone leaves the **mixer** connection's sender |
| one participant, for everybody | the server's `participants[].muted` | `conference_mute {line}`; the outcome comes back as the next list, nothing is guessed |

A leg's own microphone left its connection when it joined, so muting *a leg*
has nothing to silence there - a mute asked for a leg, from any control, is a
mute of the room.

That matters because the operating system is one of those controls. It keeps a
mute state per call and re-publishes it unasked - when a participant is hung
up, when the audio device changes - so every leg is told the room's mute and
nothing the platform repeats is news. `LegMuteSync` does that, and tells this
client's own echoes from a person pressing mute: a report matching the **oldest
command still outstanding** for that call is that command coming home; anything
else is somebody's intention. The value alone cannot decide, because the
platform does not wait for the report before the command returns, so a report
can still be in flight when the host asks for the opposite.

## On the screen

The way in is the roster header - the strip that appears when there is more
than one call and says how many there are. That is where the set of calls to
choose between is already named, and it is the same set there is something to
merge; with one call there is neither header nor button. Where the deployment
offers no rooms the control is absent rather than disabled, because the server
would refuse a merge outright; where it does, it stays visible and goes
disabled while this particular set cannot be merged, so it does not appear and
vanish as a call is answered or ends.

While a room stands the roster gives way to a panel (`ConferencePanel`): the
legs are one conversation, not calls to choose between. It lists the host and
every participant by line, each row carrying the room-wide mute for that
person and a way to drop them, and the room's own End. Calls outside the room
keep their rows underneath, under a header that says so, with the same control
offered as `Add`.

The control grid below acts on the room whenever the focused call is a leg: its
hangup ends the room rather than silently picking one participant, its
microphone shows and sets the room's mute, and hold and transfer are gone
because a leg has neither.

Refusals reach the person as a sentence, not as the code the server sent.

## The operating system

The legs are declared as one group (`setCallGroup('room-<room>', legs)`), which
becomes a `Conference` on Android and a call group on iOS. A member of a group
cannot be held or resumed on its own: the plugin answers `callIsGrouped` and
the server would refuse the hold as `line_in_conference` - so hold and transfer
are refused for a leg on every path, including the ones that do not come from
this app's own UI.

## Reconnect and restart

A room lives on the media server and outlives the signalling socket, so every
handshake carries two accounts of it - the server's `conference` block and this
client's own state - and all four combinations mean something:

| the server | this client | what happens |
|---|---|---|
| a room | the same room | kept; the handshake's participant list is the membership, as an update would be |
| a room | nothing | ended on the server: nobody here is connected to its mixer |
| a room | a different room | the server's is ended and this one is dropped, legs back to ordinary calls |
| nothing | a room | dropped here, legs back to ordinary calls |

What "this client's room" means is the room id, and it is recorded **before**
the offer is answered. The handshake handler runs outside every queue, so one
landing mid-answer would otherwise find a client with no room and hang up the
room it was in the middle of joining. A merge still assembling has no id yet,
and the server sends one offer per room - there is nothing to come back to, so
it is ended.

The session snapshot the foreground-service hub replays carries the conference
block too. Protocol events are never replayed, so a room built while the app
isolate was detached would be invisible to whoever attached afterwards; the
snapshot is how that subscriber learns of a room it is not connected to and
must end.

## Teardown

| how | what this client does |
|---|---|
| the host ends it | drops the room locally first, then asks the server; every leg is hung up - a room is not unwound into separate calls |
| `conference_terminated` | the calls still up become ordinary calls: all of them are active on the server, so one carries on and the rest go on hold |
| `conference_failed` | the same, plus a notification naming the reason |
| the mixer connection dies | the room cannot be asked for again - the server offers it once - so the calls are handed back the same way, and the room is ended on the server in case it still stands |

A room does not survive a Janus restart, and there is exactly one room per
signalling session.
