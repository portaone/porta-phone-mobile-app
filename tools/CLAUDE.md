# CLAUDE.md — Claude Code Navigation Guide

Start here, then load the full standards:

- **@AGENTS.md** — complete architecture, coding standards, CLI patterns, Orchestrator Pattern

---

## Project Overview

`webtrit_phone_tools` is a Dart CLI toolkit for managing WebTrit Phone application configuration,
keystores, and resources. It is a standalone Dart executable (not a Flutter app).

Entry point: `bin/webtrit_phone_tools.dart`
Command runner: `lib/src/command_runner.dart`
Commands: `lib/src/commands/`

---

## Gotchas

- **No Flutter** — this is a pure Dart CLI. Do not use Flutter APIs, widgets, or `BuildContext`.
- **No `print()`** — all output goes through the injected `Logger` from `mason_logger`.
- **No `exit()` in commands** — return exit codes from `run()` instead.
- **Local dependencies** - `theme_schema` lives at `../phone/packages/theme_schema` and the lint
  rules (`webtrit_analysis`) at `../analysis`, both in this repository.
  Both must be present locally for `dart pub get` to succeed.
- **Callbacks must be single-expression** — multi-line callback bodies must be extracted to private
  methods. This is enforced by code review.
- **Commit form** - see the root `AGENTS.md`; `scripts/commit-subject-check.sh` refuses Conventional
  Commits subjects at pre-push.
