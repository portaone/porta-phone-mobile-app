# AGENTS.md — Architecture & Coding Standards

> For AI tools (Claude Code, GitHub Copilot, etc.) and human contributors.
> These rules apply to ALL files and ALL requests.

---

## Build & Test Commands

```bash
dart pub get                  # Install dependencies
dart analyze                  # Static analysis
dart test                     # Run test suite
dart run bin/webtrit_phone_tools.dart --help  # Run CLI locally
```

---

## 1. Critical: Clean Code

- **No Cyrillic** — strictly prohibited everywhere: source files, comments, strings, logs,
  identifiers, JSON/YAML keys, and commit messages. English only.
- **Self-documenting code** — code must be clean and self-explanatory. Do not write comments to
  describe logic or use them as visual separators. Use DartDoc strictly for public APIs.
- **No conversational filler** — output only commit-ready code without unnecessary explanations.
- **Commits** - commit form, review and hooks: see the root `AGENTS.md`.

---

## 2. Dart Standards & Formatting

- **Page width:** 120 characters (strict).
- **Quote style:** single quotes (`prefer_single_quotes: true`).
- **Callbacks:** must be single-expression only. If a callback requires multiple statements,
  extract the logic into a private method.
- **Parameters:** required named parameters MUST always be declared before optional named parameters.
- **Doubles:** avoid unnecessary `.0` literals.
- **No dead code:** remove unused variables, imports, and commented-out code before committing.
- **Avoid `dynamic`:** use explicit types wherever possible. Only use `dynamic` or `Object?` when
  genuinely necessary (e.g., JSON parsing boundaries).

---

## 3. Import Ordering

Groups separated by exactly one blank line, sorted alphabetically within each group.
Omit any section if empty. No section comments.

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:io';

// 2. External dependencies
import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

// 3. Internal/project package imports
import 'package:webtrit_phone_tools/src/commands/commands.dart';

// 4. Relative imports
import '../models/models.dart';
```

---

## 4. Barrel Files

- Each directory with multiple files must export its contents via a `<directory_name>.dart` barrel.
- Barrel files list exports in alphabetical order.
- Do not re-export symbols that are purely internal implementation details.

---

## 5. Error Handling & Logging

- Use the injected `Logger` instance (from `mason_logger`) for all terminal output.
  Never use `print()` or `stdout.write()` directly.
- **Log levels:**
  - `logger.info()` — progress/status updates
  - `logger.success()` — completion messages
  - `logger.err()` — error messages visible to the user
  - `logger.detail()` — verbose/debug output
  - `logger.progress()` — spinner for long-running operations (always call `.complete()` or `.fail()`)
- **Exit codes:** commands must return `ExitCode.success.code` (0) or an error code such as
  `ExitCode.usage.code` (64), `ExitCode.data.code` (65) or `ExitCode.software.code` (70) from
  `run()`. Never call `exit()` directly from within a command.
- **Exceptions:** catch specific exception types, not bare `catch (e)`. Always log before rethrowing.

---

## 6. CLI Command Rules

### 7.1 Structure

- All leaf commands extend `Command<int>`.
- Sub-command groups extend `Command<int>` and register children via `addSubcommand(...)`.
- `run()` always returns `Future<int>` or `int`.
- All top-level commands are registered in `WebtritPhoneToolsCommandRunner` via `addCommand(...)`.

### 7.2 Argument & Option Parsing

- Prefer named options over positional args for all non-trivial inputs.
- Use `argParser.addOption()` with `mandatory: true` for required inputs.
- Provide sensible `defaultsTo` values for optional flags.
- Every `addOption()` and `addFlag()` must include a descriptive `help:` string.
- Always resolve `argResults` inside `run()`, not in the constructor.

### 7.3 Validation

- Validate all user-provided inputs (file paths, URLs, identifiers) at the beginning of `run()`
  before any I/O or process spawning.
- Log a clear error via `logger.err()` and return `ExitCode.usage.code` on invalid input.

### 7.4 Dependency Injection in Commands

- Commands receive all external dependencies (`Logger`, `HttpClient`, `PubUpdater`, runners such
  as `FlutterRunner`) via their constructor.
- Store as `final` private fields (e.g., `final Logger _logger`).
- `WebtritPhoneToolsCommandRunner` constructs and injects `Logger`, `HttpClient` and `PubUpdater`;
  a runner is an optional argument the command defaults itself when it is not passed.

### 7.5 Command Naming

- Lowercase, hyphen-separated: `configurator-setup`, `configurator-resources`.
- `description` and `summary` must be set on every command for `--help` output.

### 7.6 Testing

- Every command has a corresponding test file in `test/src/commands/`.
- Tests use `mocktail` to mock `Logger`, `PubUpdater`, `HttpClient`, and other injected dependencies.
- Test end-to-end: register the command on a bare `CommandRunner<int>('test', 'test')` with mocked
  constructor arguments, invoke `run(['command', '--flag', 'value'])`, and assert on exit code and
  logger interactions. Only `command_runner_test.dart` and `update_command_test.dart` construct
  `WebtritPhoneToolsCommandRunner` itself.
- Use `setUp`/`tearDown` for lifecycle management.

### 7.7 Simple vs Orchestrated Commands

- **Simple commands** (single responsibility, minimal I/O): implement logic directly in the
  `Command` subclass without subdirectories.
  Examples: `update_command.dart`
- **Complex commands** (multi-step: API + file I/O + external processes): use the
  **Orchestrator Pattern** described in section 8 below.
  Examples: `app_resources/`, `app_configure/`, `app_setup/`

---

## 7. Orchestrator Pattern (Complex Commands)

### 8.1 Layer Responsibilities

| Layer            | Naming                            | Responsibility                                                                |
|------------------|-----------------------------------|-------------------------------------------------------------------------------|
| **Command**      | `<Name>Command`                   | Parses CLI args, validates input, builds `Context`, delegates to layers below |
| **Context**      | `<Name>Context`                   | Immutable validated state; passed between all layers                          |
| **Service**      | `<Name>Fetcher` / `<Name>Service` | Fetches remote data (API calls); pure I/O, no business logic                  |
| **Processor**    | `<Name>Processor`                 | Transforms/writes data (file I/O, JSON manipulation, asset downloads)         |
| **Runner**       | `<Name>Runner`                    | Executes external processes (`flutter`, `dart`, `fluttergen`, `flutterfire`) |
| **Factory/Util** | `<Name>Factory` / `<Name>Util`    | Pure stateless helpers; no side effects                                       |

### 8.2 Layer Rules

- **Context is immutable** — never mutate a `Context` after creation. Pass additional data explicitly.
- **No cross-layer skipping** — `Command` must not call a `Runner` directly without going through
  a `Processor` or `Service` when applicable.
- **Services are pure fetchers** — no file I/O or process spawning; only remote API calls.
- **Processors own file I/O** — all file reading/writing lives in `Processor` classes only.
- **Runners own process spawning** — all `Process.start()` / `Process.run()` calls live in
  `Runner` classes only.

### 8.3 Directory Structure

```
lib/src/commands/<feature_name>/
├── <feature_name>.dart              # Barrel export
├── <name>_command.dart              # Main command class
├── models/
│   ├── models.dart
│   └── <name>_context.dart
├── services/                        # optional — only if API calls are needed
│   ├── services.dart
│   └── <name>_fetcher.dart
├── processors/                      # optional — only if file I/O is needed
│   ├── processors.dart
│   └── <name>_processor.dart
├── runners/                         # optional — only if external processes are needed
│   ├── runners.dart
│   └── <name>_runner.dart
└── utils/                           # optional — only if feature-specific helpers are needed
    ├── utils.dart
    └── <name>_util.dart
