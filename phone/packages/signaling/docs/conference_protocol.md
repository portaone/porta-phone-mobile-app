# Conference protocol

Wire-level reference for the audio-conference messages this package carries: the
exact JSON of every request, response and event, the Dart class for each, what
Core does on receipt, what it refuses with, in which order things arrive, and what
the client must do locally at each step. Enough to write a client against without
reading Core.

Last reviewed: 2026-09-11. Sources: `webtrit_core` origin/main 7db35cfb
(`lib/webtrit_core_app/controller/conference.ex`, `signaling_handler.ex`,
`janus_handler.ex`, `signaling_sender.ex`), `@webtrit/webtrit-signaling` 0.6.0, the
Web Dialer implementation (Gerrit `porta-phone/web-app` 5946b5c). Where the
conference client guide shipped in `webtrit_core/docs/` differs from the code, this
document follows the code and says so in section 12.

Contents

1. The model
2. Framing: envelopes, transactions, responses
3. Dart mapping
4. Requests
5. Events
6. The participant
7. The handshake and reconciliation
8. Sequences
9. Client-side state and obligations
10. Refusal reasons
11. Ordering and timing guarantees
12. Where the client guide and the code differ
13. Things that concern the room but are not conference messages
14. Worked example: a three-way conference, message by message
15. Limits
16. What the package tests cover

## 1. The model

A conference merges calls that are already established on the subscriber's lines
into one mixing room (Janus AudioBridge). Nothing is signalled to the PBX; for each
far end it stays an ordinary one-to-one call with the subscriber.

```
  subscriber's client                        Janus
   | PC per line ---> janus_sip line 0 --- SIP ---> PBX ---> B    mic + inbound muted locally
   |             ---> janus_sip line 1 --- SIP ---> PBX ---> C    mic + inbound muted locally
   +- one more PC --> AudioBridge room                             mic in, mix out
                        ^            v
                  bridge_out    configure rtp     (RTP rerouted inside Janus)
```

Consequences the client is built around:

- N parties cost N-1 calls, all owned by the subscriber, each billed separately,
  each occupying one of the subscriber's lines (`USER_APP_LINE_COUNT_INITIAL`,
  default 2, so three parties out of the box).
- The subscriber cannot leave: hanging up any leg ends that call; tearing the room
  down leaves the calls up. There is no "step out"; the client offers self-mute.
- There is exactly one room per signalling session. Requests therefore carry no
  room identifier; events carry `room` for the client to check against.
- The per-line PeerConnections stay open for the whole conference. Closing one
  makes Janus send a SIP BYE and ends that call. They are silenced, not closed.

## 2. Framing: envelopes, transactions, responses

Everything travels on the signalling WebSocket the client already uses for calls.
There is no new endpoint and no new socket.

Request envelope. `transaction` is a client-chosen string, unique per request;
`WebtritSignalingClient.execute` generates it when the request's `transaction` is
empty. Conference requests carry no `call_id`. Where they carry `line`, it is the
line number of a participant (a parameter), not a routing address: Core dispatches
every request whose name starts with `conference_` as a session request before it
looks at `line` (`signaling_handler.ex:72-97`).

```jsonc
{ "request": "merge", "transaction": "t-1", "lines": [0, 1] }
```

Response envelope. Exactly one per request, matched by `transaction`, delivered as
the result of `execute`:

```jsonc
{ "response": "ack",   "transaction": "t-1" }                                    // accepted for processing
{ "response": "error", "transaction": "t-1", "code": 0, "reason": "no_conference" } // refused
```

`ack` means accepted, not done: what actually happened arrives later as an event.
A refusal always has `code: 0`; the meaning is the `reason` string (section 10).
In Dart, `execute` returns normally on `ack` and throws
`WebtritSignalingErrorException(id, 0, reason)` on `error`. The numeric
`SignalingResponseCode` table does not apply; `SignalingResponseCode.values.byCode(0)`
is `null`.

Event envelope. Conference events are session-level: no `line`, no `call_id`, and
no `transaction` (Core sends them with `send_event_session/2`, which adds no
transaction). They are pushed by the server at any time after the request that
caused them, or unprompted.

```jsonc
{ "event": "conference_updated", "room": 4242, "participants": [ ... ] }
```

