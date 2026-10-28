# Call history

How the app reaches call records the backend does not volunteer, and what each
piece of the history path is responsible for.

Last reviewed: 2026-10-28.

The screens and their refresh behaviour are in
[`../architecture/data_refresh.md`](../architecture/data_refresh.md); this doc is about where the records
come from.

## The contract

`GET /user/history` takes `time_from`, `time_to`, `page` and `items_per_page`.
Core forwards all four to the adapter and answers with `items` plus a
`pagination` object whose `items_total` counts the FILTERED result set - the
range asked for, not the archive.

How the range is honoured is the adapter's business. The PortaSwitch adapter
uses a range given in full as it stands, however wide, and fills in only what
the client left out: `time_to` defaults to now and `time_from` to
`PORTASWITCH_CALL_HISTORY_DEFAULT_WINDOW_HOURS` (24) before it. That default
exists because an unbounded query made PortaBilling scan every CDR partition
twice per page view and took a customer's web services down.

Two consequences the app is built around:

- a request that names no range answers about recent history alone, so anything
  older is reachable only by naming the range it lives in;
- a range the client asks for is served exactly as asked, including a
  catastrophically wide one. Reaching further back is the client's business;
  doing it in bounded steps is the client's responsibility.

## The slice rule

`HistoryWindows` (`lib/services/history_windows.dart`) turns a cursor into
successive bounded ranges going back in time, widening as they go: at the
shipped widths a whole year is seven slices. How that sequence is built, who
moves the cursor and what to look for in a log is one page of its own,
[`../architecture/history_paging.md`](../architecture/history_paging.md); what follows here is only what a
deployment chooses.

| Knob | Default | What it sets |
|---|---|---|
| `WEBTRIT_APP_CDRS_HISTORY_FIRST_WINDOW_DAYS` | 7 | width of the slice next to the cursor |
| `WEBTRIT_APP_CDRS_HISTORY_MAX_WINDOW_DAYS` | 90 | ceiling the width doubles up to |
| `WEBTRIT_APP_CDRS_HISTORY_HORIZON_DAYS` | 365 | how far back the walk may reach; **0 switches the walk off** and the app asks the single rangeless question it asked before |

All three are build-time defines: a rebuild, not a code change, is what flips
them. `configuredCdrsHistoryWindows()`
(`lib/features/cdrs/services/cdrs_history_windows.dart`) reads them in one
place, because the sync worker and the lists have to walk the same archive the
same way.

## The five fetch paths

| Path | Code | What it asks for |
|---|---|---|
| Incremental sync | `cdrs_sync_worker.dart` `_refreshIncrementalHistory` | `time_from` = newest local record, every page to now; when the newest local record is not on those pages, its connect-to-disconnect range +/- `clearCheckMargin` (1 min) to see whether the history was cleared |
| First fill of an empty store | `_refreshInitialHistory` | slices back from now, stopping at the first that holds records; stores that newest page |
| Empty store after the first walk | `_refreshRecentHistory` | the most recent slice only - nothing to be incremental from, but no reason to re-walk the archive every five minutes |
| Scrolling to the bottom | `CdrsListCubit.fetchHistory` -> `CdrsHistoryWalk` | the next local page, then slices back from the watermark until this list has a page worth of records or the horizon ends it |
| A list that opens short | `CdrsListCubit.init`, `resolveInitialLoad` | the same walk, without waiting to be scrolled - a list shorter than the screen has no scroll extent, so its pagination listener never fires and the user has no way to ask for more |

How a slice is paged through, when the walk stops inside one and where it picks
up again is [`../architecture/history_paging.md`](../architecture/history_paging.md). What matters here is
what the list counts: records it GAINED, not records the page held, so a record
already on screen cannot stop the walk a row short of a scrollable list.

Everything a slice returns is persisted, matching this list or not: the request
is paid for once and the cache keeps all of it. That is what lets the Missed and
per-number lists filter locally on records nobody asked them about.

## A cleared history

