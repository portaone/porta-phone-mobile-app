# Presence

How the app learns other users' presence (available / activities / on a call)
and where it shows it, most visibly as the status badge on contact avatars.

Last reviewed: 2026-11-25

## State model

- `lib/models/presence/presence_info.dart` - `PresenceInfo`: `available`
  (bool), free-text `note`, emoji `statusIcon`, `activities`, `device`,
  `source` (`sip` | `direct`). A contact maps to a LIST of these - one per
  device/source - so all read sites go through the
  `PresenceInfoListExtension` helpers: `leadingSource` (the records of the
  first source that has any, see "Which source answers"), `primary`
  (among those: a record on the phone, else the one whose state began
  last), `primaryActivity`, `primaryNote`, `primaryStatusIcon`, and
  `reachable(registered:)`.
- `lib/models/presence/presence_activity.dart` - `PresenceActivity`: 12
  values (`away`, `busy`, `doNotDisturb`, `sleeping`, `permanentAbsence`,
  `onThePhone`, `meal`, `meeting`, `appointment`, `vacation`, `travel`,
  `inTransit`).
- `lib/models/dialog_info.dart` - BLF dialog state per number:
  `DialogState { trying, proceeding, early, confirmed, terminated, unknown }`,
  direction, tags, the `pullable` getter used by Call Pull, and
  `isEstablished` (`state == confirmed`) with the
  `DialogInfoListExtension.established` helper. A dialog exists from the
  first ring and `early` is the most common state in production, so
  "the contact is talking" is `isEstablished`, never "a dialog exists" -
  every read site goes through it, `pullable` included.

## Data flow

All presence and dialog data arrives over the signaling socket and is
persisted locally, then joined onto contacts:

1. `CallBloc` consumes the initial handshake state and the live
   `NumberPresenceUpdate` / `NumberDialogsUpdate` events
   (`lib/features/call/bloc/call_bloc.dart`).
2. They are written to drift via
   `lib/repositories/presence/presence_info_repository.dart` and
   `lib/repositories/dialog_info/`.
3. `lib/repositories/contacts/contacts_repository.dart` joins
   `presenceInfo` + `dialogInfo` onto each contact, so tiles simply read
   `contact.presenceInfo` / `contact.dialogInfo`.

A contact record also carries `registered: bool?`, the SIP registration
state from the contact list. It feeds the older badge where the server has
no presence support, and with presence support it is the last source asked
(next section).

## Which source answers

Three sources can say something about a contact, and they are asked in a
fixed order; the first that knows something wins:

1. **Direct presence** - what the contact's own app or web dialer published
   through Core (`source: direct`). First-hand, so it is never overruled.
2. **SIP presence** - what the PBX holds for the number (`source: sip`),
   present only for a number the user subscribed to and only while some
   device publishes for it. For somebody who also has a direct record it is
   at best an echo of it, so it is not read at all then.
3. **Registration** - `contact.registered`. Most desk phones and softphones
   take calls without ever publishing a status; for them this is the only
   thing known, and "registered" is drawn as available.

With none of the three, and no established call reported, no mark is drawn:
"unavailable" would be a claim nobody made.

Inside one source a person can have several records, one per device, each
repeating what was last set on that device. The record whose state began
LAST describes the contact - colour, glyph, label, note and icon all come
from it - so a status set a minute ago on the laptop is not hidden by the
phone still saying "available". The order is by `timestamp`, the
publisher's time of the change, which Core keeps through re-announcements
and across its own restarts; `arrivalTime` places a record that has no
timestamp and settles a tie. The one exception is a record that is on the
phone: it wins whenever it began, because a call is a fact about the
person rather than a status they chose. The web dialer follows the same
rule, so the two clients show the same thing for the same records.

Two rules follow from the order. A published `closed` is NOT second-guessed
by registration: a device that said so meant it. And a PBX answers a
subscription to a number nobody publishes for with a bare `closed` tuple,
which reads as "unavailable" and means "nothing known"; Core does not pass
that one on, so such a number has no SIP record and reaches step 3. An app
talking to a Core that still passes it on shows that contact as unavailable.

The order lives in `PresenceInfoListExtension` (`leadingSource`, and through
it `primary` and `reachable`), so the mark, the spoken label and the note
and icon beside a name all give the same answer. The textual section on the
contact screen (`presence_info_view.dart`) is the exception on purpose: it
lists every record with its source.

