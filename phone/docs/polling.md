# Background polling

`PollingService` coordinates periodic, lifecycle-triggered, and manual refreshes without overlapping work for the same registration.
Last reviewed: 2026-09-11.

## Scope and current status

This document describes the background polling contract implemented by:

- `lib/services/polling_service.dart`;
- `lib/services/polling_task_handle.dart`;
- `lib/services/polling_worker.dart`;
- `lib/services/connectivity_service.dart`;
- `lib/common/refreshable.dart`;
- `lib/utils/fixed_delay_scheduler.dart`;
- `lib/app/router/main_shell_services.dart`.

The service owns scheduling, connectivity checks, backoff, and task state. A
registered `Refreshable` owns one complete attempt and decides whether it is
still active. Feature orchestration that does not belong to one repository uses
the standard worker and owner structure in
[`polling_workers.md`](polling_workers.md). A consumer receives only the task
capability it needs instead of the ownership handle, another timer, or a
parallel call to the same work.

Most app registrations are still supplied through the `PollingService`
constructor because no consumer needs their handles. External Contacts, CDR and
User info use the worker pattern: their `*Sync` owners retain private
registrations and expose only narrow capabilities or domain methods.

UI pull-to-refresh behavior is a separate concern. See
[`data_refresh.md`](data_refresh.md) for the screens and gestures that expose it.

## Components and ownership

| Component | Responsibility | Lifetime |
|---|---|---|
| `Refreshable` | Provides `refresh()` and the permanent `isActive` opt-out | Repository-defined |
| `PollingWorker` | Defines one finite, disposable feature sync cycle | Owned by its feature owner |
| `PollingWorkerOwner<W>` | Owns a worker registration and exposes narrow task capabilities | Feature subtree |
| `PollingRegistration` | Binds one `Refreshable` instance to a base interval | Stored by `PollingService` |
| `PollingService` | Owns connectivity, lifecycle, scheduling, single-flight, and backoff | Main shell subtree |
| `PollingTaskStateSource` | Exposes read-only, replaying state for one registration | Valid until unregister or service disposal |
| `PollingTaskRunner` | Exposes manual execution without lifecycle control | Valid until unregister or service disposal |
| `PollingTaskHandle` | Combines consumer capabilities with owner-only invalidation and teardown | Valid until unregister or service disposal |
| `FixedDelayScheduler` | Arms the next tick after the current tick completes | One per registration |

`MainShellServices` creates and disposes `PollingService` through the same
provider. Individual handles do not dispose the service. A component may call
`handle.unregister()` only when it owns that registration. Other components
should receive `PollingTaskStateSource` or `PollingTaskRunner`, so they cannot
remove or invalidate a task owned by the composition root. See
[`dependency_ownership.md`](dependency_ownership.md) for the wider application
lifetime rules and [`polling_workers.md`](polling_workers.md) for the standard
feature ownership boundary.

## Core invariants

The contract has seven invariants:

1. One `Refreshable` object identity maps to one registration and one stable
   handle inside a service.
2. At most one refresh started through that registration is in flight.
3. Periodic execution uses fixed delay: the next delay starts after the current
   tick completes, not at a fixed wall-clock rate.
4. Connectivity and app lifecycle control automatic work. `runNow()` is an
   explicit caller request and does not perform a reachability preflight.
5. Only the newest OS connectivity event may publish its liveness result. A
   probe started by an older event cannot overwrite newer evidence.
6. Unregister and service disposal are terminal for a handle. Late completion
   of an already-running refresh cannot move it out of `stopped`.
7. Deferred invalidation uses trailing-edge debounce and preserves one refresh
   after work that started before the latest deadline.

The single-flight guarantee only covers calls routed through the same
`PollingService` registration. A direct call to `repository.refresh()`, a second
service, or a second repository instance bypasses it.

## Execution model

All supported triggers converge on one refresh-cycle runner. Automatic work
passes through foreground and reachability gates; an explicit manual request
does not:

```text
boot / reconnect / resume --+
periodic timer -------------+--> automatic eligibility --+
invalidation deadline ------+    (foreground + network)   |
                                                           +--> one task single-flight
manual runNow() -------------------------------------------+        |
                                                                    v
                                                         Refreshable.refresh()
                                                                    |
                                                                    v
                                                   state result + next schedule
```

Only the cycle runner invokes `Refreshable.refresh()`. It publishes state,
records the result, and completes the future shared by manual callers.

### Refresh completion contract

`Refreshable.refresh()` returns `Future<void>` because the scheduler needs two
outcomes, not a repository-specific result type:

| Domain outcome | `Future<void>` | Task phase | Automatic backoff |
|---|---|---|---|
| Required work completed, including persistence | Completes normally | `succeeded` | Reset |
| Domain policy proves remote work is not required | Completes normally | `succeeded` | Reset |
| Attempted work failed | Throws the original error and stack trace | `failed` | Incremented |
| `isActive == false` | `refresh()` is not called | `stopped` | Not applicable |

The `Refreshable` or `PollingWorker` owns the domain decision about whether the
cycle requires work. `PollingService` does not inspect repository data or infer
business success. It only maps normal completion or a thrown failure into task
state and scheduling policy.

Normal no-work completion is appropriate when the listener can prove that the
cycle has nothing to do, for example because a cached value is still fresh, a
successful conditional request returned not-modified, or there are no domain
changes to persist. It is not appropriate when an attempted request timed out,
returned a server error, lost its socket, or when persistence failed. Cached or
fallback data may still be usable after such a failure, but the attempt must
throw so polling can observe the backend health.

Logging, reporting to Crashlytics, or publishing an error to a feature stream
is additional reporting. It must not replace the thrown failure. A permanently
disabled task uses `isActive == false` or is not registered; temporary offline
state is owned by the service connectivity gate.

Success and deliberate no-work are intentionally indistinguishable to
`PollingService`: both reset backoff and publish `succeeded`. If a future policy
needs to schedule those outcomes differently, add an explicit result type then;
do not infer the distinction from logs, cache state, or exception classes.