Parsing. `Event.fromJson` throws `ArgumentError` on an unknown `event` value, and
`WebtritSignalingClient` routes that into its error handler, which the app treats
as a connection failure. The five conference events are registered in
`SessionEvent._sessionEventFromJsonDecoders`; a future Core event not listed there
would still drop the connection, so this table must grow with Core.

## 3. Dart mapping

| Wire | Dart class | File under `lib/src/` |
|---|---|---|
| `merge` | `MergeRequest({transaction, lines})` | `requests/conference/merge_request.dart` |
| `conference_add` | `ConferenceAddRequest({transaction, line})` | `requests/conference/conference_add_request.dart` |
| `conference_answer` | `ConferenceAnswerRequest({transaction, jsep})` | `requests/conference/conference_answer_request.dart` |
| `conference_ice_trickle` (req) | `ConferenceIceTrickleRequest({transaction, candidate})` | `requests/conference/conference_ice_trickle_request.dart` |
| `conference_mute` | `ConferenceMuteRequest({transaction, line, muted})` | `requests/conference/conference_mute_request.dart` |
| `conference_remove` | `ConferenceRemoveRequest({transaction, line})` | `requests/conference/conference_remove_request.dart` |
| `conference_hangup` | `ConferenceHangupRequest({transaction})` | `requests/conference/conference_hangup_request.dart` |
| `conference_offer` | `ConferenceOfferEvent({room, jsep, participants})` | `events/conference/conference_offer_event.dart` |
| `conference_ice_trickle` (evt) | `ConferenceIceTrickleEvent({candidate})` | `events/conference/conference_ice_trickle_event.dart` |
| `conference_updated` | `ConferenceUpdatedEvent({room, participants})` | `events/conference/conference_updated_event.dart` |
| `conference_failed` | `ConferenceFailedEvent({reason, room, detail})` | `events/conference/conference_failed_event.dart` |
| `conference_terminated` | `ConferenceTerminatedEvent({room})` | `events/conference/conference_terminated_event.dart` |
| participant object | `ConferenceParticipant({line, callId, muted})` | `events/conference/conference_participant.dart` |
| handshake `conference` | `ConferenceInfo({room, participants})` on `StateHandshake.conference` | `handshakes/conference_info.dart` |
| `reason` string | `ConferenceRefusalReason.fromReason(String)` | `conference_refusal_reason.dart` |
| `{"completed": true}` | `iceCandidateFromJson` / `iceCandidateToJson` | `ice_candidate_json.dart` |

All requests extend `SessionRequest`, all events extend `SessionEvent`. Every
class round-trips through `toJson` / `fromJson` and is `Equatable`.

## 4. Requests

Each entry: purpose, wire fields, Core behaviour on receipt, refusals, client
obligation, example.

### 4.1 `merge` - build a room from established calls

| field | type | required | meaning |
|---|---|---|---|
| `request` | `"merge"` | yes | |
| `transaction` | string | yes | |
| `lines` | `int[]` | yes | line numbers whose calls join the room |

Core (`Conference.start/2`), synchronously before the response:

1. `CONFERENCE_ENABLED` off -> refuse `conference_disabled`.
2. A room already exists on this session -> refuse `conference_already_active`.
3. `lines` empty -> refuse `not_enough_lines`. Note: one line is accepted.
4. Any line without an active call -> refuse `line_without_active_call`.
5. Attach an AudioBridge handle for the app and `create` the room; on failure refuse
   `attach_failed: <text>` or `room_create_failed: <text>`.
6. Attach one AudioBridge handle per leg and `join` it as a plain-RTP participant.
7. Answer `ack`, arm a 10 s setup deadline, and send `bridge_in` to each leg's SIP
   handle.

Asynchronously, per leg, on the `bridge_in` reply:

- the leg is a video call -> the whole room is abandoned: `conference_failed` with
  `reason: video_not_supported`, then nothing else;
- the negotiated codec is not Opus, PCMA or PCMU (G.722 is the usual case) -> the
  leg is dropped silently: if two or more legs remain, wiring continues and the
  room is built without it; if fewer than two remain, `conference_terminated`;
- otherwise Core wires the mix both ways for that leg and sends Janus an `unhold`
  for it (a leg on hold is deaf and mute in the room), and marks it ready.

