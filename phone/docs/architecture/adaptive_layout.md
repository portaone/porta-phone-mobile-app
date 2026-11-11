# Adaptive layout

The rules for a screen with more than one arrangement - for a watch, a tablet
or a phone lying down: which axis decides what, the watch kit, and the
structure and tests every such screen follows. The landscape rules come from
the first screen that got a second arrangement, the active call screen (see
[`features/call_ux.md`](../features/call_ux.md), section "Landscape", for the
reference implementation). The next screens follow them rather than invent
the shape again.

Last reviewed: 2026-11-09.

## The adaptation axes

A screen adapts on two axes, and each is decided in exactly one place. A
screen hands the decider its arrangements and never reads the window size or
orientation itself:

| Axis | Values | Decided by | Decides |
|---|---|---|---|
| Device class | `watch`, `handset`, `large` | `AdaptiveLayout` (`packages/adaptive_kit`) | what the screen is made of |
| Orientation | portrait, landscape | `OrientationLayoutSelector` | how a handset screen is arranged |

```dart
AdaptiveLayout(
  handset: (_) => OrientationLayoutSelector(
    portrait: MyScreenPortrait(params: params),
    landscape: MyScreenLandscape(params: params),
  ),
  watch: (_) => MyScreenWatch(params: params),
)
```

Do not scatter `MediaQuery.size` or `MediaQuery.orientation` checks through
screens or blocks.

Each arrangement is its own widget, and the screen's root is the only place
that picks one: the phone's stays the screen's own build (`_handset`), the
watch's is `MyScreenWatch` in `my_screen_watch.dart` beside the screen, with
everything only the watch does - its state, handlers and dialogs. What both
share stays on the screen above the picker (the bloc, a tab controller, a
query typed) or in shared functions, and goes to the arrangement as data and
callbacks. Below the picker nothing reads `context.formFactor`, and no body
takes a parameter that switches it to another arrangement: a new one - a
tablet - is one more argument of the one `AdaptiveLayout`.

### Device class

`FormFactor.fromSize` (`adaptive_kit`) reads the
window size, and the numbers live only in `FormFactorBreakpoints`:

- `watch` - both sides under 340: every watch the configurator previews
  (round 192 and 227, Apple Watch 162x197 and 208x248, a wide 320x240);
- `large` - shortest side 600 or more, Material's tablet threshold;
- `handset` - everything else, a phone either way up.

It is decided by size, never by platform: the same build runs on Wear OS, on
plain Android in a watch body that reports no watch feature, and in the
configurator's device preview, where the platform is the browser.

`handset` is the only required arrangement. A class without its own falls
back to it, so screens move to a watch layout one at a time and every other
screen keeps working as before. Values follow the same rule:
`context.formFactor.resolve(handset: 24, watch: 8)`; spacing comes from
`context.adaptiveMetrics` (inset, gap, tap floor), whose handset values are
the ones the app always used.

Crossing a class boundary swaps the subtree under `AdaptiveLayout`, so the
bloc, controllers and anything the user typed live above it - the same rule
as "State stays on the screen" below.

### Screens with a watch arrangement

