# AGENTS.md - callkeep

The call plugin of the app: a federated Flutter plugin that hands call presentation and control
to Telecom on Android and CallKit on iOS. This page holds what is true for every change here and
says where to read before a particular kind of change. What the plugin does and its public API
are in [README.md](README.md); each package's own `AGENTS.md` loads when you read files there.

## Layout

```text
webtrit_callkeep/                     the package the app imports: Callkeep, AndroidCallkeepServices,
  example/integration_test/           AndroidCallkeepUtils; integration tests on a device
webtrit_callkeep_platform_interface/  WebtritCallkeepPlatform, models, delegates, consts (pure Dart)
webtrit_callkeep_android/             Dart + Kotlin; pigeons/ is the Android Pigeon definition; docs/
webtrit_callkeep_ios/                 Dart + Objective-C; pigeons/ is the iOS Pigeon definition
webtrit_callkeep_web/                 in-memory implementation, no system call UI
webtrit_callkeep_linux|macos|windows/ stubs: the base class's UnimplementedError
tool/pigeon.sh                        regenerates one platform package's Pigeon output
docs/                                 release_process.md, external-flutter-engines.md,
                                      sms_trigger_regex_requirements.md, ios-call-waiting-tone.md
```

## Toolchain

- callkeep has no Flutter pin of its own: use the SDK `../phone/.fvmrc` pins (the Jenkins image
  installs the same). `fvm` does not find that file from here; its root is
  `(cd ../phone && fvm flutter --version --machine | jq -r .flutterRoot)`.
- Pigeon `29.0.1` (`pubspec.yaml` of the android and ios packages); run it only through
  `../tool/pigeon.sh`, which also strips the trailing whitespace the generators leave.
- Kotlin: ktlint `1.8.0` through the Gradle plugin (`ktlintCheck`); the pre-commit hook runs
  `ktlint --format` from `PATH` and excludes `Generated.kt`.
- Markdown: `markdownlint-cli2` run from `callkeep/`, which holds its config.
- The Gradle module resolves Flutter through `webtrit_callkeep_android/android/local.properties`
  (`flutter.sdk=<path>`, gitignored). Without it the lefthook `callkeep-android-test` prints
  `skipped:` and exits 0.

## Commands

Inside a package, after `flutter pub get`:

```bash
dart format --line-length 120 --set-exit-if-changed $(git ls-files 'lib/*.dart' 'test/*.dart' ':!:*.pigeon.dart')
flutter analyze
flutter test                     # webtrit_callkeep_platform_interface has no test/
../tool/pigeon.sh                # in webtrit_callkeep_android/ or webtrit_callkeep_ios/
```

In `webtrit_callkeep_android/android`: `./gradlew testDebugUnitTest`, `./gradlew lintDebug`,
`./gradlew ktlintCheck`.

In `webtrit_callkeep/example`: `flutter test integration_test/<file>.dart -d <device>` on a
phone (`./run_integration_tests.sh` runs every file in isolation on Android, `--web` in Chrome);
`flutter build ios --debug --no-codesign` compiles the Objective-C.

## Rules for every change

- English and ASCII only in code, comments, logs and docs. A comment says why, for a reader
  without our tickets.
- Single quotes, 120 columns, trailing commas on multi-line lists; imports in four groups
  (`dart:`, `package:flutter/`, other packages, relative), a blank line between.
- The only generated code is Pigeon output: `callkeep.pigeon.dart` and `Generated.kt` in the
  android package, `callkeep.pigeon.dart`, `Generated.h` and `Generated.m` in the ios package.
  Never edit it; change the definition, regenerate, and commit both together.
- There are two Pigeon definitions, `webtrit_callkeep_android/pigeons/callkeep.messages.dart`
  and `webtrit_callkeep_ios/pigeons/callkeep.messages.dart`. A shared type changes in both, in
  the same commit.
- The app imports only `package:webtrit_callkeep`; nothing is imported from a platform package
  or the platform interface directly. No Pigeon type leaves a platform package.
- A new method goes through every layer in one change: the default in
  `WebtritCallkeepPlatform` (throws `UnimplementedError`), the wrapper in `webtrit_callkeep`,
  the Pigeon method, converter and native code in the android and ios packages, the web
  implementation when web must answer it, and its row in
  [webtrit_callkeep_android/docs/pigeon-apis.md](webtrit_callkeep_android/docs/pigeon-apis.md).
  The desktop stubs keep the base default.
