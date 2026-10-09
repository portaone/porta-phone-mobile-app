# Conference

Merging the calls a person already holds into one room where everybody hears
everybody. The room is the server's - a Janus AudioBridge the backend builds
and owns - and this client asks for it, joins it, and follows what it says.
Last reviewed: 2026-10-09.

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
  widgets/conference_panel.dart       the room on screen: the host, the participants
  widgets/call_row_frame.dart         the row every list on the call screen is made of
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
| `phase` | `none` / `assembling` / `active` / `rejoining` |
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

**Answering happens off the mutation queue.** Building the connection to the
mixer is a media round trip and sending the answer is a request; held inside
the queue, they would block the very deadline that exists to end this wait, and
the host's own End with it. The work therefore runs on its own and reports back
as an event - and it carries the number of the attempt it was started for, so
an answer for a room already given up cannot raise it from the dead, not even
when the next room is still assembling and has no id to tell it apart by. An
answer the session could not carry is a failure to join, not a room: the server
is left waiting, and reading it as success would cancel the deadline and leave
the legs silent for good.

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

## A call outside the room

While a call outside the room stands, the room is **parked**: nothing is sent to
the mix and nothing of it is heard. Without that the room carries the host's
half of that call to every participant, and its own mix into his ear over the
person he is talking to - the microphone is one pooled track lent to every
connection, so no per-call mute can silence it for the room, and only the
room's own channel can be.

Parking is not a mute, and the two are kept apart in
`ConferencePeerConnection`: a mute is what the host asked for and what the
panel shows, parking is the room standing aside, and the room speaks only when
neither holds it back. So a mute set before the outside call outlives it with
nothing to restore, and there is no "who asked for this" to work out.

Both halves are applied in one place. The outbound half takes the microphone
off the room's sender; the inbound half disables the **receiver's** track,
which is the only handle on what is heard - the mixed audio plays natively and
no stream of it is kept. That track exists only once a remote description has
been set, so the state is applied again after every answer: a room parked while
it was still assembling would otherwise come up audible.

If both attempts to apply parking fail, the connection gives the room up.
The failure is checked against the current request after the await as well as
before it: an obsolete failure cannot terminate a room whose audio intent has
already changed.

When a room is lost or terminated during an outside call, every surviving leg
stays locally silent and is asked to hold. None is automatically resumed into
the private conversation. This local barrier survives a delayed or refused
hold and mute callbacks; a successful explicit resume restores the leg's audio
with its own mute intent preserved. Rejoining a room transfers isolation back
to conference membership, and ending a call removes its barrier.

While the room is the one standing aside, its participants' controls step back
to half weight - the hangups especially, which would otherwise shout from a
conversation the user is not in. They are dimmed and never disabled: a room-wide
mute and a hangup still reach the room while the host is elsewhere, and the
semantics are untouched, so a screen reader offers both exactly as before.

Moving between the two is a tap on either of them: any row of the room leads
back into it, and the row of the call outside leads out to that call. The tap
acts rather than merely taking the focus - it holds the conversation left behind
and resumes the wanted one, and the room's own audio follows from the rule. A tap
that only took the focus would hand the user the room's controls while the room
was still silent, which is what the screen did before: the way back was to press
Hold on the other call and know what that meant. Without a room there is one
conversation and a tap stays a selection.

The hold is all the tap commands. Which conversation the screen frames, and which
one the bottom controls act on, is read off the audio by
[`CallState.focusedCall`] - so a hold the server refuses leaves both on the call
that is still heard, rather than on a room nobody can hear. Nor is the settled
state asked whether a switch is needed: between a tap and the server's answer the
calls still read the way they did before it, so a second tap would find nothing
to do and the first one's request would land unopposed. The conversation the last
tap asked for is held in `CallBloc._conversationSwitchInFlight` until that hold
or unhold settles, refusal included; the requests are ordered by the mutation
queue, so the tap that came last is the one that settles last.

When to park is [`CallState.conferenceMustPark`], planned in `onChange` off the
state rather than commanded from the paths that accept and end calls. Four
places mark a call accepted, the handshake restore after a reconnect among
them, and a command from one of them that the others do not send would leave
the room either silent for good or carrying a private conversation. An
**accepted** call is the boundary, not a ringing one: before the answer there is
nobody to be private with, and standing aside for a ringing call would cut the
room off for an incoming call the host may well decline.

