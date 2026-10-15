# Request Queue

What `SignalingModule.execute` does with a request when there is no connection, and three ways
a caller in the app reads the result wrongly. For anyone writing code in `CallBloc` that sends
something "if the session is up".
Last reviewed: 2026-10-15.

The code:

- `WebtritSignalingService.execute`
  ([`signaling_service/lib/src/signaling_service.dart`](../signaling_service/lib/src/signaling_service.dart)) -
  the module the app gets from `lib/utils/signaling_service_factory.dart`;
- `SignalingRequestQueue`
  ([`signaling_service_platform_interface/lib/src/signaling_request_queue.dart`](../signaling_service_platform_interface/lib/src/signaling_request_queue.dart));
- `SignalingModuleImpl.execute` (same package, `signaling_module_impl.dart`) - the WebSocket
  module, which uses the same queue.

The package layering is in [`../ARCHITECTURE.md`](../ARCHITECTURE.md).

## Without a connection a request waits, it is not dropped

What you do: call `execute` while the session is down, expecting nothing to happen.

What happens: the request is queued (`enqueue`) and sent as soon as `SignalingConnected`
arrives (`flush`). Its future completes when the request has been sent, or fails with
`NotConnectedException` once `requestTimeout` (30 s) passes without a connection.

Why it matters: a request made during an outage goes out after the reconnect. If the handshake
of that reconnect triggers the same action, the server gets two requests with different
`transaction` ids. For `ConferenceRejoinRequest` that is two rejoins, and the server moves the
host onto a new handle for each.

Instead: when the handshake will repeat the action anyway, do not hand a session that is down
the request at all:

```dart
if (!_signalingModule.isConnected) return;
```

`CallBloc._askForRejoin` is the example.

## `execute() == null` does not mean "not connected"

What you do: treat a `null` from `execute` as the session being down, and write a test for it.

What happens: the module the app runs on never returns `null` - without a connection it returns
the queue's future. `null` comes only from a module that has nowhere to send, such as
`SignalingHubModule` (Android, `signaling_service_android/lib/src/fgs/hub/signaling_hub_module.dart`)
before it is connected. The doc comment on `SignalingModule.execute` ("Returns null when not
connected") describes that module, not the one `CallBloc` holds.

The trap in tests: `FakeSignalingModule` in `test/features/call/bloc/call_bloc_harness.dart`
returns `null` when `sendable = false`. A test built on that proves a behaviour the app does not
have. To model "the session is down", set `connected = false` and assert that the request was
not executed (`requests` stays empty).

Handling `null` is still right where it is cheap: `CallBloc._sendConferenceRequest` treats it as
`notSent`, because an awaited `null` completes like an acknowledgement.

## `executeNow` can report "sent" for a request that never went

What you do: read a normally completed `execute` future as "the server took it".

What happens: if the session goes away while the request is in flight (`isActive()` turns
`false`), `executeNow` catches the `NotConnectedException` and completes normally.
`WebtritSignalingService.execute` then sees no error either.

Why: the queue drops reconnect-window errors on purpose, so callers are not burdened with them
(see the doc comment on `executeNow`).

The consequence in `CallBloc`: `_sendConferenceRequest` returns `taken` for such a request. A
caller that acts on `taken` - quieting the legs for a merge, marking a room active after its
offer was answered - acts on a request the server never saw.

Instead: where a silent loss would leave the call in a wrong state, do not rely on the future
alone. Check `isConnected` again when the answer is handled, or tie the answer to the session
it was sent on and ignore it once that session is gone - the rejoin flow does the latter through
the attempt counter of `RoomOfferWait` (`_offerWait.isCurrent(attempt)`).