The sites that used to pass the registration alone - the contact pickers,
the call log, the number CDRs, the watch rows, the chat header and the
members of a group chat - build their badge with
`AvatarStatusBadge.ofContact`, which hands it all three sources and the
contact's calls; passing the registration alone drew a registered phone as
reachable while its owner had published do not disturb. The other sites
still call `AvatarStatusBadge.maybe(...)` with the contact's fields; which
ones, and the gap they leave, is under "Where the badge appears".

Times: `PresenceInfo.arrivalTime` is Core's stamp, taken from the event as
it is. A publisher's `timestamp` that names no zone is its wall clock and
is turned into an instant with the record's `timeOffsetMin`
(`lib/mappers/signaling/presence_info_mapper.dart`); the app itself
publishes its time in UTC, and keeps its own status in the preferences in
UTC too, so a change of the phone's zone does not move it. A status stored
by an older build names no zone and is read as the wall clock of the offset
stored with it (`lib/mappers/json/presence_settings_mapper.dart`).
`PresenceInfo.stateBeganAt` is the one notion of "when this status began" -
the timestamp, cut back to the arrival when the publisher's clock runs
ahead - used to order the records.

## Avatar badges: two systems plus one indicator

`lib/widgets/leading_avatar.dart` (`LeadingAvatar`) knows nothing about
presence: it exposes a `badge` slot that receives the whole avatar square.
The status badge is a separate widget,
`lib/widgets/avatar_status_badge.dart` (`AvatarStatusBadge`) - call sites
build it via `AvatarStatusBadge.ofContact(contact)` or
`AvatarStatusBadge.maybe(...)`, which return `null` (no badge mounted) when
there is nothing to show. The badge sizes and anchors
itself via `lib/utils/badge_layout.dart` as an
`avatar diameter * sizeFactor` square, and decides which bottom-right badge
renders by `PresenceViewParams.hybridPresenceSupport` - the two are
mutually exclusive. The top-left smart-contact indicator is still drawn by
`LeadingAvatar` itself:

| Overlay | Widget | Placement | Default sizeFactor | Shown when |
|---|---|---|---|---|
| Registered dot (legacy) | `_RegisteredDot` (avatar_status_badge.dart) | bottom-right, inside the box | 0.2 | hybrid presence OFF and `registered != null` |
| Presence mark | `lib/widgets/sip_presence_indicator.dart` | centre ON the avatar's edge (`BadgeLayout.onCircleEdgeSquare`) | 0.5 | hybrid presence ON and something is known: a presence record, an established call, or `registered != null` |
| Smart-contact indicator | `_smartIndicator` (leading_avatar.dart) | top-left | 0.4 | `smart: true` (unrelated to presence) |

The default avatar radius is 20 (diameter 40), so the presence mark is 20 dp
across and the legacy dot 8 dp. All sizeFactors are themable per deployment
(see below).

The presence mark is placed by its CENTRE on the circle inscribed in the
avatar box, so about a tenth of the avatar diameter hangs outside the
silhouette. That is deliberate: centred inside, a mark this size covers the
face or the initials underneath. Consequences worth knowing:

- the overhang is paint-only - the avatar keeps its size, no row reflows, and
  the part that sticks out lives in the gap that already separated the avatar
  from the text;
- nothing above the badge may clip: `LeadingAvatar` and `AvatarStatusBadge`
  both use `clipBehavior: Clip.none`, and no current host wraps the avatar in
  a clip. A new host that does would cut the mark;
- the overhanging part is NOT hit-testable (Flutter does not hit-test outside
  a box), which is fine while the mark is not interactive;
- on a large avatar the mark scales with it, so leave room below: the chat
  profile screen (`radius: 50`) keeps 16 dp before the name for exactly this.

The legacy registration dot - drawn where the server has no presence support,
never alongside the presence mark - is laid out IDENTICALLY to it:
`onCircleEdgeSquare`, `sizeFactor` 0.5, and the same
`scaffoldBackgroundColor` ring at `side * 0.1`. It used to sit at 0.2 fully
inside the avatar, which is a QUARTER of the coloured area WT-1779 gave the
presence mark, so deployments without presence support never got the mark
the change was about; the ring is the part that makes the overhang work -
without one, the half over the row background reads as a partial dot. It
carries a `Semantics` label of its own -
`presence_badge_state_registered` / `_unregistered` - so the dot is spoken
as well as drawn; with no registration data the badge renders nothing and
says nothing.

