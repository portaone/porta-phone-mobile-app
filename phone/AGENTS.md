# AGENTS.md - phone

WebTrit Phone, the Flutter VoIP app: `lib/` is the app, `packages/` the libraries it is built
from. This page holds what is true for every change here and says where to read before a
particular kind of change. The explanations live in `docs/` (map: [docs/README.md](docs/README.md))
and in each package's own `AGENTS.md`, which loads when you read files in that package.

## Layout

```
lib/                 the app: features/, app/ (router, keys), blocs/, repositories/, models/,
                     services/, theme/, l10n/; bootstrap.dart builds the process-long objects
packages/            libraries; they never import from lib/
  api/               Core REST client
  signaling/         signaling protocol client
  signaling_service/ the connection the app keeps open, per platform
  data/app_database/ Drift database and DAOs
  theme_schema/      theme DTOs and their JSON schema
  ...                each with its own AGENTS.md
../callkeep/         the call plugin, a path dependency (callkeep/ of this repository)
test/                unit and widget tests; integration_test/, patrol_test/ for devices
docs/                architecture/, guides/, reference/, features/
```

## Toolchain

- Flutter is pinned in `.fvmrc` and, for the Jenkins checks, in the root `Dockerfile`
  (`FLUTTER_VERSION`, `FLUTTER_SHA256`). A bump changes both in one commit. Older release
  branches may carry `.github/flutter_version.yaml` instead; the builder falls back to it.
- Run `fvm flutter ...` / `fvm dart ...`: a bare `flutter` or `dart` from `PATH` may be another
  version and formats and generates differently. The git hooks call `dart` from `PATH`, so
  keep it the same version. `fvm install` once per machine.
- A new clone or worktree lacks files a build needs: [fresh_checkout.md](docs/guides/fresh_checkout.md).

## Commands

```bash
melos bootstrap                          # dependencies of every package
melos run check                          # format check, analyze, l10n check
melos run test                           # tests of every package
fvm flutter test                         # the app's tests (from phone/)
fvm dart run build_runner build --workspace   # codegen, every workspace member
```

- Every `flutter build` needs `--dart-define-from-file=dart_define.json` and
  `--no-tree-shake-icons`; without the second a release build fails only after the whole
  compile. `melos run build:*` passes both; type them for web. There are no build flavors:
  `dart_define.json` alone switches the optional manifest features
  ([optional_features.md](docs/reference/optional_features.md)).
- Which check proves which change and what each costs:
  [build_verification.md](docs/guides/build_verification.md). Run format, analyze and test
  before any build.

## Rules for every change

Code:

- English and ASCII only in source, comments, logs, strings and keys; Cyrillic only in the
  translation values of `lib/l10n/arb/*.arb`.
- A comment says why - the rationale, the platform fact, the failure it guards against - in
  full, for a reader without our tickets: never a ticket id or "see the report". DartDoc on
  public API.
- No DI framework or service locator (`get_it`, `injectable`). Dependencies go in through
  constructors and `Provider` / `RepositoryProvider`.
