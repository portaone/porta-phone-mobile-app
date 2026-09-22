# Paging a history by date

How the app reaches records a history endpoint does not volunteer: what a slice
is, who moves the cursor, and what to look at when it misbehaves. The call
history is the only user of it today; nothing in the mechanism knows that.

Last reviewed: 2026-09-22.

The endpoint's own rules, and which CDR path asks for what, are in
[`features/call_history.md`](features/call_history.md).

## The shape of the problem

A history endpoint that is asked without a date range may answer about recent
history alone - the PortaSwitch adapter looks 24 hours back, because an
unbounded query made the switch scan every partition twice per page view. So
reaching an older record means naming the range it lives in, and the client
cannot name one wide range either: it would re-create exactly that cost.

Paging by page number does not help. `page` walks INSIDE a range; it cannot walk
past the range the backend chose for a request that named none.

So the app pages by DATE, in bounded steps, and the whole mechanism is three
things:

| Piece | Where | What it owns |
|---|---|---|
| `HistoryWindows` | `lib/services/history_windows.dart` | turns a cursor into the sequence of ranges to ask for |
| `cdr_history_walk` | `packages/data/app_database` (one row) | how far back the store has been asked, surviving screens and launches |
| `CdrsHistoryWalkQueue` | `lib/features/cdrs/services/` | one walk at a time over one store |

## A walk, step by step

Say it is 21 Sep 12:00, a page is 50 records, and the store holds twelve calls
from today, the oldest at 08:00. The user scrolls to the bottom.

```
local page          nothing older than 08:00 -> the store is exhausted
cursor              watermark ?? oldest stored record  = 21 Sep 08:00

  slice A   7 d    14 Sep 08:00 .. 21 Sep 08:00   empty   -> watermark = 14 Sep 08:00
  slice B  14 d    31 Aug 08:00 .. 14 Sep 08:01   empty   -> watermark = 31 Aug 08:00
  slice C  28 d     3 Aug 08:00 .. 31 Aug 08:01   8 recs  -> watermark =  3 Aug 08:00
  slice D  56 d     8 Jun 08:00 ..  3 Aug 08:01   50 recs -> a page is full, stop
                                                             watermark = oldest taken + 1 s
```

Four requests, and the two empty weeks cost one each rather than ending the
list. The next scroll starts with the local page - everything slices C and D
brought is in the store now - and only walks again when that runs out, from the
watermark, with the widths starting over at seven days.

Three properties make this work, and each is a defect that happened:

1. **The walk advances by the SLICE, not by what came back.** An empty answer
   moves the cursor exactly as far as a full one. Advancing by the oldest record
   received is what made older history unreachable in the first place: with
   nothing received, there was nothing to advance by, and the list declared the
   archive over.
2. **The cursor belongs to the store, not to a list.** Two lists share one
   archive and one cache; a per-list cursor had them walking the same slices
   side by side, and a re-opened screen re-walking days it had already walked.
   It only ever moves further back, and a wipe clears it with the records.
3. **Slices overlap by one backend tick.** A backend may read both bounds as
   exclusive, and a record stamped exactly on a boundary would then belong to no
   slice at all. A record returned twice only has to be recognised, which
   `mergeWithHistory` does by id - keeping the copy that arrived last, as the
   store does.

## Inside one slice

A slice can hold more records than a page. The walk pages through it with
`page`, and `CdrHistoryPage.hasMoreAfter` decides when to stop:

- the backend reported `items_total` for the range: ask until that many are
  taken;
- it reported nothing: any page holding records means "ask again", and only an
  empty page ends the slice. Comparing against the size that was ASKED for would
  be wrong - a backend may serve fewer per page than requested, and a short page
  is not evidence of the last one.

An empty page ends a slice whatever a total said, because a count can include
rows the endpoint never serialises. One walk may also spend only a bounded
number of pages in total, which is what stops a backend that ignores `page` and
hands the same page back forever.

## The end of a list

Only the horizon ends one. `historyEndReached` is set when the walk reaches the
slice that starts at `now - horizon`, never when an answer comes back empty. A
walk cut short any other way - the sanity bound on widths that defeat the
widening - keeps its watermark and carries on next time.

A horizon of zero switches the walk off: the app then asks the single rangeless
question it asked before this existed, advancing by the oldest record each page
returns.

## Reading a log

Every request the walk makes carries both bounds, so a capture reads as the walk
itself. A healthy one on a busy account:

```
time_from=2026-09-14T12:57:55 time_to=2026-09-21T12:57:55 page=1   7 d
time_from=2026-09-10T07:43:17 time_to=2026-09-17T07:43:17 page=1   resumed at a record
time_from=2026-08-27T07:43:17 time_to=2026-09-10T07:43:18 page=1  14 d
time_from=2026-08-27T07:43:17 time_to=2026-09-10T07:43:18 page=2   the slice held >50
...
time_from=2025-09-21T12:12:11 time_to=2025-12-10T07:43:18 page=1   clamped at the horizon
```

What to look for when it misbehaves:

| Symptom | What it means |
|---|---|
| a request with no `time_from` | the walk is off (horizon 0), or it is the sync cycle's incremental pass, which names a lower bound only |
| the same range twice in the same second | two walks are running at once - the queue is not shared between the lists |
| the same range and page again and again | the backend is ignoring `page`; the per-walk budget should cut it off |
| widths not doubling | each `fetchHistory` starts a fresh sequence at the first width; several narrow slices in a row are several gestures, not one |
| the list stops with records still on the server | check `historyEndReached` against the horizon, and the watermark: `cdr_history_walk` may already be at the floor |

Captures of all of this against a live environment are kept with the ticket, in
`agent/tasks/WT-1960/refs/` - before and after the queue, and a cold start.

## Tests

| What | Where |
|---|---|
| The slice sequence, widths, horizon, overlap | `test/services/history_windows_test.dart` |
| The walk against a backend with a default window | `test/features/cdrs/cdrs_history_walk_test.dart` |
| The watermark itself | `packages/data/app_database/test/cdrs_dao_test.dart` |
| On a device against the local stand | `patrol_test/cdr_history_walk_e2e_test.dart` |