- A function the native side starts a Dart isolate in is top-level and
  `@pragma('vm:entry-point')`, or release builds strip it.
- The consts in `webtrit_callkeep_platform_interface/lib/src/consts/` are mirrored by hand in
  `webtrit_callkeep_android/android/.../common/Consts.kt`; nothing generates or checks it
  (`build.yaml` names a generator that does not exist). Change both.
- `webtrit_callkeep` is not a pure pass-through: `Callkeep` keeps the ends reported for calls
  the app never held (`wasEndedBeforePresented`) and drops their late presentation before the
  delegate. Logic of that kind is tested in `webtrit_callkeep/test/`.
- A `perform*` delegate method returns `false` to refuse: on iOS the CallKit action fails and
  the system UI goes back; Android discards the answer. It never ends the call.

## The phone dependency

`phone/pubspec.yaml` declares `webtrit_callkeep` as `path: ../callkeep/webtrit_callkeep` on every
branch; callkeep is not tagged, so a phone commit builds with the callkeep beside it. The
`version:` in `webtrit_callkeep/pubspec.yaml` is the plugin's version (the platform packages are
not versioned); it changes only at an app release, in a commit of its own,
`<ticket> Bump callkeep to A.B.C`, together with the `webtrit_callkeep` entry of
`phone/pubspec.lock`. See [docs/release_process.md](docs/release_process.md) and
[callkeep_dependency.md](../phone/docs/reference/callkeep_dependency.md).

## Before a particular change

| You are about to | Read first | Skill |
| --- | --- | --- |
| change Kotlin, the Android Pigeon definition, the manifest, a service or notification | [architecture.md](webtrit_callkeep_android/docs/architecture.md), `webtrit_callkeep_android/AGENTS.md` | `callkeep-android-change` |
| change Objective-C, the iOS Pigeon definition, call groups, hold or mute on iOS | [webtrit_callkeep_ios/README.md](webtrit_callkeep_ios/README.md), `webtrit_callkeep_ios/AGENTS.md` | `callkeep-ios-change` |
| add or change a method of the public API | `webtrit_callkeep_platform_interface/AGENTS.md`, [pigeon-apis.md](webtrit_callkeep_android/docs/pigeon-apis.md) | both of the above |
| host callkeep on an engine of your own | [external-flutter-engines.md](docs/external-flutter-engines.md) | |
| change the SMS call trigger | [sms_trigger_regex_requirements.md](docs/sms_trigger_regex_requirements.md) | `callkeep-android-change` |
| bump the plugin version at a release | [release_process.md](docs/release_process.md) | `release-cut` |
| push a change | [gerrit_push.md](../docs/gerrit_push.md) | `gerrit-push` |

## Before handing over

- Format, analyze and test are clean in every package you touched; for Kotlin also
  `testDebugUnitTest` (ending in `BUILD SUCCESSFUL`, not `skipped:`), `lintDebug` and
  `ktlintCheck`; `cd ../phone && fvm flutter test` passes.
- What the gate does not prove:
  - lefthook `callkeep-analyze` covers `webtrit_callkeep`, the platform interface, android and
    ios only, and `callkeep-test` runs only the android package's Dart tests;
  - `callkeep-android-test` passes without running anything when `local.properties` is missing;
  - the Jenkins checks run tests only, no analyze or format
    ([gerrit_checks.md](../docs/gerrit_checks.md)); the Android JVM job runs only when
    `webtrit_callkeep_android/android/**` changed;
  - there are no native iOS tests anywhere, and the example's integration tests run only on a
    device - nothing runs them for you;
  - every `callkeep/` change also runs the phone suite in Jenkins.
- The README or `docs/` page of the behaviour changes in the same change.

## Writing docs

- Plugin-wide pages go in `docs/`, Android component pages in `webtrit_callkeep_android/docs/`
  (indexed by its `architecture.md`), iOS rules in `webtrit_callkeep_ios/README.md`.
- Plain ASCII, relative links, tables aligned by hand; `markdownlint-cli2` from `callkeep/`
  is clean.
