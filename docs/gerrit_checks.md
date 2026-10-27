# Gerrit checks

Four Jenkins jobs vote Verified on every patchset. The table of jobs, their paths and their
`Dockerfile` stages, and the job setup, are in [.jenkins/README.md](../.jenkins/README.md). This
page adds what they do not run, how to reproduce them, and what fails them for reasons outside
the change. The push itself is in [Pushing to Gerrit](gerrit_push.md).

## Scope

- **Tests only.** The jobs run unit tests and nothing else: no `flutter analyze`, no
  `dart format`, no `check_l10n.dart`, no semantics gate. Those run only in the lefthook gate, so
  a green Verified says nothing about them.
- **Paths of this patchset only.** Each job decides from `git diff --name-only HEAD~1 HEAD`, the
  commit of the patchset alone, whether its `TEST_PATHS` are touched. A commit higher in a chain
  that touches no tested path passes without tests even if a lower one broke them.
- **Each change on its own.** Every commit of a chain is checked at its own tree, so every commit
  has to pass, not only the tip.
- **Triggered on upload only.** The trigger is `patchsetCreated`: a `recheck` comment does
  nothing. To run the checks again, upload a new patchset - `git commit --amend --no-edit`
  gives the same tree a new commit - and push it (mind `%wip`, see
  [Pushing to Gerrit](gerrit_push.md#gerrit)).

## Reproducing locally

The exact run is the `Dockerfile` stage, as `.jenkins/README.md` shows. Building the image on an
ARM machine emulates x86 and is slow.

Without Docker, the one thing that differs most from a local `flutter test` is that the phone job
runs every `phone/test` file in one process, through a generated `test/all_test.dart`. Generate
the same file and run it (from `phone/`):

```sh
(cd test && { echo "import 'package:flutter_test/flutter_test.dart';"; \
  find . -name '*_test.dart' ! -name all_test.dart | sort | awk '{printf "import \x27%s\x27 as t%d;\n", $0, NR}'; \
  echo 'void main() {'; \
  find . -name '*_test.dart' ! -name all_test.dart | sort | awk '{printf "  group(\x27%s\x27, t%d.main);\n", $0, NR}'; \
  echo '}'; } > all_test.dart)
flutter test --no-pub --reporter=failures-only test/all_test.dart
rm test/all_test.dart    # not gitignored
```

This uses your Flutter and your OS, so it is not identical to the job, but it catches the
one-process failures below. To narrow one down, put only the two suspect files into
`all_test.dart`, in the same alphabetical order.

The callkeep Android job is `./gradlew testDebugUnitTest` in
`callkeep/webtrit_callkeep_android/android`, which needs a `local.properties` with
`flutter.sdk=<path>` (the image writes `/opt/flutter`).

## Passes locally, fails in Jenkins

**State left behind by one test file breaks a later one.** Locally, `flutter test` and the
lefthook gate run each test file in its own process; the phone job runs them all in one, in
alphabetical order. A static field in app code that one test fills with a mock carries that mock
into the next files. A static singleton once kept a mocked repository from a `features/cdrs`
test, and a `features/contact` test then did not see a button; locally everything was green.
The fix belongs in the code (the singleton now belongs to its repository, see
`NumbersWatchSubject`), not in the tests. A test that changes global state - platform channel
mocks, `Logger.root.level`, the app lifecycle state - restores it in its own `tearDown`. Before
pushing a change that touches static state or the tests around it, run the one-process recipe on
every commit of the chain.

## Fails for reasons outside the change

**GitHub unreachable from the CI node.** `phone/pubspec.yaml` takes some dependencies straight from
GitHub (`phoenix_socket`, `flutter_webrtc`, `l10n_mapper_generator`). `pub get` clones them
whenever the Docker layer with the dependencies is not cached, and while the cache holds nobody
reaches GitHub, so a broken access stays invisible. When the cache was lost, the node failed with:

```
fatal: could not read Username for 'https://github.com': No such device or address
```

Signs: only the phone check is red (the callkeep and tools packages have no git dependencies), and
it fails within minutes, before any test. Removing one git dependency only moves the failure to
the next one. A retry does not help until the node reaches GitHub again; then upload a new
patchset.

**A branch without the pipelines gets -1 from all four jobs.** Jenkins reads the pipeline from the
patchset, so a branch cut before `.jenkins/` and `Dockerfile` existed fails every check whatever
the code. `release/1.16.6` is such a branch. Check before pushing to a release branch:

```sh
git ls-tree --name-only origin/release/vX.Y.Z | grep -E '^(Dockerfile|\.jenkins)$'
```

The way out is to bring the CI over in a commit of its own (the `Dockerfile` pins the Flutter of
`phone/.fvmrc`, so match it to that branch's) or to set Verified by hand.

**-1 on every fresh change at once is the CI, not the code.** If changes that have nothing in
common all got -1 within minutes of each other, look at the CI first:

```sh
ssh -p 29418 git.portaone.com gerrit query --current-patch-set \
  "status:open project:porta-phone/mobile-app after:<date>"
```

This proves nothing about your change: a change that really breaks a check looks the same on such
a day. Upload a new patchset once the CI is fixed and look again.

## Reading the result

The Jenkins console needs a login (it answers 403 without one). The result per job is in the
change's comments:

```sh
ssh -p 29418 git.portaone.com gerrit query --format=TEXT --comments change:<change>
```

Look for `Build Failed` and the `.../<job>/<n>/ : FAILURE` lines. The reason for a failure is
only in the console.