```

### 8.4 External Process Execution

- Use `Process.start()` for long-running processes that stream output (e.g., `flutterfire configure`).
- Use `Process.run()` for short operations awaited to completion (e.g., `flutter gen-l10n`).
- Always check exit code and log errors before propagating failures.
- Never hardcode absolute binary paths; rely on the system `PATH`.

### 8.5 HTTP & Retry

- Every configurator call a command makes goes through the CLI's own `HttpClient`
  (`lib/src/utils/http_client.dart`, built on `package:http`): `getBuildBundle`, `getTranslationFiles`,
  `getCatalogTranslationFiles`. `ConfiguratorClient` (`lib/src/configurator/`) is covered by tests but
  no command uses it. `FontAssetProcessor` downloads fonts with its own `http.Client` and retry.
- `HttpClient` retries 5xx responses and `http.ClientException` up to 3 times, after 5, 15 and 30
  seconds plus jitter.
- Fast-fail (do not retry) on 4xx client errors, especially 401 Unauthorized.

---

## 8. Extension Methods

- Extension classes live in `lib/src/extension/`.
- Each file contains exactly one extension, named `<type>_extension.dart`.
- Extensions must be pure (no side effects, no I/O).
- All extensions are exported via `lib/src/extension/extension.dart`.

---

## 9. Tech Stack

| Dependency          | Version     | Purpose                                  |
|---------------------|-------------|------------------------------------------|
| `args`              | ^2.7.0      | CLI argument parsing                     |
| `cli_completion`    | ^0.5.1      | Shell completion support                 |
| `mason_logger`      | ^0.3.3      | Terminal output with colors/spinners     |
| `path`              | ^1.9.1      | Cross-platform path handling             |
| `pub_updater`       | ^0.5.0      | `update`: asks pub.dev, where this package is not published |
| `http`              | ^1.6.0      | All HTTP (`HttpClient`, fonts)           |
| `archive`           | ^4.0.7      | ZIP/archive handling                     |
| `yaml`              | ^3.1.3      | YAML parsing                             |
| `theme_schema` (local) | path: ../phone/packages/theme_schema | Declared; nothing under `lib/` imports it |
| `test`              | ^1.25.15    | Unit/integration tests                   |
| `mocktail`          | ^1.0.4      | Mocking in tests                         |