### Trigger behavior

| Trigger | Reachability behavior | If a cycle is active | Failure behavior | Scheduling result |
|---|---|---|---|---|
| Boot or reconnect | Uses the connectivity result that caused the transition | Does not overlap it | Logged; increments automatic backoff | Arms the next periodic tick |
| Foreground resume | Performs one fresh check shared by all registrations | Does not overlap it | Logged; increments automatic backoff | Arms the next periodic tick |
| Periodic tick | Uses the TTL cache or performs a check | Joins the current cycle | Logged; increments automatic backoff | Computes the next fixed delay |
| `runNow()` | No service-level preflight | Joins the same future | Returned to the caller | Re-arms one full computed delay after completion |
| `invalidate()` deadline | Uses the TTL cache or performs a check | Waits for an older cycle, then runs once | Logged; increments automatic backoff | Re-arms from the invalidated cycle |

A group-leading cycle is used for boot, reconnect, resume, and adding a new
registration while polling is active. It performs at most one reachability
check, then offers a leading refresh to every current registration. Adding one
task can therefore refresh stale members of the existing group as well; fresh
members keep their existing periodic deadline.

### Leading refresh freshness

Before an automatic leading refresh, the service uses:

```text
minAge = min(task.interval, leadingRefreshMinAgeCap)
fresh = last completed cycle succeeded AND 0 <= now - lastSuccessAt < minAge
```

The age starts at successful completion, including domain-approved no-work.
Registration time does not establish freshness. The last completed outcome is
tracked separately from the transient `running` and `waitingForConnectivity`
phases, so a failure after success remains eligible even at equal timestamps.
A negative age after a clock rollback is treated as stale.

Boot, reconnect, resume, and group-leading after registration skip fresh tasks.
The check occurs after reachability verification, immediately before invocation.
Inactive tasks are unregistered, and an in-flight refresh is joined without
starting a duplicate. Tasks with no success or a latest failure remain eligible.
A due invalidation bypasses freshness and retains its trailing-cycle guarantee;
a deferred invalidation keeps its original deadline. `runNow()` and periodic
ticks bypass this gate entirely.

A skipped leading refresh preserves an active timer or re-arms a paused timer
for its remaining delay. The stored deadline includes the jitter already sampled
for that tick. A real refresh establishes a new deadline from completion, even
if it finishes while offline/backgrounded. An overdue deadline causes one
eligible attempt, without replaying missed ticks. Interval changes reset the
periodic deadline. Restoring connectivity for a fresh task restores its previous
completed state without fabricating a new success timestamp or resetting backoff.

With interval 10 seconds, cap 30 seconds, and zero jitter, successful refreshes
stay at 0, 10, 20, 30 seconds despite flaps every 6 seconds. The cap is a
suppression threshold, not a timer: reaching it does not trigger work by itself.
Repeated failures are not throttled by this gate; a long-interval task can still
refresh every cap seconds if reconnects keep arriving.

`MainShellServices` snapshots
`WEBTRIT_APP_POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS` when creating the service
and passes it as `PollingOptions.leadingRefreshMinAgeCap`. Both defaults are
30 seconds. Non-negative whole seconds are accepted; **0 disables the gate**.
Malformed or negative runtime overrides use the validated build value;
malformed or negative build values fall back to 30 seconds. Runtime override
changes affect newly created services only. Backoff and jitter do not enlarge
the freshness threshold.

Automatic triggers never create an overlapping refresh. `runNow()` has stronger
semantics: when a cycle already exists, it joins that cycle and returns its
result. The trigger that originally created the cycle owns its backoff policy.
For example, a manual caller that joins a failing scheduled cycle receives the
error, and that scheduled failure still increments backoff.

## Registration and stable handles

Low-level infrastructure can register a `Refreshable` with its base interval:

```dart
final task = pollingService.register(
  PollingRegistration(
    listener: repository,
    interval: const Duration(minutes: 5),
  ),
);
```

Registering the same listener instance again returns the same handle.

- Same listener and same interval: no scheduling change.
- Same listener and a different interval: the old schedule is invalidated and
  restarted without an extra leading refresh.
- Different listener instance: a separate task, even if it accesses the same
  endpoint.
- Registration after `PollingService.dispose()`: throws `StateError`.

Do not make an unrelated screen re-register a listener only to discover its
handle. Low-level code that creates a registration must keep the full handle at
that ownership boundary and pass only `PollingTaskStateSource`,
`PollingTaskRunner`, or a narrower application-specific capability to
consumers.

Feature workers use `PollingWorkerOwner` instead of retaining the handle by
hand:

```dart
final contactsWorker = ExternalContactsSyncWorker(
  userRepository: userRepository,
  externalContactsRepository: externalContactsRepository,
  contactsRepository: contactsRepository,
);
final contactsSync = ExternalContactsSync(
  worker: contactsWorker,
  pollingService: pollingService,
  interval: const Duration(minutes: 1),
);

final PollingTaskStateSource stateSource = contactsSync;
final PollingTaskRunner runner = contactsSync;
```

The owner registers the worker once, keeps the handle private, and owns both
unregister and worker disposal.

Constructor registrations are convenient when no consumer needs a handle:

```dart
final pollingService = PollingService(
  connectivityService: connectivityService,
  registrations: [
    PollingRegistration(
      listener: userRepository,
      interval: const Duration(seconds: 10),
    ),
  ],
);
```

They follow the same execution rules, but their handles are not exposed by the
constructor. Migrate a task to an explicit owner at the composition boundary
when another component needs on-demand control or state.

## Manual refresh

Use `runNow()` for an on-demand refresh of a registered task:

```dart
final PollingTaskRunner contactsRunner = contactsSync;

try {
  await contactsRunner.runNow();
} catch (error, stackTrace) {
  // Map the repository error to the owning feature's UI or domain state.
}
```

`runNow()` means "run or join now", not "always start a new request".

