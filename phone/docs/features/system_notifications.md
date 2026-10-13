# System notifications

Announcements the operator sends to the app: a list, an unread badge, and a
local push when one arrives. This page is about how that data moves - what
keeps it up to date, and what happens the moment the user touches it.

Last reviewed: 2026-10-09.

The scheduler these workers run on is documented in
[`../polling.md`](../polling.md); the worker/owner pattern itself in
[`../polling_workers.md`](../polling_workers.md). This page covers only what is
specific to the feature.

## The two directions

The feature has two halves, and they are separate polling tasks on purpose:

| Direction | Worker | Owner | One cycle |
|---|---|---|---|
| server -> device | `SystemNotificationsSyncWorker` | `SystemNotificationsSync` | fetch the initial history, or every update since the local anchor |
| device -> server | `SystemNotificationsOutboxWorker` | `SystemNotificationsOutbox` | send every queued delete, then every queued read receipt |

Both live in `lib/features/system_notifications/services/`, both are registered
in `lib/app/router/main_shell_services.dart` behind the same gate
(`featureAccess.systemNotificationsConfig.systemNotificationsSupport`), and a
deployment without the feature registers neither.

Two other pieces are not polling tasks and are unaffected by any of this:
`SystemNotificationsPushService` (turns a stored notification into a local
push) and `SystemNotificationBackgroundWorker` (a Workmanager task that syncs
while the app is not running). Both are started by `SystemNotificationsShell`,
once, when it mounts: `MainShell` pins one `FeatureAccess` snapshot for the
whole session, so the flags the shell reads cannot change while it is up.

## PollingService responsibilities

Neither worker owns a timer, a connectivity check, or a retry policy. That is
the point of the pattern: a worker knows how to do the work once and how to
report whether it succeeded, and `PollingService` decides when. The feature
gets all of the following without implementing any of it.

- **Nothing runs in the background.** Both tasks stop when the app is not in
  the foreground and resume with a leading refresh.
- **Nothing runs offline.** A cycle starts only once a reachability check
  passes, and that answer is shared and cached
  (`WEBTRIT_APP_POLLING_REACHABILITY_TTL_SECONDS`, 30 s) rather than probed per
  task.
- **A failing backend is backed off.** A cycle that throws moves the task to
  `PollingTaskPhase.failed` and delays the next attempt - 600 s, then 900 s,
  then every 900 s (`WEBTRIT_APP_POLLING_MAX_BACKOFF_SECONDS`). A success
  resets it.
- **Devices do not sync in lockstep.** Every delay carries up to 10 percent of
  random jitter.
- **Reconnecting and returning to the app refresh both tasks**, subject to a
  freshness gate so a flapping network does not re-run everything.

Intervals:

| Task | Default | Key |
|---|---:|---|
| sync | 10 s | `WEBTRIT_APP_SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS` |
| outbox | 300 s | `WEBTRIT_APP_SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS` |

The outbox interval is long because the interval is not how receipts are
normally sent - see the next section.

## On-demand flush

Reading a notification is the one thing here the scheduler cannot predict, and
it is handled the way every on-demand refresh in this app is handled: not by
calling the backend from the screen, but by asking the task that already owns
that work.

```
user taps a notification
  -> SystemNotificationsScreenCubit.markAsSeen()
     1. writes an outbox row (pending) to SQLite      <- durable, offline-safe
     2. SystemNotificationsOutbox.requestFlush()      <- asks the task to run
  -> the task runs one cycle and sends the queue
  -> the server later reports the notification as seen
  -> the sync worker brings that back, and the row is deleted
```

The order matters and is tested: the row is written *before* the send is asked
for, so the receipt survives a failed send, a lost connection, and the app
being killed. Asking for the send is an optimisation on top of a fact that is
already on disk.

`requestFlush()` is `invalidatePollingTask()` underneath, the same mechanism
behind `CdrsSync.requestPostCallRefresh()`. Three of its properties are
deliberate.

- **It is debounced by one second.** Reading through a screenful of
  notifications is one cycle, not one per tap: `PollingService` cancels and
  restarts the pending invalidation, so a burst collapses onto its trailing
  edge.
