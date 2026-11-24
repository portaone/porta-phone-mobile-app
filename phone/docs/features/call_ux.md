# Call - UX / product

The product-level view of the calling experience: what the user can do, the
screen states and the widgets that back them. The
implementation deep-dive lives in [`call_arch.md`](call_arch.md).

Last reviewed: 2026-11-23

## What the user can do

- Place an outgoing audio or video call.
- Receive an incoming call (foreground, backgrounded, or killed via push).
- During an active call: mute, toggle camera, switch audio device (earpiece /
  speaker / Bluetooth), open the keypad (DTMF), hold/resume, transfer (blind or
  attended), share the phone's screen (Android, an ordinary call), and hang up.
- Handle a second call: a new incoming call while one is active, or two calls at
  once - answer one and put the other on hold, or decline.

## Call states (UX)

The active call screen (`CallActiveScaffold`) renders from `CallState.activeCalls`.
Each call is an `ActiveCall` with the flags the UI reads:

- `isIncoming`, `wasAccepted` (has `acceptedTime`) - ringing vs answered.
- `held` - on hold.
- `processingStatus` - fine-grained lifecycle (see the state machine in the
  architecture doc).

The toolbar (AppBar title slot, centered) carries one global status line
(`CallToolbarStatus`), never tied to a call row. Signaling states: "No
internet connection" / "Not registered" (coral dot), "Connecting..." /
"Reconnecting..." (amber pulsing dot; Reconnecting once a connection has
existed). Below those: a media failure message, or the worst stream-quality
warning across calls (signal bars + direction arrow + label). The central
`CallInfo` shows only name/number, the call description or live duration, and
the processing status.

- `displayName` / `handle`, `remoteVideo`, `muted`, `transfer`.

Single call:

- **1 incoming** - caller info + Decline / Answer.
- **1 active** - caller info + control grid (mute, camera, speaker, transfer,
  hold, keypad) + hang up.
- **1 on hold** - same grid with Hold shown as Resume (play glyph).

Multiple calls (list-based):

- The screen shows one tappable `CallRow` per call - colored status dot +
  badge (RINGING / ON CALL / ON HOLD), name, live duration or a short
  Incoming/Outgoing label, and a camera glyph on video lines - under an
  "N calls - tap to choose" header. Tapping
  a row focuses that call. With multiple calls the rows carry the per-call
  info; the central info block appears for a single call only.
