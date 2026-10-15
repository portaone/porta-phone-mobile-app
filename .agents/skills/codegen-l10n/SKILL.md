---
name: codegen-l10n
description: Runs the generators and the formatter of the phone app through the pinned SDK and keeps their side rewrites out of the change - `build_runner`, `flutter gen-l10n`, `dart format` - and adds or changes a localized string in the four ARB files. Load it when a request mentions build_runner, codegen, regenerate, `.g.dart`/`.freezed.dart`, gen-l10n, l10n, ARB, translation, a new string or key, the l10n mapper, `check_l10n`, or `dart format`.
---

# Codegen, formatting and l10n

When: a freezed/json model, route, asset or ARB file changed and generated code must follow,
or Dart files need formatting before a commit.

## Steps

1. Once per checkout: `fvm install`, then `fvm flutter pub get` in `phone/` before any format
   or generator run ([fresh_checkout.md](../../../phone/docs/guides/fresh_checkout.md#first-step)).
2. Everything goes through the SDK in `phone/.fvmrc`: `fvm dart ...`, `fvm flutter ...`, and
   `fvm exec melos run <script>` for the melos scripts in `phone/pubspec.yaml`.
3. Format only what you changed: `fvm dart format <file> <file>`, or `fvm exec melos run fmt`,
   which skips `*.g.dart`, `*.freezed.dart`, `*.gr.dart`. Never `dart format` a directory that holds generated
   files; `lib/l10n` below is the one exception, as `l10n:generate` formats it that way.
4. Code generation: `fvm dart run build_runner build --delete-conflicting-outputs` in the
   package whose sources changed - `phone/`, `phone/packages/api`,
   `phone/packages/theme_schema` or `phone/packages/data/app_database`. In `phone/` one run
   rewrites `*.g.dart`, `*.freezed.dart`, `lib/app/router/app_router.gr.dart`,
   `lib/app/assets.gen.dart` and `lib/l10n/app_localizations.g.mapper.dart`.
5. Right after every generator or formatter run: `git status --short` and `git diff --stat`;
   revert every file that is not an output of your change
   ([format_and_codegen.md](../../../phone/docs/guides/format_and_codegen.md)).

Adding or changing a string (`phone/`, procedure in
[localization.md](../../../phone/docs/guides/localization.md#adding-or-changing-a-key)):

6. Name the key `<bloc>_<Widget><Fields>[_<variant>]` (`lobby_AppBarTitle`) ([phone/AGENTS.md](../../../phone/AGENTS.md)).
   Insert it as text, before an anchor key, in `lib/l10n/arb/app_en.arb` (with its `@key`
   metadata) and at the same place in `app_uk.arb`, `app_it.arb`, `app_th.arb` - all four in
   the same change.
7. `fvm exec melos run l10n:generate` (gen-l10n, then format of `lib/l10n` at 120).
8. `fvm dart run build_runner build --delete-conflicting-outputs` for the mapper, then
   `fvm dart format --line-length 120 lib/l10n` again, since build_runner writes at 80.
9. `fvm dart tool/check_l10n.dart` - must print no findings and exit 0.
10. Commit the four ARB files with `lib/l10n/app_localizations*.g.dart` and
    `lib/l10n/app_localizations.g.mapper.dart`, nothing else from the generator run.
11. A reworded existing string does not reach customers by itself:
    [localization.md](../../../phone/docs/guides/localization.md#how-these-files-reach-a-customer).

## Before handing over

- `git diff --numstat -- phone/lib/l10n/arb` shows only added lines for a new key, about the
  same count in each of the four files.
- `git status --short` lists only files your change explains; no stray `*.g.dart`.
- `fvm dart tool/check_l10n.dart` and `fvm flutter analyze` pass, and printed real output.
- The generated diff of `lib/l10n/*.g.dart` is a few lines per key, not thousands.

## Traps

- `dart`/`flutter` from `PATH` can be another SDK and formats differently; the lefthook
  `phone-format` and `phone-l10n` checks and `.claude/hooks/dart_formatter.sh` all call the
  bare `dart`, so keep `PATH` on the `.fvmrc` version - [format_and_codegen.md](../../../phone/docs/guides/format_and_codegen.md).
- `dart format lib/...` rewrites every generated file in that directory (26 in `packages/api`):
  name files or use `melos run fmt` - [format_and_codegen.md](../../../phone/docs/guides/format_and_codegen.md).
- Formatting before `pub get` falls back to width 80 and rewraps untouched lines: `pub get`
  first, `git checkout` the file and redo the edit if it happened - [fresh_checkout.md](../../../phone/docs/guides/fresh_checkout.md#first-step).
- Loading an ARB with a JSON library and dumping it back expands every one-line `@key` entry:
  insert as text, parse only to check - [format_and_codegen.md](../../../phone/docs/guides/format_and_codegen.md).
- Bare `flutter gen-l10n` writes at 80 columns and buries the change in rewrapping: use the
  melos script - [localization.md](../../../phone/docs/guides/localization.md#adding-or-changing-a-key).
- gen-l10n without build_runner leaves the mapper behind; `parseL10n` fails silently at
  runtime and the pre-push l10n check goes red - [localization.md](../../../phone/docs/guides/localization.md#validation).
- A key added to three locales only fails the check; add uk, it and th with en, never later -
  [localization.md](../../../phone/docs/guides/localization.md#validation).
- A full build_runner run rewrites a few unrelated `.g.dart` files: revert them before the
  commit - [format_and_codegen.md](../../../phone/docs/guides/format_and_codegen.md).
- `build_runner --build-filter=lib/l10n/*` deletes outputs outside the filter, such as
  `app_router.gr.dart`: run the full build and revert instead - [format_and_codegen.md](../../../phone/docs/guides/format_and_codegen.md).
- After `git checkout` of a generated file build_runner says `wrote 0 outputs`: delete the
  file and build again - [format_and_codegen.md](../../../phone/docs/guides/format_and_codegen.md).
- `=1` and `one` in one plural collide, and a uk `one` without `{count}` is read for 21 too;
  `check_l10n` catches neither - [localization.md](../../../phone/docs/guides/localization.md#traps).
- Rewording an existing key here does not change what customers get; the configurator
  catalog keeps the old value - [localization.md](../../../phone/docs/guides/localization.md#adding-or-changing-a-key).
- An ASCII `'` inside a plural or select form is an ICU escape and breaks gen-l10n (Italian
  `dell'ultimo`): write U+2019 there, as `logRecordsConsole_Text_recordsCountHint` in `app_it.arb` does.
- A command that printed nothing and exited 0 did not run (missing SDK, wrong directory):
  re-run with `fvm install` done and check for real output - [build.md](../../../phone/docs/guides/build.md).
