# Session Remount

Traps for code that replaces `MainShell` as a whole for the same sign-in (a new configuration, a
mode change), or that decides "there is no call right now". How the app does it today, with
`StartupConfigRefresh` and `SessionRestartScreen`, is described in
[`../features/feature_access.md`](../features/feature_access.md), section "A start that is
already behind"; this page is about why it has that shape.
Last reviewed: 2026-10-15.

## `CallBloc` reports "connected" before it knows about the call

What you do: wait for `CallState.isHandshakeEstablished` and `!state.isActive`, then treat the
session as free of calls.

What happens: a call that is ringing or already up gets cut, because the bloc's state has
windows where the call exists and `activeCalls` is still empty:

- After a handshake. `_handleHandshakeReceived` first adds `_HandshakeSignalingEventState` with
  the registration (that sets `isHandshakeEstablished`), and plans the calls of the handshake
  lines later, after awaiting `CallkeepConnections.getConnections()` and `getConnection()`. On a
  device started by a call answered from the notification, the gap was about 130 ms.
- After the platform presents an incoming call. `didPresentIncomingCall` adds
  `_CallPushEventIncoming`, and `_onCallPushEventIncoming` puts the call into the state only
  after the contact lookup (`contactResolver.resolve`).

Instead, also ask the signaling session. `SignalingModule.sessionHandshake` is the handshake as
the module knows it now, not a snapshot of the first one: a line that is not free carries a
call the whole time the bloc has not taken it up yet. `null` means "not known yet" - wait,
do not read it as free. `StartupConfigRefresh._obstacle` (`lib/app/router/startup_config_refresh.dart`)
checks both.

An unreachable server is not an answer either. `CallStatus.connectError` and `connectIssue`
only say there is no handshake; whether a call is waiting on the server is unknown.
`AppUpdateCheck` (`lib/app/router/app_update_check.dart`) counts those states as "the session
has heard from the server", which is acceptable for showing an update prompt. For an action that
ends calls it is not.

On iOS `CallkeepConnections.getConnections()` always returns an empty list (the plugin answers
only on Android and web), so it cannot be the source of "no calls" there.

## Callkeep and signaling are one per process

What you do: mount a new `MainShell` while the old one is still being torn down - for example by
changing the shell's widget key.

What happens: the end of the old teardown lands on the new session and undoes its setup:

- `WebtritSignalingServiceAndroid.dispose()`
  (`packages/signaling_service/signaling_service_android/lib/src/plugin.dart`) sets
  `_currentMode = null` and clears `_eventBuffer` after its own awaits, in the shared plugin,
  wiping the state of a session that has already connected;
- `Callkeep.tearDown()` on Android ends in `ForegroundService` with `core.clear()` and
  `core.tearDownService()`, clearing the calls of a session that has already run `setUp()`.

A normal sign-out and sign-in never shows this: the login screen and a person stand between the
two.

Why a new key does not help: Flutter builds the new element (its `initState` runs) during the
frame and unmounts the old one at the end of it, so the order is the wrong way round.

Instead: leave the shell's route for a route of your own, and come back only after the old shell
says it has let go of both. `MainShell` keeps a `Completer` (`_ended`) that completes after both
`_tearDownCallkeep()` and `_tearDownSignaling()` finish in `dispose()`, and
`SessionRestartScreen` (`lib/features/session_status/view/session_restart_screen.dart`) awaits
it before `replaceAll([const MainShellRoute()])`.

`SignalingModuleImpl.dispose` waits up to 3 s for the socket close to be acknowledged
(`signaling_module_impl.dart`). Where that acknowledgement does not come, a restart holds the
progress indicator for about that long.

## A notification is shown only from a session screen

What you do: submit a notification from a screen in between (the restart screen, an error
screen).

What happens: nothing is shown. `AppShell` (`lib/app/router/app_shell.dart`) shows a snackbar
only when the active route belongs to the notification's scope (`_scopeRoutes`: the login
router, the main screen and the settings router, the call screen); anything else is dropped
without a word.

Instead: submit it before leaving the session screen. The snackbar is held by the
`ScaffoldMessenger` above the routes, so it survives the route change.