The server is not told - the host's own mute is local too (§14: far ends learn
nothing of a conference) - but the participants are, over the same app-to-app
envelope the mute hint uses: a `conference_host_away {away}` goes to every leg
when the parking changes, to a leg as it joins a room already standing aside,
and as `false` both when the room ends and when the server drops a leg out of a
room that is standing aside - a leg that carries on as an ordinary call must not
be left showing a host away from a room it is no longer in. Core relays the
envelope without reading it, so nothing on the server side changes for a new
inner type.

It is a claim on the same terms as the mute hint, and carries the same limit: it
is not replayed, and a participant whose socket was down for it learns nothing
until the host's next change. Nothing functional hangs on it - it is a line of
text under the name.

## Telling the muted participant

The server tells a muted participant nothing: every conference message is
addressed to the host's session, and §14 of the protocol states that far ends
get no indication a conference exists at all. Their own phone therefore shows a
live microphone while nobody hears them.

The host says it instead, over `peer_message` - the app-to-app envelope the
server relays inside one call, already used for the remote camera state. A
`conference_mute_state {muted}` goes to a leg whenever the server's list says
that leg's mute changed, and a `false` goes out when the leg leaves the room or
the room ends.

It is a **claim, not a fact**, and the receiving side treats it as one:

- only the other party of that very call can send it, because that is how the
  relay is scoped - but nothing on the receiving side can check that a room
  exists or that the mute was really applied;
- it is recorded on that call (`ActiveCall.peerReportedConferenceMute`) and ends
  with it; no room is invented from it;
- it is shown as somebody's word - "the other side says you are muted" - and
  nothing functional hangs on it: no microphone is switched, no control
  changes;
- it is not replayed. A participant whose socket was down for it learns
  nothing, and the host re-sends only on a change;
- it is skipped entirely where the core does not advertise `peer_message`: an
  older one closes the signalling socket with 4600 on a request it does not
  know, and a hint is not worth the session the room lives in.

A far end that is not this app gets nothing, and cannot. The authoritative fix
is an event from the core into the muted subscriber's own session; this is what
can be done without one.

## On the screen

The way in is the roster header - the strip that appears when there is more
than one call and says how many there are. That is where the set of calls to
choose between is already named, and it is the same set there is something to
merge; with one call there is neither header nor button. Where the deployment
offers no rooms the control is absent rather than disabled, because the server
would refuse a merge outright; where it does, it stays visible and goes
disabled while this particular set cannot be merged, so it does not appear and
vanish as a call is answered or ends.

With several calls the screen shows no single large picture - one picture can
only be of one person - and each roster row carries the picture of whoever that
call is with, its status dot riding on it as a badge. A single call keeps the
large one.

While a room stands the roster gives way to a panel (`ConferencePanel`): the
legs are one conversation, not calls to choose between. It lists the host and
every participant by line, each row carrying the room-wide mute for that
person and a way to drop them. A panel row and a roster row are the same
widget (`CallRowFrame`) - the panel is a list of calls like any other - so a
leg shows the picture of whoever it is with, and the host's own row a
placeholder in its place, which is what keeps the names in one column. Calls outside the room keep their rows
underneath, under a header that says so, with the same control offered as
`Add`.

Ending the room is the grid's hangup and nothing else. The panel had a
labelled End of its own for a while, and it did exactly what the hangup below
it already did - two identical destructive controls on one screen, one of them
unlabelled. What remains is the one that is always there, and while a room
stands it says what it ends rather than "hang up".

The control grid below acts on the room whenever the focused call is a leg: its
hangup ends the room rather than silently picking one participant - dropping
one is that participant's own row - its microphone shows and sets the room's
mute, and hold and transfer are gone because a leg has neither.

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
| a room | the same room | kept; the handshake's participant list is the membership, as an update would be. If this client was on its way back into it (`rejoining`), the server is asked for the room's offer again |
| a room | nothing | ended on the server: nobody here is connected to its mixer |
| a room | a different room | the server's is ended and this one is dropped, legs back to ordinary calls |
| nothing | a room | dropped here, legs back to ordinary calls |

What "this client's room" means is the room id, and it is recorded **before**
the offer is answered. The handshake handler runs outside every queue, so one
landing mid-answer would otherwise find a client with no room and hang up the
room it was in the middle of joining. A merge still assembling has no id yet,
and the server does not send that first offer again - there is nothing to come
back to, so it is ended.

