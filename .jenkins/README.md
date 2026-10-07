# Jenkins

## Gerrit checks (WT-2002)

Every patchset uploaded to `porta-phone/mobile-app`, on any branch, triggers all four
jobs, and they vote **Verified +1** (passed) or **-1** (failed) through the Gerrit
Trigger plugin. Each job runs its unit tests only when the patchset changes its paths
(`TEST_PATHS` in its groovy) or the root `Dockerfile`; otherwise it passes without
running them, so every patchset still gets a vote:

| Pipeline | Paths | Dockerfile stage | Runs |
|---|---|---|---|
| `gerrit_check_phone.groovy` | `phone/**`, `callkeep/**` | `phone-test` | `flutter test` on a generated `test/all_test.dart` that imports every `phone/test` file (one compilation), then every `phone/packages/**` package with `test/` (~5 min) |
| `gerrit_check_callkeep.groovy` | `callkeep/**` | `callkeep-test` | `flutter test` in every `callkeep/webtrit_callkeep*` package with `test/` (~2 min) |
| `gerrit_check_callkeep_android.groovy` | `callkeep/webtrit_callkeep_android/android/**` | `callkeep-android-test` | `./gradlew testDebugUnitTest`, Robolectric JVM tests (~3 min) |
| `gerrit_check_tools.groovy` | `tools/**`, `analysis/**`, `phone/packages/theme_schema/**` | `tools-test` | `dart test` in `tools/` (~1 min) |

Each job builds its stage of the root `Dockerfile` and runs it. Locally, from the
repository root:

```sh
docker build --target phone-test -t mobile-app-phone-test .
docker run --rm mobile-app-phone-test
```

Flutter is installed from the official release tarball, pinned with its sha256 to
`phone/.fvmrc`; when `.fvmrc` changes, update `FLUTTER_VERSION` and `FLUTTER_SHA256` in
the `Dockerfile`.

The phone tests run in one process, so a test that changes global state (platform
channel mocks, `Logger.root.level`, the app lifecycle state) must restore it in its
own `tearDown`, or a later file fails.

Not run, because they cannot run in a Linux container: native iOS/macOS (XCTest) and
Windows tests, `phone/integration_test/` and `phone/patrol_test/` (need a device).

Jenkins job, one per pipeline: **Pipeline script from SCM**, Git
`ssh://jenkins@git.portaone.com:29418/porta-phone/mobile-app.git`, refspec
`$GERRIT_REFSPEC`, branch specifier `FETCH_HEAD`, script path
`.jenkins/gerrit_check_<part>.groovy`. Run it once by hand so the trigger registers.
Jenkins reads the pipeline from the patchset, so every branch needs it: a new branch
gets it when cut from `master`, an older one needs it cherry-picked.
