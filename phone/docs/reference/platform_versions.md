# Platform versions

The minimum versions the app and callkeep declare, where each number lives, and the platform
facts that hold them where they are. Both floors sit exactly on the floor of the Flutter release
the app builds with: there is no room below either of them without an older Flutter.
Last reviewed: 2026-10-15.

## Declared versions

The app builds with Flutter 3.47.1 (`phone/.fvmrc`).

### Android

| Setting            | Value                           | Where                                                                             |
|--------------------|---------------------------------|-----------------------------------------------------------------------------------|
| `minSdkVersion`    | 24 (Android 7.0)                | `phone/android/app/build.gradle`                                                  |
| `minSdkVersion`    | 24                              | `callkeep/webtrit_callkeep_android/android/build.gradle`                          |
| `minSdkVersion`    | 24                              | `phone/packages/signaling_service/signaling_service_android/android/build.gradle` |
| `minSdk`           | 24                              | `phone/packages/device_auto_rotate/android/build.gradle`                          |
| `compileSdk`       | 36                              | the three plugins above; the app uses `flutter.compileSdkVersion` (36)            |
| `targetSdkVersion` | `flutter.targetSdkVersion` (36) | `phone/android/app/build.gradle`                                                  |
| Java / Kotlin JVM  | 17                              | every Android module                                                              |

The app writes `minSdkVersion 24` as a literal with `// flutter.minSdkVersion` next to it: the
two are equal today, and the literal keeps the floor from moving when Flutter raises its default.

### iOS

| Setting                      | Value | Where                                                                                    |
|------------------------------|-------|------------------------------------------------------------------------------------------|
| `IPHONEOS_DEPLOYMENT_TARGET` | 15.0  | `phone/ios/Runner.xcodeproj/project.pbxproj`, all nine entries                           |
| `platform :ios`              | 15.0  | `phone/ios/Podfile`                                                                      |
| pod and Swift package        | 13.0  | `callkeep/webtrit_callkeep_ios/ios/webtrit_callkeep_ios.podspec` and its `Package.swift` |

The callkeep iOS plugin asks for less than the app, which is allowed: the app's target decides.
The app's deployment target is set for Runner, RunnerUITests and the project itself, three
build configurations each; change all nine entries and the Podfile together.

### Dart and Flutter constraints

| Package                                                                        | `environment`                                              |
|--------------------------------------------------------------------------------|------------------------------------------------------------|
| `phone`                                                                        | `sdk: ^3.13.0`, `flutter: ^3.47.0`                         |
| `phone/packages/*`                                                             | `sdk: ^3.8.0`; some add `flutter: '>=3.32.0'` or `^3.19.0` |
| `callkeep/webtrit_callkeep`, `_android`, `_ios`, `_platform_interface`, `_web` | `sdk: ^3.8.0`                                              |
| `callkeep/webtrit_callkeep_linux`, `_macos`, `_windows`                        | `sdk: ">=3.0.0 <4.0.0"`                                    |

The app's own constraint is the binding one; the lower constraints of the packages only say
they would build with an older toolchain.

## Android floor

- **Flutter.** Flutter 3.47 builds Android apps from API 24 (`minSdkVersion` in
  `FlutterExtension.kt` of `flutter_tools`). Flutter raised its floor from 21 to 24 in 3.35;
  the last release line that builds API 21-23 is 3.32. Going below 24 means freezing Flutter.
- **WebRTC.** The `flutter_webrtc` fork (`po/1.6.2+hotfix.3-11` in `phone/pubspec.yaml`)
  declares `minSdkVersion 21`, so it does not hold the floor. A declared floor of a dependency
  is not proof, though: a plugin can declare 21 and still call an API 26 method on the call
  path. Neither lint nor a grep finds that; only a run on an API 24 device or emulator does.
- **Telecom.** The app is a VoIP app, not the system dialer, so on the Telecom path callkeep
  needs a self-managed `PhoneAccount` (`PhoneAccount.CAPABILITY_SELF_MANAGED`, API 26).
  `ConnectionService` itself exists from API 23, but without the self-managed capability the
  app cannot use it. On API 24-25 callkeep therefore runs every call on the standalone path:
  `TelephonyUtils.isTelecomSupported` returns false below `Build.VERSION_CODES.O`, and
  `CallServiceRouter` sends the commands to `StandaloneCallService`. See
  [standalone-call-service.md](../../../callkeep/webtrit_callkeep_android/docs/standalone-call-service.md).

Platform API levels callkeep has to respect on API 24-25:

| Symbol                                                     | API |
|------------------------------------------------------------|-----|
| `ConnectionService`, `Connection`, `PhoneAccount`          | 23  |
| `PhoneAccount.CAPABILITY_SELF_MANAGED`, `MANAGE_OWN_CALLS` | 26  |
| `Context.startForegroundService`, `NotificationChannel`    | 26  |
| `FOREGROUND_SERVICE` permission                            | 28  |
| `USE_FULL_SCREEN_INTENT`, foreground service types         | 29  |
| `POST_NOTIFICATIONS`                                       | 33  |
| `FOREGROUND_SERVICE_PHONE_CALL`                            | 34  |

`NotificationChannelManager` skips channel registration below API 26, and foreground services
start through `startForegroundServiceCompat`, which checks `SDK_INT`. The restrictions of API
29 and later do not exist on Android 7, so their guards are no-ops there.

## iOS floor

- **Flutter.** Flutter 3.47 raised its iOS minimum from 13.0 to 15.0 (its
  `ios_deployment_target_migration.dart` moves projects to 15.0).
- **Firebase.** The FlutterFire pods the app uses (`firebase_core`, `firebase_messaging` and
  the rest) declare `s.ios.deployment_target = '15.0'`.
- Nothing in the app's or callkeep's own iOS code needs more than 13.0; CallKit and PushKit are
  far older than either floor.

## Changing a floor

- **Down** is closed on both platforms without an older Flutter, and below API 21 also by
  `flutter_webrtc`. Below Android 5 there are no supported Google Play services and so no FCM
  push, which means no incoming calls.
- **The floor moves under you.** A Flutter upgrade can raise its minimum (13.0 to 15.0 on iOS
  in 3.47) with no change of ours. A promise of a minimum OS version ties future Flutter
  upgrades to it.
- **Up** on Android: check which `SDK_INT` guards it makes dead and how it narrows the
  standalone path. Up on iOS: change the project entries and the Podfile in one change.
- After any change, run the app on the lowest declared version, not only on a current one.
