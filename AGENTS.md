# AGENTS.md

The PortaPhone mobile application, the call plugin it runs on and the CLI that brands it, in
one Gerrit repository. This page holds what is true for every package; each package's own
`AGENTS.md` loads when you read files there and carries its rules.

## Layout

```
phone/        the Flutter app and its packages       phone/AGENTS.md
callkeep/     the call plugin, per-platform packages  callkeep/AGENTS.md
tools/        the Dart CLI that configures a brand    tools/AGENTS.md
analysis/     the lint rules tools/ includes          analysis/README.md
docs/         Gerrit pages: push, chain rework, checks
scripts/      gerrit-push.sh, commit-subject-check.sh
.jenkins/     the Gerrit check pipelines; Dockerfile holds their stages
.claude/      settings, hooks, skills
lefthook.yml  the git hooks of every package
```

Work inside the package a change belongs to. Anything that resolves paths from the git root -
lefthook, `.claude/`, `scripts/` - is configured here only; a copy inside a package is read by
nothing.

## Git

Gerrit serves the repository; GitHub is a read-only mirror and runs nothing. A change is one
commit, a correction is `git commit --amend` - a new patchset of the same change - and there are
no pull requests. A merged commit is never amended or force-pushed.

- Subject: `WT-1234 Capitalised summary` - ticket, one space, capital letter, imperative, no
  full stop, 50 characters including the ticket, no conventional type (`fix: ...`). Test: drop
  the ticket, lower the first letter, and "If applied, this commit will <subject>" reads as
  English.
- The subject is an index entry: the component and what happened to it, so the line says which
  file to open (`Drop checksum from the asset patch request`).
- Body wrapped at 72, saying why rather than how. The ticket is the one of the task in hand;
  another ticket id anywhere in the message links the commit to that ticket.
- `Change-Id` comes from Gerrit's `commit-msg` hook; a commit without one is refused.
  `git commit --amend -F <file>` with a file that lacks it opens a second change.
- Push only through `scripts/gerrit-push.sh`: `--dry-run` first, show the commits, the target
  and the topic, wait for a yes, then push. It runs the gate, pushes with the ticket topic only
  if the gate passed, and checks what the server holds.
- Background: `git wip`, `git review` and `git ready` are aliases that `setup-devel-tools.sh`
  installs into a clone's git config. They push `HEAD` to `refs/for/<upstream>` with `%wip`,
  no mark or `%ready`, and send no topic; `%wip` puts WIP back on a change already in review.

The department rules are in [phone/CONTRIBUTING.md](phone/CONTRIBUTING.md).

## Hooks

- `lefthook.yml` (`lefthook install` once). On commit it checks Dart formatting in `phone/`,
  `tools/` and `analysis/`, and in `callkeep/` rewrites Dart, Kotlin (`ktlint`) and Markdown.
  On push it runs `scripts/commit-subject-check.sh`, then analyze, l10n and tests per package,
  each only when the pushed files touch that package. What it does not guarantee - scoping from
  a stale local `master`, steps that pass without checking, package tests it never runs:
  [docs/gerrit_push.md](docs/gerrit_push.md#the-gate).
- `.claude/` - hooks that format a Dart or Markdown file after it is written, add a final
  newline and refuse access to keystores, keys and `.env` files; and
  `.claude/skills`, a link to the skills.
- `.agents/skills/` - the skills, each a procedure for one kind of change, in the place
  Codex, Copilot and other agents read; Claude reads them through `.claude/skills`.
- `.mcp.json` - the Dart and Flutter MCP server (`scripts/dart-mcp-server.sh`, the SDK
  `phone/.fvmrc` pins): analyzer diagnostics, symbol lookup, test runs, and hot reload or
  the widget tree of a running app. Prefer its `analyze_files` and `run_tests` over shell
  commands when it is connected.

## Checks

Four Jenkins jobs in `.jenkins/` vote Verified on every patchset. They run unit tests only -
no analyze, format or l10n check - and only when the patchset touches their paths:
[.jenkins/README.md](.jenkins/README.md), and what fails them without a fault in the change,
[docs/gerrit_checks.md](docs/gerrit_checks.md).

## Rules for every package

- English and ASCII only in source, comments, logs, strings, keys and commit messages;
  Cyrillic only in the translation values of `phone/lib/l10n/arb/*.arb`.
- A comment says why, in full, for a reader without our tickets: never a ticket id or "see
  the report".
- No agent attribution: no `Co-Authored-By` lines, no "generated with" notes.
- Never edit generated files - regenerate them: `*.g.dart`, `*.freezed.dart`, `*.gr.dart`,
  `*.pigeon.dart` and the Pigeon Kotlin and Objective-C output (`Generated.kt`, `Generated.h`,
  `Generated.m` in `callkeep/`), the l10n output in `phone/lib/l10n/`, and
  `tools/lib/src/version.dart`.

## Before a particular change

| You are about to | Read first | Skill |
|---|---|---|
| push a change, a chain, a patchset or a tag | [gerrit_push.md](docs/gerrit_push.md) | `gerrit-push` |
| fix a lower commit, split or rebuild a chain in review | [gerrit_chain_rework.md](docs/gerrit_chain_rework.md) | `gerrit-chain-rework` |
| cut a release or a patch build | [release.md](phone/docs/guides/release.md), [hotfix_builds.md](phone/docs/guides/hotfix_builds.md) | `release-cut` |
| read a red Jenkins vote | [gerrit_checks.md](docs/gerrit_checks.md), [.jenkins/README.md](.jenkins/README.md) | |
| bump Flutter: `phone/.fvmrc` and `FLUTTER_VERSION` / `FLUTTER_SHA256` in `Dockerfile`, one commit | [build.md](phone/docs/guides/build.md#flutter-version-configuration), [.jenkins/README.md](.jenkins/README.md) | |
