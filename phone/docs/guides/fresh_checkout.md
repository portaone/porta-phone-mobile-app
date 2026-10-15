# Fresh checkout

What a new clone or `git worktree` of this repository lacks for building, linting and formatting,
and the first-run failures that come from it. The build itself is in [Build](build.md); the
pre-push gate in a fresh checkout is in [Pushing to Gerrit](../../../docs/gerrit_push.md#the-gate).
Last reviewed: 2026-10-15.

## First step

Run `flutter pub get` in `phone/` (and `dart pub get` in `tools/`) before anything else. Two
things depend on `.dart_tool/`:

- **Formatting.** Without it the formatter cannot resolve the `include:` of the package's
  `analysis_options.yaml`, falls back to width 80 instead of 120, and rewraps lines you did not
  touch. `--set-exit-if-changed` accepts both forms, so nothing reports it. If it happened,
  `git checkout` the file and redo the edit after `pub get`.
- **Gradle.** The Flutter Gradle plugin learns the app's plugins from it; without it a direct
  `./gradlew` in `phone/android` does not know them.

## Android

**The Gradle wrapper is gitignored.** `phone/android/.gitignore` excludes `gradlew`, `gradlew.bat`
and `gradle-wrapper.jar`, so a direct `./gradlew` says `no such file or directory`, and with the
scripts but no jar Gradle fails with `Could not find or load main class
org.gradle.wrapper.GradleWrapperMain`. The first `flutter build apk` creates all three; or copy
them from another checkout.

**Direct Gradle calls can pick the wrong JDK.** `flutter build` runs Gradle with the JDK Flutter
is configured with (`flutter doctor -v` names it; on macOS usually Android Studio's bundled JBR).
A plain `./gradlew` takes `JAVA_HOME` or the system JDK, and a much newer one has failed at
`:connectivity_plus:compileDebugJavaWithJavac` in `JdkImageTransform` (`jlink`). Point it at the
same JDK:

```sh
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew :app:lintDebug
```

**callkeep's standalone Android build needs `local.properties`.**
`callkeep/webtrit_callkeep_android/android/` has its own `gradlew`, but its `local.properties`
is gitignored. Without `flutter.sdk=<path to the Flutter SDK>` in it the build cannot see the
Flutter engine and fails in `Generated.kt` with `Unresolved reference 'io'`, and the gate's
`callkeep-android-test` skips with exit 0 instead of running the tests.

**Modules without their own Gradle build are linted through the app.**
`phone/packages/signaling_service/signaling_service_android` has no wrapper:

```sh
cd phone/android && ./gradlew :signaling_service_android:lintDebug
# report: phone/build/signaling_service_android/reports/lint-results-debug.txt
```

**Lint's NewApi check is worth reading, with two blind spots.** A module's lint checks against
that module's own `minSdkVersion` (24 in the app, callkeep and `signaling_service_android`), and
it finds calls a grep misses (`Context.startForegroundService`, style attributes of later APIs).
It does not see code inside dependencies, which have their own `minSdkVersion`, and it knows
nothing of runtime version guards.

## iOS

**`pod install` fails until the engine artifacts are there.** In a fresh checkout it fails in the
post-install hook with `Flutter.xcframework must exist. If you're running pod install manually,
make sure "flutter precache --ios" is executed first`. It looks like a CocoaPods problem; it is
missing artifacts. Run `flutter precache --ios` once.

**`flutter_webrtc` comes through Swift Package Manager, not CocoaPods.** Plugins with a
`Package.swift` are resolved by SwiftPM, so `Podfile.lock` has no `flutter_webrtc` or
`WebRTC-SDK` entry, and `pod install` after changing the `flutter_webrtc` pin does not update
the framework. The version of the framework is pinned in the fork's own
`ios/flutter_webrtc/Package.swift`; the resolved state is in the tracked `Package.resolved` files
under `phone/ios/`.

## Tracked files a build changes

Read `git diff` after building, not before, and separate your change from what the tooling wrote:

- `phone/dart_define.json` is tracked. Point it at your own server locally; do not commit that.
- `phone/android/app/src/main/res/xml/network_security_config.xml` is tracked and rewritten by
  the Gradle build from the HTTP domains in the dart-defines file passed with
  `--dart-define-from-file`.
- `flutter build ios` has rewritten `phone/ios/Runner.xcodeproj/project.pbxproj` (project-level
  `IPHONEOS_DEPLOYMENT_TARGET` raised to the Podfile's `platform`) and
  `phone/ios/Flutter/AppFrameworkInfo.plist` (`MinimumOSVersion` removed).

## Formatting on commit

`phone-format` and `tools-format` in `lefthook.yml` run `dart format --output=none
--set-exit-if-changed`: they only report, they do not rewrite. A commit refused by them stays
refused until you format and stage the files yourself:

```sh
dart format <files> && git add <files>
```

The width is 120, from `formatter: page_width` in `phone/analysis_options.yaml` and
`tools/analysis_options.yaml`; a call split over three lines can be joined into one. In
`callkeep/` it is the other way round: `callkeep-format` (`--line-length 120`) and
`callkeep-kotlin` (`ktlint --format`) rewrite the files and stage the result.
