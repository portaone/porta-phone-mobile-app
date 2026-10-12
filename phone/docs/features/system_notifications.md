# System notifications

Announcements the operator sends to the app: a list, an unread badge, and a
local push when one arrives. This page is about how that data moves - what
keeps it up to date, and what happens the moment the user touches it.

Last reviewed: 2026-10-12.

The scheduler these workers run on is documented in
[`../polling.md`](../polling.md); the worker/owner pattern itself in
[`../polling_workers.md`](../polling_workers.md). This page covers only what is
specific to the feature.

## The two directions

The feature has two halves, and they are separate polling tasks on purpose:

| Direction | Worker | Owner | One cycle |
|---|---|---|---|
| server -> device | `SystemNotificationsSyncWorker` | `SystemNotificationsSync` | fetch the initial history, or every update since the local anchor and then the top of the history, to drop what was deleted elsewhere |
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

A notification deleted on another device, or by the backend's retention
cleaner, is reported nowhere: the backend deletes the row outright, and
`getUpdates` lists only rows that exist. The store learns of it by reading a
page of the history again and comparing (`SystemNotificationsReconciler`):
whatever the store holds inside the window of that page, and the page does not
list, is gone, and is dropped the way any delete is - with its outbox entries,
its local push and a remove event for the list.

| Stretch | When | How far down |
|---|---|---|
| the top of the history | at the end of every sync cycle of updates | the newest page, and on below it while an unseen notification is stored further down - the unseen badge is counted from the whole store |
| what the screen has just shown from the store | after it is shown | to the oldest row shown, which may lie below the next backend page: the store is not always contiguous |

Both are best effort. A history request that fails is logged and tried again
with the next cycle or the next scroll; in the sync it does not fail the cycle,
whose updates are already stored. A pass reads at most five pages
(`SystemNotificationsReconciler.maxPages`), so a row stored far down the
history cannot turn it into a crawl.

One pass, step by step (`SystemNotificationsReconciler`):

```
1. snapshot  = ids the store holds now, without those whose delete is queued
               (an empty snapshot ends it here: nothing to compare)
2. upper     = none for the top of the history, or the moment the stretch
               starts below
3. page      = GET /user/notifications?created_before=<upper>&limit=<limit>
4. lower     = created_at of the oldest notification in the page,
               or none when the page is shorter than <limit>
5. gone      = snapshot ids created strictly after lower and strictly
               before upper that the page does not list
6. delete gone from the store, with their outbox entries; announce each
7. deep enough - the page was short, or lower is older than the depth asked
               for - then stop; else upper = lower and back to 3
```

With a limit of 3, a store holding 10, 9, 8, 7, 6 (by creation time, newest
first) and a backend that has lost 9:

| Request | Page | Window | Dropped |
|---|---|---|---|
| newest | 10, 8, 7 (full) | newer than 7 | 9 |

Had the backend lost 7 instead, the newest page would be 10, 9, 8, vouching
only for what is newer than 8: 7 is outside it. If 7 is unseen, the same pass
reads on - the page below 8 is 6, short, and 7 goes. If it is seen, it stays
until the screen shows it and compares that stretch.

A short page is taken for the end of the history. That rests on the backend
returning as many notifications as were asked for whenever it has them, which
Core does - it applies the limit it is given and has no ceiling of its own. A
backend that capped the page would make every page look like the last, and
everything below it would be dropped; `system_notifications_reconciler_test.dart`
pins the assumption.

Two limits keep the comparison honest (`SystemNotificationsDao.deleteMissingFromPage`):

- **The window.** A page is cut by a limit, so it vouches only for what is
  newer than its oldest notification - not for that instant itself, where
  another notification may not have fitted - and, for an older page, older
  than the moment it was asked below. A page shorter than its limit reached
  the end of the history and speaks for everything older too.
- **The snapshot.** Only what the store held before the page was asked for is
  judged. A notification that arrives while the request is out is not in the
  page either, and is left alone. One whose delete is queued is not in the
  snapshot: the outbox settles it.

A first load reconciles nothing - it has just read that page - and the
Workmanager task never does: a delete made elsewhere is noticed only while the
app is open. What the phone has never read from the backend is not compared.

A reconciliation can empty the store - everything it held was deleted on
another device. That is not a first load either: the sync worker remembers the
anchor it found in the store, not only the updates it stored itself, and goes
on reading updates from there.

## Two properties of the sync cycle

Both follow from the shape of the endpoints rather than from the pattern.

**One branch per cycle.** With no local anchor the cycle fetches the initial
history; with one, it drains updates since that anchor and then reconciles
the top of the history (see "Deleted elsewhere"). Never the
initial history and the updates both, so a first load after a wipe stays one
bounded request.

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
| `lib/features/system_notifications/services/system_notifications_reconciler.dart` | drops what a history page shows to be deleted elsewhere |
| `lib/features/system_notifications/services/system_notifications_push_service.dart` | local push from a stored notification |
| `lib/features/system_notifications/services/system_notifications_background_worker.dart` | Workmanager sync outside the app |
| `lib/features/system_notifications/widgets/system_notifications_shell.dart` | starts the push service and the background task |
| `lib/features/system_notifications/cubit/` | screen and badge cubits; the screen cubit also deletes |
| `lib/features/system_notifications/widgets/system_notifications_delete_all_action.dart` | the header's delete-all action |
| `lib/repositories/system_notifications/` | local (Drift) and remote (API) repositories |

Tests: `test/features/system_notifications/` - a worker suite per direction, a
push suite, and ten component scenarios shared between the host and Patrol
(`patrol_test/system_notifications_sync_test.dart`) over a real Drift store. The
registrations themselves are asserted in
`test/app/router/main_shell_polling_config_test.dart`.