- Concurrent callers receive the same cycle result.
- A success resets the automatic consecutive-error count.
- A cycle started manually does not increment automatic backoff when it fails.
- A manual call that joins an automatic cycle keeps that cycle's automatic
  backoff semantics.
- After the joined or newly started cycle completes, the periodic timer is
  placed one full computed delay into the future.
- An inactive or unregistered task fails with `StateError`.

Because manual execution skips the service reachability preflight, the
repository remains the source of truth for request errors. This keeps explicit
user actions observable instead of silently turning them into noops when the
cached connectivity state is wrong.

## Deferred invalidation

Low-level task owners use `invalidate(after:)` when a domain event means that
cached data is stale, but the backend may need a short publication delay.
Feature owners expose that through a domain method:

```dart
cdrsSync.requestPostCallRefresh();
```

Invalidation is automatic work, not a manual request. It respects connectivity
and foreground lifecycle checks, and its failure contributes to scheduled
backoff. The call returns immediately; consumers that need the result observe
the handle state.

Repeated invalidations replace the deadline, giving trailing-edge debounce. A
refresh that starts before the deadline does not consume the invalidation: the
service waits for that cycle to finish and then performs one trailing refresh.
If the deadline passes while offline or in the background, the request remains
pending until reconnect or resume. A reconnect or resume leading cycle may
satisfy it, but it cannot run twice.

## Observable state

`PollingTaskStateSource.state` is available synchronously. `states` is
replaying, so a new subscriber immediately receives the current value,
including a connectivity wait that began before that subscriber existed.

| Phase | Meaning |
|---|---|
| `idle` | Registered but no refresh cycle has started |
| `waitingForConnectivity` | Automatic work is paused because the latest connectivity or reachability evidence is offline |
| `running` | One refresh cycle is in flight |
| `succeeded` | The latest cycle completed successfully |
| `failed` | The latest cycle failed; `error` and `stackTrace` describe it |
| `stopped` | The task was unregistered or its service was disposed |

The state also retains:

- `lastStartedAt`;
- `lastSuccessAt`;
- `lastFailureAt`.

A typical sequence is:

```text
idle -> waitingForConnectivity -> running -> succeeded -> running -> failed
                 ^                                             |
                 +---------------------------------------------+
                                                               |
                                                               +--> stopped
```

`stopped` is terminal. It is emitted once and then the state stream closes.
`isRegistered` becomes `false` immediately. If a repository request was already
running, its future still completes for existing callers, but its late result is
not published to the stopped handle.

`waitingForConnectivity` is not a failed refresh and does not increment
backoff. The phase is published when the service receives an offline transition
or an automatic reachability check says that work cannot run. An active cycle
stays `running` and publishes its own eventual result. A later reachable cycle
moves a waiting task through `running` as usual.

Do not infer data freshness from the phase alone. The repository remains the
owner of cached data; the timestamps describe polling attempts, not the age of
every record it exposes.

## Fixed delay, backoff, and jitter

The scheduler is fixed-delay rather than `Timer.periodic`:

```text
refresh starts -> refresh completes -> delay -> next refresh starts
```

This prevents a slow request from accumulating timer callbacks. The computed
delay is:

```text
effective cap = max(base interval, maxBackoff)
0 failures: base interval + jitter
1+ failures: min(base interval * 2 ^ failures, effective cap) + jitter
```

With a 5-second interval and zero jitter:

| Consecutive automatic failures | Next delay |
|---:|---:|
| 0 | 5 s |
| 1 | 10 s |
| 2 | 20 s |
| 3 | 40 s |

The application's default cap is 15 minutes (900 seconds), configured by
`WEBTRIT_APP_POLLING_MAX_BACKOFF_SECONDS`. The default jitter adds a random
non-negative delay below 10% of the computed delay after the cap is applied,
so the final delay can exceed the cap by up to roughly 10%. A successful cycle
resets the failure count. A manually started failure leaves the current
automatic count unchanged.

The base interval takes precedence when it equals or exceeds the configured
cap. For example, a 600-second base with a 300-second cap still waits 600 seconds
after a failure, rather than speeding up to 300 seconds. This floor prevents
faster retries; it does not create additional backoff headroom. To slow a task
below its normal cadence, configure a cap greater than its base interval.

Changing an interval, stopping timers, or manually resetting cadence increments
a schedule generation. Timer continuations that crossed an asynchronous
reachability check under an older generation cannot re-arm themselves. This is
the structural stale-tick guard. The leading-only freshness gate described above
additionally suppresses refreshes of recently successful tasks.

### Application cap configuration

`MainShellServices` reads `EnvironmentConfig.POLLING_MAX_BACKOFF_SECONDS` when
creating `PollingService` and supplies it through `PollingOptions.maxBackoff`.
The scheduler and `ExponentialBackoff` have no environment dependency.

Set the cap with a dart define, for example:

```text
--dart-define=WEBTRIT_APP_POLLING_MAX_BACKOFF_SECONDS=1800
```

The value is a positive integer in seconds. A missing, malformed or
non-positive build value falls back to 900. Runtime overrides applied through
`EnvironmentConfig.applyOverrides` take precedence; invalid overrides fall
back to the validated build value. Apply overrides before the shell creates
the service. Updating them later does not change its existing options or
reschedule active tasks; a newly created service reads the new value.

With the application default and zero jitter:

| Base interval | After 1 failure | After 2 failures | After more failures | After success |
|---:|---:|---:|---:|---:|
| 300 s | 600 s | 900 s | 900 s | 300 s |
| 600 s | 900 s | 900 s | 900 s | 600 s |
| 1200 s | 1200 s | 1200 s | 1200 s | 1200 s |

This leaves normal polling intervals unchanged and gives 300-second tasks
room to slow down during an outage. The tradeoff is a longer wait for the next
automatic attempt after backend recovery: up to the current capped delay,
plus jitter, unless a manual refresh, reconnect or foreground resume triggers
work sooner. A base interval above the cap still takes precedence.

