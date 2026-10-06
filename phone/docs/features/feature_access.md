# Feature access: how runtime configuration reaches the app

What the app is allowed to show and do - voicemail, call history, extensions,
chats, self-config and so on - is not fixed at build time. It is assembled at
runtime from several sources into one object, `FeatureAccess`, and every screen
and service reads its answers from there. This doc explains where that object
comes from, and - the part that matters most in practice - WHEN a change to the
configuration actually takes effect.

Last reviewed: 2026-10-06

## Where the configuration comes from

`FeatureAccess` is assembled from three inputs:

- the application config (`AppConfig`) - the white-label configuration built
  into the app or delivered by the configurator: which tabs exist, which login
  flows are enabled, embedded pages, and so on;
- the backend capabilities (`system-info.adapter.supported`) - what the
  connected core/adapter can actually do: `voicemail`, `callHistory`,
  `extensions`, `recordings` and friends. Fetched on login and refreshed by
  background polling;
- Firebase Remote Config overrides - server-side toggles layered on top.

The assembly lives in `lib/data/feature_access.dart`; the reactive stream that
recombines these sources is built in bootstrap (`FeatureAccessStreamFactory`)
and provided app-wide by `RootApp` as a `StreamProvider<FeatureAccess>`.

## The one rule: a session runs on a snapshot

The moment the user gets past login and the main shell mounts, the shell takes
the CURRENT `FeatureAccess` value and pins it for the whole session
(`MainShell` shadows the reactive provider with a plain
`Provider<FeatureAccess>.value` over the session subtree - see
`lib/app/router/main_shell.dart`). Everything below the shell - repositories,
services, blocs, screens - reads that snapshot through an ordinary
`context.read<FeatureAccess>()` and therefore sees one consistent set of
answers from the first frame of the session to the last.

Consequences, in plain terms:

- A configuration change that arrives DURING a live session (a capability
  flipped on the backend, a Remote Config push, a configurator edit) does NOT
  apply to that session. Nothing appears, nothing disappears, nothing breaks
  mid-call. The change is not lost: the stream and its cache keep updating in
  the background.
- The change takes effect at the NEXT session start: logout/login or an app
  restart mounts a fresh shell, which pins a fresh snapshot. Logging into a
  different account or a different core works the same way - the login flow
  fetches that backend's `system-info` before the shell mounts, so the new
  session pins the new backend's capabilities. An app restart gets there by
  another road - see "A start that is already behind" below.
- Everything OUTSIDE the session subtree stays reactive. The login flow and
  the version gates read the live stream; the force-update gate can still
  interrupt a session. Theme and locale are separate streams, not part of
  `FeatureAccess`, and keep applying live (including mid-call).

## A start that is already behind

A started app does not wait for the network: the snapshot its first session
pins is built from the `system-info` it stored before (`FetchPolicy.cacheOnly`
in `FeatureAccessStreamFactory.getInitialSnapshot`). The backend is read only
once that session runs - a second or two later - and by the rule above the
answer cannot reach it. Left at that, a capability changed while the app was
closed would show up one start late: the first start stores the answer, the
second one uses it.

So the first session of a run asks once whether it is behind
(`StartupFeatureAccessCheck`, shared from bootstrap): when its first read of
the backend has been stored, what a session mounted now would get is compared
with what this one was mounted with. If they differ, the session is replaced
as a whole - not updated in place:

- `StartupConfigRefresh` (in the shell, below the blocs) waits until the
  session has heard from the server and no call is tracked - neither by
  `CallBloc` nor on a line of the signaling session. Both are asked: the bloc
  takes up a call some turns after it learns of it (the calls of a handshake
  after it reports the handshake, a presented call after the caller has been
  looked up), while the session's lines carry it all along. A server that
  cannot be reached is no answer, so the restart waits for the handshake. A
  start for an incoming call is not cut short; the restart follows the call.
- It then takes the shell to `SessionRestartScreenPageRoute`, which unmounts
  it with everything it built and says, under a progress indicator, that
  changes from the server are being applied. No notification follows. That screen waits until the old shell has let go of
  call integration and signaling - each is one per process, so a shell
  setting them up during the previous one's teardown would have its state
  wiped by it - and returns to
  the main shell route. The guard there builds the session the way it does
  after a sign-in, initial tab included.

This happens at most once per run and only for its first session: a session
after a sign-in was built from a fresh read, and the session that replaced a
stale one is not asked again. A change that arrives later, in the middle of
somebody's work, still waits for the next start - replacing the session then
would throw away the screen they are on. A host that supplies its own
configuration (the configurator's preview) is never asked.

One case is not covered: an app started without a network whose first read
lands minutes later. That read is still its first, and the session is replaced
then, wherever the user is.

## Why it works this way

Before the pin, the shell rebuilt its provider tree on every `FeatureAccess`
emission. When an update changed the SHAPE of the tree (a conditional
provider such as voicemail or the CDR sync worker appearing or disappearing),
the blocs of the old shape were closed while the navigator and its screens
survived and kept talking to them - and events sent to a closed bloc are
swallowed silently. The visible symptom: after a background config update the
call button (or chats, or history) just stopped doing anything, with no error
anywhere. Pinning the session to one snapshot removes the whole class: the
session tree is stable by construction, and the moment configuration applies
is well-defined and testable.

The regression test for the class lives in
`test/app/router/main_shell_feature_access_change_test.dart`: flip a
capability mid-session and assert the shell keeps the exact same bloc
instances.

## Notes for specific cases

- "Enable verbose logging for a live user via Remote Config" does not reach a
  running session anymore (value-level settings are pinned too). If hot log
  switching is ever needed, wire the logging knob to the Remote Config stream
  directly, above the shell - a config value that changes no tree shape is
  safe to apply live.
- The configurator's realtime preview mirrors the same semantics: editing the
  feature configuration relaunches the embedded app (a fresh boot with fresh
  dependencies), because pushing config into a running session would, by the
  rule above, change nothing.