When every remaining leg is ready, Core joins the room on the app's behalf and the
mixer's SDP offer arrives as `conference_offer` (section 5.1). If not every leg is
ready within 10 s of the `ack`, `conference_terminated`.

Client obligation. Immediately after `ack`, for every line in `lines`: disable the
microphone track and the inbound audio track of that line's PeerConnection, and
record the line as muted-for-conference. Do this on `ack`, not on `conference_offer`:
a failure between the two arrives as `conference_failed` or `conference_terminated`
and the client undoes the muting from that record. Enforce "two or more lines"
locally; Core does not. Do not offer a video call as a candidate; Core refuses it
after `ack`, not before.

```jsonc
-> { "request": "merge", "transaction": "t-1", "lines": [0, 1] }
<- { "response": "ack", "transaction": "t-1" }
   ... bridge_in, configure, bridge_out, unhold per leg ...
<- { "event": "conference_offer", "room": 4242, "jsep": {...}, "participants": [...] }
```

### 4.2 `conference_add` - add one more established call to the room

| field | type | required | meaning |
|---|---|---|---|
| `request` | `"conference_add"` | yes | |
| `transaction` | string | yes | |
| `line` | int | yes | the line whose call joins; a participant index, not an address |

Core (`Conference.add_line/2`): no room -> `no_conference`; line already a
participant -> `line_already_in_conference`; no call on the line ->
`line_without_active_call`; handle attach failure -> `attach_failed: <text>`.
Otherwise `ack`, then the same per-leg wiring as in `merge`. A leg added while the
room is still assembling is not announced separately: it appears in the
`conference_offer` list. A leg added to an active room is announced by
`conference_updated` once it is wired. No new offer is sent to the app: the app's
PeerConnection to the mixer is unchanged.

Client obligation: mute that line in both directions after `ack`, exactly as for
`merge`, and record it.

### 4.3 `conference_answer` - answer the mixer's offer

| field | type | required | meaning |
|---|---|---|---|
| `request` | `"conference_answer"` | yes | |
| `transaction` | string | yes | |
| `jsep` | `{ "type": "answer", "sdp": string }` | yes | the local description of the conference PeerConnection |

Core relays it to the app's AudioBridge handle. Never refused; ignored without a
room. There is no confirmation event; the PeerConnection connecting is the
confirmation.

Client obligation: create a new PeerConnection, `setRemoteDescription(offer.jsep)`,
add the local audio track (audio only; a video m-line is rejected by the mixer),
`createAnswer`, `setLocalDescription`, send it here, then trickle candidates.

### 4.4 `conference_ice_trickle` - ICE candidate of the conference PeerConnection

| field | type | required | meaning |
|---|---|---|---|
| `request` | `"conference_ice_trickle"` | yes | |
| `transaction` | string | yes | |
| `candidate` | candidate object or `{ "completed": true }` | yes | in Dart, `null` encodes as the completed marker |

The candidate object is the WebRTC one (`candidate`, `sdpMid`, `sdpMLineIndex`),
passed through verbatim. Core relays it to the app's mixer handle. Never refused.
If the mixer handle does not exist yet (offer not sent), Core drops it with a log
warning; trickle only after `conference_offer`.

### 4.5 `conference_mute` - room-wide mute of one participant

| field | type | required | meaning |
|---|---|---|---|
| `request` | `"conference_mute"` | yes | |
| `transaction` | string | yes | |
| `line` | int | yes | the participant |
| `muted` | bool | no, default `true` | `true` silences them for everyone, `false` restores |

Core (`Conference.set_muted/3`): no room -> `no_conference`; line not a participant
-> `line_not_in_conference`; participant not yet wired -> `line_not_ready`;
`muted` present but not a boolean -> `invalid_muted`. Otherwise Core tells the
mixer to stop (or resume) taking that participant's audio, records the flag, and
sends `conference_updated` with the new `muted` values.

What it is not: it does not touch the participant's call or SIP leg, they keep
hearing the room; and it is unrelated to the local mute the client applies to a
merged line's PeerConnection (section 9), which nobody in the room notices.

Client obligation: keep the per-participant control disabled until that participant
is present in the last `conference_offer` / `conference_updated` list; before that
Core answers `line_not_ready`. Always send `muted` explicitly.

