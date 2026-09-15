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
  String get announcement;                        // what the banner says
  bool offeredBy(MainFlavor flavor);              // which sections can answer
  bool accepts(DestinationCandidate candidate);   // which rows are answers
  VoidCallback? get onCancel;                     // the way out, where there is one
  IconData get pickIcon;                          // the mark it carries
  String pickLabel(DestinationCandidate c);       // what the control is called
  void submit(DestinationCandidate candidate);    // what to do with one
}
```

`submit` is never called for a candidate `accepts` refused, and that is enforced
rather than promised: `submitDestination` in `lib/widgets/destination_picking.dart`
asks first and answers whether it went through. Screens do not perform the check
themselves, because a screen that forgets it is the failure this mechanism
exists to remove - and two of them did forget.

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
  const ForwardVoicemailPurpose({required this.announcement, required this.messageId, required this.onCancel});

  @override
  final String announcement;
  final String messageId;

  @override
  final VoidCallback? onCancel;

  @override
  bool offeredBy(MainFlavor flavor) => flavor == MainFlavor.contacts;

  @override
  bool accepts(DestinationCandidate candidate) => candidate.contact?.canReceiveForwardedVoicemail ?? false;

  @override
  IconData get pickIcon => Icons.forward_to_inbox;

  @override
  String pickLabel(DestinationCandidate candidate) => 'Forward to ${candidate.contact!.displayTitle}';

  @override
  void submit(DestinationCandidate candidate) => _forward(messageId, candidate.contact!.sourceId!);

  @override
  List<Object?> get props => [announcement, messageId];
}
```

What to get right:

- **Value equality.** The scope is rebuilt with the shell. A purpose compared by
  identity alone would notify every row on the screen on every frame.
- **`announcement` arrives localized.** It is built where a context is at hand,
  so nothing below needs strings of its own.
- **`offeredBy` decides every section**, with no default arm. A section added to
  `MainFlavor` later then fails to compile rather than quietly answering false.
- **`pickLabel` and `pickIcon` are how the control presents itself.** Left to the
  screen it can only say and draw one purpose's gesture, and it would be the
  wrong one for every other: handing a call on is not passing a message along.
- **`onCancel` is null only where the person already has a way out.** A transfer
  is abandoned by returning to the call, which clears the flag that built the
  purpose; a message looking for a recipient has no such screen to go back to,
  so without a button the only way to stop is to send it to somebody.

Then say when it is in force. The feature answers that itself, in a static on
the purpose, so the shell never learns what the feature is for:

```dart
static SomePurpose? maybeOf(BuildContext context) {
  final asking = context.select<SomeCubit, Something?>((cubit) => cubit.state.pending);
  if (asking == null) return null;

  return SomePurpose(announcement: context.l10n.some_key, ...);
}
```

The shell asks each feature in turn, and that line is the whole of what it
knows - `lib/features/main/view/main_screen_page.dart`:

```dart
final DestinationPickPurpose? pickPurpose =
    BlindTransferPurpose.maybeOf(context) ?? ForwardVoicemailPurpose.maybeOf(context);

return MainScreen(
  body: DestinationPicking(purpose: pickPurpose, child: child),
  pickPurpose: pickPurpose,
  ...
);
```

Only one purpose can be in force: somebody cannot be choosing for two things at
once. The order of that `??` is the arbitration, and a call in hand comes
first.

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
  dialling, offering to hand a call over - whether or not it can be chosen. A
  row that kept those was how a refused destination still ended up being acted
  on, through a menu entry nobody thought of as part of choosing.
- **Only a row the purpose accepts becomes tappable.** One it does not stays
  visible and inert rather than vanishing: somebody looking for a colleague who
  is not eligible should see that they are there and cannot be chosen, not
  wonder where they went.

A refusal has exactly one shape: no callback. A row that keeps a callback and
leaves the submission to refuse it is a row that looks pickable and is not.