- Never edit generated files (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`, the l10n output) -
  regenerate them, and commit only what your change regenerated
  ([format_and_codegen.md](docs/guides/format_and_codegen.md)).
- Single quotes, 120 columns, required named parameters before optional ones, callbacks of a
  single expression (extract the rest into a private method). Imports in six groups, a blank
  line between, alphabetical inside: Dart SDK, Flutter SDK, external, internal packages,
  `package:webtrit_phone/...`, relative.
- `super.initState()` first, `super.dispose()` last, dispose in reverse creation order;
  `withValues(alpha: ...)`, not `withOpacity`; elevation through `Card`, not a `Container`
  with a shadow; no raw `Colors.*` or `TextStyle` in widgets -
  `Theme.of(context).extension<T>()`.
- Widgets are `StatelessWidget` classes, not helper methods; dumb widgets sit in
  `features/*/view/widgets/`.

State and lifetime:

- State classes are `@freezed`; events are `sealed class` + `Equatable`, never freezed.
- Never pass a `BuildContext` into a bloc or service. A callback may close over
  `context.l10n` only if it runs later; calling `context.l10n` inside `BlocProvider.create`
  throws.
- A bloc that awaits must not write back the `state` it read before the await, and must not
  emit after `close()`: [bloc_async_state.md](docs/architecture/bloc_async_state.md).
- Bookkeeping a bloc carries between events - per-call maps, timers, retry counters, pending
  offers - is a class of its own with its own tests (`RoomOfferWait`, `DebounceMap`), not raw
  fields; a flow already spread over a bloc is extracted first, in a commit that changes no
  behaviour ([call_arch.md, Key Patterns](docs/features/call_arch.md#key-patterns)).
- What lives for the process is built by `bootstrap()` and released only by
  `AppDependencies.dispose()`; a provider disposes only what its own `create:` built
  ([dependency_ownership.md](docs/architecture/dependency_ownership.md)).
- New code reaches the database through DAOs, not through `AppDatabase` tables; Drift classes
  stay in the repository layer (the exceptions: `packages/data/AGENTS.md`). Tests use `mocktail` / `MockClient`, never the network.
- The `AppRouter.routes` tree is complete from the start: never declare a route conditionally
  on a capability, login or flag - the collection is built once, before `system-info`, and a
  route left out then throws on navigation. Declare every variant; choose at navigation time
  (guards, `AutoTabsRouter.routes`). Siblings may share a `path` - only route names must be
  unique.

UI (a control shipped without this is a defect):

- Every interactive control has a name from l10n and, where automation reaches it, an id
  from `lib/app/keys.dart`: `SemanticAction` for a control, `SemanticId` for an anchor or a
  text field, `CallActionButton` in a call; never a bare `Semantics(identifier:)` around a tap
  target. Every screen with controls has a `*_semantics_test.dart` that taps through
  semantics. The rules, the wrappers and the traps:
  [accessibility.md](docs/guides/accessibility.md).
- Renaming in `keys.dart` breaks `patrol_test/` and `integration_test/` silently - they are
  outside analysis; grep them.
- A new or changed string goes into all four ARB files in the same change, with the key form
  `<bloc>_<Widget><Fields>[_<variant>]`: [localization.md](docs/guides/localization.md).

## Before a particular change

| You are about to | Read first | Skill |
|---|---|---|
| change `CallBloc`: an event, handler, mutation, handshake step | [call_arch.md](docs/features/call_arch.md), [bloc_async_state.md](docs/architecture/bloc_async_state.md) | `callbloc-change` |
| write the test for a fix in calls | [call_arch.md](docs/features/call_arch.md) | `call-tests` |
| send something over signaling | [request_queue.md](packages/signaling_service/docs/request_queue.md), [signaling_architecture_target.md](docs/architecture/signaling_architecture_target.md) | `callbloc-change` |
| touch how an incoming call arrives (push, background, socket) | [incoming_call_scenarios.md](docs/architecture/incoming_call_scenarios.md) | |
| replace or rebuild `MainShell` for the same sign-in | [session_remount.md](docs/architecture/session_remount.md) | |
| call a new Core endpoint, react to a Core error | [core_error_codes.md](docs/architecture/core_error_codes.md), `packages/api/AGENTS.md` | `core-endpoint` |
| hide a feature behind a capability or a per-user answer | [feature_gates.md](docs/architecture/feature_gates.md), [feature_access.md](docs/features/feature_access.md) | `core-endpoint` |
| add a theme property or a theme DTO | `packages/theme_schema/AGENTS.md` (recipes, schema contract rules) | |
| refresh data periodically or on resume | [polling.md](docs/architecture/polling.md), [data_refresh.md](docs/architecture/data_refresh.md) | |
| change a table or a column | `packages/data/AGENTS.md`, [schema_changes.md](packages/data/docs/schema_changes.md), [query_traps.md](packages/data/docs/query_traps.md) | `drift-schema-change` |
| add or change a string, run a generator or the formatter | [localization.md](docs/guides/localization.md), [format_and_codegen.md](docs/guides/format_and_codegen.md) | `codegen-l10n` |
| use a Material widget, write a dialog or a widget test | [material_ui.md](docs/guides/material_ui.md) | |
| lay a screen out for landscape | [adaptive_layout.md](docs/architecture/adaptive_layout.md) | |
| refactor without changing behaviour | [refactor_equivalence.md](docs/guides/refactor_equivalence.md) | |
| raise a minimum OS or SDK version | [platform_versions.md](docs/reference/platform_versions.md) | |
| change the call plugin | `../callkeep/AGENTS.md` | `callkeep-android-change`, `callkeep-ios-change` |
| cut a release or a patch build | [release.md](docs/guides/release.md), [hotfix_builds.md](docs/guides/hotfix_builds.md) | `release-cut` |
| push, or rework a chain in review | [gerrit_push.md](../docs/gerrit_push.md), [gerrit_chain_rework.md](../docs/gerrit_chain_rework.md) | `gerrit-push`, `gerrit-chain-rework` |

## Before handing over

- `fvm dart format`, `fvm flutter analyze` and `fvm flutter test` are clean in every package
  you touched. The pre-push gate runs analyze and the tests of `phone/` itself, and the tests
  of `text_entities` and `link_preview`; the tests of every other package (`theme_schema`,
  `phone_number`, `app_database` with its migrations, ...) run only in Jenkins - run them in
  the package by hand.
- What the gate does not prove:
  - `tool/scripts/semantics-gate.sh` looks for `origin/develop`, which a Gerrit clone does not
    have, so it prints "skipping" and checks nothing - check the semantics rules yourself;
  - `patrol_test/` is not analysed.
- The doc of a feature changes in the same change as the feature.

## Writing docs

- A page goes by what it is for: `docs/architecture/` a mechanism several features share,
  `docs/guides/` a procedure, `docs/reference/` names a reader looks up, `docs/features/` one
  feature (indexed by `docs/features/features.md`). Add the page to its folder's README and to
  `docs/README.md`.
- A feature `<name>` (kebab-case) is one `docs/features/<name>.md`; a grown one splits into
  `<name>_ux.md` (what the user does, screen states) and `<name>_arch.md` (bloc, events,
  flows), and the plain page goes.
- Each page opens with a one-line summary and a `Last reviewed:` date, describes current
  behaviour first and unfinished work under a marked "Redesign / in progress" section, links
  code and sibling pages by relative path, and is plain ASCII.