### 4.6 `conference_remove` - take a leg out of the mix, keep its call

| field | type | required | meaning |
|---|---|---|---|
| `request` | `"conference_remove"` | yes | |
| `transaction` | string | yes | |
| `line` | int | yes | the participant |

Core (`Conference.remove_line/2`): never refused; a no-op for a line that is not a
participant. Stops the bridging on that leg, detaches its mixer handle, and: if two
or more legs remain, `conference_updated` without it; otherwise tears the room down
with `conference_terminated`. The removed call stays up and is active (not held):
Core un-held it on join and does not hold it back.

The app does not send this request (product decision: a participant is removed by
hanging up their call, which removes the leg as a side effect, section 13). The
class is carried so the package speaks the whole protocol. A client that does use
it must give that line its audio back and put it on hold, or the host talks into
the room and into that call at once.

### 4.7 `conference_hangup` - tear the room down, keep the calls

| field | type | required | meaning |
|---|---|---|---|
| `request` | `"conference_hangup"` | yes | |
| `transaction` | string | yes | |

Core (`Conference.stop/1`): never refused; a no-op without a room. Stops bridging on
every leg, destroys the room, sends `conference_terminated`. Every merged call
survives, and every one of them is active at the same time, because Core un-held
them on join and does not hold them back.

The app follows this with a hangup of every leg (product decision). A client that
keeps the calls must restore audio on each and hold all but one; see section 9.

## 5. Events

### 5.1 `conference_offer` - the mixer's offer; the room is established

| field | type | always | meaning |
|---|---|---|---|
| `event` | `"conference_offer"` | yes | |
| `room` | int | yes | the room id; keep it |
| `jsep` | `{ "type": "offer", "sdp": string }` | yes | the mixer's SDP |
| `participants` | participant[] | yes, may be empty | the legs in the room now |

When: once every leg that survived wiring is ready and the app's join on the
mixer has completed. Core sends one offer per room (`app_joined?` guard); a client
should still tolerate a second offer for the same `room` by renegotiating on the
same PeerConnection, and must treat an offer for a different `room` as a new room
(close the old PeerConnection, build a new one). A reused, spent PeerConnection
looks connected and carries silence.

Client obligation: build the conference PeerConnection and answer (4.3). From this
event on, the room is "active": `conference_updated` starts to arrive, and
`conference_mute` on the listed participants is accepted. Clear the local `held`
flag on every listed participant's call (Core un-held them) and tell the OS
(CallKit / Telecom) accordingly.

### 5.2 `conference_ice_trickle` - ICE candidate from the mixer

| field | type | always | meaning |
|---|---|---|---|
| `event` | `"conference_ice_trickle"` | yes | |
| `candidate` | candidate object or `{ "completed": true }` | yes | in Dart, the marker decodes to `null` |

Feed to the conference PeerConnection with `addIceCandidate`; `null` ends
gathering. May arrive before the client has finished creating the PeerConnection:
queue it.

### 5.3 `conference_updated` - the authoritative participant list changed

| field | type | always | meaning |
|---|---|---|---|
| `event` | `"conference_updated"` | yes | |
| `room` | int | yes | |
| `participants` | participant[] | yes | the full current list, sorted by `line` |

When (only after the app has joined; before that the list travels with the offer):

- a `conference_mute` took effect (a `muted` flag changed);
- a leg added with `conference_add` finished wiring (a new entry);
- a leg left with two or more remaining: `conference_remove`, the far end or the
  subscriber hung that call up, or Core dropped it because it could not be mixed
  (an entry disappeared).

Client obligation: replace the local list; never accumulate deltas. Diff against the
previous list: for every `call_id` that disappeared and whose call is still up
(not hung up), restore its audio in both directions and put the call on hold. For
every new entry, clear that call's `held` flag. Re-enable the per-participant mute
control for entries that are now present.

### 5.4 `conference_failed` - the room could not be built

| field | type | always | meaning |
|---|---|---|---|
| `event` | `"conference_failed"` | yes | |
| `room` | int or absent | no | |
| `reason` | string | yes | today always `video_not_supported` |
| `detail` | string or absent | no | human-readable, e.g. `line 1 is a video call and the mixer is audio only` |