- **It may jump the queue, but not past a refusing backend.** A flush normally
  runs the cycle even though the next scheduled run is minutes away - that is
  what it is for. But a cycle attempts *the whole queue*, so once sends are
  failing, one flush per tap would be one request per tap per queued entry at a
  backend that is already failing. A flush requested while the task is
  `PollingTaskPhase.failed` is therefore dropped; the retry the task has
  already scheduled is the right moment.
- **Being offline is not that case.** The task then reports
  `waitingForConnectivity`, the service defers the cycle without making a
  request at all, and the queue leaves on the leading refresh that reconnecting
  runs. Tapping while offline costs one local row and nothing else.

## Receipt retry policy

An outbox row is retried for as long as polling is willing to retry it. Nothing
counts attempts, and a failed send leaves its row untouched.

This replaced a five-attempt cap, and the reason is worth keeping. Attempts are
a meaningful budget only if something paces them. In the loop this feature used
to run, one attempt per second spent all five in about six seconds - a lift ride
was enough to abandon a receipt permanently, and `SnOutboxState.failed` is never
read again, so the notification stayed unread on the user's other devices
forever. A count is the wrong unit even with a slower loop, because a cycle can
be triggered by anything: a tap on an unrelated notification would spend the
attempts of an entry that is failing. Pacing and giving up belong to the
scheduler, which does both.

The queue is emptied by success instead. A row is deleted when the sync worker
brings its notification back with `seen` set - including when another device
sent the receipt. A receipt for a notification the backend has deleted counts as
sent (404 `notification_not_found`). The cost is that any other impossible send
is retried forever at the backoff ceiling; new receipts are unaffected, because
a cycle attempts every entry before it reports the failure.

## Deleting

A card is swiped away, or offered `Delete` as a screen reader action; the
header deletes everything at once after a question that carries the count.
Deleting goes the way reading does - through the outbox - with no undo:

```
user swipes a card (or confirms delete all)
  -> SystemNotificationsScreenCubit.deleteNotifications()
     1. writes a `delete` outbox row per stored id (pending)   <- durable, offline-safe
     2. SystemNotificationsOutbox.requestFlush()
  -> the cards leave the list and the unseen badge at once
  -> the outbox cycle sends every queued delete in one request
  -> the backend answers, and the rows go for good
```

The row stays in the store until the backend has answered, hidden: the outbox
row references it (`ON DELETE CASCADE`), so deleting it first would take the
queued delete with it. The list, the ids for delete all and the unseen count all
skip a row with a pending `delete` (`SystemNotificationsDao`), and a sync that
brings such a row back before the delete is confirmed stores it without an
event - it is not news, and the screen does not show it again.

| | |
|---|---|
| Request | `DELETE /user/notifications` `{"ids": [...]}` for every queued delete; a Core older than the bulk route (WT-1872) answers a bare 404, and the remote repository deletes one id at a time |
| Already gone on the backend | skipped there; every id sent goes on the device once the backend answers |
| Offline or refused | the delete waits in the outbox and is retried as a receipt is, the cards stay hidden; nothing is said, as nothing is said for a receipt |

"All" means every notification stored on this device
(`SystemNotificationsLocalRepository.getNotificationIds`), not the backend's
whole history: older notifications stay there. An emptied list has nothing
to scroll, and the sync worker keeps its own anchor so an emptied store is not
taken for a first load (which would read the history back at once and push
its unseen notifications as news); they come back, silently, the next time
the app starts with an empty store. The Workmanager task pushes nothing from
a load without an anchor for the same reason.

Deleting a row also deletes what the outbox holds for it, in the same
transaction (`SystemNotificationsDao.deleteNotifications`, which returns what it
removed so the events name exactly that). A cycle sends the deletes before the
receipts, so a receipt for a notification that is going is not sent at all; a
seen receipt for a notification the backend no longer has counts as sent, and
the outbox does not write a sent row back for a notification deleted while its
receipt was out. A deleted notification's local push is taken out of the shade.

## Deleted elsewhere

A notification deleted on another device, or by the backend's retention, leaves
this one too - by the same road a `seen` flag changed elsewhere arrives, the
updates of a sync cycle. The backend deletes softly, as it does chat messages:
the row stays for a while as a marker, without its text, and `getUpdates` lists
it with `deleted_at` set when asked to (`include_deleted=true`).