In the lists this is one object, `TilePick`, handed to the row. Its presence is
what says a choice is being made; its `onPressed` says whether this row answers
it. The row then draws the purpose's mark, or nothing at all - not the dial
shortcut, and not the overflow menu behind it, which went on offering to call,
to message and to hand a call over until this replaced it.

Nothing about this is gated on the call-transfer configuration. That setting is
permission to hand a call over, not permission to answer whatever is being
asked; a purpose of its own must work where transfers are switched off.

`pickDestination` submits and then pops, because the choice was made on a list
the person was sent to and there is nothing left to do there. The keypad is the
exception - it is where they already were, so it calls `purpose.submit` directly
(`lib/features/keypad/view/keypad_view.dart`).

The keypad has no rows, so it asks both questions of what is typed: whether the
section can answer at all (`offeredBy`), and whether the current value is an
answer (`accepts`). Offering the section is not acceptance of everything typed
into it. It also watches the whole value rather than whether there is one -
two different numbers are not the same state - and clears the field only once
the purpose has taken it, so a refusal does not look like a successful send.

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

## The purposes

**Handing a call over** - `lib/features/call/models/blind_transfer_purpose.dart`.
Accepts anything with a number, is offered by favourites, recents, contacts and
the keypad, and submits through `CallController.submitTransfer`.

Its state did not move here. Whether a transfer is under way is still a field
on the call (`Transfer.blindTransferInitiated` on `ActiveCall`), cleared by
returning to the call screen, by the call ending, and by a signalling failure.
The shell reads that flag and builds the purpose from it. So the call owns the
mode, and this owns only what the lists do about it.

**Passing a voice message on** -
`lib/features/voicemail/models/forward_voicemail_purpose.dart`. Narrower: it
takes only a contact that came from the backend with an id of its own and is
not the person forwarding, because a forward addresses an account rather than
dialling a number. That also keeps it off the keypad, where nothing typed could
be one.

Its state is `VoicemailForwardingCubit`, provided with the shell so it outlives
the voicemail screen - the colleague is chosen two sections away, and the answer
has to come back to something that still knows which message it was. That cubit
also says what came of the send, which `VoicemailForwardReporter` turns into a
line at the bottom of whatever screen the person ended up on - a widget of the
feature's own, mounted by the shell above the sections.

Only one purpose is in force at a time, and a call in hand comes first: somebody
holding a call they are trying to hand on cannot wait while a message finds a
recipient. That precedence is one expression in
`lib/features/main/view/main_screen_page.dart`.

## Known gaps

- **Nothing is said on a section that cannot answer.** The user is still
  choosing there and is not told so.

It predates this mechanism. Closing it is now one place rather than eight: the
banner, at `main_screen.dart` - which is where the way out went when the second
purpose needed one.

## Tests

| File | What it pins |
|---|---|
| `test/features/call/models/blind_transfer_purpose_test.dart` | The transfer policy, walking every `MainFlavor` |
| `test/widgets/destination_picking_test.dart` | The scope, and that an unchanged purpose does not notify |
| `test/features/main/main_screen_test.dart` | The banner, driven by a fake purpose so the screen cannot hardcode wording |
| `test/features/contact/contact_screen_semantics_test.dart` | A card row in picking mode, through `contact_screen_harness.dart` |
| `test/features/contact/widgets/contact_phone_tile_adapter_test.dart` | The card's control: shown only for an accepted number, ungated by transfer, and no other route out while picking |
| `test/features/keypad/keypad_picking_test.dart` | The pad following the typed value, and not needing transfer switched on |
| `test/widgets/call_tile_picking_test.dart` | A list row: the purpose's mark, and no menu left behind it |
| `test/features/voicemail/forward_voicemail_purpose_test.dart` | The second purpose, and how much narrower it is |
| `test/features/voicemail/cubits/voicemail_forwarding_cubit_test.dart` | The message that waits while the address book is browsed |
| `test/features/voicemail/widgets/voicemail_forward_reporter_test.dart` | What the person is told once a forward is over, and when a retry is offered |