When: a leg's `bridge_in` reply reports video. The room is gone; no
`conference_terminated` follows. Every other assembly failure (a leg that never
joins, an unsupported codec, an AudioBridge error) does not take this form: it
either drops the leg (`conference_updated`) or ends the room
(`conference_terminated`).

Client obligation: undo the muting recorded since `ack` on every line, drop the
local room state, show the reason.

### 5.5 `conference_terminated` - the room is over

| field | type | always | meaning |
|---|---|---|---|
| `event` | `"conference_terminated"` | yes | |
| `room` | int or absent | no | |

Five causes, indistinguishable on the wire:

1. the subscriber sent `conference_hangup`;
2. fewer than two legs were left to mix, after a remove, a hangup or a dropped leg;
3. the 10 s setup deadline passed with a leg still joining;
4. the controller shut down while Janus was alive (session end);
5. Core lost its Janus session and discarded the room (`Conference.discard/1`).

In causes 1-4 the calls that are still up carry on as ordinary calls. In cause 5
they have no media any more and their hangup events follow shortly.

Client obligation: close the conference PeerConnection, drop the room state, and for
every recorded merged line whose call is still established: restore audio in both
directions; then hold every one of them except the one the user is focused on
(they are all active at once after the room). Skip calls that are disconnecting.
If the client itself sent `conference_hangup` and intends to hang the legs up, skip
the restore.

## 6. The participant

```jsonc
{ "line": 1, "call_id": "def", "muted": true }
```

| field | type | meaning |
|---|---|---|
| `line` | int | the leg's line; the key for `conference_mute` and `conference_remove` |
| `call_id` | string | the call on that line; the key to the client's own call record (name, direction, state) |
| `muted` | bool | the room-wide mute the host set with `conference_mute` |

Core builds this list with `participant_lines/1`, sorted by `line`, `muted` always
present. The Dart parser reads `muted` leniently (anything but an explicit `true`
is `false`), as the signaling_ts client does. The host is never in the list; a UI
that shows the host adds that row itself.

## 7. The handshake and reconciliation

The `state` handshake gains one key:

```jsonc
{ "handshake": "state", "keepalive_interval": 30000, "timestamp": ..., "registration": {...},
  "lines": [...], "guest_line": {...}, "dialog_infos": [...], "presence_infos": [...],
  "conference": null }
{ ..., "conference": { "room": 4242,
                       "participants": [ { "line": 0, "call_id": "abc", "muted": false } ] } }
```

`StateHandshake.conference` is `ConferenceInfo?`: `null` when absent or `null`
(a Core without conferencing sends no key). The Android FGS hub codec carries the
block across the isolate boundary (`signaling_service_android`, `lib/src/fgs/hub/signaling_hub_codec.dart`).

The room lives in Janus and outlives a signalling drop; the client's conference
PeerConnection does not survive an app restart. On every handshake:

| server `conference` | client has a room | do |
|---|---|---|
| present | no | send `conference_hangup`: the room cannot be rejoined, and it would otherwise keep a participant that never comes back |
| `null` | yes | forget the room locally; restore audio on recorded merged lines that are still established |
| present | yes | adopt the server's `room` and `participants` as authoritative |
| `null` | no | nothing |

Observed on the test stand: after a page reload with calls already gone the
handshake carries `conference: null`, so the first row is hard to reach; the
`ForgetConference` row is the one that runs after an app restart.

## 8. Sequences

### 8.1 Building a room

```
client                                        Core
  |  merge {lines:[0,1]}                        |
  | ------------------------------------------> |  checks, room create, join legs
  |  ack                                        |
  | <------------------------------------------ |  arm 10 s deadline, bridge_in x2
  |  [mute both lines, both directions, now]    |
  |                                             |  per leg: configure, bridge_out, unhold, ready
  |                                             |  all ready -> app join
  |  conference_offer {room, jsep, participants}|
  | <------------------------------------------ |
  |  [new PeerConnection, setRemote, answer]    |
  |  conference_answer {jsep}                   |
  | ------------------------------------------> |
  |  ack                                        |
  | <------------------------------------------ |
  |  conference_ice_trickle (both ways, many)   |
  | <-----------------------------------------> |
  |  [PeerConnection connected: mix audible]    |
```

