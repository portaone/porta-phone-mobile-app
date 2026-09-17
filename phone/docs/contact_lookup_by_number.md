# Finding the contact a phone number belongs to

How the app turns a phone number into a name, and the two invariants that keep
it from naming the wrong person. Last reviewed: 2026-09-17.

## The question

A number arrives from somewhere the user did not pick it: a call history record,
an incoming push, a keypad field. The app wants the person behind it, so the
screen can show a name instead of digits.

The question sounds like a dictionary lookup and is not one. The number in hand
and the number in the phone book are written by different systems and rarely
character-for-character the same.

## The two steps

```
exact match on the stored number
        │ miss
        ▼
national significant number of the dialled number
        │
        ▼
match a contact whose stored number ENDS WITH it
```

The second step exists for one concrete case, and it is worth stating because it
is what constrains every change here. A local phonebook entry is saved as
`0507259336`. The PBX puts the call through with the country code, so the record
comes back as `+380507259336`. Nothing about those two strings is equal, and the
person is the same.

`String.nationalPhoneIfValid` (`lib/utils/string_phone_utils.dart`) supplies the
step in the middle. It answers only for a number that parses as a valid full
number, so a short extension or a malformed string skips the fallback entirely
rather than matching something by accident.

## The pieces

| Piece | Where | What it is |
|---|---|---|
| `_phoneIs` | `packages/data/app_database/lib/src/daos/contacts_dao.dart:65` | The stored number is this number |
| `_phoneEndsWith` | `contacts_dao.dart:74` | The stored number ends with this number |
| `_winningContactId` | `contacts_dao.dart:83` | Which single contact a predicate resolves to |
| `_selectWinningContact` | `contacts_dao.dart:93` | That contact's full data |
| `sourcePriorityOrder` | `packages/data/app_database/lib/src/daos/contact_source_priority.dart` | Who wins when a number is shared: the PBX entry, not the device one |
| `ContactsRepository.watchContactByPhoneNumber` | `lib/repositories/contacts/contacts_repository.dart:207` | The two steps, in order |

The four public lookups differ only in the predicate they hand to one rule:

```dart
Future<FullContactData?> getContactByPhoneNumber(String number) =>
    _selectWinningContact(_phoneIs(number)).get().then(_gatherSingleContact);

Future<FullContactData?> getContactByPhoneMatchedEnding(String number) =>
    _selectWinningContact(_phoneEndsWith(number)).get().then(_gatherSingleContact);
```

That is deliberate. The rule for who wins on a collision, and where the limit
sits, is written once. It used to be written twice, and the two copies drifted -
see the second invariant.

## Invariant 1: the limit is on the contact, never on the rows

```dart
BaseSelectStatement _winningContactId(Expression<bool> phoneMatch) => selectOnly(contactsTable)
  ..addColumns([contactsTable.id])
  ..join([innerJoin(contactPhonesTable, contactPhonesTable.contactId.equalsExp(contactsTable.id))])
  ..where(phoneMatch)
  ..orderBy(contactsTable.sourcePriorityOrder())
  ..limit(1);
```

The outer query joins phones, emails, favorites, presence and dialog info, so it
yields one row per combination. SQL `LIMIT` counts rows. Put it on the outer
query and you do not get one contact - you get one ROW of a contact, and
`_gatherSingleContact` builds the phone and email lists out of exactly those
rows. The contact arrives with a single phone and a single email, and a screen
that asks "can I text this person" gets the wrong answer.

There is a second, sharper reason the limit cannot simply be deleted.
`_gatherSingleContact` (`contacts_dao.dart:96`) takes the contact from
`rows.first` and then appends every phone and email it sees, without checking
which contact the row belongs to. Without the subquery narrowing the result to
one id, a predicate matching two people would hand back one person carrying the
other's numbers. The limit is not a performance detail; it is what makes the
gathering correct.

This was a live defect. `#1424` fixed it for the exact lookups by introducing
this subquery and left the ending lookups on the old shape, twenty-five lines
below in the same file, where it stayed until WT-1818.

## Invariant 2: "ends with" is not a regular expression

```dart
Expression<bool> _phoneEndsWith(String number) =>
    contactPhonesTable.number.substr(-number.length).equals(number);
```

The obvious way to write this is a pattern, and the obvious pattern is wrong in
a way that does not look wrong. drift evaluates SQL `REGEXP` as
`RegExp(pattern).hasMatch(value)` - a SEARCH, not a comparison. So `'.*X'` does
not mean "anything, then X at the end". It means "X appears somewhere", and the
leading `.*` contributes nothing at all.

That is how a company main number came to be displayed with an employee's name
(WT-1818, reported as PortaOne-32807). Under a `<main number> + <extension>`
numbering plan every employee's number contains the main number as a PREFIX, so
calling the main number matched all of them and showed whichever sorted first.

Appending `$` does fix that case. It was not taken, because the line would still
only read correctly to someone who knows how the pattern is evaluated, and the
next person to touch it would be in the same position as the last one.
`substr(-N).equals(...)` says what it does with no hidden semantics, needs no
metacharacter escaping, and cannot be read two ways.

Escaping is still needed where a pattern genuinely belongs - the contacts search
box (`watchAllContacts`), where "contains" is the intended meaning.

## The callers

| Caller | Method | NSN fallback |
|---|---|---|
| CDR history rows (`ContactInfoBuilder`) | `watchContactByPhoneNumber` | yes |
| Call screen (`DefaultContactResolver`) | `getContactByPhoneNumber` | no |
| Incoming push (`bootstrap.dart`) | `getContactByPhoneNumber` | no |
| Voicemail, call log bloc | `getContactByPhoneNumber` | no |
| Local recents list | neither - `recents_dao.dart` joins on exact equality | no |

The `get` and `watch` variants do not agree, and that is a known gap rather than
a decision: the same number can carry a name in the history and none on the call
screen. Do not add a caller that depends on the difference.

## Deliberate limits

**This is not a phone-number comparison.** An ending match is a heuristic. The
country code is discarded before the fallback, so a stored `+48507259336` can
answer a query for `+380507259336`: the ending is the same and the PBX entry
outranks the local one. libphonenumber already encodes the right rule, and
`String.comparePhoneNSN` (`lib/utils/string_phone_utils.dart`) already wraps it -
it has no callers. Moving the comparison there means SQL becomes a coarse
prefilter and the decision happens in Dart, which is a change of shape, not a
line.

**The lookup does not manage the lifetime of what it returns.** A caller that
keeps a result has to notice when it stops being true. `ContactInfoBuilder`
currently holds a static cache, ignores a `null` from its own stream and does not
resubscribe when its source changes, so a deleted or renumbered contact can stay
on screen. That is the widget's problem to fix, not this lookup's.

## Testing notes

- `packages/data/app_database/test/contacts_dao_test.dart` covers the predicate:
  an ending that is not at the end, an ending longer than the stored number, a
  whole number as its own ending, non-digit characters, and the reported
  scenario with two extension holders.
- `test/repository/contact_lookup_by_number_test.dart` covers the CHAIN - exact
  miss, NSN derivation, ending lookup. The DAO tests pass even if the NSN step
  is broken, which is why this one exists.
- When changing anything here, check both directions: revert your change and
  confirm a test goes red. Both invariants above have a test that fails when
  only that half is undone.
