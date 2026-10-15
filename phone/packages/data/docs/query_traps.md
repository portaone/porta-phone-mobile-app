# Drift query traps

Mistakes in a Drift query that still return the right rows and keep the tests green. Each was
found on the contacts queries in `app_database/lib/src/daos/contacts_dao.dart`; the search rule
they serve is described in [contact_search.md](../app_database/docs/contact_search.md), the
lookup by number in [contact_lookup_by_number.md](../app_database/docs/contact_lookup_by_number.md).
Last reviewed: 2026-10-15.

## Condition on joined rows instead of the entity

- What you do: put `where` or `limit` on the query "contact joined with its phones and emails".
- What happens: the contact comes back with only the phones and emails of the rows that passed.
  A contact found by one of its two numbers arrives with one number; `limit(1)` returns a
  contact with one phone and one email.
- Why: the joined query has one row per phone and email of a contact, and `where` and `LIMIT`
  act on rows.
- Instead: choose the entity by its id first, then join the details. `ContactsDao._carries`
  asks "the contact id is among the owners of a matching number"
  (`contactsTable.id.isInQuery(...)`), and `_winningContactId` puts the `limit(1)` on a
  `selectOnly(contactsTable)` subquery, never on the outer joined query.

## Correlated subquery over an unindexed column

- What you do: `EXISTS (SELECT ... FROM contact_phones WHERE contact_id = contacts.id AND ...)`.
- What happens: correct results, quadratic cost. On an in-memory database with 5000 contacts one
  search took six to seven times as long as reading the whole list; with 20 000 it did not
  finish in minutes. The package tests stayed green.
- Why: a subquery that names the outer query runs again for every outer row, and neither
  `contact_phones.contact_id` nor `contact_emails.contact_id` has an index of its own (the
  `UNIQUE(number, label, contact_id)` constraint does not lead with it), so each run reads the
  whole table.
- Instead: leave the subquery free of the outer query - `contacts.id IN (SELECT contact_id FROM
  contact_phones WHERE ...)` - so SQLite works it out once. Only a measurement on thousands of
  rows shows the difference.

## Cached stream in a benchmark

- What you do: measure by calling `watch(...).first` N times with the same query.
- What happens: the first call runs the query; the rest return almost instantly, and the
  benchmark reports numbers that do not exist.
- Why: Drift's `StreamQueryStore` keeps one stream per SQL text and arguments, and a stream
  whose last listener left is dropped only on the next event-loop turn (`Timer.run`), so a
  back-to-back call gets the cached result.
- Instead: give every run a query not asked before (another spelling of the same word: `yev`,
  `Yev`, `yEv`) and change one row of the table before it, so any stream is invalidated.

## `REGEXP` and ASCII-only case folding

- `column.regexp(pattern)` runs Dart `RegExp(pattern).hasMatch(value)` for every row (drift
  registers `regexp` as a Dart function on the connection). `hasMatch` searches, so a pattern
  without anchors means "contains". Text the user typed goes through `RegExp.escape`
  (`ContactSearchWord`). For "ends with", `ContactsDao._phoneEndsWith` compares a `substr`
  instead of using a pattern.
- SQLite's built-in `lower()`, `upper()`, `instr()` and `LIKE` fold letter case for ASCII only.
  A case-insensitive match or a word position in Cyrillic cannot be computed with them. That is
  why the contacts search filters in SQL through `REGEXP` and computes the order in Dart
  (`ContactSearch.rank`) over the rows already selected.
- When one rule lives on both sides, both read it from one definition
  (`ContactSearchWord.pattern`) and a test asks both sides about the same queries
  (`test/contacts_dao_search_test.dart`).

## Contacts query cost on a phone

On a low-end Android Go phone (release build), reading the contacts list and assembling it from
the joined rows took about 160 ms for 1000 contacts, 0.8 s for 5000 and 3.3 s for 20 000.
Checking the words is cheap next to that. So filtering in memory after reading the whole list
was slower than the implementation it was meant to replace, while filtering in SQL before the
join was 1.8 to 5 times faster than it. Reduce the rows that are read; do not optimise the matching.

## Benchmark app for the data package

The data package cannot run on a phone on its own. A throwaway app can:

1. In `phone/packages/`, run `fvm flutter create --platforms android --org com.example -t app
   --no-pub <name>`. In its `pubspec.yaml` set `resolution: workspace` and depend on
   `app_database: any`; add `- packages/<name>` to `workspace:` in `phone/pubspec.yaml`. It then
   builds with the same dependency versions as the app.
2. `fvm flutter build apk --release --target-platform android-arm64`. Its own package id keeps
   the installed app untouched.
3. Read the result from the screen (`adb exec-out screencap -p > result.png`): in that run the
   `print` output of the release build never reached logcat.
4. Afterwards `adb uninstall` it, delete the folder and restore `phone/pubspec.yaml`.

To compare two implementations, build the app twice, once on each commit.
