# Voicemail

The mailbox: what the backend recorded for this account, and everything the
person can do with one message - hear it, keep it, throw it away, call back,
open the caller's card, pass it to a colleague.
Last reviewed: 2026-10-06.

## Where it lives

```
lib/features/voicemail/
  bloc/        VoicemailCubit + VoicemailState (one screen), VoicemailPlaybackController
  cubits/      VoicemailSessionCubit (what the whole session shares)
  models/      ForwardVoicemailPurpose, VoicemailForwardOutcome, VoicemailScreenContext
  utils/       VoicemailForwarding (sending a message on), media headers
  view/        the router page, the two hosts, the screen
  widgets/     the list body, a tile, playback, filters, header actions
lib/repositories/voicemail/   VoicemailRepository - the only thing that talks to the backend and the database
```

## Two hosts, one screen

The same list is reached two ways, and each brings its own chrome:

| Host | File | Where it appears |
|---|---|---|
| A section of the bottom menu | `view/voicemail_tab_page.dart` -> `voicemail_tab_screen.dart` | when the brand's `app.config.json` configures a voicemail tab |
| A sub-screen of settings | `view/voicemail_screen_host.dart` | always, under Settings |

Both wrap `VoicemailScreen` in `VoicemailScreenHost`, which builds
`VoicemailCubit`, the playback controller and `VoicemailScreenContext` (the
media cache path, the date format and the headers an authenticated media
request needs).

## Who holds what

Two cubits, split by how long what they hold has to live, and no copy of either
in the other.

| | `VoicemailSessionCubit` | `VoicemailCubit` |
|---|---|---|
| Lives | the whole session, provided eagerly in `main_shell_blocs.dart` | one screen, built by `VoicemailScreenHost` |
| Holds | the stored mailbox, the count of waiting messages, the forwarders' names, how the last read of the mailbox went | which view is on, what is picked, the trash and how its read went, whether an action of this screen is in progress |
| Does | reads the mailbox when asked | everything the person does to a message, and says what came of it |

The mailbox is the session's because it outlives any one screen: voicemail is
shown from two places and counted on a third, and the screen reached from
settings is torn down and built again as the person moves about. A copy held by
each screen is a copy that can disagree with the badge beside it.

A widget needs both - the list is the session's, the filter over it the
screen's - and reads them together as a `VoicemailView`
(`bloc/voicemail_view.dart`), built by `VoicemailViewBuilder` from the two
states each time either changes and stored nowhere. Every answer the old state
used to carry - `visibleItems`, `isRefreshing`, `isLoadedWithError`,
`forwarderOf` - is worked out there. Nothing is mirrored, so no field has two
owners: the read of the mailbox and the read of the trash are two statuses in
two places, and one finishing cannot end the other.

The session cubit follows the count from the start, because a badge reads it,
and the mailbox only while a screen is showing it: `VoicemailCubit` calls
`attach()` when it is built and `detach()` when it closes. The query behind the
list joins the address book and runs again on every write to either, which is
not a cost to carry for somebody who never opens voicemail.

It never reads the mailbox on its own. The repository is registered for polling
and for refresh on connectivity recovery. Its `status` starts as
`VoicemailStatus.initial` - nobody has asked yet, which is not the same as
having been answered with nothing - and a screen decides from that state alone
whether to ask (`VoicemailCubit._readOnOpening`):

- **a mailbox still `initial`**, which is what the first screen of a session
  finds - and it says so if the read fails;
- **a mailbox whose last read left an `error`**, and then quietly: a poll that
  finds an empty mailbox writes nothing, so nothing else would clear the
  failure, but the person has been told once already;
- **on a pull to refresh**, always.

A screen does not read on every visit. The screen reached from settings is
built each time, and with the connection down each of those reads would fail
the same way, its sentence pushing aside whatever else the person was just
told.

A list arriving from the store says nothing about how the read of it went, so
it changes neither `status` nor `error`. The store emits for reasons that are
not a read - a write to the address book the query is joined with, the cached
copy the repository shows before it asks - and one of those must not end the
progress of a read still out or pass a failed one off as good.

A failed read stands in for the list (`VoicemailView.isLoadedWithError`) only
when the list that was read is empty - the whole mailbox, or the trash while it
is shown. A view that matches none of a mailbox's messages is an empty view.

The selection follows the list it was made over: the visible one. A picked
message that is deleted, or stops matching the view - heard while New is
showing - leaves the selection. A read of the trash that lands after the person
left the trash is dropped whole.

Whether the backend serves voicemail at all is asked of the repository every
time it could have changed - when a screen attaches, around a read, when the
list arrives - not once. The repository learns it from its own first read,
keeps it as a plain flag, and from then on answers every read with nothing
rather than an error; a flag read once at the start of the session would be
read before that.

The tab is a **router**, not the screen (`view/voicemail_router_page.dart`): a
message names the person who left it, and opening that person's card is a
screen of its own. A route lives in exactly one place in the tree, so every tab
that can reach a contact declares that route as its own child - otherwise
opening a card would carry the person into somebody else's tab.

