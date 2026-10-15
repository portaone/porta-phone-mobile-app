# Async State in a Cubit or Bloc

Two traps of a Cubit or Bloc that loads several things at once: a stale `state` written back
after an `await`, and an `emit` that lands after `close()`.
Last reviewed: 2026-10-15.

## `emit(state.copyWith(x: await ...))` writes back a stale state

What you do:

```dart
emit(state.copyWith(pipelines: await loadPipelines()));
```

What happens: another field that a parallel load set while this one was waiting is reset to the
value it had before. The bug shows up only sometimes, because it depends on the order the
responses arrive in, and opening the screen again seems to fix it.

Why: Dart evaluates the receiver before the arguments. `state` is read first, `await` runs
second, so `copyWith` is applied to the state as it was before the wait.

Instead, await into a local first and read `state` after:

```dart
final pipelines = await loadPipelines();
emit(state.copyWith(pipelines: pipelines));
```

The one-line form is harmless only when nothing else writes the state between the start of
the call and the `emit` (loads that run one after another), or when `copyWith` is given every
field. The same applies to a snapshot taken before the wait (`final s = state; await ...;
emit(s.copyWith(...))`).

To look for it:

```bash
grep -rnE "emit\((this\.)?state\.copyWith\([^;]*await " --include='*.dart' lib packages
```

A one-line grep misses calls split over several lines, so read those too. `phone/lib` and
`phone/packages` have no occurrences at the moment.

## `emit` after `close()`

What you do: start loads from the constructor and leave the screen before they answer.

What happens: the load completes on a closed Cubit and `emit` throws
`Bad state: Cannot emit new states after calling close` as an uncaught error.

Why: `close()` does not cancel futures the Cubit started; they keep running and call `emit`
when they finish.

Instead, guard in one place rather than in every method. Either override `emit`:

```dart
@override
void emit(MyState state) {
  if (isClosed) return;
  super.emit(state);
}
```

or route every late emit through one helper, as `VoicemailCubit._safeEmit` does
(`lib/features/voicemail/bloc/voicemail_cubit.dart`).

A Cubit whose `close()` awaits something before `super.close()` has a window where `isClosed`
is still `false`: it flips only inside `super.close()`. Anything started in that window must
check a flag the Cubit sets itself at the top of `close()`. `CallRoutingCubit`
(`lib/features/call_routing/cubit/call_routing_cubit.dart`) sets `_closing` for that, and
`test/features/call_routing/call_routing_cubit_close_race_test.dart` closes it while its
initialization is parked on an `await`.

## Testing the order of responses

A race between loads reproduces reliably only when the test decides the order:

- each fake dependency returns `Completer.future` instead of a ready value;
- the test completes them one at a time, in the order it wants, with `await pumpEventQueue()`
  between them;
- it then asserts every field the loads set, not only the last one.

Run the test once without the fix: it must fail.
