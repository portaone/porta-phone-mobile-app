---
name: callbloc-change
description: Procedure and async-state checklist for changing CallBloc in phone/lib/features/call - adding or changing an event, a handler, a _CallMutationEvent, a state mutation or a handshake step. Load when a request touches call_bloc.dart, call_event.dart, the mutation queue, HandshakeProcessor, call restore or reconnect, a callkeep perform callback, or a fix "in CallBloc".
---

# CallBloc change

When: you add or change an event, a handler, a mutation or a handshake step in `CallBloc`.
For the test itself load the `call-tests` skill.

## Steps

1. Read "Event Categories" and "Key Patterns" in [call_arch.md](../../../phone/docs/features/call_arch.md)
   and "Architecture" in [phone/AGENTS.md](../../../phone/AGENTS.md).
2. Find the entry point. A signaling event is turned into a bloc event in one place, `toCallEvent` in
   `phone/lib/features/call/bloc/call_signaling_event_mapping.dart`; events are declared in
   `call_event.dart` (sealed + Equatable, never freezed); handlers and their transformers are
   registered in the `CallBloc` constructor in `call_bloc.dart`.
3. React in the handler, not in the mapping: `toCallEvent` only translates. Make the decision in
   `CallBloc`, not in the plugin that carries it out.
4. Keep a handler to checks and state writes. Whatever touches the peer connection, callkeep or
   signaling goes through `add(_CallMutationEvent.xxx(...))` and its `__onMutationXxx` handler -
   one sequential queue.
5. Do not hold that queue on something the next event does not need (a platform report, a slow
   native round trip); a path that must bypass the queue says why in a comment, as
   `_planConferenceAudio` does.
6. If a reconnect has to redo the step, plan it in `phone/lib/features/call/utils/handshake_processor.dart`
   (a `HandshakeAction`, mapped in `call_handshake_action_mapping.dart`) and cover it in
   `phone/test/features/call/bloc/handshake_processor_test.dart`.
7. A new per-call map, timer, counter or pending offer is a class of its own with its own tests
   (`RoomOfferWait`, `DebounceMap`). If the flow is already spread over the bloc, extract it first
   in a commit that changes no behaviour.
8. Walk the checklist below for every `await` the change adds or moves.
9. Write the test (`call-tests` skill) and see it fail without the fix. From `phone/`:
   `fvm flutter test test/features/call` and `fvm flutter analyze`.
10. Update `call_arch.md` / `call_conference.md` in the same change when what they describe moves.

## Async state checklist

- **State read after await.** Never write back a `state` or an `ActiveCall` captured before the
  wait. Look the call up again (`state.retrieveActiveCall(callId)`) and check its status is still
  the one the code assumed.
- **The call is gone when the future completes.** Return without emitting; do not re-add it, and
  do not touch another call - key every write by call id, never "the current call".
- **Facts from enqueue time.** A mutation waits its turn; what the handler knew when it queued it
  travels in the event (`wasHeld` on `signalingHangup`), because by then the call may have left.
- **The server or the OS rejected it.** A refusal leaves the previous state standing: no
  optimistic write before the answer, or roll it back. `await null` is not an acknowledgement, a
  completed `execute` is not proof the server saw it, and a broad `catch` must not end a live call.
  Only an answer that says the call is gone (410) ends it.
- **Replay after reconnect.** A request sent while the session is down is queued and sent after the
  reconnect; if the handshake redoes the action, the server gets it twice - skip it with
  `if (!_signalingModule.isConnected) return;`. A handshake plan is decided before the callkeep reads
  and run after them: a hangup or a live offer in between wins. An empty `activeCalls` at handshake
  time can still be a push or an answer on its way, not "no call". Tie a late answer to the attempt or
  session it was sent on (`_offerWait.isCurrent(attempt)`).
- **Every entry path.** The rule holds for UI (`CallControlEvent`), native perform callbacks
  (`_CallPerformEvent`, including ones the OS starts on its own), signaling, handshake and restore.
- **close() races.** `CallBloc.close()` awaits teardowns before `super.close()`, so `isClosed` is
  still false in that window; a subscription, timer or `unawaited` future that calls `add` checks
  `isClosed` first.

## Before handing over

- The new test fails with the fix reverted, on the assertion the fix is about.
- `fvm flutter test test/features/call` is green and `fvm flutter analyze` is clean.
- Every `await` in the diff went through the checklist; the change note names the items that applied.
- No new raw field on `CallBloc` for state carried between events.
- The change note says what unit tests could not show (CallKit, Telecom, audio routing) and how it was checked.

## Traps

- `emit(state.copyWith(x: await ...))` copies the state from before the wait - [bloc_async_state.md](../../../phone/docs/architecture/bloc_async_state.md).
- A null from `execute` and a silently completed `executeNow` both look like success - [request_queue.md](../../../phone/packages/signaling_service/docs/request_queue.md).
- Awaiting a platform report inside a mutation made a second hangup wait seconds on a cold start - [hangup_report_not_awaited_test.dart](../../../phone/test/features/call/bloc/hangup_report_not_awaited_test.dart).
- An early `return` in the handshake plan drops the offer delivery for other calls; keep deliveries apart - [handshake_processor.dart](../../../phone/lib/features/call/utils/handshake_processor.dart).
- A plan decided before the callkeep reads revived a call hung up meanwhile - [handshake_race_test.dart](../../../phone/test/features/call/bloc/handshake_race_test.dart), [stale_handshake_plan_test.dart](../../../phone/test/features/call/bloc/stale_handshake_plan_test.dart).
- A refused hangup or decline replayed by the next handshake stopped the whole plan - [termination_queue_test.dart](../../../phone/test/features/call/bloc/termination_queue_test.dart).
- A refused hold must leave the call and its hold state as they were - [set_held_handler_test.dart](../../../phone/test/features/call/bloc/set_held_handler_test.dart).
- `onError` only logs; finalizing a call belongs to the disconnect, hangup and ICE paths - [call_arch.md](../../../phone/docs/features/call_arch.md).
- A grouped conference leg cannot be held or transferred on any path - [call_conference.md](../../../phone/docs/features/call_conference.md).