The session snapshot the foreground-service hub replays carries the conference
block too. Protocol events are never replayed, so a room built while the app
isolate was detached would be invisible to whoever attached afterwards; the
snapshot is how that subscriber learns of a room it is not connected to and
must end.

## A lost mixer connection

A network outage on the host takes every peer connection's path with it. The
calls come back with an ICE restart; the connection to the mixer cannot - the
mixer made the offer and refuses one from the client. What the server has
instead is `conference_rejoin` (Core 1.0.0): it moves the host onto a new
handle in the same room and sends a new offer, and the legs go on being mixed
the whole time.

So when the mixer connection reaches `failed`:

```
phase: active -> rejoining      same room, legs, list and mute; nothing shown to the user
close the dead connection       its candidates stop; mute and parking are kept
-> conference_rejoin
                                the offer gets the deadline a merge's offer has, from here
<- ack
<- conference_offer {room: the same}
answer on a fresh connection
-> conference_answer            phase: active
```

Three conditions, all read where the failure arrives
(`__onMutationConferenceConnectionFailed`), or the room is given up as before:

- **the core has the request** (`CallCapabilitiesConfig.isConferenceRejoinEnabled`,
  from the core version). An older core does not refuse an unknown request, it
  closes the socket with 4600; the handshake after it still reports the room,
  so asking again on reconnect would never stop.
- **the connection had reached the mixer.** One that fails without ever coming
  up did not lose a path it had, and a new one would fail the same way for as
  long as media cannot get through.
- **the room is `active`.** A room still being built, or one already on its way
  back, has no working connection to replace.

One request per session, and only to a session that is up. The mixer
connection can fail while the socket is still down, and the signaling module
keeps a request it is handed then and sends it on reconnect - next to the one
the handshake would send. The server moves the host onto a new handle for each,
so the second makes the offer already on its way an offer from a handle that is
gone. So a session that is down is not handed the request at all: the room
stays `rejoining`, nothing is decided and no deadline runs, and the handshake
that brings the session back either still reports the room, and asks, or does
not, and the room is dropped like any other the server no longer has. A
handshake on a session that has already been asked asks nothing.

A rejoin belongs to the session it was asked of. When that session goes, the
attempt is void: the wait for its offer ends there, deadline included, and
whatever comes back from it later - an acknowledgement as much as a failure -
is dropped, because its attempt is no longer the current one. The next
handshake starts the way back anew. That covers a request or an offer lost with
the socket, an answer to the new offer the session did not carry, and an answer
the request queue reports as sent although it never left. Nothing about an old
request is read off the connection as it is when the result is handled: by then
it may be another session's. A merge is not the session's in this sense - its
attempt and its deadline run on through a session loss.

The deadline runs from the request, not from its acknowledgement: a server that
is up and silent would otherwise keep the host out of the room for as long as
the request is retried. It is also what ends a rejoin that could not be sent,
or an answer that did not get through, on a session that stays up - nothing
else would ask again. Only a refusal ends the room at once.

Every offer is answered on a connection of its own, the same room's included,
so an offer that does arrive twice replaces the connection instead of being
renegotiated onto one made with another handle.

A refusal ends the room, except `conference_not_established`: that one says an
offer is already on its way, and it is waited for under the same deadline.

What the wait for an offer needs to remember - which attempt is current,
whether this session was asked, and the deadline - is kept by `RoomOfferWait`
(`lib/features/call/conference/room_offer_wait.dart`), for the first offer after
a merge as for the one after a rejoin. A merge's deadline runs on through a
session loss; a rejoin's ends with the session.

## Teardown

| how | what this client does |
|---|---|
| the host ends it | drops the room locally first, then asks the server; every leg is hung up - a room is not unwound into separate calls |
| `conference_terminated` | the calls still up become ordinary calls: all of them are active on the server, so one carries on and the rest go on hold |
| `conference_failed` | the same, plus a notification naming the reason |
| the mixer connection dies and there is no way back (see above), or the offer asked for never comes | the calls are handed back the same way, and the room is ended on the server in case it still stands |

Every terminal event names the room it is about, and one naming a room this
client is not in is somebody else's end: acting on it would drop a live room.
A room still assembling has no id yet, so an unnamed event - and any event at
all while there is nothing to tell apart - is taken as this one.

A room does not survive a Janus restart, and there is exactly one room per
signalling session.
