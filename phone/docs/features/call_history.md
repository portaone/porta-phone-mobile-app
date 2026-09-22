# Call history

How the app reaches call records the backend does not volunteer, and what each
piece of the history path is responsible for.

Last reviewed: 2026-09-22.

The screens and their refresh behaviour are in
[`../data_refresh.md`](../data_refresh.md); this doc is about where the records
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
[`../history_paging.md`](../history_paging.md); what follows here is only what a
deployment chooses.

| Knob | Default | What it sets |
|---|---|---|
| `WEBTRIT_APP_CDRS_HISTORY_FIRST_WINDOW_HOURS` | 168 (7 days) | width of the slice next to the cursor |
| `WEBTRIT_APP_CDRS_HISTORY_MAX_WINDOW_HOURS` | 2160 (90 days) | ceiling the width doubles up to |
| `WEBTRIT_APP_CDRS_HISTORY_HORIZON_DAYS` | 365 | how far back the walk may reach; **0 switches the walk off** and the app asks the single rangeless question it asked before |

All three are build-time defines: a rebuild, not a code change, is what flips
them. `configuredCdrsHistoryWindows()`
(`lib/features/cdrs/services/cdrs_history_windows.dart`) reads them in one
place, because the sync worker and the lists have to walk the same archive the
same way.

## The five fetch paths

| Path | Code | What it asks for |
|---|---|---|
| Incremental sync | `cdrs_sync_worker.dart` `_refreshIncrementalHistory` | `time_from` = newest local record, every page to now |
| First fill of an empty store | `_refreshInitialHistory` | slices back from now, stopping at the first that holds records; stores that newest page |
| Empty store after the first walk | `_refreshRecentHistory` | the most recent slice only - nothing to be incremental from, but no reason to re-walk the archive every five minutes |
| Scrolling to the bottom | `CdrsListCubit.fetchHistory` -> `CdrsHistoryWalk` | the next local page, then slices back from the watermark until this list has a page worth of records or the horizon ends it |
| A list that opens short | `CdrsListCubit.init`, `resolveInitialLoad` | the same walk, without waiting to be scrolled - a list shorter than the screen has no scroll extent, so its pagination listener never fires and the user has no way to ask for more |

How a slice is paged through, when the walk stops inside one and where it picks
up again is [`../history_paging.md`](../history_paging.md). What matters here is
what the list counts: records it GAINED, not records the page held, so a record
already on screen cannot stop the walk a row short of a scrollable list.

Everything a slice returns is persisted, matching this list or not: the request
is paid for once and the cache keeps all of it. That is what lets the Missed and
per-number lists filter locally on records nobody asked them about.

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
| The sync cycles | `test/features/cdrs/cdrs_sync_worker_test.dart` |
| The watermark itself | `packages/data/app_database/test/cdrs_dao_test.dart`, `test/migrations_test.dart` |
| Range and pagination on the wire | `packages/api/test/api_client_cdr_history_test.dart`, `test/repository/cdrs_remote_repository_test.dart` |
| On a device against the local stand | `patrol_test/cdr_history_walk_e2e_test.dart` |