Between `ack` and `conference_offer` the room does not exist from the client's
point of view. Failures in that window: `conference_failed` (video) or
`conference_terminated` (deadline, too few legs, AudioBridge error).

### 8.2 Adding a fourth party

```
  place an ordinary call on a free line, wait for it to be established (accepted)
  |  conference_add {line: 2}                   |
  | ------------------------------------------> |  attach, join, bridge_in
  |  ack                                        |
  | <------------------------------------------ |
  |  [mute line 2, both directions]             |
  |                                             |  configure, bridge_out, unhold, ready
  |  conference_updated {room, participants x3} |
  | <------------------------------------------ |
```

Placing that call while the room is up must not put the merged lines on hold; Core
refuses a hold on a conferenced line with `line_in_conference` (section 13).

### 8.3 A far end hangs up (three legs, room continues)

```
  <- hangup {line: 1, call_id: "def"}           ordinary call event, that call is over
  <- conference_updated {room, participants without "def"}
```

Nothing to restore: that call is gone. With two legs, the second message is
`conference_terminated` instead, and the remaining call is restored (5.5).

### 8.4 The host ends the conference (app behaviour)

```
  -> conference_hangup                          |
  <- ack                                        |
  <- conference_terminated {room}               |  calls still up, all active
  -> hangup {line: 0, ...}  -> hangup {line: 1, ...}   app hangs each leg up itself
```

### 8.5 A leg Core cannot mix (G.722)

```
  -> merge {lines:[0,1,2]}      <- ack      [mute 0,1,2]
                                            bridge_in reply for line 1: codec G722 -> dropped
  <- conference_offer {participants: [line 0, line 2]}
  [line 1 vanished from the list: restore its audio, hold it]
```

With only two lines and one dropped: `conference_terminated` instead of the offer.

### 8.6 Video refusal

```
  -> merge {lines:[0,1]}        <- ack      [mute 0,1]
  <- conference_failed {room, reason: "video_not_supported", detail: "line 1 ..."}
  [restore audio on 0 and 1; no conference_terminated follows]
```

### 8.7 Reconnect while the room is up

```
  socket drops; Janus and the room stay up; the merged calls stay up
  socket reconnects -> handshake state {conference: {room, participants}}
  client still holds its room and PeerConnection -> adopt server list, carry on
  client lost its PeerConnection (restart) -> conference_hangup, then restore/hold legs
```

### 8.8 Janus lost

```
  <- conference_terminated {room}     (Core discard/1; legs have no media)
  <- hangup ... per line, shortly after
  [restore only calls still established; expect them to end]
```

## 9. Client-side state and obligations

Room state as the client should model it:

```
none --merge ack--> assembling --conference_offer--> active --conference_terminated--> none
                    |  conference_failed / conference_terminated -> none (undo muting)
                    +- conference_add ack: extra line recorded as muted
active --conference_updated--> active (list replaced; vanished legs restored+held; new legs un-held)
active --handshake conference:null--> none (restore)
none --handshake conference:{...}--> send conference_hangup, stay none
```

Obligations, each one a defect the web implementation hit first:

| when | do |
|---|---|
| `ack` to `merge` / `conference_add` | mute mic and inbound audio on each named line's PeerConnection; record the line |
| any time while merged | never close a merged line's PeerConnection (Janus sends BYE); never send `hold` for it; exclude it from "hold the others" when placing or answering a call |
| `conference_offer` | fresh PeerConnection per `room`; clear `held` on listed calls and tell the OS; treat participants as the list |
| `conference_updated` | replace the list; restore + hold every vanished call still up; clear `held` on new entries |
| `conference_failed` | undo muting on all recorded lines; drop state |
| `conference_terminated` | close the conference PeerConnection; restore audio on recorded lines still established; hold all but the focused one; skip if the client is about to hang them up |
| handshake `conference:null` with local room | as terminated |
| handshake `conference:{...}` without local room | `conference_hangup` |
| OS asks to hold a merged line (CallKit / Telecom) | refuse locally; the OS-level conference/grouping is the plugin's job |

"Restore audio" means: re-enable the microphone track and the inbound audio track
on that line's PeerConnection.

## 10. Refusal reasons

`ConferenceRefusalReason.fromReason(reason)`; exact match, or prefix match on
`<value>:` for the two families that carry a diagnostic after a colon. Keep the raw
`reason` string from the exception when the text matters.

