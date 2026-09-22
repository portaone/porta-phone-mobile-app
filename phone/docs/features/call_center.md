# Call center: my queues

What a call center agent sees of the queues they serve, and the two ways of
going on or off the line - one queue, or all of them at once.
Last reviewed: 2026-09-22.

## Where it lives

```
lib/features/call_center/
  bloc/      CallQueuesCubit + CallQueuesState, CallQueueWriteOutcome
  view/      the route page (which owns the polling task) and the screen
  widgets/   a queue row, the control for every queue, the status dot
lib/repositories/call_queues/  CallQueuesRepository - the only thing that talks to the backend
lib/models/call_queues/        CallQueue and the snapshot the repository publishes
```

## The queue and its agents

A call queue is a hunt group on the PBX with a queue attached: callers wait in
it until one of its agents takes them. Being logged in is per queue, so an
agent can be taking calls from Support while logged out of Sales. It is the
same flag the PBX dial codes `*41`/`*42` and the self-care portal write, which
is why the client never owns it - see [the answer as the source of
truth](#the-answer-as-the-source-of-truth).

## The two gates

| Gate | Answered by | When it is known |
|---|---|---|
| The deployment offers the feature | `callCenter` in `system-info` -> `adapter.supported`, read through `FeatureAccess.callCenterAvailable` | before the session's shell mounts |
| This user is an agent of something | a non-empty `items` from `GET /api/v1/user/queues` | only after an authorised read |

The second gate cannot live in `FeatureAccess`: that object is pinned for the
whole session (see [feature access](feature_access.md)) and is built long
before any authorised request. So the two placements answer it differently.

The **settings row** is a configured item in the services section, next to
voicemail and gated the same way: the section mapper drops it where the backend
does not advertise the capability. Its other half is asked live - the session
builds the repository wherever the capability is on, reads once at its start,
and the row reads the answer from the cubit. An empty list is not an error - it
is the backend saying "not an agent" - and the row is absent for them.

Where the feature is not offered at all the endpoints answer `501`, which the
repository treats as terminal: it stops being active, and the polling service
unregisters it on the next attempt.

## The screen

One row per queue - name, number, whether this agent is taking its calls, how
many callers are waiting, how many agents are logged in of the total - over one
control for every queue at once.

### `callers_waiting`: unknown is not zero

`null` means the figure is unavailable, and where the PBX call control
interface is unreachable it is `null` on every queue, permanently. `0` means
the PBX answered that nobody is waiting. Rendering the first as the second
tells an agent their queue is empty while callers are on hold, so the value
stays nullable from the wire (`packages/api`) through the model to the row,
where it is drawn as a dash.

### The control for every queue

Material has no three-state switch and the wire has no third state: the backend
takes "log in to all" or "log out of all". A mixed list is drawn with a dash on
the thumb and a caption counting the queues, while the switch itself reads as
off - which is the direction it acts in, logging the agent into everything.
That is the start-of-shift action and the safer one to reach by accident.

### The answer as the source of truth

Every write answers with the state after the change, and that is what is drawn.
The switch is not flipped locally first: the same flag is written by the dial
codes and by self-care, and the answer also carries agent counts that moved
meanwhile. While a row's own request is in flight the control gives way to a
progress indicator, so nothing has to flip back when the PBX refuses.

Two refusals mean something particular. `call_queue_not_found` (404 with that
code) says the list on screen is older than the PBX - the row is left as it is
and the list is read again. A `503` is the PBX site in disaster recovery: reads
work, writes do not, and the person is told so rather than shown a generic
failure. A bare 404 or a 501 is the feature being absent, which the transport
reports as `EndpointNotSupportedException` (see `packages/api`).

## Polling

There is no push channel for queue counters. The screen registers the
repository with `PollingService` when it opens and unregisters it when it
closes, so the reads last exactly as long as the screen does - every one of
them reaches the PBX, and the adapter re-reads the customer's whole hunt group
list on each. The interval is
`WEBTRIT_APP_CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS`, ten seconds by
default, the slow end of what the backend contract allows. Backgrounding the
app stops the timers by itself; see [polling](../polling.md).

A read that started before a write is dropped when it returns: it carries the
state from before the change, and applying it would flip the agent's switch
back for a whole interval, in front of them. A row with a write in flight keeps
what it shows while the rest of the list still follows the backend, and while
every queue is being written at once an incoming read is dropped whole.

## Backend

`GET /api/v1/user/queues`, `PATCH /api/v1/user/queues` and
`PATCH /api/v1/user/queues/{id}`, in core from 0.38.0, behind the adapter
capability `callCenter` (off by default per deployment).