- The `CallInfo` block and the action area below act on the focused call only.
  A ringing focus gets exactly Decline / Answer plus an "Acting on: <name>"
  hint - a translucent pill with the focused name in bold and the affected
  names highlighted - that spells out the side effect ("<name> will be put on
  hold" or "will be ended"); an active/held focus gets the control grid + End.
- Answer is one intent (`CallControlEvent.answerFocused`): it holds the
  answered calls when possible, ends the non-holdable ones (e.g. an outgoing
  call still ringing), and leaves another ringing incoming call ringing.
- Hold pauses the focused call; Resume brings it back as the only live call,
  holding the others first. There is no swap button: switching lines is focusing
  the other row and pressing Resume.

### Focused call

`CallState.selectedCallId` + the `focusedCall` getter express which call the
info block and action area act on: the explicitly selected call when it still
maps to a live call, otherwise the derived `current` (= last non-held call).
Auto-focus: a new ringing incoming call grabs the focus, and so does a call the
user has just placed - an ordinary second call, an attended-transfer
consultation, a call placed to add somebody, or a second tap on a number still
being placed - unless an incoming call is ringing. Left on the call it was
placed from, the End button would end that held call (or the whole room) while
the new call went on ringing. When the focused call ends, the next ringing
incoming call is focused; otherwise the selection a placed call took over is
given back, unless the user picked another call meanwhile. It is given back too
once the placed call joins the room, so a room that comes apart later does not
hand the focus to a call nobody picked. A call restored after a reconnect does
not take the focus. The media overlay keeps following the
derived `current` call.

With a conference room up, an accepted selection is not consulted at all. The
screen then shows two conversations - the room and a call taken outside it - and
which of them is in use is a fact rather than a preference, so the focus follows
the audio: the live call outside the room while it stands aside, the room's first
leg otherwise. A call that is still ringing - incoming, or placed and not yet
answered - is the exception and keeps the focus it was given; it is in neither
conversation. Moving
between the two is a tap on either block, which asks for the hold and leaves the
focus to follow - see
[`call_conference.md`](call_conference.md).

### Sharing the screen

Android only. The person shows the phone's screen to the far end in place of the camera; the
far end, an app or a SIP phone, sees it as video. In a conference the screen goes to the room
(see [call_conference.md](call_conference.md), The screen in the room): the host shares from
the room's More menu or from the three-dot menu of a leg - More then carries a ring and a
screen badge, and no tile stands for the share - and every participant sees it in the main
place of the room's full screen, under a line saying who shares, the participants in a row
under it.

- **Entry.** The toolbar's three-dot menu (`callActionsOptionsId`) gets "Share screen"
  (`callActionsScreenShareId`) after the picture's entries ("Fit"/"Cover", "Enable/Disable
  Blur", which stay for a call with the far end's video). It is offered for an answered,
  connected call that is not held, not being transferred (the transfer picker open is not a
  transfer yet) and while no room is being put together - for a leg, while the room is up and
  has video - on Android, where the
  state says the phone can share (`CallState.canShareScreen`). The menu is shown whenever it
  has an entry, so an audio call on Android has the menu with "Share screen" as its one entry;
  on iOS an audio call still has no menu.
- **Start.** The system asks the person to let the app capture the whole screen or, from
  Android 14, one app; a refusal changes nothing. A single app the person leaves gives no new
  frames: the far end keeps its last picture until the person comes back to it. An audio call becomes a video call for the share, as when the camera is
  turned on; if the far end does not take the video the share stops with "The other side does
  not accept video - screen sharing stopped". A share the system or the capture refused says
  "Screen sharing could not start". The system shows a notification "Sharing your screen" with
  its own Stop.
- **While sharing.** The entry reads "Stop sharing". The small camera preview window gives its
  place to a tile of the same size (`callScreenShareTileId`): the menu's colour, a screen icon,
  "Sharing screen" and a Stop in the end-call colour (`callScreenShareStopId`). The camera
  control is disabled and the camera itself is let go, its indicator off: the screen holds the
  call's video, and stopping the share opens the camera again as it was.
- **Stop.** "Stop sharing", the tile's Stop, the notification's Stop or the system ending the
  capture, a hold, a merge into a room or an invitation to one (the share is started again
  from the room), or the end of the call. The camera comes back as it was;
  if it cannot be opened again the call's video goes off with the camera error message. A call
  that became a video call for the share stays one with the camera off. A share stopped while
  it was still starting says nothing.

The phone screen arrangement only: a watch has no menu entry for it.

### Transferring a call

The transfer button opens a menu, and every entry carries a second line saying
what it does.

- **Unattended transfer** ("Hand the call over without talking first") - the
  screen steps aside and the person picks a number in favourites, recents,
  contacts or the keypad. The call is handed over at once; if the switch
  refuses, it comes back to the screen.
- **Attended transfer** ("Talk to them first, then hand the call over") -
  offered for an answered audio call while a line is free for a second one. The
  screen steps aside with "Choose who to consult before transferring". The
  choice places a second call and holds the first. Once the second call is
  answered, the menu offers the first call as the one to connect ("Connect them
  with this call"); choosing it joins the two parties and ends both calls on
  this phone. No other call is offered as a target while a consultation is up.
  - The second call declined or not answered: the first call is taken off hold
    and a notice says so ("They declined, returning to the call", "No answer,
    returning to the call"). Busy is told by the call ending as busy. The first
    call stays on hold if the person had held it before starting, or if another
    call is live by then.
  - A contact with one number is the choice. A contact with several asks
    which ("Choose a number to call"); the sheet closes with the request. The
    same holds for Add participant.
  - Back on the call screen without choosing, or the first call ending while
    choosing: the banner goes.
  - The first call ending while the second still rings: the second stays as an
    ordinary call.
- Two calls up with no consultation between them - the second one came in, or
  was dialled as an ordinary call: the menu of the live call on screen lists
  every held call, "<name> - Connect them with this call", each an entry of its
  own; the one picked is connected with the call on screen. The menu of a held
  call on screen lists every other call the same way, live or held. A call that cannot be
  transferred - one already in a transfer, one ending - is not listed. The
  unattended and the attended transfer to somebody else stay offered next to
  these entries; the attended one while a line is free for the consultation.

## Key widgets

| Widget                   | File                                   | Role                                                                        |
|--------------------------|----------------------------------------|-----------------------------------------------------------------------------|
| `CallActiveScaffold`     | `view/call_active_scaffold.dart`       | Active call screen; owns keypad/DTMF state and the control intents          |
| `CallScreenHandset`      | `view/call_screen_handset.dart`     | The phone's routes under the call screen (`callScreenRoutes`), the whole screen: it hands `CallControls`, off the system's areas, to their first page `CallHomeScreenPage` (`view/call_home_screen_page.dart`) through `CallScreenHomeScope`; the menus the controls open sit in these routes, so they close with the call screen, and are closed when the controls hide |
| `CallControls`           | `widgets/call_controls.dart`           | Toolbar + orientation selector; also defines `CallScreenParams`, the one object all wiring travels in |
| `CallControlsPortrait`   | `widgets/call_controls_portrait.dart`  | Portrait arrangement: info on top, avatar flexing, actions at the bottom    |
| `CallControlsLandscape`  | `widgets/call_controls_landscape.dart` | Landscape arrangement: info zone, action grid, hangup apart behind a rule |
| `CallInfoBlock`          | `widgets/call_info_block.dart`         | Who the screen is about: the roster with several calls, `CallInfo` with one |
| `CallActionArea`         | `widgets/call_action_area.dart`        | What can be pressed: the control grid, or Decline/Answer with the hint      |
| `CallList` / `CallRow`   | `widgets/call_list.dart`               | Tappable per-call rows with status badge + duration                         |
| `ConferencePanel`        | `widgets/conference_panel.dart`        | The room as one block: a row per leg, above the roster of the calls outside it |
| `FocusedActionHint`      | `widgets/focused_action_hint.dart`     | "Acting on" hint + answer side effect                                       |
| `CallInfo`               | `widgets/call_info.dart`               | Focused-call name / number / call description / timer                       |
| `IncomingCallActions`    | `widgets/incoming_call_actions.dart`   | Decline / Answer for the focused ringing call                               |
| `ActiveCallActions`      | `widgets/active_call_actions.dart`     | In-call control grid + keypad (the hangup row rides along in portrait only) |
| `ScreenShareTile`        | `widgets/screen_share_tile.dart`       | Stands in for the camera preview while the screen is shared                 |

### Landscape

The screen turns only during a call (the app is portrait-locked elsewhere).
This screen is the reference implementation of the adaptive-layout playbook -
the generalized approach for giving any screen a second arrangement lives in
[`../architecture/adaptive_layout.md`](../architecture/adaptive_layout.md).
Landscape is a real arrangement, not the shrunk portrait column it used to be:
the caller info (avatar beside the left-ranged name/timer, or the roster with
several calls) takes the left, the control grid stands beside it, and the
hangup button stands apart behind a fading rule so the destructive control is
the hardest one to hit by accident. A ringing focus swaps the grid and hangup
zones for Decline / Answer with the "Acting on" hint. The keypad opens in
landscape too: the keys take the grid zone at full size, the typed digits show
in the info zone next to the caller, the closing button stands under the
hangup, and turning the phone keeps an open keypad open - but focusing another
call closes it, because a DTMF session belongs to the call it was opened for.

## Keeping this doc current

Update this file in the same change that changes the call UI - especially the
"Call states" section - and bump `Last reviewed`.