| `reason` | enum value | sent by | meaning |
|---|---|---|---|
| `conference_disabled` | `conferenceDisabled` | `merge` | `CONFERENCE_ENABLED` is off on this Core; hide the feature (the adapter also omits `conference` from `system-info.supported`) |
| `conference_already_active` | `conferenceAlreadyActive` | `merge` | one room per session |
| `not_enough_lines` | `notEnoughLines` | `merge` | `lines` was empty |
| `line_without_active_call` | `lineWithoutActiveCall` | `merge`, `conference_add` | no call on that line |
| `room_create_failed: <text>` | `roomCreateFailed` | `merge` | AudioBridge `create` failed |
| `attach_failed: <text>` | `attachFailed` | `merge`, `conference_add` | could not attach an AudioBridge handle, e.g. plugin not loaded |
| `no_conference` | `noConference` | `conference_add`, `conference_mute` | nothing to act on |
| `line_already_in_conference` | `lineAlreadyInConference` | `conference_add` | |
| `line_not_in_conference` | `lineNotInConference` | `conference_mute` | |
| `line_not_ready` | `lineNotReady` | `conference_mute` | participant still joining; retry after it appears in a list |
| `invalid_muted` | `invalidMuted` | `conference_mute` | `muted` present but not a boolean |
| `line_in_conference` | `lineInConference` | LINE `hold` | not a conference refusal: a hold on a merged line, on the `HoldRequest` transaction |
| anything else | `unknown` | | keep the raw string |

`conference_answer`, `conference_ice_trickle`, `conference_remove` and
`conference_hangup` are never refused.

## 11. Ordering and timing guarantees

- The `ack` / `error` for a request always precedes any event that request causes.
- `conference_offer` arrives at most once per `room` in current Core
  (`app_joined?`), after every surviving leg is wired, and never before the `ack`.
- `conference_updated` never arrives before `conference_offer` for that room; while
  the room is assembling, list changes are folded into the offer.
- Setup deadline: 10 s from the `ack` of `merge` to every leg being ready; on expiry
  `conference_terminated`. `conference_add` does not re-arm it.
- `conference_failed` and `conference_terminated` are terminal: the room is gone
  and no further event for that `room` follows.
- Events carry no `transaction`; correlate by `room` and by order.
- A `hangup` call event for a merged line precedes the `conference_updated` or
  `conference_terminated` it causes.
- Core sends Janus `unhold` for a joining leg without any client event; the only
  signal is the participant appearing in a list.

## 12. Where the client guide and the code differ

The conference client guide in `webtrit_core/docs/` is right on the model and the
local rules; these four points follow the code instead:

1. `not_enough_lines` is sent only for an empty `lines` list. A one-line `merge`
   is accepted; the client enforces two or more.
2. End of ICE gathering is `{"completed": true}`, as signaling_ts 0.6.0 sends and
   as the line-level `ice_trickle` event already uses, not `null`.
3. `line_in_conference` is not a conference refusal; it is the refusal of a line
   `hold` request.
4. Handshake participants carry `muted` (the TypeScript type omits it).

And one point the guide states as "silent" that is not: losing the Janus session
sends `conference_terminated` (section 5.5, cause 5).

## 13. Things that concern the room but are not conference messages

- `hold {line}` on a merged line: refused with `code: 0, reason: line_in_conference`
  on the `HoldRequest` transaction. The client must not send it; the OS-level hold
  on that call is the plugin's concern.
- Core's un-hold of a joining leg: a Janus `unhold`, no event. Clear the local
  `held` flag when the participant appears in a list.
- `hangup` on a merged line: the ordinary call event, then `conference_updated`
  without that participant or `conference_terminated`.
- Participant removal in the app: an ordinary hangup of that call, not
  `conference_remove`.
- Feature discovery: `GET /api/v1/system-info` lists `conference` in the adapter's
  `supported` functionalities when the deployment offers it; without it, hide the
  merge control (a `merge` would only fail with `conference_disabled`).

## 14. Worked example: a three-way conference, message by message

Subscriber A has B on line 0 (active) and C on line 1 (A held B while calling C,
so line 0 is on hold). A merges, mutes C for the room, C hangs up, A hangs up B.