`SipPresenceIndicator` renders:

- a colored disc - three colors: a `primaryActivity` of `busy` or
  `doNotDisturb` picks `busyColor`, otherwise
  `presenceInfo.reachable(registered:)` picks `availableColor` and
  everything else `unavailableColor`. Asking not
  to be called outranks reachability - a contact on "do not disturb" IS
  reachable, they just published something, and the point of the state is to
  stop the call. Only a PUBLISHED activity reaches the color: BLF state does
  not, nor does the `onThePhone` activity, because Core publishes that one
  from the moment of dialling and it would paint people as busy over calls
  nobody answered;
- a glyph INSIDE the disc, in `iconColor`, whenever the status was
  PUBLISHED. Icon choice: `dialogInfo.established != null` ->
  `phone_in_talk`, else the icon for `presenceInfo.primaryActivity`, else a
  tick for a plain available and a cross for a plain unavailable. A dialog
  that is merely ringing does NOT light it - `early` is the most common
  state in production, and an unfiltered list showed contacts as talking
  from the first ring;
- NO glyph when only the registration of the phone is known. The mark
  shows how much is known: a status somebody published carries a glyph, a
  registration carries the colour alone, so the two are told apart at a
  glance without a second colour. The two registration marks are plain
  discs, green for a registered phone and grey for one that is not. The
  spoken label follows the same split:
  "Registered" / "Not registered" for a registration mark, "Available" /
  "Unavailable" for a published status. The web dialer draws and names
  them the same way;
- the ring around the disc (`Theme.scaffoldBackgroundColor`, which can
  mismatch on surfaces that are not the scaffold background) and the glyph
  are a SHARE of the mark - 0.1 and 0.55 of its side. They have to be:
  the same widget is rendered at a fixed 16x16 in the presence pickers
  (`presence_settings_screen.dart`, `presence_info_view.dart`), where a fixed
  ring plus a fixed glyph would leave the availability colour a sliver.

`AvatarStatusBadge` wraps the mark in a `Semantics` label, so the state is
spoken as well as drawn: an established call -> `presence_badge_state_onCall`,
else the published `primaryActivity` in words (`PresenceActivity.l10n`),
else `presence_badge_state_available` / `_unavailable`. The label follows the
GLYPH, not the colour - an established call is spoken though it leaves the
colour alone, and `busy` / `doNotDisturb` are spoken as their activity name
rather than as a "busy" state of their own.

The emoji `statusIcon` and the `note` never reach the badge - contact tiles
append them to the title/subtitle text instead
(`lib/features/contacts/widgets/contact_tile.dart`), and an ESTABLISHED BLF
dialog swaps the subtitle to remote-party info there - the established one
specifically, not the first in the list, so a contact who is already talking
while another call rings in is described by the call they are in.

Known gap, server-side: where BLF is off, "on a call" arrives only as the
`onThePhone` activity, and Core sets it from the moment of DIALLING, with no
state to filter on - so on that path a ringing contact still reads as
talking. Tracked outside the client.

## Colors and theming

The presence badge style flows through the standard theme pipeline:

- theme JSONs `assets/themes/original.widget.{light,dark}.config.json` ->
  `presenceBadge` (`sizeFactor`, `availableColor`, `unavailableColor`,
  `busyColor`, `iconColor`) and
  `registeredBadge` (`sizeFactor`, `registeredColor`, `unregisteredColor`);
- parsed by `PresenceBadgeStyleConfig` in
  `packages/theme_schema/lib/models/common/leading_avatar_style_config.dart`;
- mapped in `lib/theme/factory/styles/leading_avatar_style_factory.dart`
  into `PresenceBadgeStyle` (`lib/theme/styles/presence_badge_style.dart`).

The shipped themes name none of these: the app's own values live in
`LeadingAvatarStyle.defaults` - `colorScheme.tertiary` (available),
`colorScheme.onSurfaceVariant` (unavailable), `colorScheme.surface` (glyph)
and the sizes above. A theme that writes one of them pins it for good, so the
shipped files carry them only as disabled `_`-prefixed examples. There is no
per-activity or busy/on-call color role today.