## Capabilities the deployment declares

Nothing here is assumed. `FeatureAccess` reads the adapter's capabilities and
the screen offers only what is there (`lib/data/feature_access.dart`):

| Capability | What it adds |
|---|---|
| `voicemail` | the section itself |
| `voicemailSave` | the Keep action and the Saved filter |
| `voicemailTrash` | the Trash filter, Move to trash, Restore, Delete for good |
| `voicemailForward` | the Forward action |

A filter the mailbox cannot serve is absent rather than greyed out: nothing
promises a list that would come back empty for a reason the person cannot see.
Without the trash, a delete is final and the dialog says so.

On the wire the two read the other way round from their names: a plain `DELETE`
deletes for good, and `trash=true` is what moves a message to the trash. A client
that offers no trash controls therefore deletes by saying nothing, instead of
filling a mailbox it gives its user no way to empty (see `deleteUserVoicemail`).

## The list and its filters

The screen shows one filtered view (`VoicemailFilter`) of the session's mailbox,
or what the trash returned:

- **all** and **unheard** - local, over the stored mailbox;
- **saved** - local, the kept ones;
- **trash** - remote: the trash is asked for when the filter is chosen, not
  carried with the mailbox.

`refresh()` therefore means different things per filter, which is why it asks
the filter rather than the caller.

## One message, and several at once

| Action | Where | Note |
|---|---|---|
| Play | `VoicemailPlaybackController` + `widgets/audio_view.dart` | one player for the whole list; the file is cached under `mediaCacheBasePath` |
| Mark heard / new | `toggleSeenStatus` | the patch is awaited and reverted if the backend refuses |
| Keep / stop keeping | `toggleSavedStatus` | `voicemailSave` only |
| Call back | `startCall` | dials the number that left the message |
| Open contact | `callerOf` + `widgets/voicemail_body.dart` | the card is looked up on the tap rather than carried on every message; a caller who has left the address book says so |
| Move to trash, restore, delete for good | `removeVoicemail`, `restoreVoicemail`, `removeVoicemailPermanently` | |
| Forward | see below | `voicemailForward` only |

Several messages are selected in the list and acted on from the header
(`widgets/voicemail_delete_action.dart`): in the trash that means restoring them
or deleting them for good, everywhere else moving them to the trash. The three
bulk paths share one loop and one policy - a message the server refuses does not
stop the rest, the first refusal is what the caller is told about, and a
condition that will hold for every message stops the loop rather than being
asked a hundred times.

## A message that is not where the list has it

The list is drawn from what was true when it was read, and a mailbox moves on:
deleted from another device or from the IVR, emptied out of the trash, acted on
twice. Every action over one message can meet that, and each one answers it for
itself:

| What the backend said | What happens here |
|---|---|
| it did what was asked | the state is put where the action left it, and a move to the trash carries the way back |
| the message is not there any more | the list is read again, the row goes with it, and the person is told why |
| anything else | nothing here is touched |

Nothing of this is decided on screen. The row that was tapped is usually gone by
the time there is anything to say - the list has been re-read and the message is
no longer in it - so the mailbox says it through the app's notifications channel
(`models/notifications.dart`), which is also where the way back after a move to
the trash is offered. That one is a confirmation, not a refusal, so it leaves on
its own after three seconds like a deleted recent or favorite (`persist` false;
a bar with an action would otherwise wait to be answered, see
`docs/accessibility.md`). The list only asks.

The line between the last two is the point. A refusal that names the message
tells us something about the state and the list can be put right. A server that
broke tells us nothing - the write did not happen, and what is on the server now
is exactly as unknown as it was before the call - so re-reading would be
inventing an answer the backend did not give.

Which refusal is which is not read here at all: the api names it. A
`message_not_found` from the voicemail endpoints arrives as
`VoicemailMessageGoneException`, declared as a rule on those endpoints and keyed
on the code rather than the status - these calls are optional, so a bare 404 is
how a deployment says it has no such route, and a mailbox that was never
configured has a name of its own too.

A backend that broke needs no exclusion there: the api names that case itself.
Any 5xx no rule claimed arrives as `ServerFailureException`, which is a name for
"nothing follows from this" rather than a status for a feature to read.

## Saying that something did not happen

Every refusal other than `gone` used to be logged, recorded and never
mentioned: the message stayed on screen exactly as it was, so a tap that came
to nothing looked like a tap that was never made. They now go to the app's
notifications bloc through `onSubmitNotification`, which the shell turns into a
snackbar (`app/router/app_shell.dart`).

| What did not happen | What is said |
|---|---|
| a delete, one message or a selection | the message(s) could not be deleted |
| a restore out of the trash | the message(s) could not be restored |
| marking read/unread, keeping/unkeeping | the message could not be updated |
| emptying the trash | the trash could not be emptied |
| a read that left a list on screen | the list could not be refreshed |

