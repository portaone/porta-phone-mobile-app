# Voicemail

The mailbox: what the backend recorded for this account, and everything the
person can do with one message - hear it, keep it, throw it away, call back,
open the caller's card, pass it to a colleague.
Last reviewed: 2026-09-18.

## Where it lives

```
lib/features/voicemail/
  bloc/        VoicemailCubit + VoicemailState, VoicemailPlaybackController
  cubits/      VoicemailUnreadCubit (the badge on the tab)
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

## The list and its filters

`VoicemailCubit` holds the mailbox as it is stored plus what the trash returned,
and the screen shows one filtered view of it (`VoicemailFilter`):

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
the trash is offered. The list only asks.

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
able to ask, so each of them carries what the backend answered - a
`RequestFailure`, or nothing where the request never arrived - behind a
`Details` action onto the existing error screen (`app/notifications/view/error_details_screen.dart`) with the status, the
backend's own code and the request id - what a support ticket needs and what
nobody can recover once the snackbar has gone. A failure with no such answer to
show - the network never got there - offers no action. Each action says what did
not happen in its own words, and the sentences are `models/notifications.dart`.

## The forwarder's name on a tile

A forwarded message arrives with the id of whoever passed it along and nothing
else about them. The cubit resolves those ids against the address book, matched
on the id the backend issued rather than on a number, keeps each answer, and the
tile shows the name on a line of its own under the date. It is not a
replacement for the sender: both names matter and they answer different
questions - who left the recording, and how it got here. A colleague the
address book does not know falls back to their id, which is a poor name but a
true one.

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

`VoicemailUnreadCubit` counts unheard messages for the tab icon
(`widgets/voicemail_flavor_overlay.dart`). It is eager: a badge that starts
counting only once somebody opens the screen it sits on is of no use there.

## Tests

| File | What it pins |
|---|---|
| `test/features/voicemail/bloc/voicemail_cubit_test.dart` | selection, keeping, the trash, forwarder names, the caller lookup, and which refusal re-reads the list |
| `test/features/voicemail/extensions/request_failure_test.dart` | which refusals mean the message is gone, and which only look like it |
| `test/features/voicemail/voicemail_filter_test.dart` | which filters a deployment offers, and what each one shows |
| `test/features/voicemail/voicemail_tile_test.dart` | what one row offers, including the actions a capability removes |
| `test/features/voicemail/view/voicemail_selection_test.dart` | the header over the trash: restore, delete for good, and the count in the dialog |
| `test/features/voicemail/view/voicemail_forward_test.dart` | the screen leaving a request and sending the person to the address book |
| `test/features/voicemail/view/voicemail_open_contact_test.dart` | opening the caller, and a caller who is no longer there |
| `test/features/voicemail/utils/voicemail_forwarding_test.dart` | the send itself and every refusal turned into a sentence |
| `test/features/voicemail/forward_voicemail_purpose_test.dart` | who may be chosen, and how much narrower this is than a transfer |
| `test/repository/voicemail_bulk_remove_test.dart` | the shared bulk loop and its policy |