```jsonc
-> { "request": "merge", "transaction": "m1", "lines": [0, 1] }
<- { "response": "ack", "transaction": "m1" }
   // client: mic off + inbound off on PC(line 0) and PC(line 1); record {0, 1}
   // Core: bridge_in x2, configure, bridge_out, unhold on line 0 (it was held), app join
<- { "event": "conference_offer", "room": 4242,
     "jsep": { "type": "offer", "sdp": "v=0\r\n..." },
     "participants": [ { "line": 0, "call_id": "call-b", "muted": false },
                       { "line": 1, "call_id": "call-c", "muted": false } ] }
   // client: new PC, setRemote, answer; held=false on call-b (Core un-held it), tell CallKit
-> { "request": "conference_answer", "transaction": "m2",
     "jsep": { "type": "answer", "sdp": "v=0\r\n..." } }
<- { "response": "ack", "transaction": "m2" }
-> { "request": "conference_ice_trickle", "transaction": "m3",
     "candidate": { "candidate": "candidate:1 1 udp ...", "sdpMid": "0", "sdpMLineIndex": 0 } }
<- { "response": "ack", "transaction": "m3" }
<- { "event": "conference_ice_trickle",
     "candidate": { "candidate": "candidate:2 1 udp ...", "sdpMid": "0", "sdpMLineIndex": 0 } }
-> { "request": "conference_ice_trickle", "transaction": "m4", "candidate": { "completed": true } }
<- { "response": "ack", "transaction": "m4" }
<- { "event": "conference_ice_trickle", "candidate": { "completed": true } }
   // PC connected: A hears B and C mixed; B and C hear A and each other

-> { "request": "conference_mute", "transaction": "m5", "line": 1, "muted": true }
<- { "response": "ack", "transaction": "m5" }
<- { "event": "conference_updated", "room": 4242,
     "participants": [ { "line": 0, "call_id": "call-b", "muted": false },
                       { "line": 1, "call_id": "call-c", "muted": true } ] }
   // C is silent for everyone; C still hears the room

   // C hangs up
<- { "event": "hangup", "line": 1, "call_id": "call-c", ... }            // ordinary call event
<- { "event": "conference_terminated", "room": 4242 }                    // fewer than two legs
   // client: close conference PC; call-b still up -> restore its audio; it is the
   //         only call, so it stays active (no hold)

   // A hangs up B: an ordinary hangup request on line 0; nothing conference-related
```

The same conference torn down by A instead:

```jsonc
-> { "request": "conference_hangup", "transaction": "m6" }
<- { "response": "ack", "transaction": "m6" }
<- { "event": "conference_terminated", "room": 4242 }
   // app behaviour: hang up call-b and call-c with ordinary hangup requests;
   // a client keeping them would restore audio on both and hold one of them
```

## 15. Limits

- Audio only. A video leg makes `merge` fail after `ack` (5.4); the client should
  not offer it.
- Codecs Opus, PCMA, PCMU. A G.722 leg is dropped silently (8.5).
- Room size is the app's line count: `USER_APP_LINE_COUNT_INITIAL` (default 2,
  three parties). The value is fixed per app record on first login.
- One room per session; it does not survive a Janus restart (8.8).
- Far ends get no participant list and no indication a conference exists; after a
  transfer the remaining party's identity may be wrong, which is a known platform
  issue outside this client.
- The 10 s setup deadline: a leg still ringing has nothing to bridge, so only
  established calls are candidates.

## 16. What the package tests cover

`test/src/requests/conference/conference_requests_test.dart`: `toJson` of every
request against the wire JSON above and round trip through `SessionRequest.fromJson`;
the completed marker for a `null` candidate; `muted` sent explicitly both ways; wrong
type refused.

`test/src/events/conference/conference_events_test.dart`: `Event.fromJson` on the
JSON of every event, round trip through `toJson`, the completed marker decoding to
`null`, `conference_failed` with and without `room` / `detail`,
`conference_terminated` with and without `room`, the participant `muted` read, and
that an unknown `conference_*` event still throws.

`test/src/handshakes/handshake_state_test.dart`: handshake without the key, with
`null`, and with a running room.

`test/src/conference_refusal_reason_test.dart`: every reason string, the two
prefixed families, unknown and empty.
