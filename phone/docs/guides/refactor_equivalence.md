# Refactor Equivalence

How to show that a refactoring changed no behaviour by running the old and the new code side by
side on random inputs. Existing tests say "the cases someone thought of still work"; this says
"on everything that could be generated, the two versions do the same".
Last reviewed: 2026-10-15.

The rule that a flow is extracted from a bloc in a commit that changes no behaviour is in
[`../../AGENTS.md`](../../AGENTS.md) ("Rules for every change") and "Key Patterns" of
[`../features/call_arch.md`](../features/call_arch.md). This page is one way to back that
commit up.

## Fitting code

- The code decides something that cannot be undone (keep or reject a live call, as
  `HandshakeProcessor.process` in `lib/features/call/utils/handshake_processor.dart` does).
- It has many conditions, and the refactoring moves them around.
- The function is pure, or its side effects can be recorded by a fake (for `HandshakeProcessor`,
  the calls to `QueuedTerminationRequestsRepository`).

## Comparison test

1. Put the old version of the file next to the new one under another name:
   `git show origin/master:<path> > <path>_old_tmp.dart`. Its classes have the same names, so
   the test imports the two files with prefixes (`as old`, `as neu`).
2. A temporary test generates inputs from `Random(seed)` and feeds the same objects to both
   versions.
3. Compare results as strings: a `describe(Object? value)` that prints `runtimeType.toString()`
   and every field. The types from the two files are different types, so `==` does not work.
4. Record side effects with a fake (for example the removals, in order) and compare them too.
5. Use several independent seeds with tens of thousands of cases each. Print how many results
   were non-empty and how often each kind of result occurred - otherwise "they agree" may mean
   "both returned nothing".
6. Check the check: remove one condition from the new version, and the test must fail.
7. Delete the temporary files before committing, and say in the commit body that the
   comparison was run and on how many cases.

## Traps

- The generator must reach every branch. A generator that never produces, say, a conference or
  a line whose log holds the client's own requests says nothing about those branches. The
  per-kind counter from step 5 shows it.
- The frequencies are artificial. Random inputs are wider than real sessions but not like them:
  this proves the two versions equal, not that either is right.
- For a mapping (each input type to one output), the same idea is cheaper: a test that feeds
  every input type and checks the class and fields of the result, run unchanged against the code
  before the refactoring and after. If it passes on both, the behaviour is the same, and the
  test stays in the repository. `test/features/call/bloc/signaling_event_mapping_test.dart` is
  such a test for `toCallEvent` in `lib/features/call/bloc/call_signaling_event_mapping.dart`.