The legacy dot resolves its colors from `RegisteredStatusStyles`
(`lib/theme/factory/styles/registered_status_style_factory.dart`, fed by
`statuses.registrationStatuses` in the theme JSON). Note its fallback is
`colors.error` for BOTH states.

## Where the badge appears

Built from the whole contact with `AvatarStatusBadge.ofContact`: number
CDRs, the call log, the SMS and chat contact pickers, the chat header, the
members of a group chat and the watch rows. Without hybrid presence they
show the legacy dot; with it the presence mark, from all three sources.

Passed `registered`/`presenceInfo`/`dialogInfo` one by one through
`AvatarStatusBadge.maybe(...)`:

- contacts list and search: `lib/features/contacts/widgets/contact_tile.dart`
  via `contact_tile_adapter.dart`;
- favorites: `lib/features/favorites/widgets/favorite_tile.dart`;
- recents: `lib/features/recents/widgets/recent_tile.dart`; CDRs:
  `lib/features/cdrs/widgets/cdr_tile.dart`;
- chats: conversation list tile, chat details, and message avatars, which
  pass no `dialogInfo`.

Favorites and recents are mapped without dialogs
(`lib/mappers/drift/favorites_mapper.dart`, `recents_mapper.dart`), so
their badge, like that of a message avatar, cannot show a call.

The presence settings screen previews `SipPresenceIndicator` directly at a
fixed 16x16.

No badge by design:

- the big avatar on the contact details screen
  (`lib/features/contact/view/contact_screen.dart`) - presence is shown
  there as a textual section (`widgets/presence_info_view.dart`) instead;
- the in-call header (`lib/features/call/widgets/call_remote_avatar.dart`
  deliberately renders without badges).

## Enablement and gating

`PresenceViewParams` (`lib/utils/view_params/presence_view_params.dart`) is
provided by the main shell from `FeatureAccess.sipPresenceConfig`
(`lib/app/router/main_shell.dart`); the mapping lives in
`SipPresenceMapper.map` (`lib/data/feature_access.dart`):

- `hybridPresenceSupport` = app config `supported` contains hybrid presence
  AND the core reports `hybridPresenceAware`;
- `presenceViaSipSupport` additionally requires the adapter's
  `supportsSipPresence`;
- `dialogsViaSipBlfSupport` additionally requires `supportsSipDialogs`.

SIP presence/BLF subscriptions are also per-contact opt-in: checkboxes on
the contact details screen write `SipSubscriptionType.presence/dialog`
through `SipSubscriptionsRepository`; syncing the subscription list to the
backend is gated by `subsSyncEnabled`
(`lib/models/feature_access/sip_presence_config.dart`).

Publishing the user's OWN presence (the presets under Settings -> Presence,
`lib/features/settings/features/presence/`) rides the same gating; the
periodic send is driven from `CallBloc`.

## Test coverage

`test/widgets/avatar_status_badge_test.dart` pins the badge contract: which
generation renders under `hybridPresenceSupport`, the default 0.2/0.5 sizes,
the legacy dot colors, the mark's centre sitting on the avatar's edge with
the glyph inside it, the order of the sources (direct over SIP, registration
when nothing is published, no mark when nothing is known), what the mark
draws for each level of knowledge (tick or cross for a published plain
status, a bare disc for a registration), and the no-data
cases (`AvatarStatusBadge.maybe` and `AvatarStatusBadge.ofContact`
returning `null`, the latter also for a phone that is only ringing).
`test/mappers/presence_signaling_mapper_test.dart` and
`test/mappers/presence_settings_mapper_test.dart` pin the times: a zoneless
time read as its publisher's wall clock, and the app's own status kept and
published as an instant.
`test/models/presence_info_test.dart` pins the same order in the model.
`test/theme/leading_avatar_style_defaults_test.dart` pins that a theme is
read as overrides only - what it leaves out comes from the app values.
`test/widgets/leading_avatar_test.dart` covers name-derived avatar colors
and the badge slot, including a composition test asserting the slot hands
the badge exactly the avatar diameter. There are no golden tests for these
widgets, and `BadgeLayout` has no test of its own - its geometry is covered
through the widgets.