```
another device deletes a notification
  -> the next sync cycle: GET /user/notifications/updates?...&include_deleted=true
  -> the page carries it with deleted_at
  -> SystemNotificationsLocalRepository.upsertNotifications drops it:
     the row, what the outbox holds for it, its local push
  -> the card leaves the list and the unseen badge
```

Nothing deleted is ever stored, and there is no second request: the delete
costs what any other update costs, at any depth of the history. The Workmanager
task applies it the same way.

| | |
|---|---|
| The anchor | a deleted notification is read but not stored, so the store's newest `updated_at` does not reach it. The sync worker resumes from the newer of that and the newest update it has read; the Workmanager task, which has no memory between runs, drains every page each run instead of taking one |
| A backend that cannot report deletes | one older than 1.2.0 refuses the parameter as an unknown field (422, `include_deleted`), so it is not sent: `CoreInfo.supportsDeletedNotificationUpdates` reads the core version from the system info, and the remote repository is built with the answer - by the Workmanager task from the system info the app stored last. Deletes made elsewhere are then not heard of, as before, and the store is not read afresh by age |
| Many deleted at once | a bulk delete stamps one moment on every row, and the anchor moves by that moment. The backend therefore never splits notifications changed at the same instant between pages - a page can be longer than the limit asked for - so none is left behind the anchor |
| Away for too long | the backend reports a deleted notification for as long as its administrator keeps notifications (`NOTIFICATION_RETENTION` days), and names that in the system info as `core.notification_deleted_retention_days`; `0`, the default, is without limit. The sync records when it last brought the store up to date (`SystemNotificationsSyncJournal`). A store older than that time may hold notifications deleted since with nothing left to read about them, so the cycle reads the first page of the history again and drops the rest - quietly, as a first load, keeping the rows the outbox has yet to send something for. With no limit a store is never too old. No record at all counts as stale once, whatever the limit: that is a store filled before the app could hear of deletes |

## Two properties of the sync cycle

Both follow from the shape of the endpoints rather than from the pattern.

**One branch per cycle.** With no local anchor the cycle fetches the initial
history; with one, it drains updates since that anchor. Never both, so a first
load after a wipe stays one bounded request. A store that may be stale (see
"Deleted elsewhere") is a third branch: the first page again, in place of updates.

**The anchor advances by timestamp.** `getUpdates` pages by `since`, not by page
number. The anchor therefore moves to the newest record of each full page, and a
full page that cannot move it ends the cycle rather than being fetched forever;
the store now holds those records, so the next cycle resumes from its own
advanced anchor.

Separately, an absent anchor is what marks a load as history, which suppresses
one local push per record. A worker that counted "have I synced yet" in memory
would push a whole first load at the user whenever it was rebuilt, so the flag
is set only after a cycle completes - including an empty one, or the first
genuine notification on a new account would be silently swallowed.

## Layout

| Path | Contents |
|---|---|
| `lib/features/system_notifications/services/system_notifications_sync_worker.dart` | sync worker + owner |
| `lib/features/system_notifications/services/system_notifications_outbox_worker.dart` | outbox worker + owner |
| `lib/features/system_notifications/services/system_notifications_push_service.dart` | local push from a stored notification |
| `lib/features/system_notifications/services/system_notifications_background_worker.dart` | Workmanager sync outside the app |
| `lib/features/system_notifications/widgets/system_notifications_shell.dart` | starts the push service and the background task |
| `lib/features/system_notifications/cubit/` | screen and badge cubits; the screen cubit also deletes |
| `lib/features/system_notifications/widgets/system_notifications_delete_all_action.dart` | the header's delete-all action |
| `lib/repositories/system_notifications/` | local (Drift) and remote (API) repositories; the record of the last sync |

Tests: `test/features/system_notifications/` - a worker suite per direction, a
push suite, a suite for the Workmanager task, and eleven component scenarios shared between the host and Patrol
(`patrol_test/system_notifications_sync_test.dart`) over a real Drift store. The
registrations themselves are asserted in
`test/app/router/main_shell_polling_config_test.dart`.
