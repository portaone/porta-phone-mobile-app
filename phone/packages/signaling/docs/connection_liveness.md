# Connection liveness

How the client and Core each decide that a signaling connection is dead, what each timer is
restarted by, and what a call goes through when a connection dies without being closed. The one
place this is written; the package's `AGENTS.md` and the app's docs link here.

Last reviewed: 2026-11-12. Sources: this package with the receive watchdog and the state rule, and
two probes over it (section 4); Core `porta-phone/backend` master `7c5e287d` (read, not changed);
runs on the stand of 2026-11-10 to 2026-11-12 on device-4 (Xiaomi, Android 10), device-7 (Xiaomi,
Android 15) and device-9 (iPhone 12 mini, iOS 27), whose evidence is case PO-84 of the QA
repository. What is read in code and not run is marked so.

Contents

1. The timers
2. What Core does
3. A connection that dies without being closed
4. What the client does not do, and why
5. Reproducing it

## 1. The timers

The client has three, all in `WebtritSignalingClient`.

| Timer | Started | Restarted by | When it runs out |
| --- | --- | --- | --- |
| keepalive | the state handshake, with its `keepalive_interval` (30 s without one) | every `execute`, and its own answer | sends `KeepaliveHandshake` and waits for the answer |
| receive watchdog (`ReceiveWatchdog`) | `listen`, before any message | every message received, never what is sent | sends the keepalive at once, unless one is waiting for its answer |
| transaction | each request, the keepalive included | - | the request fails with `WebtritSignalingTransactionTimeoutException` |

The default wait of a transaction is `defaultExecuteTransactionTimeoutDuration`, 10 s.

The keepalive timer is put off by outgoing requests on purpose: a request tells Core the client is
alive as well as a keepalive does (section 2). It says nothing about whether the server can still
be heard. That is the watchdog's question, so it listens to the receiving side only. A live
connection hears at least the answer to its keepalive once per interval, so on a healthy one the
watchdog never runs out and no frame is added.

The connection is given up only when a keepalive gets no answer, or gets one before the state
handshake came (`WebtritSignalingKeepaliveWithoutStateException`, a kind of the keepalive timeout:
Core sends the state first, so such a connection lost frames on the way). The error is reported
through `onError`, once, and the client leaves the connection as `disconnect` does -
both timers stop, the subscription is cancelled (no `onDisconnect`, no more messages), the sink is
closed, `execute` throws `WebtritSignalingDisconnectedException`, and the requests still waiting
fail at once with the timeout they would have got at their own time (`Transaction.timeOutNow`).
`signaling_service` then reconnects as for any failure.

So the longest a dead connection goes unnoticed is the interval plus one wait: 40 s with Core's
30 s, from the last message received, whatever is sent meanwhile and whether the state has come
or not.

## 2. What Core does

Read in Core's code; the first two were also seen in its log during the runs.

- Core closes a connection it has heard nothing on for twice the interval it announced - 60 s for
  the app - with close code 4502, `signaling keepalive timeout error`
  (`controller/receive_signaling_keepalive_timer.ex`). Every frame from the client restarts that
  timer (`controller/signaling_handler.ex`, `ReceiveSignalingKeepaliveTimer.restart`), requests as
  well as keepalives. A web client is announced 60 s, so 120 s.
- 30 s after Core lost the client's socket, it hangs up every accepted call of that session
  (`controller/calls_release_timer.ex`, `@disconnect_threshold_ms`), checked once a second. The log
  line is `socket disconnected <ms>ms ago - hangup call`.
- Core answers the client's keepalive at once and sends the state handshake as the first frame of
  a new connection.

## 3. A connection that dies without being closed

Shown on the stand with `silent_network_loss` of the QA repository: what Core sends to the phone is
dropped while the phone's network works, and the media is cut for 20 s so the app restarts ICE
and sends `update` on the dead connection.

**Before the watchdog** (master `112aa06b8a6`, release 1.19.0 `71670894959`), Android, in front and in
the background: the app retried `update` every 10 s and never sent a keepalive - each retry put it
off. The far end never heard the user again. Only the first `update` reached Core: without Core's
acknowledgements the phone's TCP stalled and the retries never left it. Core heard nothing for
60 s, closed the socket, and hung the call up 30 s later, at about 107 s; the phone showed the
call until the network came back.

**With the watchdog**, the same steps: the watchdog sent the keepalive at 30 s, its timeout gave the
connection up at 40 s, a new connection came 3 s later, `CallBloc` replayed the kept offer on its
state handshake and the far end heard the user again 43-50 s after the loss, in front and in the
background, on both Android phones. The call stayed.

**On the iPhone** the socket whose data is not acknowledged went down by itself about 18 s after
the unanswered `update`, with no keepalive involved, and the app recovered in 39-40 s on master
and with the watchdog alike. Which layer closes it was not looked at.

**Everything Core sends lost, on every connection** (the phone cannot reach Core at all): no build
keeps the call. The client gives the connection up at 40 s, cannot make a new one, and Core hangs
the call up as above.

**A connection that never gets its state but answers keepalives** is given up at the first
answer, and the client connects again. Core sends the state as the first frame of every
connection and closes one it cannot attach (read in code); in app logs of 2026-06 to 2026-11, 257
connections got it in at most 0.68 s. So only something between the two loses it: shown through a
proxy that drops what Core sends (the server's steps of the defect) - with the watchdog alone the
connection made while the answers were lost stayed without state and the call was never heard
again; with the state rule the far end heard the user 33 s after the answers came back, once a
new connection got its state and the kept offer was replayed.

## 4. What the client does not do, and why

- **The keepalive is not restarted by what is received instead of by what is sent.** Core counts
  only frames from the client (section 2). A client that hears Core often - presence, dialogs,
  call events - would then send nothing for minutes and be closed with 4502 at 60 s. Read in
  code, not run.
- **Silence alone does not give a connection up.** The watchdog asks first: one request that Core
  ignores on a live connection costs that request its own timeout, as before, and not the
  connection.
- **No fixed wait for the first state handshake.** A slow Core (a large call log, a controller
  starting over) would turn it into a reconnect loop. A connection that hears nothing at all is
  asked at 30 s like any other, and one that answers before its state is given up (section 1):
  that rule rests on the order Core sends in, not on a guessed time.

- **A request with no answer does not ask the connection at once.** Tried as a probe (2026-11-12,
  PO-84 on device-4): the far end heard the user again at 46 s, as without it. The first request
  of a dying call is the ICE restart's `update`, sent when ICE fails some 20 s into the loss, so
  its timeout and the keepalive after it end when the watchdog's would anyway. It would gain only
  when a request goes out right as the connection dies; that was not run.
- **No `TCP_USER_TIMEOUT` on the socket.** Tried as a probe on master without the watchdog: with
  20 s on Android the kernel closed the socket whose data stayed unacknowledged (`_wsOnDone` 1002,
  about 50 s after the last keepalive), the app reconnected and the far end heard the user again
  at 46 s - what the iPhone does by itself. Not taken: it does not reach a connection whose TCP is
  alive while the server's frames are lost, and it was run only on `ws://`, not over TLS.

## 5. Reproducing it

- Case PO-84 of the QA repository: the loss of section 3, in front and in the background; it needs
  a build that logs at FINE. Its "Observed" section holds the runs.
- `silent_network_loss` of the QA repository: `cut("signaling", way="to-phone",
  scope="established")` kills only the connection the phone has; `scope="address"` every one;
  `way="both"` (the default) is a full loss both ways.
- The client alone: `test/signaling_integration_test.dart`, group `Silent connection`, over a
  mocked channel with `fake_async`.