An answer is about the write and nothing else. Some of these actions are
followed by a read - the trash keeps no stored copy, so it is asked for again -
and that read is not part of the answer: a restore that happened followed by a
list that would not load is a restore that happened, and the read says the rest
in its own words. Reporting it the other way told the person the opposite of
what the backend did, and offered to put back a message that was already back.

Two deliberate silences. A message the backend no longer has has a sentence of
its own, said the same way - the list is already right, and saying it twice in
two wordings is worse than saying it once. And a read that failed with nothing
to show is answered by the retry view standing in place of the list.

The sentences say what did not happen, not what went wrong: the reason is a
status code and a word from another system, and putting it in the sentence
would trade a clear statement for an unreadable one. It is still worth being
able to ask, so each of them carries what the backend answered behind a
`Details` action onto the existing error screen (`app/notifications/view/error_details_screen.dart`) with the status, the
backend's own code and the request id - what a support ticket needs and what
nobody can recover once the snackbar has gone. Which failure it was is the catch clause rather than a
test inside it: a `RequestFailure` carries its answer, and a request that never
arrived carries none and offers no action. Each action says what did
not happen in its own words, and the sentences are `models/notifications.dart`.

## The forwarder's name on a tile

A forwarded message arrives with the id of whoever passed it along and nothing
else about them. `VoicemailSessionCubit` resolves those ids against the address
book, matched on the id the backend issued rather than on a number, keeps each
answer, and the tile shows the name on a line of its own under the date. It is not a
replacement for the sender: both names matter and they answer different
questions - who left the recording, and how it got here. A colleague with no
name is shown the way the address book shows them, by extension or else by
number. A colleague the address book does not know falls back to their id,
which is a poor name but a true one.

## Passing a message to a colleague

Forwarding has no picker of its own. The person is sent to the address book -
the app's own, with its presence, its sources and its favourites - through the
destination-picking mechanism: [`../destination_picking.md`](../destination_picking.md).

```
menu -> Forward
  voicemail_body.dart          picking.ask(ForwardVoicemailPurpose(...)) + navigate to contacts
  forward_voicemail_purpose    who may be chosen: a contact from the backend, with the
                               server's own id, and not the person forwarding
  a row is tapped              submit -> VoicemailForwarding.send(message, recipient)
  voicemail_forwarding.dart    POST /user/voicemails/{id}/forward, then announce a report
  the shell's presenter        the sentence, and a retry where one could end differently
```

Nothing of this is kept between forwards: the message and the colleague are
arguments, the sentences are resolved when the person asks for the forward, and
the answer goes to the one thing still on screen by the time it arrives.

What each refusal means is `extensions/request_failure.dart` ->
`VoicemailForwardOutcome`: a recording too large and a colleague who is full are
answers, not faults, and are not worth another try; a backend that does not
forward at all, or a request that never got there, is.

## The badge on the tab

`VoicemailSessionCubit` carries the count of unheard messages for the tab icon
(`widgets/voicemail_flavor_overlay.dart`) and for the settings row
(`lib/features/settings/widgets/unread_voicemail_count_builder.dart`). Both
select the count alone, so a message changing does not rebuild them. The cubit
is eager: a badge that starts counting only once somebody opens the screen it
sits on is of no use there.

## Tests

| File | What it pins |
|---|---|
| `test/features/voicemail/bloc/voicemail_cubit_test.dart` | selection, keeping, the trash, forwarder names, the caller lookup, which refusal re-reads the list, and the read of the trash kept apart from the mailbox's - over a real session cubit |
| `test/features/voicemail/cubits/voicemail_session_cubit_test.dart` | the count, the mailbox followed only while a screen shows it, forwarder names, a backend with no voicemail noticed late, a read asked for and how it can end |
| `test/features/voicemail/bloc/voicemail_forwarder_names_test.dart` | the forwarder line over a real address book: a name, no name, an extension, nobody |
| `test/features/voicemail/extensions/request_failure_test.dart` | which refusals mean the message is gone, and which only look like it |
| `test/features/voicemail/voicemail_filter_test.dart` | which filters a deployment offers, and what each one shows |
| `test/features/voicemail/voicemail_tile_test.dart` | what one row offers, including the actions a capability removes |
| `test/features/voicemail/view/voicemail_selection_test.dart` | the header over the trash: restore, delete for good, and the count in the dialog |
| `test/features/voicemail/view/voicemail_forward_test.dart` | the screen leaving a request and sending the person to the address book |
| `test/features/voicemail/view/voicemail_open_contact_test.dart` | opening the caller, and a caller who is no longer there |
| `test/features/voicemail/utils/voicemail_forwarding_test.dart` | the send itself and every refusal turned into a sentence |
| `test/features/voicemail/forward_voicemail_purpose_test.dart` | who may be chosen, and how much narrower this is than a transfer |
| `test/repository/voicemail_bulk_remove_test.dart` | the shared bulk loop and its policy |