The [configuration tests](../test/environment_config_test.dart) cover value
resolution and validation. The
[shell tests](../test/app/router/main_shell_polling_config_test.dart) exercise
actual service creation, default/overridden caps, creation-time snapshotting
and recovery. The
[scheduler tests](../test/services/polling_service_test.dart) verify exact
failure/recovery deadlines with zero jitter, while the
[backoff tests](../test/utils/backoff_retries_test.dart) cover the base floor
and explicit cap overrides.

## Connectivity and application lifecycle

`PollingService` listens to `ConnectivityService.connectionStream` and performs
an initial connectivity probe.

`ConnectivityService` may receive another OS event while the HTTP liveness
probe for the previous event is still in flight. It assigns a monotonically
increasing generation to every event and publishes a probe result only while
that generation is still current. Comparing only transport values is not
enough: `wifi -> none -> wifi` repeats the same value and would otherwise let
the first Wi-Fi probe publish after the second one. This latest-event-wins rule
is owned by the producer so every stream consumer receives ordered evidence.

- An offline transition cancels timers while retaining their periodic deadlines.
- An online transition starts a group-leading cycle.
- Repeated reports of the same connectivity state do not start another leading
  cycle.
- Reachability results are cached for `reachabilityTtl` and shared where
  possible.
- A reachability result from an older connectivity epoch cannot overwrite newer
  evidence.

With the default `pauseInBackground: true`, moving to the background cancels
automatic schedules. Resuming while connected performs a fresh shared
reachability check and starts a group-leading cycle. Neither an offline event nor
a background transition cancels a repository future that is already running;
the service only prevents new automatic work. Fresh tasks skip leading refresh
and resume their retained periodic deadline.

`runNow()` is independent of `_isConnected` and foreground state. The owner must
only expose it where an explicit refresh makes sense, and must handle the
repository error returned while the network is unavailable.

## Options

| Option | Default | Effect |
|---|---:|---|
| `pauseInBackground` | `true` | Stops automatic schedules outside the foreground |
| `verifyReachabilityOnTick` | `true` | Checks reachability before periodic work, subject to the TTL cache |
| `reachabilityTtl` | 30 s; app: `WEBTRIT_APP_POLLING_REACHABILITY_TTL_SECONDS` | Reuses recent reachability evidence |
| `leadingRefreshRequiresVerify` | `true` | Requires reachability before a group-leading refresh |
| `leadingRefreshMinAgeCap` | 30 s | Skips leading refresh after success for min(interval, cap); 0 disables |
| `jitterRatio` | `0.1`; app: `WEBTRIT_APP_POLLING_JITTER_PERCENT` / 100 | Adds a random non-negative delay below this fraction of the computed delay |
| `maxBackoff` | 5 min standalone; 15 min in the app | Caps exponential failure backoff without going below the base interval |

The table lists `PollingOptions` constructor defaults. The shell explicitly
overrides `maxBackoff`, `leadingRefreshMinAgeCap`, `reachabilityTtl` and `jitterRatio`
with application configuration (see `environment.md`); direct service construction
retains the constructor defaults.

Tests normally inject zero jitter and a deterministic backoff policy. Production
code should keep jitter unless synchronized backend load is desired and has been
measured.

## Inactive tasks, unregister, and disposal

`Refreshable.isActive` is a permanent opt-out, not a temporary loading or
connectivity flag. When it becomes `false`, the service unregisters the task on
the next automatic attempt. A manual call detects it immediately, unregisters
the task, and returns `StateError`.

Use `handle.unregister()` for a dynamically owned task. It:

1. removes the listener from the service;
2. invalidates and cancels its schedule;
3. publishes `stopped` and closes the state stream.

Disposing `PollingService` performs the same terminal transition for every
remaining handle and cancels its connectivity subscription. Service-level and
handle-side unregister calls ignore repeats. These operations do not cancel the
repository's own in-flight I/O; a repository that needs cancellation must own
that behavior itself.

## Current application registrations

`lib/app/router/main_shell_services.dart` is the composition root for current
polling tasks. Defaults come from `lib/environment_config.dart` and may be
overridden by the matching dart-define.

