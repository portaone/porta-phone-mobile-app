# Optional Features

How the features whose permission or capability must not ship unused are chosen at build time,
on both platforms.

Last reviewed: 2026-11-26

Some features must not merely stay switched off for a brand that does not use them - their Android
permission and their manifest components must be **absent from the shipped app**. A permission the
app never uses is still shown to the user and still has to be declared in the store listing, and an
App Links filter for a domain the brand does not serve claims links it cannot open. So the decision
has to be made at build time.

Today one feature is optional in that sense on Android:

* **deep links** - the App Links intent filter on the main activity

---

## How it works

Each optional feature owns one manifest fragment under `android/app/optional-manifests/`:

```
android/app/optional-manifests/
  deeplinks/AndroidManifest.xml
```

`android/app/build.gradle` reads the switches out of the dart-defines the build already carries and
adds the matching fragment to the manifest sources of every variant:

```groovy
androidComponents {
    onVariants(selector().all()) { variant ->
        optionalManifests.each { manifest ->
            variant.sources.manifests.addStaticManifestFile(manifest)
        }
    }
}
```

A fragment that is not added takes no part in the merge, so nothing it declares reaches the built
APK or AAB.

| Dart define               | Value         | Effect                                          |
|---------------------------|---------------|-------------------------------------------------|
| `WEBTRIT_APP_LINK_DOMAIN` | non-empty     | deep-link intent filter is merged in            |
|                           | empty/missing | no intent filter, no `APP_LINK_DOMAIN` resource |

The switch comes from the same `dart_define.json` the Dart code reads, so one file decides the
feature both in the app and in the manifest. Every build prints what it resolved:

```
Deep links: enabled
```

---

## Building

Nothing extra to pass - there are no build flavors and no flavor name to type:

```bash
melos run build:apk
melos run build:appbundle
melos run start:android
```

The same holds for IDE run configurations (`melos run ide:sync`) and for a hand-typed
`flutter build` - the feature follows `dart_define.json`.

---

## Verifying

The switch is worth checking on the artifact rather than the source.

The merged manifest is produced by a single Gradle task, far cheaper than a full build. It wants
the dart-defines in the form Flutter passes them - a comma-separated list of base64-encoded
`KEY=VALUE` pairs. Note that a missing or malformed value does not fail the task: it succeeds with
the feature off, which reads exactly like a fragment that refused to merge.

```bash
cd android
defines="$(printf '%s' 'WEBTRIT_APP_LINK_DOMAIN=app.webtrit.com' | base64 | tr -d '\n')"
./gradlew :app:processReleaseManifest -Pdart-defines="$defines"
cat ../build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
```

For a finished bundle, read its own manifest. `aapt2 dump badging` takes an apk and rejects an
`.aab`, and the bundle stores the manifest as protobuf, so either unpack it or use bundletool:

```bash
unzip -p build/app/outputs/bundle/release/app-release.aab base/manifest/AndroidManifest.xml \
  | strings | grep -E 'flutter_deeplinking_enabled'
```

---

## History

Until 2026-09 the optional features were Android product flavors, one dimension per feature, so
a build had to pick a combined flavor name. Boolean switches modelled as flavor dimensions
multiply - two meant four names, a third would have meant eight - and the name had to be computed
and passed by every caller - a script in this repo, a shared makefile, fastlane, and four IDE run
configurations, each able to disagree with `dart_define.json` in silence. The manifest fragments
and the merge that consumes them are unchanged; only the selection moved from a flavor name to
the dart-define the feature already had.

---

## iOS

Two features are optional on iOS: deep links, as on Android, and screen sharing in a call.

`ios/Runner/Runner.entitlements` declares `com.apple.developer.associated-domains`, and an
entitlement is not inert. Every provisioning profile then has to carry the matching capability, so
a brand that does not use deep links cannot even be signed:

```
Provisioning profile ... doesn't include the Associated Domains capability
```

`tool/scripts/ios_optional_features.sh` reads the same `WEBTRIT_APP_LINK_DOMAIN` the Dart code and
`android/app/build.gradle` read, and removes the entitlement when no domain is named. Both iOS
build scripts run it first, so `melos run build:ios` and `melos run build:ios:config` produce a
project that already matches the settings file:

```
sh tool/scripts/ios_optional_features.sh && flutter build ios ...
```

It needs nothing installed - `plutil` reads the JSON, `PlistBuddy` edits the plist. It used to live
in the build pipeline as a Ruby script needing the `xcodeproj` gem, deciding a phone feature from
outside the phone; the pipeline calls the phone's own script now, the way it does for Android.

Not `ios/Flutter/Environment.xcconfig`, deliberately: it is gitignored and written by the Xcode
scheme's pre-action at archive time, so it does not exist yet and would fall back to the hard-coded
default domain.

### Screen share

Screen sharing on iOS needs the broadcast upload extension `ios/ScreenShare` (bundle id
`<app bundle id>.ScreenShare`), embedded in Runner, and an App Group the two share. Both need the
brand's Apple Developer account to carry them: the extension's App ID, the App Group on both App
IDs, and a provisioning profile for each. A brand without them must still build and sign, so the
extension is optional, switched by `WEBTRIT_IOS_SCREEN_SHARE_APP_GROUP`:

| Dart define                          | Value           | Effect                                                   |
|--------------------------------------|-----------------|----------------------------------------------------------|
| `WEBTRIT_IOS_SCREEN_SHARE_APP_GROUP` | `group.<...>`   | the extension is built, embedded and signed; iOS shares  |
|                                      | empty/missing   | no extension, no App Group, no share entry on iOS        |

The repository's own `dart_define.json` sets `group.com.webtrit.phone`. The project is committed
with the extension in, and the value reaches it as a build setting through the Runner scheme's
pre-action, like every `WEBTRIT_*` define: the entitlements of both targets and the
`RTCAppGroupIdentifier` key flutter_webrtc reads. With no group named,
`tool/scripts/ios_optional_features.sh` takes out of the project Runner's dependency on the
extension and its place in "Embed Foundation Extensions" (so it is neither built nor signed), the
App Group entitlement of Runner, and the `RTCAppGroupIdentifier` and `RTCScreenSharingExtension`
keys of Runner's `Info.plist`. At start the app reads the define through
`EnvironmentConfig.IOS_SCREEN_SHARE_APP_GROUP` and, when it names a group, asks the native side
whether the key and the extension are there (`ScreenBroadcast.ofThisBuild`), so a build without
them offers no share. The
script puts nothing back: a checkout it took the extension out of is restored with git before the
feature is turned on, and the script refuses to go on until it is.

With the feature on, the release build signs two targets with two profiles: the fastlane `build`
lane takes the extension's profile from `IOS_SCREEN_SHARE_PROVISIONING_PROFILE_PATH`, next to the
app's `IOS_PROVISIONING_PROFILE_PATH`, and applies each to its own target
([build.md](../guides/build.md#ios)). With the feature off, that variable stays unset and the app's
profile alone signs the build, as the extension is no longer in it.