| Screen | Watch arrangement |
|---|---|
| Login landing (`features/login/view/login_mode_select_*.dart`) | One launch button in a branded build: logo and greeting in the middle, the button filling the bottom edge (`WatchEdgeButton`). The greeting is measured against the room above the button: one that fits keeps its size; a longer one - a brand's paragraph - is set smaller under a smaller logo, cut to the lines the room holds with a chevron, and a tap opens it whole on a page that scrolls (`WatchTextScreenPageRoute`), going back returning to the landing; assistive technology reads it whole from the cut one. A demo build or several buttons: the brand in the middle, the buttons on the bottom of the face, the custom-core sign-in last. Nothing at the top of the face. |
| Custom-core URL (`features/login/view/login_core_url_assign_*.dart`) | Proceed as the edge button; above it a short scrolling column - the field's prompt, the field (label `URL`), the sales contact - fading out over the button. No app bar (a watch goes back with a swipe), no logo. |
| Ways in (`features/login/view/login_switch_*.dart`) | No segments: the configured ways in as a `WatchIconGrid`, like the main hub - round buttons with short captions (`loginType_*Short`), in the brand's order, the first filled, each with its segment's automation id and full name; a choice opens its form on the whole face, going back returns to the grid and waits while the form's request is in flight; a single way in opens directly. No QR sign-in: it reads the code through a camera, and watches have none (`LoginTypeWatch.availableOnWatch`). No logo, no app bar; `LoginScaffold.watch` keeps the screen's status bar style. |
| Sign-in forms - OTP, password, sign-up and both code screens (`features/login/widgets/login_form_layout.dart`) | `LoginFormLayout` is the one decision point for all five: the content scrolls in a short column with the secondary action (Resend) at its end, the primary action is the edge button, the column fades out above it. Descriptions take the small body size. |
| Terms, contacts consent, permissions and permission tips (`features/user_agreement`, `features/contacts_agreement`, `features/permissions`) | `WatchActionLayout`: a short title instead of the icon, the text in the small body size scrolling, the consent as a `WatchToggleChip` with a short label that still says the terms were read, the terms as a `WatchLink`, Continue as the edge button. The contacts toggle sits right under the title, in view beside Continue, because continuing without it declines, as on a phone. The tips are left with the edge button (the phone's main button there too); Open settings follows the steps. |
| Main screen (`features/main/view/main_screen_watch.dart`) | No tab bar: a hub of the configured sections as a `WatchIconGrid`, with the counts the tab icons carry and Settings last (the id of the phone's account button, its connection-state dot and session issue badge); the app starts on a section, as a phone does; a section opens on the whole face, going back returns to the hub. Sections stay built under the hub, as a phone keeps its tabs, and one opened from elsewhere opens on the face. A choice being made takes the hub's title place, with Cancel in Settings' place, and runs as a one-line strip over the section. The hub stays with a single section - it is where Settings lives. `MainScreen` only builds `MainScreenParams` and picks `main_screen_handset.dart` or `main_screen_watch.dart`; the tab router underneath is the phone's. |
| Keypad (`features/keypad/view/keypad_view_watch.dart`) | Twelve keys filling the face without the letters, the number and backspace above them, the contact under the number on a line kept while nothing matches (the keys never move under a finger), the call as the edge button; only the edge button rebuilds as the number changes. A held 0 types `+`. Video, transfer and the caller-id menu stay on the phone for now. On the smallest face a key is about 44 x 24, under the tap floor - twelve keys do not fit otherwise; the keys have no gaps. |
| Recents - the device's call log and the account's call history (`features/recents/view/recents_screen.dart`, `features/cdrs/view/recent_cdrs_screen.dart`) | No app bar, tabs or actions button: the section's title (the hub's name for it), one chip that flips the filter (`RecentsWatchFilterChip`, All and Missed), a `WatchSeparator` under it, and a `WatchListTile` per call - the avatar, the name, the time after the direction's arrow, red when missed, with "Missed" in the row's name for a screen reader (`RecentsWatchTile`). The rows are built as they scroll (`WatchScrollList.builder`); the call history fetches older records near the end as on the phone. A tap opens the calls with that number (`CallLogScreenPageRoute`, `NumberCdrsScreenPageRoute`) - never a call from a tap on the list - or, while somebody is being chosen, chooses the row. On its way the list is `WatchStatePage.loading`; with nothing to show, `WatchStatePage` with the screen's message, and on a filter other than the first an edge button back to it; the account's call history, empty on its first filter, has Refresh there instead of the phone's pull to refresh (a failure is said in a snackbar). Both screens build it from `RecentsWatchBody`. Deleting a call and clearing the history stay on the phone. |
| Calls with one number - the device's log and the account's history (`features/call_log/view/call_log_screen.dart`, `features/cdrs/features/number_cdrs_log/view/number_cdrs_screen.dart`) | `CallLogWatchPage`: the contact's name (the number when it is nobody's), the number under it, a `CallLogWatchRow` per call - the direction's arrow, the duration or Missed in red (the Missed list's own test), the time - read as one line, a video call pill closing the list when video is on, and the call as the edge button in the keypad's call style. The list is lazy and the account's history loads older calls near its end; while the calls are on their way the list is a spinner and the call is already there, and with no calls the list says so. No avatar, copy of the number or delete: those stay on the phone. |
| Contacts - both arrangements, tabbed and unified (`features/contacts/view/contacts_screen.dart`, `contacts_filter_screen.dart`; the watch arrangements `ContactsScreenWatch` and `ContactsFilterScreenWatch` in `contacts_screen_watch.dart`, `contacts_filter_screen_watch.dart` beside them; the lists in `features/contacts/features/*/view/`, the watch's `ContactsLocalTabWatch` and `ContactsExternalTabWatch` in `*_tab_watch.dart` beside the phone's, mounted by the pages through `contactSourceTypeWatchWidgetBuilder`) | One address book at a time, as on the phone: the section's title, one row for the search and the book (`ContactsWatchToolbar` on the shared `WatchSearchRow`, a short bar under it): with no query a round search button and the book as a pill (`ContactsWatchSourceChip`, in place of the tabs or the chooser - a tap shows the next book, through the same tab controller or selection event), with one the query as a pill with its cross and the book as a round button; with one book the search takes the row. The search is a button, not a field: a watch's keyboard takes the whole face with its own line to type in, so a tap opens it over a field nobody sees and the row shows the query as typed; and a `WatchListTile` per contact - avatar and name - that opens the contact's page or, while somebody is being chosen, chooses it (`contactPickOffer`, shared with the phone row). The screen hands the heading to the shown book's list through `ContactsWatchScope`; each list draws the whole face (`ContactsWatchBody`). On its way a book is `WatchStatePage.loading`; no access, a failure or an empty book is a `WatchStatePage` with the chip under the state and one action on the edge (Open Settings, Refresh - the cloud book's in place of the pull - Change selection); a search that finds nothing stays the list, a row saying so, so the field being typed in is not rebuilt. Where the unified screen offers the favourites, they are one more step of the same chip (`ContactsWatchSources` over the screen's list selections) and are drawn like a book (`ContactsWatchFavorites` through `ContactsWatchBody`): the same row of search and pill, the bar, the favourites' rows, the search narrowing them by name and number, the same state pages. |
| Favorites (`features/favorites/view/favorites_screen.dart`; the watch list, `FavoritesWatchList`, in `features/favorites/widgets/favorites_watch.dart`) | No app bar and no reorder button: the section's title and a `WatchListTile` per favourite number in the contact row's shape - the avatar and the name, the number under it where the name is not the number (`FavoritesWatchTile`). A tap opens the calls with that number (`CallLogScreenPageRoute`, `NumberCdrsScreenPageRoute`), where Call is the edge button - never a call from a tap on the list - or, while somebody is being chosen, chooses it; a long press removes the favourite after the watch confirm, in place of the phone's swipe. On its way the list is `WatchStatePage.loading`; empty, a `WatchStatePage` with a short line and how a favourite is added (`FavoritesWatchBody`). No search in the section, as on the phone. The order is the one set on a phone: rearranging, video, chat, SMS and call-from stay there. A screen that heads the list its own way hands `FavoritesWatchList` a `FavoritesWatchBodyBuilder`: the unified contacts screen draws the favourites as one more of its lists (`ContactsWatchFavorites`). |
| Chats - the conversations, chats and SMS (`features/messaging/features/conversations/view/conversations_screen.dart`) | `ConversationsWatchBody`: no app bar, tabs or floating button: the section's title, one row of the search and the list pill (`WatchSearchRow`, the same row as Contacts; `ConversationsWatchListChip` in place of the tabs - a tap shows the other list through the same tab controller), a `WatchSeparator`, and a `WatchListTile` per conversation - the avatar, the name (the group's, the other number for SMS), the last message, the unread count as the end mark and in the row's name for a screen reader (`ChatConversationsWatchTile`, `SmsConversationsWatchTile`). A tap opens the conversation. New chat (New SMS) is a `WatchPillButton` closing the list, in place of the floating button. On its way the list is `WatchStatePage.loading` saying how the chat connection stands; with no conversations, a `WatchStatePage` with the pill under it and New chat on the edge; a search that finds nothing stays the list, a line saying so. Deleting or leaving a conversation stays on the phone; New chat and New SMS open a page of their own (the row below). |
| A conversation - chat and SMS (`features/messaging/features/chat_conversation/view/conversation_screen.dart`, `features/messaging/features/sms_conversation/view/sms_conversation_screen.dart`) | `ConversationWatchThread`, both kinds through the same part: the name at the top (the contact's, the group's, the other number), the messages as `WatchBubble`s on a reversed `WatchScrollList.builder` - newest at the bottom, the user's own on the right with the phone's marks (on its way, sent, read; SMS: waiting, sent, delivered), the sender's name over a group's, "Failed" under an SMS the network refused - and Reply as the edge button: it opens the watch keyboard over the whole face (`WatchKeyboardInput`), its send key posts the message and the other side is told the user is typing. Older messages load as the top comes near; the other side's newest is marked read when the thread shows. On its way `WatchStatePage.loading`; failed, a state page with Try again on the edge; with no messages, a state page with Reply on the edge. Editing, deleting, replying to one message, forwarding, attachments, muting and the conversation's details stay on the phone. |
| New chat and new SMS (`features/messaging/features/chat_conversation_builder/view/chat_conversation_builder_watch.dart`, `features/messaging/features/sms_conversation_builder/view/sms_conversation_builder_watch.dart`; opened by `ConversationsScreen`) | A page in place of the phone's sheet, built like Contacts: the title, the search as a `WatchSearchRow` pill, the bar, the rows. New chat: Create group first where groups are on, then the contacts (registered badge, "Ext: 1001"); a tap opens the chat. Create group: the members tinted with a tick and Next on the edge counting them, then the name as a pill opening the keyboard, the members, Create on the edge once the name has 3 characters, a spinner over the stage while the group is made; Back steps back through the stages, not while the group is being made. New SMS: a typed number that parses is the first row (the phone's Create), one of seven digits or more that does not a line with the format it takes, then the Cloud PBX and local contacts, one row per SMS number; several numbers of the user's own open a page to pick one, an invalid number or none of the user's own is the adaptive acknowledgement. |
| Voicemail - the bottom-menu section and the settings screen (`features/voicemail/view/voicemail_tab_screen.dart`, `voicemail_screen.dart`; the watch parts in `features/voicemail/widgets/voicemail_watch.dart`) | No app bar, filter row or bulk actions: `VoicemailWatchBody` draws `VoicemailWatchList` - the section's title, the filter as one pill (`VoicemailWatchFilterChip`, a tap shows the next filter the mailbox offers) with the bar under it, and a `WatchListTile` per message: who left it, its length and when, a dot while it is new ("New" in its name for a screen reader); the trash ends with the phone's line on mailbox space. A tap opens the message's page (`VoicemailWatchPage`, pushed over the list with the screen's providers): the name and the date, `WatchPlayButton` - the ring filling as it plays, the time under it, playing marks it heard - then the phone's actions as rows: Mark as heard / new, Save / Unsave, Move to trash (Delete, after the watch confirm, where there is no trash); in the trash Restore and Delete permanently. Call back is the edge button, not in the trash and not for an unknown caller. The page closes once its message has left the list; going back stops it playing. Not supported, on its way, failed (Try again on the edge) and empty (Refresh on the edge, where a phone pulls to refresh) are `WatchStatePage`s, an empty or failed filter with the pill under its state. Picking several, forwarding, opening the contact, emptying the trash and the media cache stay on the phone. |
| Settings (`features/settings/view/settings_screen.dart`; the watch list in `features/settings/widgets/settings_watch.dart`) | No app bar: `SettingsWatchList` - the account's name heads the list, its number and balance under it; the connection as a `WatchListTile` with its dot and the phone's words (a tap opens Diagnostics); Online as a `WatchToggleChip` saying what it means under it ("Updating..." while it changes; off the server dimmed, "Needs connection", a tap opens Diagnostics, where the reason is); Sessions with its count; the brand's sections with their titles as `WatchListLabel`s, each item a row - Language and Theme mode name their value, Call center its queues, Voicemail its unread count, Delete account red - hidden where the phone hides them; Log out last, red, after the watch confirm. Busy, a spinner over the list. The log console is not offered; pull to refresh is not there. |
| Settings choice pages - Language, Theme mode, Caller ID, SIP Presence (`features/settings/features/{language,theme_mode,caller_id,presence}/view/`) | `SettingsWatchChoicePage` (`features/settings/widgets/settings_watch_choice.dart`): the setting's name, a `WatchListTile` per option, the one in force tinted with a tick; a tap applies it at once, as the phone does, and goes back. Theme mode where the brand fixes it: the rows dimmed. Caller ID: the default number only, the main one and the account's others, on its way a loading page; dial code matching stays on the phone and a line says so. SIP Presence: the presets with their presence marks, "Custom" over them when the settings match none; availability, note, activity and the status icon stay on the phone and a line says so. |
| Network and media settings (`features/settings/features/network/view/network_screen.dart`, `features/settings/features/media_settings/view/media_settings_screen.dart`) | Both on `SettingsWatchChoicePage` with `closeOnChoice: false`, the page staying where it is. Network: the two ways incoming calls are delivered under their label; "How they differ" opens both explanations on `WatchTextScreen`; the SMS fallback as a `WatchToggleChip`, offering nothing as the phone's checkbox. The persistent-connection reminder is the adaptive `AcknowledgeDialog` (title and text on the face, OK on the edge), the battery warning the watch confirm, its yes named Open Settings. Media: the quality presets, "Custom" only while it is in force; the speaker toggle where the deployment offers it; Reset to default after the watch confirm (it clears what only the phone shows); a line naming what stays on the phone (custom quality, audio processing, video, ICE, TURN). |
| Diagnostic (`features/settings/features/diagnostic/view/diagnostic_screen.dart`; the watch parts in `widgets/diagnostic_watch.dart`) | `DiagnosticWatchList`: the phone's checks as `WatchListTile`s - the check, its status in a word, its mark - worst first: failing (outlined), to look at, running, fine. A tap opens `DiagnosticWatchCheckPage`: the check, its status under it, what it means, the fix as the edge button where there is one, with the phone's hint of the settings section (Allow, Open settings - the watch's own settings; short to fit the edge); the fix closes the page, as the phone's sheet does. The network check opens `DiagnosticWatchNetworkPage`, kept up to date, Run again on the edge (the summary is `NetworkTestSummary`, shared with the phone's row); the contacts agreement its page with the consent as a toggle pill and Continue on the edge. The ICE candidate list stays on the phone. |
| About, terms and pages on the phone (`features/settings/features/about/view/about_screen.dart`, `webview_about_screen.dart`, `features/terms_conditions/view/terms_conditions_screen.dart`; `widgets/watch_open_on_phone.dart`) | About: the app line and the device under the title, then the Core's address and `WatchInfoRow`s - Core version ("?.?.?" when the Core could not be asked), session id (the phone's automation ids on the address and the id), FCM token, bundle version when given; the logo, the developer taps, embedded links, backend capabilities, licenses and copying stay on the phone. A watch has no web view (none on the Wear emulator), so the terms of the user agreement, a brand's web About and Help (`features/settings/features/help/view/help_screen.dart`, for brands with a Help item; sent with the app's `localeName`, as its web view opens it) are `WatchOpenOnPhonePage`: the page's name, "Opens on your phone", Open on phone on the edge; sent through `phone_link` (`RemoteActivityHelper` to the paired phone), "Check your phone" and back after a moment; with no phone to take it, "No phone connected" and Try again. |
| Active sessions (`features/settings/features/sessions/view/sessions_screen.dart`; the row is `SessionWatchTile` in `widgets/session_tile.dart`, shared with the device limit) | When idle sessions end as a row that opens `SettingsWatchChoicePage` (the installation's period, the presets, a period of one's own in force; a number of days of one's own stays on the phone), or a line stating it where it cannot be chosen; "This device" and its row - tinted, `readOnly` - then "Other devices" and theirs: the kind's icon, the device, OS, place and when seen, a tap signs it out after the watch confirm (a spinner while it does). Sign out others is the red edge button, after the watch confirm. On its way, failed (Try again on the edge) and empty (Refresh on the edge, for the phone's pull to refresh) are `WatchStatePage`s. On the device limit the rows are the same pills, a gap between them. |
| Storage and cache (`features/settings/features/cache_management/view/cache_management_screen.dart`) | A `WatchListTile` per store: its name, its size ("Unknown" when it could not be measured), a spinner while it is measured or cleared, a bin otherwise. A tap asks on the watch confirm - "Clear Voicemail audio?", the store's description under it - and clears it; on the phone Clear goes without asking, but a row is easier to touch by chance than a button. Nothing cached is a `WatchStatePage`. |
| Device limit (`features/login/view/login_device_limit_screen.dart`) | No app bar: the screen's name, the phone's reason under it, the account's devices as the session rows (`SessionWatchTile`) - a tap signs one out after the watch confirm and finishes signing in here. Back is the watch's swipe, held while a device is being signed out, as on the phone. What comes after (still at the limit, already gone, out of time) is said as on the phone. |
| Version gates (`features/version_gate/view/update_required_screen.dart`, `compatibility_issue_screen.dart`) | Neither can be left by Back. Update required: why in a line, the app, build and minimum versions as `WatchInfoRow`s, Log out as the last row; Update on the edge once the store has the app. Compatibility issue: the phone's text under the title (the reason and both versions), Update as a row where the store has a newer build, Log out on the soft edge. |
| System pages (`app/notifications/view/error_details_screen.dart`, `features/undefined/view/undefined_screen.dart`, `features/session_status/view/session_restart_screen.dart`) | Error details: the error's title and its fields as `WatchInfoRow`s that scroll; copying a field, sharing and the log console stay on the phone. An invalid link or a feature not supported: the `WatchStatePage` with the badge, the title, the text and Continue on the edge. Session restart: on its way `WatchStatePage.loading` with the phone's line under the spinner; unreachable, the reason with Try again on the edge and Log out under the state, the phone's automation ids and keys on both. |
| Notifications (`features/system_notifications/view/system_notifications_screen.dart`) | The notices as `WatchNoticeCard`s on a reversed list - newest at the bottom, as on the phone, older ones loading as the top comes near: the kind's mark, the title, three lines of the text and the time, an unseen one tinted and marked seen as it shows. A tap opens the whole notice on `WatchTextScreen`; a long press deletes it after the watch confirm, in place of the swipe. On its way and empty are `WatchStatePage`s; deleting all stays on the phone. The hub has no way in yet (the phone opens it from the bar's badge); a push tap opens it. |
| Embedded pages and the log console (`features/embedded/view/embedded_screen_page.dart`, `embedded_tab_page.dart`; `embedded_watch_page.dart`) | A watch has no web view: an embedded page - a Settings item (Terms, an embedded link) or a bottom-menu section - is `EmbeddedWatchPage`. On the network it is the open-on-phone page under its configured name (its host when it has none); built into the app (an asset, inline content) it has no address to send, so a `WatchStatePage` says to open it in the app on the phone. The page opened on the phone gets nothing the app injects (payload, metrics), so the phone's load-error page never shows on a watch. The log console is not offered: no Settings row, no tile under error details, no taps on About. |
| Call center - the bottom-menu section and the settings screen (`features/call_center/view/call_center_tab_screen.dart`, `call_center_screen.dart`; `widgets/call_center_watch_body.dart`) | `CallCenterWatchBody` under a title (the section's name from the hub, "My queues" in settings): All queues as a `WatchToggleChip` saying how many it takes calls from - mixed reads off and a tap logs into all, as on the phone - then a pill per queue: its name, online or offline and how many wait; a pill offers nothing while a change is on its way. A refused change says why as the phone does. Loading, failed (Try again on the edge) and no queues are `WatchStatePage`s; the queue number and agent counts stay on the phone. |
| Contact (`features/contact/view/contact_screen.dart`) | `ContactWatchView`: a small avatar and the name, a `WatchListTile` per number - a tap calls it, or, while somebody is being chosen, chooses it - then rows for the main number: Video call, Message, History, Favorites (a row with a star, tinted when on - a switch left its label too little room), and the addresses last; numbers and addresses keep one line (`fitTitle`); the call to the main number is the edge button in the keypad's call style. No overflow menu, call-from, SMS, transfer, presence or SIP options: they stay on the phone. |
| Call (`features/call/widgets/watch/`) | `CallActiveScaffold` keeps the state, the remote picture and the hiding of the controls, and swaps `CallControls` for `CallControlsWatch` over the same `CallControlsParams`. The face: a ringing call is Decline and Answer side by side (no edge button), an outgoing one its step and the end edge button, an answered one its name and the phone's status line (`callDescription`, shared with `CallInfo`), Mute, the audio route (a speaker toggle, or the devices when a headset is there) and More, with the end edge button. Which actions the focused call allows is `CallActionAvailability`, shared with the phone's `CallActionArea`. One tap away, each a page of the call screen's routes (`callWatchRoutes`, read from `CallWatchScope`), each on the whole face, back returning to the page before: More (a `WatchIconGrid` of keypad, hold, transfer, camera, camera switch, calls, the room, fit and blur), the audio devices, the transfer menu, the calls with Merge, the room with its participants, and the in-call keypad. A page that no longer applies - a call ringing, the room ended, the calls merged into it - is closed by `CallControlsWatch`. On a watch the floating call thumbnail and the camera preview are not shown; the hub shows the call put aside as a pill in its title's place. Failure dialogs and snackbars are still the phone's. |

The watch parts of the kit, in `packages/adaptive_kit`. A screen's watch arrangement says what
to show; how it sits on a face comes from these.

Screen shapes:

- `WatchActionLayout` - a screen with one main action: content scrolling in a short column, an
  optional secondary action at its end, the main action as the edge button, the column fading
  out above it. Descriptions and plain text take the small body size, outlined fields the
  pill shape. `title:` opens the column with a `WatchTitle`; the main action is a
  `WatchAction` (a label, a callback, the screen's style, an automation id) or, when the
  button shows more than a label (a spinner), a `primary:` builder. The sign-in forms, the
  custom-core screen and the consent screens are built on it.
- `WatchScrollList` - a screen that is only a list (a menu, a list of choices): the padding a
  face needs and a fade into the bottom edge; with `bottom`, the choices sit on the bottom of
  the face and the rest is centred above them. As a page opened over another screen it takes
  a `title`, a `spacing` between its rows, and `opaque` for the page's own background.
  `WatchScrollList.builder` is the same list for rows there can be many of (a call history): the
  rows are built as they scroll into view, after the title and an optional `header` (a filter
  chip), with a `controller` for a list that loads more near its end, and an optional `edge` -
  the page's one action as the edge button, the list fading out above it (the calls with a number).
- `WatchEdgeLayout` - a screen whose content stays put above one main action along the bottom
  (a call, a keypad): the body gets the face less the edge button's room, an optional
  `backdrop` fills the face behind it. The scrolling counterpart is `WatchActionLayout`.
- `WatchStatePage` - a list section with nothing to list yet: empty, failed, access refused. The
  section's title stays on top, the middle holds an optional muted icon (smaller on a small face),
  the message and a hint under it, read as one node; what can be done about it - try again, open the
  settings, start a chat - is a `WatchAction` on the edge button. `WatchStatePage.loading` is the
  section on its way: a spinner the screen reader names by the app's `progressLabel`, an optional
  hint ("Connecting..."), no action. The state is a live region, so a section's loading page turning
  into what came of it is announced; a middle that does not fit scrolls and fades into the edge below.
  Every list section shows these states this way, not with the phone's placeholders. `footer:` keeps
  what the section offers beside the state - the chip of another list - under it, scrolling with it.
- `WatchConfirm` - a question asked before doing something, on the whole face: the question (a
  header) and an optional detail in the middle, inside a list's padding and scrolling with a fade at both
  edges when they do not fit, and the answers as two `WatchRoundButton`s under them - no on the left,
  tonal; yes on the right, filled, in the error colours when it is destructive. The labels are the app's
  and the background is whatever holds it; `questionColor`, `detailColor` and `confirmColor` (its icon
  black or white, whichever reads on it) fit it to a surface that is not the scheme's. The app's
  `ConfirmDialog` shows it on a watch as a full-screen dialog named as an alert, in the dialog theme's
  surface and text colours (the screen's without them) and the theme's colour for its yes button (same
  answers: yes, no, nothing when dismissed), and its `AlertDialog` elsewhere.
- `WatchIconGrid` - a screen of round buttons with captions under a short title, three to a
  row (fewer, and larger, when there are fewer). On a round face the grid keeps to two thirds
  of the face, centred, the title above it, so the corner captions clear the bezel. A `header`
  widget can take the title's place; a cell without `onPressed` is shown disabled. The main
  hub, the ways in and a call's More are built on it.
- A menu in front of pages is routes, not a kit part: the ways in and the main hub are the first
  tab of their `AutoTabsRouter` on a watch, `LoginTypeSelectScreen` and `MainHub`, and a text a face cuts short
  opens whole on `WatchTextScreenPageRoute`, pushed on the root router from any screen.
- `WatchEdgeButton` - a screen's one action along the bottom of the face (of a screen that
  fills the window, with nothing under it). Its builder gets the style to merge over the
  button's own (`overlay.merge(themeStyle)`): the outline - `WatchEdgeButtonBorder`, a rounded
  top cut by the face circle, on a round face, a `StadiumBorder` on a rectangular one - and the
  label padding. `compact: true` is the thinner one a keypad uses. The content above leaves
  `WatchEdgeButton.reservedHeight(context)` free.

Parts:

- `WatchPill.style` - a full-width button inside a column (a list entry, a secondary action, a
  link): a pill at the 48-point tap floor, merged over the button's own style.
- `WatchRoundButton` - a round button with a short caption under it, one node named by its
  label: filled, tonal or outlined (`WatchRoundEmphasis`), on a light page or over the call
  (`WatchRoundTone.onDark`: light, translucent, solid when on). A screen's own style, such as
  a hangup's colours, wins. The grid's cells and a call's controls are built on it.
- `WatchKeyGrid` - twelve keys in four rows sharing the height, with no gaps; a held key enters
  its alternate (0 for +) unless `alternates` is off, as for a call's tones. The app gives it
  `watchDialKeys`, its keypad as the grid's `WatchKey`s.
- `WatchSpinner` - the spinner of something on its way, in the one watch size, named by the
  app's label; the state page and a list's rows still coming show it.
- `WatchTitle` - a screen's short centred title, in place of an icon or an app bar.
- `WatchScrollList.builder(reverse: true)` - row 0 at the bottom above the edge button, the title at
  the top: a conversation, newest last.
- `WatchListTile` - one row of a watch list (a device, a call, a way to transfer): a pill at
  the tap floor with an icon, a title of up to two lines (or one, set smaller, with `fitTitle` - a
  number, an address), a one-line subtitle and a trailing
  mark; one button for assistive technology. `selected` tints it, `outlined` marks the row
  the screen acts on; `onLongPress` is the row's second action (removing it), offered to a screen
  reader under `longPressHint`; a disabled row offers neither.
- `WatchSearchRow` - the row over a searchable list: a round search button beside the list's
  chooser as a pill, or the query as a pill with its cross beside the chooser as a round button;
  the search alone without a chooser. A tap opens the watch keyboard over a field nobody sees; a
  page or dialog over the row takes the field's focus, so closing it brings no keyboard back.
- `WatchKeyboardInput` - the watch keyboard behind a button: a field nobody sees under what the
  builder draws (a search pill, Reply), given `open`; a page or dialog over it takes the field's
  focus, so closing it brings no keyboard back. `WatchSearchRow` is built on it.
- `WatchBubble` - one message of a conversation: the user's own on the right in the primary colour,
  the other side's on the left, the sender's name over it in a group, the time and a delivery mark
  under the text, a note under the bubble ("Failed"); one node for a screen reader.
- `WatchInfoRow` - a value to read, not press (a version, an id, an error's field): its label small above it,
  the value a node of its own with an optional automation id, as the phone's rows read.
- `WatchNoticeCard` - a notice in a list: a mark and a title, a few lines of its text and the time, tinted while unread; one node with a tap and a named long press.
- `WatchListLabel` - the title of a group of rows inside a list (a settings section): small capitals in
  the primary colour, a heading for a screen reader.
- `WatchListTile(readOnly: true)` - a row that shows something and takes no tap, at full strength, read as text.
- `WatchToggleChip` takes a `subtitle`: what the state means, or why it cannot change now; offering nothing it reads as disabled.
- `WatchPlayButton` - play and pause of a recording: one round button with a ring around it that
  fills as the recording plays (turns without an end while it loads) and the time under it; one
  node for a screen reader, what the press does and how far it has got in words.
- `WatchLink` - a link inside a column (a page to read): an underlined label at the tap floor,
  not a second pill competing with the screen's action; it takes an automation id.
- `WatchToggleChip` - a consent or a setting as one full-width pill with a small switch; one
  semantics node with the label, the state and the tap.
- `WatchLogo` (in the app, it needs the theme's images) - a themed logo fitted into a height,
  without the paddings the theme gives it for a phone. Only the landing shows a logo on a watch; the screens after it give the room to
  their content.
- `WatchListNote` - a centred, muted line in a list's place of rows (no calls, nothing found), read
  out when it appears.
- `WatchPillButton` - a tonal pill of a list's controls (a filter, an address book): an icon and a
  short label set smaller to fit half a row, the icon left out on a small face; one button named
  by its `semanticsLabel`.
- `WatchSeparator` - the short centred bar between a list's controls (a filter, a search) and its rows:
  a line across would run into the bezel of a round face. Decoration, not read out.
- `WatchFadeMask`, `WatchStadiumFields` - the fade (at the bottom, and at the top too when asked) and
  the pill fields the layouts above apply.

Geometry:

- `context.isRoundScreen` - a round watch face. Android answers it (`Configuration.isScreenRound`,
  read once at startup through the `device_profile` plugin and shared as `ScreenShape`); where
  nothing answers - the configurator's preview, tests - a watch whose window is square counts as
  round. `roundSafeInset(diameter)` keeps content inside the square inscribed
  in the face.
- `context.isSmallWatch` - a face below `FormFactorBreakpoints.smallWatchMaxShortestSide` (200);
  every size that differs between the small and the large faces switches on it.
- `context.watchContentPadding()` - the padding of content that does not scroll (the keypad, the
  landing's brand); `context.watchListPadding(minBottom:)` - of a scrolling list.
- `watchResizesForKeyboard` - false: the watch keyboard covers the whole face, so a watch
  scaffold does not shrink for it.

A screen's watch arrangement is built from stock widgets plus these; anything that needs a
painter of its own (text along the bezel, a bezel scroll indicator) is left out.

### Does it fit

`packages/adaptive_kit/test/helpers/screen_presets.dart`, reached from the app's tests through
`test/helpers/screen_presets.dart`, holds the configurator's devices
(`watchPresets`, `handsetPresets`, `largePresets`) and
`pumpCollectingOverflows`, which returns every overflow of a pumped screen
instead of failing on the first. A fit test runs a screen on every preset
with the shipped theme (`withShippedTheme` in `test/helpers/shipped_theme.dart`:
without it the logos and type that make a screen tall are missing) and keeps the screens it
does not fit yet in a known-overflow list; a preset leaves the list in the
change that makes the screen fit. The tests so far:
`test/features/login/login_mode_select_fit_test.dart` (fits everywhere, watches included),
`test/features/keypad/keypad_fit_test.dart` (fits everywhere, watches included).

## Step 0: rotation is a product decision

The app is portrait-locked globally (`app/view/app.dart` sends
`PreferredOrientation.portrait` at startup through `OrientationsBloc`) and
unlocked per flow: `features/call/view/call_shell.dart` switches to
`PreferredOrientation.auto` while a call is on screen and back to portrait
after. A screen without an unlock never sees landscape, so adding an
arrangement starts with deciding - and wiring - where its flow unlocks
rotation, the way the call shell does.

## Delivery shape: two stacked changes

The call screen shipped as a stack, and the split is what made both halves
reviewable. Repeat it:

1. **Preparation, behavior-preserving.** Extract the screen's building
   blocks into standalone widgets, bundle the constructor traffic into one
   params object, move the screen body into `<screen>_portrait.dart`. The
   screen renders exactly as before - the change is judged on that claim, so
   keep any legacy landscape fallback alive in this half.
2. **The arrangement, almost purely additive.** A new
   `<screen>_landscape.dart`, the `OrientationLayoutSelector` swap, the
   landscape test suites, the feature-doc update. Reviewers read one new
   file and a two-line selector.

Commit the second on top of the first: Gerrit keeps the two as one relation
chain, and the second is submitted after the first.

## Structure rules

- **Blocks are dumb, screens compose.** A shared block (an info panel, an
  action grid) renders content and fires callbacks; it never decides where
  it stands or reads the orientation. Each arrangement file places the same
  blocks differently. Knobs like `hangupRowShown`/`padded` on the call
  action area are the pattern: the layout above turns off what it places
  itself.
- **One params object.** Everything the arrangements present and dispatch
  travels as a single object built once by the screen
  (`CallControlsParams` is the reference). A new control is one new field,
  not a change in every constructor on the way.
- **State stays on the screen.** Anything both arrangements show (the call
  screen's typed DTMF digits) is owned by the screen, exposed as a
  `ValueListenable`, and merely rendered by the arrangements - so rotation
  can neither lose nor duplicate it, and updating it repaints the listeners
  instead of rebuilding the screen.
- **Rebuild trigger.** Where the screen owns layers around the selector, an
  `OrientationBuilder` around the body guarantees the rebuild on rotation;
  the selector itself subscribes only to the orientation aspect.

## Layout rules for the landscape file

Hard-won on the call screen; treat them as defaults, not suggestions.

- **Budget from constraints, not from the screen size.** Landscape sizes
  derive from `shortestSide` (the height), so on a wide-but-low window they
  can outgrow the width. Zone widths come from `constraints.maxWidth` minus
  the real chrome.
- **Floor every tap target at `kMinInteractiveDimension`.** Zones shrink;
  buttons do not. Compute the zone width at which scaled buttons hit the
  floor and stop shrinking the zone there.
- **Fold, never vanish.** When a dedicated zone no longer fits (the call
  screen's isolated hangup on a split-screen window), fold its control back
  into the main grid so one scale carries everything down together. A
  control the user needs must never be budgeted away.
- **Text yields, buttons do not.** Long names, raised font scale: text
  wraps and tall content scrolls. Never put text and critical buttons under
  one `FittedBox` - the text's growth becomes the buttons' shrink.
- **`FittedBox(scaleDown)` is a guard, not a layout tool.** It backstops
  the degenerate window nobody designed for; the floors above must make it
  a no-op on real devices.

## Test conventions

- **The default 800x600 test surface IS landscape.** A suite that pins
  portrait behavior must say so (`pinPortraitSurface()` in the call harness
  is the pattern), or it silently tests the other arrangement.
- **A landscape suite and a landscape semantics suite** beside the portrait
  ones: zone order, controls that exist only there, activation through
  semantics (`tapViaSemantics`), `expectTapTargetSemantics` and
  `meetsGuideline(labeledTapTargetGuideline)` per
  [`accessibility.md`](../guides/accessibility.md).
- **Degenerate surfaces are test cases**: a split-screen-narrow window, a
  doubled font scale, the fold threshold. Assert no overflow and the tap
  floors.
- **Measure with `getRect`, not `getSize`.** Inside a `FittedBox`,
  `getSize` reports the pre-scale layout size and passes vacuously;
  `getRect` applies the transform the user actually gets.
- **Prove every new test can fail**: break the line it pins, watch it go
  red, restore. Commit before the mutation pass - `git checkout --`
  restores the committed state, including over your uncommitted fixes.
