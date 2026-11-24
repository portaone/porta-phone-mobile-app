# Conference

Merging the calls a person already holds into one room where everybody hears
everybody. The room is the server's - a Janus AudioBridge the backend builds
and owns - and this client asks for it, joins it, and follows what it says.
Last reviewed: 2026-11-19.

The wire format, every refusal reason and the obligations this client is held
to are in
[`packages/signaling/docs/conference_protocol.md`](../../packages/signaling/docs/conference_protocol.md).
This page is the app side: what holds the room's state, what happens to a call
that joins it, and how it is taken down.

## Where it lives

```
lib/features/call/
  conference/
    conference_room.dart              the room as one object: every step of its life
    conference_room_ports.dart        what the room and its owner say to each other: calls, updates, commands, steps, notices
    conference_peer_connection.dart   the client's own connection to the mixer
    room_video.dart                   the room's video as a part of the room: when to join, the camera, an invitation
    conference_camera_plan.dart       what the user asked of the camera in the room's video, and an invitation
    conference_video_session.dart     the room's video: subscriber and publisher connections
    leg_mute_sync.dart                keeps the platform's mute for each leg in step with the room's
  models/conference_state.dart        ConferenceState, ConferencePhase
  models/linked_call.dart             LinkedCall: a call placed to join a call or the room (purpose join)
  bloc/call_bloc.dart                 composes the room: hands it the room's events and the user's requests
  bloc/call_conference_event_mapping.dart  which step of the room takes each conference event of the queue
  bloc/call_state.dart                the derivations: mergeableCallIds, mergeableLegs, canMerge, canAdd
  widgets/conference_panel.dart       the room on screen: its participants
  widgets/conference_full_screen.dart the room in full screen: video tiles, "You", the room's control bar
  view/call_screen_handset.dart       the phone's call screen: its routes, the full screen among them
  widgets/call_row_frame.dart         the row every list on the call screen is made of
  widgets/call_list_action.dart       the Merge and Add controls in a roster header
```

## The room in CallBloc

`CallBloc` holds the room as one object it composes, `ConferenceRoom`
(`conference/conference_room.dart`), in its field `_room`. The room owns the connection
to the mixer (`ConferencePeerConnection`), the wait for the room's offer
(`RoomOfferWait`), the codecs of the legs (`RoomCodecs`) and their mute
(`LegMuteSync`), and takes every step of the room's life.

The API is named by what each part is. A request of the user is an imperative
(`merge`, `addCall`, `muteParticipant`, `setSelfMuted`, `end`, `rejoin`,
`video.setCamera`, `video.switchCamera`); what happens outside the room - the
server's word, the session, the app, the calls - is `on<What>` (`onOffer`,
`onParticipants`, `onFailed`, `onTerminated`, `onRemoteCandidate`, `onSessionLost`,
`video.onEvent`, `video.onAppLifecycleChanged`, `video.onSessionBack`,
`video.onRoomKept`, `video.onCallsChanged`); the room's own continuations are private
and reached through `takeStep`. The sealed families carry their kind in the name:
`...Command`, `...Step`, `...Notice`, and a step is named for what happened
(`AnswerTakenStep`, `CameraSwitchedStep`).

The room knows nothing of the bloc, its state or its events
(`test/architecture/conference_boundary_test.dart` keeps it so). What it needs is
handed to it at construction:

- the signalling, callkeep and the server's capabilities;
- `ConferenceCalls` - what it reads of the calls around the room (the room itself, a
  call, every call there is, which calls can join, what the server's list changes)
  and asks of one call (its audio, its codec). The bloc implements it over its own
  state (`_BlocConferenceCalls`);
- `onCommand` - a `ConferenceCommand` for something only the owner can do to a leg:
  renegotiate it, hold or resume it, end it, turn its camera on or off with the room's,
  retry a merge or an add;
- `onStep` - a `ConferenceStep`, a continuation of the room's own (the answer to its
  offer was taken, the mixer's connection failed, a candidate was gathered) that has
  to take its turn in the bloc's queue. The bloc queues it as one event and hands it
  back to `ConferenceRoom.takeStep`;
- `onNotice` - a `ConferenceNotice` for something the user is to be told (the room was
  refused, failed, ended, its camera could not be opened); the bloc words it as a
  notification of the app;
- `onError` - a sink for errors (the bloc's `CallErrorReporter`).

Once the bloc is closing, what the room raises goes nowhere: a command, a step and a
notice are dropped (`_onConferenceCommand`, `_onConferenceStep`,
`_onConferenceNotice`), and the offer deadline of a room the bloc no longer cancels is
nobody's. A handler still in flight at close() runs on, and its request may be
answered after it; before the room was a module of its own, the first event it
queued then threw.

The room's state stays the bloc's, `CallState.conference`. A step that changes it is
called with a `ConferenceWrite` and describes each change as one `ConferenceUpdate` -
the room, the calls taken off hold, the transitions of calls, the camera each call
shows, the placed call's focus, the invitation to somebody else's room's video - which
the bloc applies as one change of its state, where it changed before.

A call's own negotiation tells the room what it has to know for the move onto the
conference codecs through `ConferenceRoom.legNegotiation`, a `LegNegotiation`: the
offers and answers of a call being moved, and its end. It is the part of `RoomCodecs`
the calls see; checking, restricting and the move itself stay the room's.

The boundary is kept by imports as well as by names: a file of the module imports the
files it uses, not a barrel of the feature, since a barrel that exports one file
importing the bloc brings the bloc along. The architecture test
(`test/architecture/conference_boundary_test.dart`) follows the imports through the
call feature, names the chain it finds and refuses a direct import of the barrels
above the feature. It does not follow a chain out of the feature: the app's own
barrels (lib/models, lib/extensions, lib/repositories) import the router and with it
every feature, so from nearly any file a walk reaches the bloc - a cycle of the app,
not of this module.

The room has tests of its own with the owner stood in for
(`test/features/call/conference/conference_room_test.dart`: a `ConferenceCalls` of
plain values, the commands, steps and writes recorded); how it behaves inside the
bloc, with real calls around it, is in the bloc's conference tests next to it.

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

On a phone each participant's row carries the mute for everyone and a menu holding
End their call: the two are never side by side, so a slip on the mute does not drop a
person from the room. The menu opens under its trigger, so a second tap on the trigger
does not land on End, and closes when the participant's row goes. A watch shows one
participant on a page of its own, with both as round buttons.

While the room is the one standing aside, its participants' controls step back
to half weight, so that they do not shout from a conversation the user is not in.
They are dimmed and never disabled: a room-wide mute and the end of a call still
reach the room while the host is elsewhere, and the semantics are untouched, so a
screen reader offers both exactly as before.

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

## Calling somebody in

Merging needs the calls to exist first. Calling somebody in places the call and
joins it in one go: the person picks somebody, the call they are in is held,
the new call is placed, and once it is answered it is merged with that call -
or added to the room when it was made from one of the room's legs. Nothing has
to be pressed in between.

It is a linked call with the purpose `join` (`CallState.linkedCall`,
`LinkedCall`): placing it, holding the call it is for and giving that call
back when the new one does not come up are the linked call's, shared with the
attended transfer and described in [`call_arch.md`](call_arch.md) under
"Attended transfer". What joining adds:

- **Who can be called into what** - `CallState.addParticipantAvailability`:
  the deployment builds rooms; no other linked call is under way; a free main
  line, counted without taking it (`retrieveIdleLine` would move the line
  rotation); and for a call, an answered audio call on a numbered line, not in
  a transfer and not next to a room - a second room is refused, and the room
  is joined through its legs; for a leg, a room that is up, since an
  assembling or rejoining room cannot take a call. With every main line taken
  the control stays and says so (`noFreeLine`). The answer is asked again when
  the choice arrives (`canLinkCallTo(..., purpose: join)`): the calls went on
  while the person was in the lists.
- **The room through a leg** - the room has no id of its own on this side, so
  the call is placed for one of its legs and `intoRoom` records that it is for
  the room. That leg leaving while the call rings is one person going, not the
  conversation: the call stays tied until the room itself ends. A room is never
  held for the call - it stands aside while a call outside it is up and comes
  back by itself - so a failed call leaves the room as it was.
- **The line** - always a main line, never the guest line of another caller
  ID: the server merges calls by line, and a guest-line call has none.
- **The codecs** - the room is a mixer on the server that speaks opus, PCMA
  and PCMU only. A call on another codec (G.722, iLBC) is left out of the room,
  and a room left with one call is closed with nothing but
  `conference_terminated` - no reason, so this side cannot tell it from an
  ordinary end. The call's offer therefore carries only those codecs
  (`kConferenceAudioCodecs`, `RoomCodecs.restrict`), and so do a
  leg's own offers and its answers to an offer from the far end, which could
  otherwise move it off them. A callee that speaks none of them turns the call
  down before answering - an ordinary failed call that gives the conversation
  back. DTMF and comfort noise stay; where none of the codecs is offered at all
  nothing is removed, since a description with no voice codec carries no call.
  It is applied after the encoding settings, which a deployment may bypass as a
  whole: the room needs it regardless.
- **A call already off the codecs** - the call the new one joins, and any call
  merged or added by hand, was placed with every codec before anybody knew it
  would be merged, and may have settled on G.722. Before the merge or add is
  asked, each such call (read from the first voice payload of its last answer,
  `SDPModBuilder.audioCodecInUse`) is renegotiated with the conference codecs
  alone, and the request is asked again once every one has its answer -
  checking the codecs again, so a far end that answered on G.722 anyway is not
  merged nor moved a second time. The policy and what is kept about a move
  are `RoomCodecs`' (`conference/room_codecs.dart`), which hands the conference
  commands - renegotiate, hold again, ask again - and is tested on its own:
  - only an applied answer counts: `updated` carries none, and stands for one
    only when the connection is back in stable;
  - a request asked while a move is on waits for it and is asked after it; a
    join of an Add participant is asked again as a join, so its link - and the
    anchor's way back if the new call ends - stays until it is made;
  - an offer kept for replay from before carries every codec: it is withdrawn
    and the move's own offer made;
  - a far end that answers 415, 488, 500 or 606 keeps its call as it was: the
    offer is rolled back, not kept and sent again as other refused offers are,
    and the request asked again fails with `ConferenceFailedNotification`
    (`codec_not_mixable`). 500 is among them because PortaSIP answers
    `500 SDP Negotiation Failed` to a re-INVITE whose codecs the far end
    refused. Other errors answered at once (491, 503) are retried as for any
    renegotiation. Answers that do not come in 20 s give the move up the same
    way, and an error that arrives after that rolls the offer back too;
  - the server acknowledges an offer with `updating` before the far end has
    seen it, so the far end's refusal comes after that, as a `declining` event
    with its code (`signalingDeclined`): the offer is rolled back, the call is
    no longer updating and the move gives up. With a code of the list above
    the request fails with `codec_not_mixable`; with any other (491, 503) with
    `codec_move_not_answered`, and asked again it moves the call anew. Only
    the move's offer is rolled back: an offer the connection asked for itself
    (a camera, an ICE restart) would be asked for again at once and refused
    again, several times a second (seen on the stand), so it is left. A
    `declining` for a call with no offer awaiting its answer, or one that
    names a transfer, changes nothing;
  - a held call is moved as it is: the connection offers sendrecv - the hold is
    the server's - so the move takes it off hold on the far end, as the merge
    would a moment later; when no room takes it after all, the hold is asked
    for again. A refused call never left hold and is left alone. The direction
    is not written into the offer instead: the connection would then see its
    transceiver differ from what was agreed and renegotiate again, sendrecv, on
    what is by then a leg of the room (seen on the stand);
  - a moved call that ends takes nothing with it: the request asked again
    finds fewer calls and does nothing, and the person has seen the call end.

  PortaSIP passes such an offer on to the far end (seen on the stand with
  transcoding off and on) and answers 500 when the far end refuses it. Not
  covered: an offer kept for replay from
  before a call became a leg goes out as it was kept.
- **The join** - `signalingAccepted` of the new call queues `linkedCallJoin`,
  which runs the same merge or add a person's tap runs. Being queued, it runs
  after the answer has been applied, and a Merge pressed at the same moment
  finds the room already there and is ignored rather than asked twice. A room
  that is rejoining at that moment is waited for (`awaitingRoom`); the join is
  made when it is up again. The link is over once the join has run, joined or
  not: a refused merge leaves two ordinary calls, because ending a call the new
  party has just answered would be worse than one more tap.
- **What is said** - as for the attended transfer: a decline and an unanswered
  call get a line of their own, busy and every other refusal are told by the
  hangup, and a cancel is the person's own.

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
legs are one conversation, not calls to choose between. It lists every
participant by line, each row carrying the room-wide mute for that person and a
way to drop them. A panel row and a roster row are the same widget
(`CallRowFrame`) - the panel is a list of calls like any other - so a leg shows
the picture of whoever it is with. Calls outside the room keep their rows
underneath, under a header that says so, with the same control offered as
`Add`.

The host has no row of his own. The screen around the list is his, and the row
only repeated it: its microphone was the room's mute, which the call screen's
own mute button reaches as well, and a tap on it led back into the room, which
every participant row does. That button is the room's whenever the room hears
the host - on a leg, and on a call outside the room that is not yet answered,
such as one he is calling in, since the room stays live until that call is up
(`CallActionAvailability.micActsOnRoom`). While the room stands aside, a note
under the panel's header says so (`conferenceParkedNote`).

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

Calling somebody in is an entry of the transfer menu (`ActiveCallActions`),
under a divider after the transfers: both start with choosing who else the call
is about, and the grid has no place for a control of its own. Where the
deployment offers rooms the button is named "Add or transfer" and shows
`Icons.add_call`; elsewhere it stays the plain transfer. For a leg of the room
the menu holds Add participant alone - a leg is not a call to hand over. The
entry is disabled rather than absent while the conversation cannot take
somebody, and with every main line taken it says so in its second line. Every
entry of that menu carries such a second line (`CallPopupMenuItem.subtitle`)
saying what it does - a person's name in a transfer menu says who, not what
happens to the call - and Add participant's says whether the call goes into
the call or the conference. Pressed, it sends the person to the lists with
`AddParticipantPurpose` (see
[`../architecture/destination_picking.md`](../architecture/destination_picking.md)),
for the focused call; for a leg that is the room.
`lib/features/call/widgets/linked_call_picking.dart` takes the request back
when that call goes - a leg leaving included, so the person asks again from
the room as it is - when a request made for the room outlives the room, or
when the person returns to the call without choosing. While the call rings,
the same entry offers Cancel invite, named after who is being called; it ends
the linked call, which gives the conversation back, and goes once the call is
answered, since ending a call somebody is talking on is the hangup's. One at a
time, so the two never stand together. The button opens the menu only when an
entry in it acts or says why it cannot; with nothing but an inert entry it
stays disabled, as the plain transfer did.

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
(`MixerFailedStep`), or the room is given up as before:

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

## Video

`ConferenceVideoSession` is the client's side of the conference video room
(protocol section 18): two video-only connections next to the mixer's audio one.
`ConferenceRoom` owns one, used only where `CallCapabilitiesConfig.isConferenceVideoEnabled`;
the bloc has no part of the video of its own (see "In the room" below).

- The **subscriber** receives everyone else's video. `subscribe` asks the room, which
  offers through Core; every offer is answered on the same connection, except the
  first after a subscribe and one that arrives while the connection is spent - Core
  sends that one unasked after Janus hung the subscriber up, for a new connection.
  An offer with no subscription standing is not answered.
- The **publisher** sends the camera, video only: the microphone in the camera stream
  belongs to the mixer and is not added. The camera m-line is named `camera` for Core;
  a later publish renegotiates the same publication on the same connection, an ICE
  restart among them. A shared screen goes out on that same line in the camera's place
  (`shareScreen`), named `screen` (`descriptions`): over a published camera the line's
  sender takes the screen and the publication is renegotiated, the camera let go; with
  no camera out a publication is made of the screen alone. `stopScreen` puts the camera
  back on the line, opened again, while it is still wanted, and ends the publication
  otherwise. While the screen is out the camera stays wanted but waits (`publish` says
  `CameraNotPublished`), and taking the camera off - the user, the background - drops the
  wish without touching the screen. A failed publisher is made again with what is
  wanted, the screen first; a screen the room refuses or fails for good is given up and
  told to the owner (`onScreenLost`) - the camera stays wanted then, and the room's video
  puts it back when the person still wants it - and nothing is said when the owner stopped
  it or left the video. A stop that comes before the queued share ran finds the camera
  still on the line and leaves it there. The camera <-> screen move of the line is
  `CameraScreenSwap`, the same as a call's share. The screen's stream belongs to whoever
  captured it; the session never releases it. The shared camera track is turned on for the room; when the room
  lets it go it goes back as the calls want it then (`callsWantCamera`), or as the
  room found it where the owner does not say. A second answer to one publish is
  ignored.
- A publication offers the room Baseline H.264 only (`withBaselineH264Only`, room_video_codecs.dart):
  Janus gives a publication the first codec of its offer and sends it to every subscriber as it
  is, an iPhone offers H.264 High first, and an Android phone's answer refuses that line
  (`m=video 0`) - it saw nothing of an iPhone's camera or screen in the room.
- An offer with a new SDP session id (`o=`) is a new subscription and gets a new
  connection at once, without waiting for the old one's state to say so; what the
  room said of the old streams is dropped with it, since Core names the new ones
  right after the offer. The offer of a restart this client asked for is answered on
  the same connection even if its ICE has failed. Janus offers the update of a
  subscription - another participant's camera joining after this client subscribed -
  under a new session id as well, but with the next version (`o=` version 2 after 1),
  while a new subscription starts at 1: such an offer is answered on the same
  connection. Taken for a new subscription, the closed connection made Janus hang the
  subscriber up, and every picture of the room was gone.
- Candidates a connection gathers before Core acknowledged the request behind it
  would be refused with `no_peer_connection`, so they wait here and go out tagged
  with their `pc`. Remote candidates ahead of an offer or answer wait for it.
- Candidates waiting for the acknowledgement go out at once and in order when it
  comes, so that one gathered meanwhile cannot pass them. An ICE restart starts the
  wait over for both ends: the room's candidates wait for the restart's offer or
  answer, this client's for the publish or answer that carries the new credentials.
  A refused candidate (`conference_video_failed` naming the trickle, for an invited
  far end whose controller acknowledged ahead of the host's) has that connection's
  candidates sent once more when the connection is known to be there.
- An invited far end's own controller acknowledges every answer, so an acknowledged
  answer does not reset the subscriber's retry: a connected subscriber does.
- `conference_video_failed` closes that connection; it is made again once in a row and
  then left gone (the room's 100 publishers, `code` 432, among the reasons).
- A refusal says what to do (protocol section 10): `not_subscribed` subscribes again,
  `attach_failed` asks again once after a short delay, anything else
  (`not_in_conference`, `video_disabled`, ...) ends that connection - a publication
  being renegotiated or restarted as much as a first one. The same holds for the
  refusals an invited far end gets from the host's controller.
- A subscribe or publish that went unanswered may have been taken and is sent once
  more; an answer that went unanswered lets its candidates go all the same; a first publication unanswered twice is undone with `conference_video_unpublish`
  so that Core is not left with it. One that could not be sent at all stays wanted
  and is made again after the reconnect.
- `unpublish` sends the request before it closes the connection, so the room does not
  report the closed one as a failure. `leave` tells the room and closes both;
  `teardown` closes both and tells nobody.
- After a signalling reconnect the subscription is remade from scratch and the
  publisher restarts ICE: events sent while the socket was down are lost and the video
  is not in the handshake.
- Received streams are named by the participant through the `mid` -> `feed` list of
  the last `conference_video_updated`, each with its kind (`camera`, `screen`), and
  reported with the room's `presenter`; a stream the room has not named yet is not
  reported. The list is taken in turn with the offers, on the session's queue: when a
  participant unpublishes, Core offers a new subscription and sends its list 9 ms
  later, while the offer is still being taken - taken first, the list would be
  dropped by the offer, and the cameras that remain would show no more.
- A renegotiation hands the same track over in a new stream object; it is the same
  camera (`ParticipantCamera.isSameTrackAs`), given to the renderer again but not
  waited for: the platform reports a first frame only for a new track.

### In the room

The video is the room's, as its audio is, and a part of it of its own: `RoomVideo`
(`conference/room_video.dart`) holds the session and `ConferenceCameraPlan`, and
decides when to join, when to make the video again, what the camera does in the
background and what a publication that was given up says (`publish` says what
became of each publication: `CameraPublished`, `CameraUnavailable`,
`CameraRefused` with the room's reason, and `CameraNotPublished` for the rest - not
wanted any more, unanswered, not sent). It reads the room and the calls through
functions it is given and raises the room's own steps, commands and notices, with no
vocabulary of its own: the cameras received and the refusal of the room's video as
steps (`VideoFeedsChangedStep`, `VideoDisabledStep`, `CameraSwitchedStep`), which the
room writes as a `ConferenceUpdate`, the camera of a leg as `SetLegCameraCommand`, a
camera that could not be opened as `CameraUnavailableNotice`, a shared screen the room
would not take as `ScreenShareLostNotice`.

The bloc hands the room's video, through `ConferenceRoom.video` (`RoomVideoControls`),
only what concerns it: the video events of the signalling (`onEvent`, recognised by
`RoomVideo.isEvent`), the camera controls (`setCamera`, `switchCamera`), the screen
(`shareScreen`, `stopScreenShare`, `takesScreen`, through `RoomScreenDestination`), the app's
lifecycle (`onAppLifecycleChanged`), a session that came back (`onSessionBack`;
`onRoomKept` when the handshake keeps the room), and the calls as they change
(`onCallsChanged`).

- The host joins the room's video once the mixer's answer is taken: everyone else's
  cameras, and his own when one of the merged calls was a video call. After a
  signalling reconnect with the room standing, and after a rejoin, the video is made
  again over the session that is up: the subscription from scratch, the publisher
  with an ICE restart (18.7).
- An invited far end (protocol section 19) joins on `conference_video_invite` through
  the call on that line; its video ends with `conference_video_terminated`, with the
  end of that call (whether or not the event arrived) and with a reset of every call.
  After a signalling reconnect it remakes the video as the host does. The invitation
  is in `CallState.invitedVideo` from the moment it is taken. A client that merges
  calls of its own leaves the invitation first (`conference_video_leave`) - on the way
  to the server, so not for a merge that goes nowhere; the same for a join through a
  call placed to bring somebody in - and its own room gets its own video.
- A room the server refuses the video of (`video_disabled`) is audio only to its end:
  `ConferenceState.videoDisabled` is set, nothing more is asked of its video, and a
  video call is not offered to it (`CallState.roomTakesVideo`) - the server would end
  the whole conference over one (section 17).
- What the user asked of the camera is `ConferenceCameraPlan`: it outlives the app
  going to the background, where the camera is unpublished (the others see the
  avatar) and from where it is published again. A room that starts while the app is
  in the background publishes the camera when the app returns; the bloc tells the
  video where the app is when it starts, not only when that changes. A camera that could
  not be opened, or that the room refused, is said to the user and taken for
  unwanted.
- The camera is opened once and shared with the calls that send video. The room's
  camera button turns the legs' camera on and off with it - their video is not
  forwarded in the room, and a call left alone when the room is gone goes on as the
  camera was - and a camera switch tells the legs which camera they show. A participant sees
  the host by the video of its own call with him, so a leg that is a voice call is given the
  camera when the room's is turned on: its call renegotiated with video, as a call's camera
  button does; a far end that refuses the video stays a voice call. A video
  call outside the room that has its camera on keeps it when the room's is turned
  off, and when the room lets the camera go it stays on only for a call whose own
  camera the user has on.
- The camera control of the default screen is the room's on a leg, and on the call
  an invitation came through (`CallActionAvailability.cameraActsOnRoom`); for a room
  with no video it offers nothing.
- A participant called into a room is called with video when the room carries any
  (`ConferenceState.hasVideo`); one called for a video call that a room is to be made
  of, when that call is a video call.
- Received cameras go to `ConferenceState.videoFeeds` for the host and to
  `CallState.invitedVideo` for an invited far end; the host's own published camera is
  `ConferenceState.selfVideo`, shown only in full screen, as the "You" tile. A video
  call outside the room keeps its own preview; one that joins a room loses it.
- On the default screen the host sees a participant's camera on their row of the
  panel (`ConferenceParticipantCamera`): round and of the avatar's own size, over the
  avatar, which stays where it is - a row is the same with a camera and without one,
  does not move when a camera comes or goes, and its picture is not made again. The
  camera shows once it has drawn a frame, and after a new stream for it (a
  subscription made again) once that one has: until then the avatar is seen, not an
  empty circle. The renderer is given the camera's own track (`ParticipantCamera`):
  the room gives every track of its subscription the same stream id (Janus sends
  `a=msid:janus janus<N>`), and a stream id alone would show the first participant's
  camera on every row. A leg whose call is not known yet shows no picture and no
  camera. The camera is `conferenceParticipantCamera<N>` for a case while it is seen.

### The screen in the room

A screen is shared in a room where the video of the call goes (`ScreenShareCoordinator`, see
[call_arch.md](call_arch.md), Screen share): for the host from a leg - the More menu of the full
screen ("Share screen", `callScreenShareConferenceId`) or the default screen's three-dot menu while
a leg is focused - as one share of the room whichever leg asked; for an invited far end from the
call the invitation came through, as in a call. Its status is `CallState.screenShare` like any
share's, read for a leg as the room's (`screenShareOf`, `roomScreenShare`). The consent, the
service and the capture are a call's own; the captured screen goes to `RoomVideo.shareScreen`
(`RoomScreenDestination`) instead of a call's sender. Its stop waits for the room to take the
screen off before the capture is released, without holding the bloc's queue; the share is over
for the state at once.

- **Who may share.** The host while the room is up and has video and is not parked for a call
  outside it; an invited far end while its invitation stands. One share at a time on a phone: while
  one runs, no other call offers to start one. Anyone in the room may share while someone else
  does: Core keeps them in order and calls the latest its presenter, the one before again when the
  latest stops; this client follows the room's word.
- **While sharing.** The screen takes the camera's place on the room's line and the camera is let
  go. The camera control stays: what the person asks of it is remembered by the room's video
  (the session holds the wish), and a camera wanted comes back after the share - the same for the
  host and for an invited far end - facing the way the room's calls show it (`callsFrontCamera`),
  the front camera where none says: opened without a facing, an iPhone gives the rear one. On the
  default screen the call screen's floating tile says
  "Sharing screen" with its Stop (`callScreenShareTileId`, `callScreenShareStopId`), as for a call;
  on the full screen the host's "You" tile says it instead (`ConferenceFullScreen.isOpen` tells the
  call screen). More reads "Stop sharing". In the background the screen stays in the room - the
  person shares what they look at elsewhere - while a camera would leave. The room's SIP phones
  get the screen (Core sends them the presenter's screen first).
- **The host's participants.** A participant sees the host by the video of its own call with
  him, not by the room's, so the host's share also goes on every leg's video sender in the
  camera's place (`RoomScreenDestination` with a `CallSenderDestination` per leg) and the camera
  goes back there after it, on or soft-muted as it was. A leg that is a voice call is given a
  video sender for the screen, its call renegotiated, and keeps it empty after: the camera need
  not have been on. A far end that refuses the video stays a voice call and the share goes on
  for the others. The legs are told the video is on (`media_state`) for the share and as the
  camera is after it. A camera turned on while the screen is out reaches the legs after it.
- **Stop.** The person, the notification, the end of the capture outside the app, the end of the
  room or of its video, a room parked for a call outside it (the person is talking to somebody
  else), the end of the invitation, and a room that refuses or fails the screen for good (told as
  "Screen sharing could not start"; the camera comes back when it is wanted). The host's way back
  into the room (rejoining) keeps the share: the room's video is made again with the screen on its
  line.
- **A share that was there before.** A call that shares its screen and then joins a room -
  merged or added by the host, or invited by its far end - stops its share first: the room's
  video is not that call's, and the share is started again from the room.
- **Receiving.** Received screens go to `ConferenceState.screens` with the room's `presenter`;
  the full screen shows the presenter's screen in the main place (`ConferenceState.mainScreenFeed`:
  the presenter's, else any received - the host's own is not received), whole (contained),
  `callScreenShareConferenceScreenId`, and the tiles in one row under it that scrolls sideways. A
  phone sends its screen only when the screen changes, so a picture opened after the sharer's last
  change gets no frame until the next one (seen on the stand: a still home screen left the place
  empty); until the first frame the place shows who shares and "Waiting for the screen". An
  invited far end keeps a participant's screen as that participant's video
  (`InvitedConferenceVideo.feeds`), in place of the camera it stands in for.

### Full screen

The room in full screen is a page of the call screen's routes on a phone
(`ConferenceFullScreenPage`, one participant `ConferenceParticipantPage`, in
`callScreenRoutes`), declared by `CallScreenHandset` over the default screen. It opens
from the round button of the panel's header while the room has video and the focused
call is one of its legs. Back - the arrow or the system Back - pops the top page. It
closes by itself, as the watch's pages do: a call ringing, the focus moving to a call
outside the room (calling somebody in through Add moves it) and the end of the room
bring back the default screen; the focus moving from one leg to another - the first leg
leaving a room that goes on - keeps it open. A participant who leaves takes his page
with him, showing him until it is gone, and the page on top - the tiles or another
participant - says who left. The tiles under a participant's page are not seen and
hold no cameras; they get them back when the page closes. The "You" tile shows the
front camera mirrored, as the local preview does, and the rear one as it is. The routes
are shared with the watch, which never opens the room: under a host without the phone's
call screen a page of the room shows nothing and pops itself. The tiles show the cameras through
`ParticipantVideo`, the same widget as the rows' round camera
(`widgets/conference_participant_camera.dart`): the avatar until a first frame, the
participant's own track, the renderer released with the tile. A tile keeps its renderer
when it moves to another row. The end control of its bar ends the room, as the default
screen's hangup does while the focused call is a leg.

### Redesign / in progress

- A camera that stops sending after its first frame shows its last frame, or black,
  over the avatar: nothing tells the row that the frames stopped.
- An invited far end sees no camera yet: what it receives is in
  `CallState.invitedVideo` (a participant's screen in place of the camera) and is shown nowhere.
- A share of a call that joins a room stops rather than carrying over into the room's
  video: the capture could move, but the room's publication comes later than the merge,
  and a carried share would need a state of its own while it waits.
- The call screen has two more owners of an `RTCVideoRenderer` (`StreamThumbnail`,
  `RTCStreamView`) that release one before it is made and so keep its texture;
  `ParticipantVideo`, shared by the rows and the tiles, does not, and is not shared
  with them yet.
- While the room is in full screen the default screen stays built under it, so a
  participant's camera is drawn by the renderer of their row as well as by their tile
  (the tiles under a participant's page hold none).
- The speaker / audio device control of the full screen's bar is a third copy of the
  audio route control, beside the default screen's and the watch's; the three are to be
  one shared control.
