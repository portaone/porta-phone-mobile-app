# Formatting and code generation traps

Ways a formatter or a generator, run to tidy one file, rewrites lines that are not yours. The
tool's own output rarely shows it; `git status` and `git diff --stat` do. Look at both after
every formatter or generator run, before the next step, and revert what is not yours at once.
Last reviewed: 2026-10-15.

Which checks to run for a change and in what order: [build_verification.md](build_verification.md).
What the git hooks run: [development.md](development.md). The l10n regeneration steps:
[localization.md](localization.md).

## `dart` from `PATH` instead of the pinned SDK

- What you do: run `dart format` or `flutter ...` as found on `PATH`.
- What happens: the SDK may not be the one in `phone/.fvmrc`, and `dart format` output can differ
  between SDK versions (the l10n check depends on this, see [localization.md](localization.md)).
- Instead: `fvm dart ...` / `fvm flutter ...` (Toolchain in [AGENTS.md](../../AGENTS.md)). To
  name the project's Flutter version, read `.fvmrc`, not `flutter --version`. The lefthook
  `phone-format` check runs the `dart` on `PATH`, so keep that one in line with `.fvmrc` too.

## `dart format` on a directory

- What you do: `fvm dart format lib/src/daos` to format the DAO you edited.
- What happens: the generated `*.g.dart` next to it are rewritten as well; in
  `packages/data/app_database/lib/src/daos` that is 15 generated files, in `packages/api` 26.
- Why: generated files are not kept at the project width, and `dart format` has no exclude
  (the `fmt` script in `phone/pubspec.yaml` filters them out with `find` for that reason).
- Instead: name the files you changed, or use `melos run fmt`, which skips `*.g.dart`,
  `*.freezed.dart` and `*.gr.dart`.

## ARB files rewritten through a JSON library

- What you do: load `lib/l10n/arb/app_*.arb` with a JSON parser, add keys, dump it back.
- What happens: every one-line metadata entry, such as
  `"@cacheManagement_Label_itemsCount": {"placeholders": {"count": {"type": "int"}}}`, is
  expanded over several lines - dozens of lines of noise per file.
- Instead: insert new keys as text before an anchor line, and use the parser only to check that
  the file still parses. Then follow the steps in [localization.md](localization.md).

## `build_runner` rewrites unrelated generated files

- What you do: a full `fvm dart run build_runner build --delete-conflicting-outputs` in `phone/`
  or `packages/api`.
- What happens: a few generated files the change has nothing to do with come out different.
  Seen with `lib/models/integration/raw_http_request.g.dart`,
  `lib/models/metrics/media_query_metrics.g.dart`,
  `packages/api/lib/src/models/call_queues/call_queue_list_response.g.dart` and
  `packages/api/lib/src/models/voicemail/user_voicemail_list_response.g.dart`.
- Instead: revert those files before committing, so the commit carries only the outputs of
  your change.

## `build_runner` after a reverted generated file

- What you do: revert a `*.g.dart` or `*.freezed.dart` with `git checkout --`, then run
  `build_runner build` again.
- What happens: it reports `wrote 0 outputs`. The model has its new field and the generated code
  does not, so tests fail rather than the build.
- Why: by its cache the output is already up to date.
- Instead: delete the reverted generated files and build again.

## `THIRD_PARTY_LICENSES.md` is out of date

- What you do: `melos run licenses:generate` (`tool/generate_licenses.dart`) after adding one
  dependency.
- What happens: the file changes by about a thousand lines, almost none of them about your
  dependency, because it has not been regenerated for a long time.
- Instead: regenerate it in a commit of its own, not inside the feature commit, so the review of
  the feature does not carry the unrelated diff.