| Polling listener | Default interval | Condition |
|---|---:|---|
| `UserInfoSyncWorker` (via `UserInfoSync`) | 900 s | Always |
| `SystemInfoRepository` | 300 s | Always |
| `ExternalContactsSyncWorker` | 300 s / 1800 s | Core supports extensions; 1800 s when hybrid presence is on, 300 s when off (see [Contacts presence interval](#contacts-presence-interval)) |
| `CdrsSyncWorker` | 300 s | Call history is enabled for the session |
| `SystemNotificationsSyncWorker` (via `SystemNotificationsSync`) | 10 s | Core offers system notifications and the app configuration allows them |
| `SystemNotificationsOutboxWorker` (via `SystemNotificationsOutbox`) | 300 s | Same gate as the sync; the interval is a safety net, a read receipt asks for a send at once |
| `VoicemailRepository` | 300 s | Voicemail is available for the session |
| `CallQueuesRepository` | 10 s | ONLY while the call center screen is open - the page registers the task on mount and unregisters it on dispose, because every read reaches the PBX |
| `CallerIdSettingsRepository` | 300 s | Remote implementation is active |
| `FavoritesRepository` | 300 s | Syncable implementation is active |
| `SipSubscriptionsRepository` | 300 s | Syncable implementation is active |
| `IceServersRepository` | 300 s | Core supplies bundled ICE servers |

All environment interval values must be positive. A missing, invalid, or
non-positive runtime override falls back to its compile-time default.

### Refresh contract migration audit

This table tracks the current contract status of the registrations above.
The initial audit used `master` commit `0aee08a3c`; entries include subsequent
migrations, reviewed on 2026-09-10.
"Needs migration" means at least one path violates the completion contract:
it hides a failure as success, replaces the original error, or leaves a joined
refresh future incomplete. Recheck these paths when migrating each listener.

| Listener | Status | Current behavior |
|---|---|---|
| `UserInfoSyncWorker` | Conforms | Fetches, compares, and stores through `UserRepository.storeInfo()`, which persists before publishing; failures propagate with their original stack |
| `SystemInfoRepository` | Conforms | Awaits persistence before publishing; rethrows remote and cache-write failures |
| `ExternalContactsSyncWorker` | Conforms | Writes once per cycle and rethrows failures; polling owns the next attempt |
| `CdrsSyncWorker` | Conforms | Awaits the full sync cycle and rethrows |
| `SystemNotificationsSyncWorker` | Conforms | Awaits history or the drained updates and rethrows; keeps no cross-cycle state |
| `SystemNotificationsOutboxWorker` | Conforms | Attempts every queued entry, then rethrows the first failure with its original stack |
| `VoicemailRepository` | Conforms | Shares one fetch future; preserves original failures even when cache fallback fails |
| `CallerIdSettingsRepository` | Needs migration | `sync()` logs and swallows failures |
| `FavoritesRepository` | Conforms | Refresh rethrows sync failures; persisted local edits retain best-effort sync |
| `SipSubscriptionsRepository` | Conforms | Refresh rethrows sync failures; persisted local edits retain best-effort sync |
| `IceServersRepository` | Needs migration | A failed remote fetch returns the fallback normally |

For User info the polling listener is
[`UserInfoSyncWorker`](../lib/features/user_info/services/user_info_sync_worker.dart),
owned by `UserInfoSync`. One cycle fetches the remote snapshot, compares it with
the cache, and stores a changed one through
[`UserRepository.storeInfo()`](../lib/repositories/user_info/user_repository.dart),
which awaits the cache write before publishing. An unchanged snapshot completes
without a write or duplicate update. `getAndListen()` exposes cached data and
persisted updates; refresh failures reach polling through the worker's returned
future without being added to the data stream. The repository's own `refresh()`
is no longer registered anywhere and is kept only until the follow-up change
removes it. The
[worker tests](../test/features/user_info/user_info_sync_worker_test.dart) cover
both failure sources, stream preservation, persistence ordering, and automatic
backoff recovery with the worker registered in a real `PollingService` over the
real repository.
The [host integration tests](../test/repository/user_repository_integration_test.dart)
extend this through the real API client, datasources and mappers with controlled
HTTP and an in-memory preferences backend. The
[Patrol guard](../patrol_test/user_repository_refresh_test.dart) additionally
checks backoff recovery and session-rejection routing with native preferences;
see [coverage](integration_test_coverage.md#background-polling---user-repository-refresh)
and [run commands](integration_test_commands.md#run-the-user-repository-refresh-guards).

In [System Info](../lib/repositories/system_info/system_info_repository.dart),
`refresh()` awaits both the remote fetch and cache write, then publishes the
persisted snapshot on `infoStream`. Write failures retain their original error
and stack, with no data-stream update. `preload()` and network-backed
`getSystemInfo()` calls share this persistence contract; cache-only reads and
cache-first hits still need no remote work. The
[integration tests](../test/repository/system_info_repository_integration_test.dart)
cover these entrypoints, cache/stream ordering, failures and retry recovery.

The [login owner](../lib/blocs/app/app_bloc.dart) awaits `preload()` and explicitly
handles a failed prefill as non-fatal to the already valid session. The
main-shell route guard still verifies cache readiness before constructing its
providers. This caller-side fallback does not hide a polling refresh failure.

System Info's default 300-second interval backs off to 600 and then 900 seconds
with the application's default cap. Repository tests use shorter intervals to
verify failure accounting and recovery. The
[Patrol guard](../patrol_test/system_info_repository_refresh_test.dart) verifies
the failed-write and recovery path with native preferences and controlled HTTP.

In [Voicemail](../lib/repositories/voicemail/voicemail_repository.dart), `refresh()`
and direct `fetchVoicemails()` calls share one future covering the list request,
detail requests and required SQLite writes. Mutations waiting for that fetch
observe the same outcome. Every caller receives the original error and stack,
including on 401 and when re-emitting cached data also fails. Persisted rows
remain available to the UI; this fallback never turns a failed cycle into success.
Writes remain per item, not an all-or-nothing batch transaction.

The constructor retains its eager fetch and handles its detached observation;
joining polling/UI callers still receive the failed future. The
[composition root](../lib/app/router/main_shell_repositories.dart) supplies the
session guard, so `UnauthorizedException` is routed once per fetch before being
rethrown. Polling does not perform logout or classify HTTP errors.

An unconfigured mailbox or unsupported endpoint fails the attempted cycle and
sets `isActive` to false. Callers joining that still-running fetch receive its
failure; later direct calls need no work, and polling unregisters the inactive
listener. Like System Info, voicemail's default 300-second interval backs off
to 600 and then 900 seconds with the application's default cap. Repository tests
use shorter intervals to prove accounting and recovery.

The [unit contract tests](../test/repository/voicemail_refresh_contract_test.dart)
cover shared completion, mutation waiters, eager-fetch failures, inactivity and
20/40/10-second retry recovery. The
[host integration suite](../test/repository/voicemail_repository_integration_test.dart)
uses the real API mapping and SQLite. The
[Patrol guards](../patrol_test/voicemail_repository_refresh_test.dart) check shared
503/401 failures and delayed-write recovery on-device with an isolated database.
See [coverage](integration_test_coverage.md#background-polling---voicemail-refresh)
and [commands](integration_test_commands.md#run-the-voicemail-refresh-guards).

In [Favorites](../lib/repositories/favorites/favorites_repository.dart),
`refresh()` awaits the outbox read, remote pull or batch sync, and required local
writes. It logs and rethrows the original error and stack. An error while
recording a failed outbox attempt is logged separately and never replaces the
sync failure. The ETag advances only after local persistence succeeds; a `304`
or disabled remote sync completes normally without replacing local rows.

Local add, remove and reorder operations still persist the edit and its outbox
entry first. These writes must succeed. Their subsequent opportunistic sync
checks connectivity and treats refresh failures as non-fatal to the saved edit.
Polling calls the strict `refresh()` directly and owns its connectivity gate
and automatic retry delay. This change does not alter the existing outbox
attempt limit or make local writes and outbox acknowledgement atomic.

The [Favorites contract tests](../test/repository/favorites_repository_test.dart)
cover original errors, secondary bookkeeping failures, persistence and ETag
ordering, local-edit behavior, and automatic 20/40/10-second backoff recovery.
The [host integration tests](../test/repository/favorites_repository_integration_test.dart)
exercise the real API client, mapping and SQLite with controlled HTTP, including
401/429/503 failures, durable outbox retries, recovery, and `304` responses.
The [Patrol guards](../patrol_test/favorites_repository_refresh_test.dart) reuse
that harness with isolated file-backed SQLite on the device to verify automatic
pull backoff and saved-edit/outbox recovery. See
[coverage](integration_test_coverage.md#background-polling---favorites-refresh)
and [commands](integration_test_commands.md#run-the-favorites-refresh-guards).

In [SIP subscriptions](../lib/repositories/sip_subscriptions/sip_subscriptions_repository.dart),
`refresh()` has the same strict boundary as Favorites: it awaits the outbox read,
remote pull or batch sync, and local persistence, then rethrows the original
failure and stack. Secondary outbox bookkeeping failures are logged separately.
Only completed persistence advances the ETag; `304` and disabled remote sync
are successful no-work outcomes.

Local upsert and remove still persist the edit and outbox first, then await
best-effort sync with a connectivity preflight. A sync failure does not fail
the saved edit; a local mutation or initial outbox write failure still does.
Removal retains its contact-user-ID lookup before deleting the local row.
Polling invokes strict refresh without a repository connectivity gate. The
existing attempt limit, direct post-edit sync path and non-atomic outbox
acknowledgement are unchanged; this is not a worker or concurrency migration.

The [contract tests](../test/repository/sip_subscriptions_repository_test.dart)
cover original failures, bookkeeping, ETag/write ordering, local edits and
automatic 20/40/10-second backoff recovery. The
[host integration tests](../test/repository/sip_subscriptions_repository_integration_test.dart)
exercise real API mapping and SQLite with 401/429/503 responses, `304`, invalid
payloads, and durable upsert/delete retries including the resolved contact ID.
The [Patrol guards](../patrol_test/sip_subscriptions_repository_refresh_test.dart)
reuse the harness with an isolated database file for pull backoff and saved-edit
recovery. See [coverage](integration_test_coverage.md#background-polling---sip-subscriptions-refresh)
and [commands](integration_test_commands.md#run-the-sip-subscriptions-refresh-guards).
Like Favorites, the default 300-second interval backs off to 600 and then 900
seconds with the application's default cap. These repository tests use shorter
intervals; application configuration is covered separately by the shell tests.

Repository migrations should be separate review units. They may need feature
error-stream preservation, session handling, or domain-specific fallback
decisions that do not belong in the polling contract itself.

ICE server ticks have additional repository-level renewal rules; see
[`ice_servers.md`](ice_servers.md). `PollingService` does not inspect those
rules, it only invokes the repository contract.

## Adding or migrating a task

Use this checklist:

1. Decide whether the cycle belongs naturally to one repository. If it does,
   implement `Refreshable`; if it coordinates several dependencies, implement
   the worker pattern from [`polling_workers.md`](polling_workers.md).
2. Make `refresh()` return the real completion and original failure of one
   attempt. A deliberate no-work decision may complete normally; an attempted
   failure must not.
3. Override `isActive` only for a permanent end of useful polling.
4. Add a positive environment interval when deployments need configuration.
5. Register the same listener instance at the composition boundary.
6. Keep the full handle inside low-level ownership code. A feature worker must
   use `PollingWorkerOwner`.
7. Pass only `PollingTaskStateSource` or `PollingTaskRunner` when another
   component needs state or manual execution.
8. Remove parallel timers and direct refresh paths for the same action.
9. Keep feature-specific loading and error presentation outside
   `PollingService`.
10. Add unit coverage for timing, failure, lifecycle, and ownership behavior.
11. Add or update Patrol coverage when correctness depends on real app
    lifecycle, connectivity, login, or screen-mount behavior.

Repository refresh should be safe to call again after completion. It may update
its own cache or stream, but it must not create an untracked periodic loop.

## Testing

The deterministic unit contract lives in
`test/services/polling_service_test.dart` and
`test/services/connectivity_service_test.dart`. Standard feature ownership is
covered by `test/services/polling_worker_test.dart`. Together they cover:

- boot, reconnect, resume, background pause, and offline recovery;
- fixed delay, jitter, backoff, and stale timer invalidation;
- stable handle identity, replaying state, and offline availability;
- manual single-flight success and failure;
- deferred invalidation debounce, trailing execution, and lifecycle recovery;
- manual versus automatic backoff ownership;
- interval changes, inactive listeners, unregister, and disposal;
- late completion after a terminal stop;
- out-of-order liveness probes across repeated transports, offline events, and
  disposal;
- worker registration, capability delegation, safe invalidation, and ordered
  idempotent teardown.

Run them with:

```bash
fvm flutter test --no-pub test/services/polling_service_test.dart
fvm flutter test --no-pub test/services/connectivity_service_test.dart
fvm flutter test --no-pub test/services/polling_worker_test.dart
```

The on-device invariants live in:

- `patrol_test/polling_connect_invariant_test.dart`;
- `patrol_test/connectivity_probe_ordering_test.dart`;
- `patrol_test/contacts_worker_sync_e2e_test.dart`;
- `patrol_test/cdr_sync_pagination_e2e_test.dart`.

The native freshness suite (`patrol_test/polling_freshness_test.dart`) exercises
real 10-second timers with 6-second flaps, Android network recovery and
background/resume, explicit refreshes, failure recovery, in-flight invalidation,
and a disabled cap. It checks the real API/repository/native-preferences path
with controlled HTTP and prints request/completion timing traces.

The connectivity-ordering guard drives a real OS network flap, forces the older
probe to finish last, and verifies that the periodic schedule survives. The
connect invariant asserts one user-info request for login, aged resume, and aged
network recovery, using a 3-second test freshness cap. Service tests in
`test/services/polling_freshness_test.dart` cover fresh skips, preserved deadlines,
6-second flaps with a 10-second interval, failures, and explicit invalidations. The Contacts test covers the worker-driven flow from login through UI
data, self-filtering, manual refresh, aged resume, offline failure, and network
recovery (also using a 3-second test freshness cap). The CDR pagination test verifies the initial polling registration and
a three-page finite sync cycle against the local Core and SIP adapter.
See [`integration_test_commands.md`](integration_test_commands.md) for setup and
commands, and [`integration_test_coverage.md`](integration_test_coverage.md) for
the scenario index.

## Feature integrations

### Contacts

`ExternalContactsSyncWorker.refresh()` owns one full cycle: fetch through the
remote gateway, filter out the current user, and merge changed data into the
local store. The worker is the polling listener; the remote repository is a
fetch-only gateway and cannot start a second schedule.

Changed data is written once per cycle, without a worker-owned retry loop.
A failed write immediately fails the cycle with its original error and stack.
Only successful persistence advances the worker's unchanged-data snapshot, so
the next cycle fetches again and retries persistence even if the remote list
has not changed. Automatic failures use polling backoff; a manually started
failure does not increase it.

This replaces the legacy short write retries retained from the old sync BLoC.
Native DB contention is handled below the worker by the shared Drift server
and WAL/busy-timeout configuration. If a write still fails, cached contacts
remain visible until a later successful cycle; an empty list shows failure,
and a failed manual refresh shows an error notification. The first automatic
failure schedules the next cycle after roughly twice the base interval plus
jitter, subject to connectivity and lifecycle gating; the base interval depends
on the presence mode (see below).

Disposal before a required write starts fails the cycle with `StateError`.
A write already in flight may finish, and its actual result still reaches the
caller; disposal does not cancel or roll back that write.

`ExternalContactsSync` owns the worker and its registration. The external tab
calls its feature BLoC refresh action. The BLoC receives
`PollingTaskStateSource` and `PollingTaskRunner`, maps the cycle into feature
state, and invokes `runNow()`. The full handle remains private to the standard
owner. A pull during an automatic cycle therefore joins it instead of starting
a second download.

Unregistering during a cycle keeps task state terminal (`stopped`), but joined
manual callers still receive the real cycle outcome. The tests in
[`external_contacts_sync_worker_test.dart`](../test/features/contacts/external_contacts_sync_worker_test.dart)
cover these disposal races, immediate write failures without local retries,
automatic backoff, recovery, and the unchanged-data shortcut. They use controlled
repositories and time, not a native storage failure or a live backend.

#### Contacts presence interval

The base interval is chosen once at registration from the deployment's presence
mode (`FeatureAccess.sipPresenceConfig.hybridPresenceSupport`), which is the same
flag `AvatarStatusBadge` reads:

- **hybrid presence on** - the badge takes registration state from the SIP presence
  channel and ignores the contacts payload, so this fetch only refreshes the
  directory (names and numbers, which change rarely). Default interval **1800s**
  (`WEBTRIT_APP_EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS`).
- **hybrid presence off** - the contacts payload's registration status is the
  presence source, so the fetch stays fairly fresh. Default interval **300s**
  (`WEBTRIT_APP_EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS`).

The presence snapshot is pinned for the session, so the interval is fixed for the
session and needs no mid-session re-registration. `EnvironmentConfig
.externalContactsPollingSeconds` resolves the value; the 1800s default is expected
to become a cheap conditional poll once contacts gain a cached copy and an ETag.

### CDR

`CdrsSyncWorker.refresh()` owns one finite sync cycle: it fetches the initial
page or drains all incremental pages, persists the fetched records as one
batch, and then writes its completed-sync marker when needed. It owns no timer
or connectivity subscription.

`CdrsSync` extends `PollingWorkerOwner<CdrsSyncWorker>` and owns the worker and
its private polling registration. `CallBloc` receives a callback backed by
`requestPostCallRefresh()`: when a call ends, the owner invalidates the task
with a one-second publication delay. Repeated call-ended events therefore
debounce, an active scheduled cycle cannot overlap them, and the normal
periodic cadence is re-armed after the trailing refresh.

The Full and Missed CDR cubits receive `PollingTaskStateSource` and
`PollingTaskRunner` from `CdrsSync`. Pull-to-refresh invokes the current cubit's
feature action, which awaits `runNow()`, so it joins an active scheduled or
post-call cycle and presents that cycle's completion or failure to the user.
Widgets have no polling dependency, and neither presentation consumer can
invalidate or unregister the app-owned task.

Every failed CDR cycle asks the local repository to report an initial-sync
failure, but the repository emits `CdrsInitialSyncFailed` only while its durable
sync cursor is absent. A manual pull that fails after the first successful sync
therefore updates task state and the pull UI without producing an initial-sync
event.

When the app is already offline, `PollingService` correctly skips the worker,
and publishes `waitingForConnectivity` for the CDR polling task. `CdrsSync`
exposes that replaying state to every CDR list. An empty list releases its
initial loader immediately on that state, including when the screen subscribes
after the offline transition. A slow online cycle remains `running`, so it does
not incorrectly flash an empty state. The next successful repository cycle
still resolves and renders the records.

### User info

`UserInfoSyncWorker` delegates persistence to `UserRepository.storeInfo()` and
`UserInfoSync` uses the standard owner. The registration lives outside the
`PollingService` constructor list so the task is reachable through the owner's
narrow capabilities: `UserInfoCubit` receives the `PollingTaskRunner` and its
`refresh()` backs the Settings pull gesture, so a pull joins a scheduled cycle
instead of starting a second request; `UserInfoSync.requestPostCallRefresh()`
is invoked from the same call-ended hook as the CDR owner, with a delay (default
one second, `WEBTRIT_APP_POST_CALL_REFRESH_DELAY_SECONDS`) so the backend has
charged the call and the balance on screen reflects
it without waiting for the next tick. Foreground and reconnect already run the
leading refresh. The repository keeps the cache, the gateway and the
`getAndListen()` stream, and nothing else: it is not `Refreshable`, so the
cycle cannot be run anywhere but through the worker. Tests: `test/features/user_info/user_info_cubit_test.dart`
and the Settings pull cases in `test/features/settings/settings_refresh_test.dart`,
`test/features/user_info/user_info_sync_worker_test.dart`, the host suite
`test/repository/user_repository_integration_test.dart` and both Patrol suites
bind `harness.worker`; `test/app/router/main_shell_polling_config_test.dart`
asserts the owner registration at the user interval and that the shell fetches
once per cycle, so a second registration would be visible.
`test/repository/user_repository_test.dart` covers the store itself - the
replay, the persist-before-publish order and a failed write.

### System notifications

The feature's own page, covering both directions and the on-demand path end to end,
is [`features/system_notifications.md`](features/system_notifications.md).

`SystemNotificationsSyncWorker` implements the cycle and `SystemNotificationsSync`
is the standard owner with no extra capability: the feature has no pull-to-refresh
and no domain trigger, so scheduling is the only thing that runs it. A cycle takes
one branch - the initial history when the local store has no anchor, otherwise
every update since that anchor - and never both, so a first load stays one bounded
request.

Disposal rejects later refreshes and checks the worker's lifetime after every
await. An HTTP response arriving after disposal cannot start a store write,
and completing an already-started write cannot fetch another page. An I/O
operation already in progress is not cancelled; the retired cycle reports
`StateError` instead of success.

Two properties of the endpoint shape the cycle. It pages by timestamp rather than
by page number, so the anchor is advanced from the newest record of each full page,
and a full page that cannot advance it ends the cycle instead of being fetched
forever. The local anchor selects history versus updates; it does not say
whether an empty first sync has already succeeded. The worker remembers a
successful cycle for its own lifetime, including an empty history response.
Only history loaded before that first success is stored as `initialData`,
suppressing local pushes for the initial bulk and its retries. Notifications
arriving after a successful empty load are news and may produce a local push.
A new worker starts with no completed cycle, matching the previous loop's
per-worker initialization policy; this marker is not persisted across sessions.

The registration lives in `main_shell_services.dart` behind the feature gate, so a
deployment without system notifications registers nothing. `SystemNotificationsShell`
keeps the push service and the background task. Tests:
`test/features/system_notifications/system_notifications_sync_worker_test.dart`
covers the cycle, the paging, disposal races and the failure contract;
`test/features/system_notifications/system_notifications_sync_push_test.dart`
uses an in-memory Drift store and the real push service to verify that history
is silent and later notifications can produce pushes, including after an empty
first sync;
`test/features/system_notifications/system_notifications_integration_test.dart`
and `patrol_test/system_notifications_sync_test.dart` share seven regression
scenarios with real API mapping, owner teardown, file-backed SQLite and push
policy, including late responses after database cleanup. See the
[native run instructions](integration_test_commands.md#run-system-notification-sync-regressions);
`test/app/router/main_shell_polling_config_test.dart` asserts the registration at
the configured interval and that a core without the feature registers nothing.

### System notifications outbox

The write half of the same feature, and the one place in polling where the work is
queued rather than fetched. Marking a notification as read writes an outbox row and
returns, so the tap survives being offline and being killed; `SystemNotificationsOutboxWorker`
is what sends the queue. One cycle attempts every pending entry once. A failing entry
does not stop the others - the cycle walks the whole queue and then rethrows the first
failure with its original stack trace, so one poisoned entry cannot hold up the rest
while polling still backs off on a real error.

`SystemNotificationsOutbox.requestFlush()` is called by `SystemNotificationsScreenCubit`
right after the row is written, so the ordinary case is sent promptly and the interval
only has to catch what an earlier session left behind - which is why it is 300 seconds
rather than the sync's 10.

A flush runs the cycle whether or not the task is backing off, which is deliberate: a
receipt the user has just produced should not wait out a backoff window that an
unrelated entry caused. It is therefore asked for on the task's trailing-edge debounce
(one second) rather than immediately, so reading through a screenful of notifications
is one cycle instead of one request per tap - which is what would otherwise arrive at a
backend that is already refusing them.

A failed send leaves its entry exactly as it was, and nothing counts attempts. The
old worker abandoned an entry after five, which a one-second loop spent in about six
seconds - but a count is the wrong unit here whatever the loop does, because anything
may trigger a cycle: scrolling a list of unread notifications asks for a flush per
tap, and those flushes would spend the attempts of an unrelated entry that is failing.
Retry pacing and giving up belong to `PollingService`, which is the point of the
migration, so a receipt is retried for as long as polling retries it. The queue is
emptied by success instead: an entry is dropped when the sync worker brings its
notification back with `seen` set, including when another device sent it.
`SnOutboxState.failed` is no longer written by the app. Tests:
`test/features/system_notifications/system_notifications_outbox_worker_test.dart`
covers the drain, the partial failure, twenty failed cycles leaving an entry intact,
the confirmations and disposal at every boundary; `test/app/router/main_shell_polling_config_test.dart` asserts the
registration runs on its own interval rather than the sync's.

## Non-goals

`PollingService` does not:

- cache domain data;
- choose UI loading or error states;
- retry inside one repository request;
- cancel repository I/O already in progress;
- deduplicate direct calls or work in another service instance;
- decide whether a feature should exist for the session;
- replace repository-specific freshness rules.
