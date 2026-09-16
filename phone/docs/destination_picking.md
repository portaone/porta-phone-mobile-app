# Sending somebody to the lists to choose a person

How a feature asks the user to pick somebody out of the contacts, recents,
favourites and keypad, and what those lists do while the choice is being made.
Last reviewed: 2026-09-16.

## The three pieces

Some features cannot finish without a person: a call being handed on needs
somewhere to go. Rather than build a picker of its own, the feature sends the
user to the lists the app already has and every row becomes the choice.

The lists know nothing about the features that ask. They know one thing: a
`DestinationPickPurpose` is in force above them, or none is.

| Piece | Where | What it is |
|---|---|---|
| `DestinationPickPurpose` | `lib/models/destination_picking/destination_pick_purpose.dart` | Why somebody is being chosen, and what happens once they are |
| `DestinationCandidate` | `lib/models/destination_picking/destination_candidate.dart` | What one row can hand over |
| `DestinationPicking` | `lib/widgets/destination_picking.dart` | The scope above the sections; what a list asks |

```dart
abstract interface class DestinationPickPurpose {
  String get announcement;                       // what the banner says
  bool offeredBy(MainFlavor flavor);             // which sections can answer
  bool accepts(DestinationCandidate candidate);  // which rows are answers
  void submit(DestinationCandidate candidate);   // what to do with one
}
```

## The candidate's two halves

The lists are not alike. A contact row knows a person; a call-history row knows
a number that may belong to nobody; the keypad knows only what was typed. Each
row offers what it has and the purpose decides whether that is enough:

```dart
class DestinationCandidate {
  final String? number;
  final Contact? contact;
}
```

Handing a call on needs a number and ignores the rest. Something that addresses
an account on the backend rather than dialling it - forwarding a voice message
to a colleague, say - reads the contact and ignores the number.

## Adding a purpose

One class, and one line where the active purpose is decided. No list changes.

```dart
class ForwardVoicemailPurpose extends Equatable implements DestinationPickPurpose {
  const ForwardVoicemailPurpose({required this.announcement, required this.messageId});

  @override
  final String announcement;
  final String messageId;

  @override
  bool offeredBy(MainFlavor flavor) => flavor == MainFlavor.contacts;

  @override
  bool accepts(DestinationCandidate candidate) => candidate.contact?.canReceiveForwardedVoicemail ?? false;

  @override
  void submit(DestinationCandidate candidate) => _forward(messageId, candidate.contact!.sourceId!);

  @override
  List<Object?> get props => [announcement, messageId];
}
```

Three things to get right:

- **Value equality.** The scope is rebuilt with the shell. A purpose compared by
  identity alone would notify every row on the screen on every frame.
- **`announcement` arrives localized.** It is built where a context is at hand,
  so nothing below needs strings of its own.
- **`offeredBy` decides every section**, with no default arm. A section added to
  `MainFlavor` later then fails to compile rather than quietly answering false.

Then say when it is in force. That decision lives in one place,
`lib/features/main/view/main_screen_page.dart`:

```dart
final pickPurpose = <the feature's own state says a choice is being made>
    ? SomePurpose(announcement: context.l10n.some_key, ...)
    : null;

return MainScreen(
  body: DestinationPicking(purpose: pickPurpose, child: child),
  pickPurpose: pickPurpose,
  ...
);
```

Only one purpose can be in force: somebody cannot be choosing for two things at
once. With a second purpose, that expression is where the two are arbitrated.

## The row contract

Two questions, and they are not the same one.

```dart
final purpose = context.pickPurpose;                        // null when no choice is being made
final candidate = DestinationCandidate(number: number, contact: contact);
final picks = purpose != null && purpose.accepts(candidate);

onTap: purpose != null
    ? (picks ? () => pickDestination(context, purpose, candidate) : null)
    : onToggleExpanded,
expanded: expanded && purpose == null,
onDialPressed: purpose == null && number != null ? () => call(number) : null,
```

- **While a choice is being made, no row does what it normally does** - expanding,
  dialling - whether or not it can be chosen.
- **Only a row the purpose accepts becomes tappable.** One it does not stays
  visible and inert rather than vanishing: somebody looking for a colleague who
  is not eligible should see that they are there and cannot be chosen, not
  wonder where they went.

`pickDestination` submits and then pops, because the choice was made on a list
the person was sent to and there is nothing left to do there. The keypad is the
exception - it is where they already were, so it calls `purpose.submit` directly
(`lib/features/keypad/view/keypad_view.dart`).

The keypad also has no rows, so it asks `offeredBy(MainFlavor.keypad)` rather
than `accepts`: whether this section can answer at all. A destination that has
to be an account cannot be typed.

## Call sites

| Section | File |
|---|---|
| Contacts | `lib/features/contacts/widgets/contact_tile_adapter.dart` |
| Contact card | `lib/features/contact/view/contact_screen.dart` |
| Recents | `lib/features/recents/view/recents_screen.dart` |
| Favourites | `lib/features/favorites/widgets/favorites_list.dart` |
| Call history | `lib/features/cdrs/widgets/full_recent_cdrs_list.dart`, `missed_recent_cdrs_list.dart` |
| Keypad | `lib/features/keypad/view/keypad_view.dart` |
| The reorder button it hides | `lib/features/contacts/view/contacts_filter_screen.dart` |

The banner is drawn once, by `MainScreen`
(`lib/features/main/view/main_screen.dart`), above the navigation bar and under
the same blur - a section drawing its own would put it beneath the bar the
screen floats over, where nobody sees it. It appears only on a section the
purpose says can answer: told on a page of conversations it would announce a
choice that cannot be made there.

## Blind transfer, the only purpose today

`lib/features/call/models/blind_transfer_purpose.dart`. It accepts anything with
a number, is offered by favourites, recents, contacts and the keypad, and
submits through `CallController.submitTransfer`.

**Its state did not move here.** Whether a transfer is under way is still a
field on the call (`Transfer.blindTransferInitiated` on `ActiveCall`), cleared
by returning to the call screen, by the call ending, and by a signalling
failure. The shell reads that flag and builds the purpose from it. So the call
owns the mode, and this owns only what the lists do about it.

## Known gaps

- **No cancel.** The banner is a live region with no button. The way out is to
  return to the call, which clears the flag.
- **Nothing is said on a section that cannot answer.** The user is still
  choosing there and is not told so.

Both predate this mechanism. Closing either is now one place rather than eight:
the banner, at `main_screen.dart`.

## Tests

| File | What it pins |
|---|---|
| `test/features/call/models/blind_transfer_purpose_test.dart` | The transfer policy, walking every `MainFlavor` |
| `test/widgets/destination_picking_test.dart` | The scope, and that an unchanged purpose does not notify |
| `test/features/main/main_screen_test.dart` | The banner, driven by a fake purpose so the screen cannot hardcode wording |
| `test/features/contact/contact_screen_semantics_test.dart` | A card row in picking mode, through `contact_screen_harness.dart` |