"Clear call history" is an entry of the recents actions menu (`RecentsActions`),
opened from a floating button at the corner of the list (`RecentsActionsFab`,
id `recentsActions`; the entry is `recentsClearHistoryAction`). It is kept out
of the header on purpose: a destructive control there is where a press meant for
something else lands. The entry can be picked while the full list holds
anything, on either tab: the Missed calls are part of the history. After a dangerous confirmation
`CdrsHistoryClearCubit` asks the backend, lets a sync cycle already running end
(what it fetched before the clear would otherwise land after the drop), replaces
the local store with nothing (`replaceAfterClear`: synced, walked to the
beginning, so nobody asks for the hidden archive) and runs one more sync;
a backend without the route (`EndpointNotSupportedException`) and a failed
request each get a snack bar of their own and keep the local copy.

Where the recents tab shows the local call log instead (no call history on the
backend), the same action clears that log on this device only: `RecentsCleared`
deletes every call log entry, also those older than the 14 days the list shows,
and the confirmation says "on this device".

`POST /user/history/clear` deletes nothing on the switch. Core remembers when the
user cleared the history, per user and not per device, and from then on
`GET /user/history` returns no record that connected earlier, whatever range is
asked for. Nothing tells a client that a clear happened, so the incremental sync
finds out for itself: the newest stored record is still returned while the
history is intact. It is usually on the incremental pages already; when it is
not, the cycle asks for the range from its connect time to its disconnect time,
a minute either side: a backend may filter on either, and PortaSwitch filters on
the time a call was billed, which the record does not carry (on testenv-domain-12
it falls within a second of the connect time). When it does not come back, the history was cleared - here or on any
other device of the account - and the cycle replaces the local store, in one
transaction, with what the incremental pages held: the calls made after the
clear. The check has a request of its own because the pages may stop early (a
backend may serve fewer per page than asked), and a record missing for that
reason must not cost the whole history. The replace keeps the store synced; the
walk watermark goes only when the clear is inferred, so a wrong guess makes the
lists walk the archive again rather than lose it. A clear made on this device
moves the watermark to the beginning, since the backend hides everything older.
The lists drop what they hold on `CdrRecordsWiped` and are released by
`CdrsInitialSyncCompleted`. When the local drop fails after the backend cleared,
the screen still says cleared: the next cycle drops the copy, and asking the
backend again would clear the calls made in between.

## Traps

- `from`/`to` mean opposite things either side of the repository boundary, which
  is why they are not called that any more: `timeFrom`/`timeTo` are range bounds
  on the wire (`api_client.dart`, `cdrs_remote_repository.dart`), while
  `olderThan`/`newerThan` are the watermarks of a descending local list
  (`cdrs_local_repository.dart`, `cdrs_dao.dart`).
- `pagination` is optional. Whether it is filled in at all is the adapter's
  business, so `itemsTotal` is nullable, and without it only an empty page can
  end a slice - a short one proves nothing, because a backend may serve fewer
  per page than asked.
- A wide range is a cost on the switch, not on the app. Widening a slice is a
  deployment decision, which is why the widths are knobs rather than constants.

## Tests

| What | Where |
|---|---|
| The slice rule itself | `test/services/history_windows_test.dart` |
| The lists against a backend with a default window | `test/features/cdrs/cdrs_history_walk_test.dart` |
| The sync cycles, a clear seen from another device | `test/features/cdrs/cdrs_sync_worker_test.dart` |
| Clearing from this device | `test/features/cdrs/cdrs_history_clear_cubit_test.dart`, `test/features/recents/recents_actions_semantics_test.dart` |
| Clearing the local call log | `test/features/recents/recents_bloc_test.dart`, `packages/data/app_database/test/recents_dao_test.dart` |
| The watermark itself | `packages/data/app_database/test/cdrs_dao_test.dart`, `test/migrations_test.dart` |
| Range and pagination on the wire | `packages/api/test/api_client_cdr_history_test.dart`, `test/repository/cdrs_remote_repository_test.dart` |
| On a device against the local stand | `patrol_test/cdr_history_walk_e2e_test.dart` |
