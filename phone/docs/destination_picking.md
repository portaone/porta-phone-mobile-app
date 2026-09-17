# Sending somebody to the lists to choose a person

How a feature asks the user to pick somebody out of the contacts, recents,
favourites and keypad, and what those lists do while the choice is being made.
Last reviewed: 2026-09-17.

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
| `DestinationPickingCubit` | `lib/blocs/destination_picking/destination_picking_cubit.dart` | Where a feature leaves its request, and what it has to say afterwards |
| `DestinationPickReport` | `lib/models/destination_picking/destination_pick_report.dart` | What came of a choice, in the feature's own words |

```dart
abstract interface class DestinationPickPurpose {
  String get announcement;                       // what the banner says
  DestinationPickPrecedence get precedence;      // who wins if two features ask
  bool get closedByChoice;                       // does a choice end it, or the feature
  bool get cancellable;                          // whether the banner offers a way out
  bool offeredBy(MainFlavor flavor);             // which sections can answer
  bool accepts(DestinationCandidate candidate);  // which rows are answers
  IconData get pickIcon;                         // the mark it carries
  String pickLabel(DestinationCandidate c);      // what the control is called
  void submit(DestinationCandidate candidate);   // what to do with one
}
```

`submit` is never called for a candidate `accepts` refused, and that is enforced
rather than promised: `submitDestination` in `lib/widgets/destination_picking.dart`
asks first and answers whether it went through. Screens do not perform the check
themselves, because a screen that forgets it is the failure this mechanism
exists to remove - and two of them did forget.

Two more things happen there, and for the same reason. A row built for a request
that no longer holds the floor is refused: a live request can take over between
the row being drawn and the tap landing on it, and that tap must not act for
whoever was pushed aside. And the request is closed by the choice only where the
purpose says a choice is what ends it - otherwise by whoever owns the mode. A
transfer does not end when a number is handed to it: the switch may refuse the
REFER, and the call is still looking for a target.

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

One class, and one place where the feature asks. No list changes. The example
below is the real one, shortened -
`lib/features/voicemail/models/forward_voicemail_purpose.dart`.

```dart
class ForwardVoicemailPurpose extends Equatable implements DestinationPickPurpose {
  const ForwardVoicemailPurpose({required this.announcement, required this.messageId});

  @override
  final String announcement;
  final String messageId;

  /// Nobody is on the line waiting for this, so it stands aside for a call.
  @override
  DestinationPickPrecedence get precedence => DestinationPickPrecedence.ordinary;

  /// There is no other way out of it: the screen that started this is two
  /// sections away by now.
  @override
  bool get cancellable => true;

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
- **`precedence` is the feature's own statement**, not the shell's knowledge of
  which features exist: a transfer says somebody is on the line, and that is
  why it cannot be pushed aside.
- **`closedByChoice` says who decides when it is over.** True where the feature
  owns the request outright - it asked, the choice answers it, done. False where
  the request mirrors a mode kept elsewhere, and the answer may still be
  refused; then whoever owns that mode takes the request back.

Then ask, wherever the feature decides it wants somebody, and send the person to
the lists yourself:

```dart
final asked = context.read<DestinationPickingCubit>().ask(
  SomePurpose(announcement: context.l10n.some_key, ...),
);
if (!asked) return;      // somebody is already choosing for something that outranks this

context.router.navigate(<wherever the person should choose>);
```

Nothing is added to the shell. It reads the one state and never learns which
features put anything in it:

```dart
final pickPurpose = context.select<DestinationPickingCubit, DestinationPickPurpose?>(
  (cubit) => cubit.state.purpose,
);
```

Only one purpose can be in force: somebody cannot be choosing for two things at
once. `ask` answers `false` rather than queueing, and `precedence` decides which
of the two it is - equal ranks leave the first one standing.

## Saying what came of it

By the time a forward has an answer the person is wherever the lists left them,
so the feature cannot say it on the screen that asked. It announces instead, in
its own words:

```dart
picking.announce(DestinationPickReport(
  message: l10n.voicemail_Snackbar_forwardTooLarge,
  isFailure: true,
  retryLabel: l10n.voicemail_Label_retry,   // only where trying again could end differently
  onRetry: () => _send(message, recipient),
));
```

`DestinationPickReportPresenter`, mounted once above the sections, puts it on screen. What
a backend refusal means is the feature's business; which snackbar it becomes is
not the feature's problem.

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

In the lists this is one object, `DestinationPickOffer`, handed to the row. Its presence is
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

**Passing a voice message on** -
`lib/features/voicemail/models/forward_voicemail_purpose.dart`. Narrower: it
takes only a contact that came from the backend with an id of its own and is
not the person forwarding, because a forward addresses an account rather than
dialling a number. That also keeps it off the keypad, where nothing typed could
be one. It asks in `voicemail_body.dart` and sends the person to the address
book itself; the sending and what came of it are
`lib/features/voicemail/utils/voicemail_forwarding.dart`, which announces a
report rather than holding any state of its own.

### Who owns the mode, and the bridge that follows from it

The forward owns its request outright - it asked, the choice answers it - so
`closedByChoice` is true and the mechanism closes it where the choice is taken.

A transfer does not. Whether one is looking for a target is one of six
`Transfer` states on `ActiveCall`, set in one place inside `CallBloc` and
cleared in ten - signalling failures, the call ending, the attended-transfer
branches. Asking the call to `ask` and `withdraw` by hand from each of those
would be a second copy of that state machine, one forgotten edge away from a
banner nothing can take off the screen. And a switch that refuses the REFER
leaves the call still looking for a target, so a choice is not the end of it
either: `closedByChoice` is false there, and the request goes when the call
says so.

So the call publishes what it always did, and
`lib/features/call/widgets/blind_transfer_picking.dart` reflects one slice of
it - "is a transfer looking for somebody" - into the request, in one direction.
It is a `BlocListener`, mounted among the call's own in
`lib/features/call/view/call_shell.dart`, which is where the call's
collaborators already live and where the `CallControllerScope` it needs is in
scope. The mechanism learns nothing about calls; the call learns nothing about
the mechanism.

A bridge is not what a feature normally needs. It is for a mode that already
lives in somebody else's bloc and is driven from there. A feature that decides
for itself - passing a voice message on - calls `ask` where the person asks for
it, and mounts nothing.

## Known gaps

- **Nothing is said on a section that cannot answer.** The user is still
  choosing there and is not told so.

It predates this mechanism. Closing it is now one place rather than eight: the
banner, at `main_screen.dart`.

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
| `test/blocs/destination_picking_cubit_test.dart` | The request itself: who wins when two features ask, and that a report outlives the request |
| `test/features/call/widgets/blind_transfer_picking_test.dart` | The bridge, including a transfer that ends without taking somebody else's request with it |
| `test/widgets/destination_pick_report_presenter_test.dart` | What a feature has to say, the retry offered only where one can change the answer, and a report that was waiting before the presenter arrived |
| `test/features/voicemail/forward_voicemail_purpose_test.dart` | The second purpose, and how much narrower it is |
| `test/features/voicemail/utils/voicemail_forwarding_test.dart` | The message being sent, and each of the backend's refusals turned into a sentence |
