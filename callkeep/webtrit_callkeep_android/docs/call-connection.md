# Shared call connection and group

Backend-owned call state and membership rules shared by Telecom and standalone.
Last reviewed: 2026-09-18.

`models/CallConnection.kt` owns one call's identity, metadata, logical lifecycle,
answer fact and mute state. It has no Telecom dependency, does not dispatch events
and performs no audio or notification work. The backend serializes its mutations.
`CallMetadata` remains the existing Bundle payload, not another lifecycle owner.
A partial metadata update cannot change a connection's identity or answer it.
Lifecycle and mute changes use explicit methods; a terminal connection cannot be
reactivated. Reusing an id creates a new connection object.

`PhoneConnection` owns a `CallConnection` through composition because its parent
is Android's `Connection`. The standalone service owns a registry of the same
objects instead of separate metadata and answered-call collections. Its set of
answered ids is derived from that registry. Pending answers and incoming-call
registration remain service concerns, since they may predate a connection.

The logical state and Telecom state are distinct. Telecom can hold a grouped leg
without holding the application's call. The adapter acknowledges that callback
but leaves the logical state unchanged. `TelecomConnectionState.kt` maps Android
state constants at the boundary; the shared enum imports no Telecom types.
Outgoing activation does not invent the incoming-answer fact in Telecom. The
standalone adapter retains its existing AnswerCall event for established calls.

## Membership

`models/CallGroup.kt` is an immutable snapshot: an optional group id and a set of
call ids. It owns the rules for declaration, replacement and removal. Duplicate
ids count once, fewer than two members means no group, and an empty declaration
is a no-op. Removing the last members explicitly ends a group. The group retains
its identity while at least one member survives a declaration.

The standalone service swaps one snapshot and rebuilds its notification. The
Telecom adapter reads its connection membership as a snapshot and applies the
shared result to the connection flags. It creates no Android conference and leaves
framework hold states untouched when members leave. Disconnect cleanup uses the
same shared rule. The main-process tracker applies
these rules to its shadow records as well, while keeping the caller's group id.

These are shared implementations, not shared memory. Telecom connections live in
`:callkeep_core`; standalone connections and the shadow tracker live in the main
process. Existing IPC ownership and public Pigeon APIs are unchanged.

## Verification

- `CallConnectionTest`: identity, metadata, lifecycle, mute, terminal state and isolation.
- `CallGroupTest`: replacement, identity, empty/duplicate declarations, removal and immutability.
- `CallConnectionAdaptersTest`: real Telecom callbacks and standalone handlers, including a
  platform-only hold and call-id reuse.
- Existing service notification, group, tracker, ringtone and teardown tests continue to run.

Run `./gradlew testDebugUnitTest` from `android/`. Robolectric validates adapter
behavior but does not substitute for device audio routing and Telecom arbitration tests.
