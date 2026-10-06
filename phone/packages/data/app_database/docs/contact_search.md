# Searching the contacts list

Which contacts a search keeps and in which order. Last reviewed: 2026-10-06.

The rule lives in this package, in `lib/src/daos/contact_search.dart`. Paths
below are relative to `phone/`.

## The rule

The text of the search field is split into words on spaces. Then, for every
contact of the list:

1. **Every word has to be found** in the contact - in the first name, the last
   name, the alias, any of its numbers or any of its emails. A second word
   narrows the list; it never widens it.
2. **Each word is placed** by the best place it was found in:

   | `ContactSearchMatch` | The word is |
   |---|---|
   | `nameStart` | at the start of the first name, the last name or the alias |
   | `nameWordStart` | at the start of a later word of a name: `Anna Maria`, `Petrenko-Kovalenko` |
   | `insideName` | somewhere inside a name |
   | `number` | in a phone number and in no name |
   | `email` | in an email address and nowhere else |

3. **A contact is as relevant as its weakest word.** `Yevhen Do` puts a contact
   named Yevhen Dovhopol at `nameStart` and a Yevhen whose email carries `do`
   at `email`.
4. **The list is ordered by that relevance.** Among contacts of one relevance
   the one carrying the word EARLIER in its name comes first; what is still
   equal keeps the order of the unsearched list - alphabetical by alias, else
   by name.

The position is counted in the line the name is read in: the first name opens
`first last`, the last name follows it, the alias is a line of its own. So for
`yev` both `Yevhen Dem` and `Andriy Yevtushenko` are `nameStart`, and Yevhen is
first because the word opens his line while it sits at 7 in Andriy's. With
several words the weakest word decides both: its place, and its position. When
several words share that weakest place, the latest of their positions counts.

A word is compared as typed, without regard to letter case, and is never read
as a pattern - `.*` finds a contact with `.*` in it and nothing else.

## Who does what

**The database keeps, Dart orders.** `ContactsDao.watchAllContacts` asks SQLite
for the contacts that carry every word, so the contacts a query does not find
are never read - on a slow phone reading the list is what a search costs.
`ContactSearch.rank` then orders the contacts that came back and drops nothing.

The order is not worked out in SQL because the position of a word needs
letter-case folding, and SQLite's `lower()` and `instr()` fold ASCII only.

**One definition of "contains".** Both sides read a word through
`ContactSearchWord.pattern` - the word escaped, matched in any letter case with
Dart's `RegExp`, which is also what SQL `REGEXP` runs here. So the database
cannot keep a contact the ranking is unable to place.

## Three things that constrain a change here

**The condition is on a contact, not on a row.** The list query joins phones
and emails, so it has one row per number and email of a contact. A condition
on those rows keeps only the rows that matched, and the contact comes back
without its other numbers. The search therefore chooses contacts first - names
directly, numbers and emails as "the contact id is among the owners of a
matching one" - and the rows are joined after. The same trap for a row LIMIT is
described in `contact_lookup_by_number.md`.

**The subqueries name nothing of the outer query.** Written as `EXISTS (...
WHERE contact_id = contacts.id)` the same condition is run again for every
contact, and `contact_id` has no index: for 5000 contacts a search then cost
six to seven times the reading of the whole list. Left free of the outer
query, each subquery is worked out once.

**An email match is not visible in the row.** The list row shows the name
alone, so a contact found by its email gives no reason for being listed. That
is why such a match is ranked last rather than dropped or mixed in.

## The pieces

| Piece | Where | What it is |
|---|---|---|
| `ContactsRepository.watchContacts` | `lib/repositories/contacts/contacts_repository.dart` | Splits the text into words |
| `ContactsDao.watchAllContacts` | `packages/data/app_database/lib/src/daos/contacts_dao.dart` | The alphabetical list; with words, only the contacts carrying all of them |
| `ContactsDao._carries` | same file | The condition "this contact carries the word" |
| `ContactSearchWord` | `packages/data/app_database/lib/src/daos/contact_search.dart` | A word and its pattern |
| `ContactSearch` | same file | The order |

## Tests

- `packages/data/app_database/test/contact_search_test.dart` - the order on its
  own: every place a word can be found, several words, positions.
- `packages/data/app_database/test/contacts_dao_search_test.dart` - the search
  through the DAO on a seeded database: the ticket's cases, a contact keeping
  all its numbers, and the database and the ranking asked about the same
  queries.
