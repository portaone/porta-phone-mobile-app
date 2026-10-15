---
name: call-tests
description: How to write the test for a fix in calls - CallBloc, conference, handshake, callkeep callbacks - so that it fails without the fix, using CallBlocHarness and its fakes, and what those fakes do not model. Load when a request says "add a test", "cover this fix", "regression test", "test for the call bug", or touches phone/test/features/call or call_bloc_harness.dart.
---

# Call tests

When: you write or change the test that backs a fix in `phone/lib/features/call/` or in how the
app drives callkeep.

## Steps

1. Pick the place:
   - bloc behaviour through a real `CallBloc`: `phone/test/features/call/bloc/` and
     `phone/test/features/call/conference/`, built on `CallBlocHarness`
     ([call_bloc_harness.dart](../../../phone/test/features/call/bloc/call_bloc_harness.dart));
   - a bookkeeping class (`RoomOfferWait`, `OutgoingRingbackController`): next to its peers in
     `phone/test/features/call/conference/` or `utils/`, without the bloc;
   - a screen or widget: `view/`, `widgets/`, plus a `*_semantics_test.dart` (rules in [phone/AGENTS.md](../../../phone/AGENTS.md));
   - the signaling queue or hub: `phone/packages/signaling_service/*/test/`; the plugin itself:
     `callkeep/webtrit_callkeep*/test/`.
2. Write the test from the defect, not from the fix: the steps that broke it, then an assertion
   on what the user or the server would see (state, `h.signaling.requests`, `h.callkeep.ended`).
   Name it as the rule it holds ("a refused hold leaves the call up").
3. Seed with `h.seedEstablishedCall(...)` and drive through the public surface: `h.bloc.add`,
   the delegate callbacks (`h.bloc.performSetHeld(...)`), `h.signaling.emit` / `emitHandshake`.
4. Decide the order yourself. Hold a step open with a gate (`h.signaling.gate`,
   `h.callkeep.holdGate`, `endReportGate`, `updateGate`, `deferMuteReports`), do the racing step,
   then release it, with `await pumpEventQueue()` between.
5. Drive time without the clock: a bloc deadline through an injected timer (`ManualOfferDeadline`
   passed as `offerDeadline:`; add a timer factory to `CallBloc` the same way when a new deadline
   needs one); a standalone class with `fakeAsync` and `async.elapse` (`room_offer_wait_test.dart`).
6. Seed the failure path too: `h.signaling.failure`, `h.callkeep.endReportError`, `updateError`,
   `incomingRegistrationError`. If the fake cannot produce it, extend the fake first.
7. Prove it fails: take the `lib/` part of the fix out (`git diff -- lib > /tmp/fix.patch &&
   git apply -R /tmp/fix.patch`), run the test, see it fail on its assertion - not on a compile
   error or a timeout - then `git apply /tmp/fix.patch`. For a committed fix use `git show HEAD -- lib`.
8. From `phone/`: `fvm flutter test <file>`, then `fvm flutter test test/features/call`.

## Fake limits

- `FakeCallkeep` accepts every request. It does not apply CallKit rules: two active ungrouped calls
  cannot coexist (the system drops one), a grouped call refuses its own hold (`callIsGrouped`).
  A test of grouping or hold order against it passes while the device fails.
- `FakeCallkeep.setHeld` and `endCall` only record; only `setMuted` reports back through the
  delegate. An OS-started action (hold from the lock screen, end from the system UI) is a direct
  `h.bloc.performXxx(...)` call in the test.
- The default `CallkeepConnections` reports no connections (as iOS does); pass `callkeepConnections:`
  for an Android-like case.
- `FakeSignalingModule` has no queue: `connected = false` changes `isConnected` only and `execute`
  still acks; `sendable = false` returns `null`, which the app's module never does. It does not
  model the 30 s `NotConnectedException`, a request flushed after reconnect, or `executeNow` swallowing
  a loss. `emit` updates `sessionHandshake` and delivers the event in one step.
- `FakePeerConnection` answers every negotiation with a placeholder SDP and fires no ICE or
  connection events on its own.
- `FakeUserMediaBuilder` does model the one shared, reference-counted microphone track - keep it so.

## Platform behaviour

CallKit and Telecom behaviour, audio routes, notifications, the cold-start timing of platform calls
and lock-screen actions are not in any fake. Say so in the change note: what the unit test covers,
what it cannot, and how the platform part was checked (a device, an integration test in
`callkeep/webtrit_callkeep/example/integration_test/`, the Robolectric suite in
`callkeep/webtrit_callkeep_android/android`). Do not ship a green test that asserts the fake's own
behaviour back.

## Before handing over

- The test failed with the fix reverted, on the assertion, and passes with it.
- No real-time waits (`Future.delayed` of milliseconds) and no reliance on event ordering the
  test does not control.
- A timing-sensitive test ran several times in a row green.
- The change note names what the fakes could not exercise.

## Traps

- Modelling "session down" with `sendable = false` tests a behaviour the app does not have - [request_queue.md](../../../phone/packages/signaling_service/docs/request_queue.md).
- A test that does not fix the order of two completions passes or fails by luck - [bloc_async_state.md](../../../phone/docs/architecture/bloc_async_state.md).
- Real 20-100 ms waits fail under load; pass a timer in - [call_arch.md](../../../phone/docs/features/call_arch.md) ("Bookkeeping lives outside the bloc").
- A fake that hands out a track per call hides an app-wide mute defect - [call_bloc_harness.dart](../../../phone/test/features/call/bloc/call_bloc_harness.dart) (`FakeUserMediaBuilder`).
- `tester.tap` passes while the semantics path is broken; use `tapViaSemantics` - [accessibility.md](../../../phone/docs/guides/accessibility.md).
- Replay and snapshot behaviour of the real hub needs the real hub, not the fake module - [hub_replay_restoration_test.dart](../../../phone/test/features/call/bloc/hub_replay_restoration_test.dart).
- The Android JVM suite in pre-push skips itself without `android/local.properties` and still exits 0 - [lefthook.yml](../../../lefthook.yml).
