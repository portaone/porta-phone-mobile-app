# App update / version compatibility

How the app detects that it is incompatible with the backend, and how it
prompts the user to update when a newer build is published: the version gate
screens and the Play Core in-app update flow.

Last reviewed: 2026-10-05

## Where it lives

- `lib/services/app_update_service.dart` - `AppUpdateService`: the Play Core
  in-app update flow (Android).
- `lib/app/router/app_update_check.dart` - `AppUpdateCheck`: mounted by
  `MainShell`, decides when `AppUpdateService.check()` runs and whether an
  update may take the screen.
- `lib/models/system_info/app_compatibility.dart` - `AppCompatibilityResolver`
  (default: `DefaultAppCompatibilityResolver`) and its result, the sealed
  `AppCompatibility` (`AppCompatible` / `CoreVersionUnsupported` /
  `AppVersionTooOld`).
- `lib/blocs/app/app_bloc.dart` - `AppBloc`: keeps `state.appCompatibility`,
  resolved from the cached system info at start and from every
  `SystemInfoRepository.infoStream` value.
- `lib/app/router/app_router.dart` - `onMainShellRouteGuardNavigation` sends an
  incompatible session to a gate screen; the gate screens' own guards keep it
  there while the state holds.
- `lib/features/version_gate/` - the gate screens:
    - `view/update_required_screen.dart` - `UpdateRequiredScreenPage` (app too old).
    - `view/compatibility_issue_screen.dart` - `CompatibilityIssueScreenPage`
      (core version unsupported).
- `packages/store_info_extractor/` - workspace package that fetches the latest
  published app version from the platform store (its consumers are the two
  gate screens).

## Soft update prompt (Android) - Play Core in-app updates

When a newer build is published in Google Play, the app surfaces the native
Play Core update UI - no in-app dialogs and no client-side version comparison
(Play compares the installed and published version codes itself).

`AppUpdateCheck` follows `CallBloc` and starts `AppUpdateService.check()` when
its state says the session has heard from the server (the handshake is
established, whatever the registration turned out to be) or has failed to
reach it, no call is tracked and the app is in front. Without a network
nothing is decided.

Every step below shows Play's UI in an activity of its own or restarts the
app, so each one first asks whether it may. The answer is no while the phone
is locked or that same state no longer holds. This is what keeps Play's screen
off an incoming call: the app started by the call alert is shown over the
keyguard, Play's activity is not, and the keyguard used to come back over a
ringing call.

A check that was refused is run again on the next state that allows it, so a
call or a locked phone delays the update instead of losing it. A check that
reached its end - nothing to offer, the user answered Play's prompt, or Play
failed - is the last of the session; the next one comes with a cold start or a
new login, not with a foreground resume.

When it may proceed:

1. An interrupted immediate update (`developerTriggeredUpdateInProgress`) is
   resumed - Play requires the app to finish it.
2. A flexible download that finished earlier (`InstallStatus.downloaded`) is
   installed. This is also how a download that ended during a call, on a
   locked phone or with the app in the background gets installed: that check
   was refused at the install step and is repeated.
3. An available update runs as:
    - **flexible** (background download, install on completion) - the default;
    - **immediate** (blocking native overlay) - only when the release was
      published with in-app update priority >= 4 (Google Play Developer API
      `inAppUpdatePriority`, defaults to 0) or when flexible is not allowed.
4. A declined flexible update ends the check, so it is not offered again
   until the next session.

The whole flow is a silent no-op on non-Android platforms, on devices without
Google Play services (some white-label fleets), and on sideloaded/debug builds
(Play Core fails there and the failure is swallowed).

Note on version semantics: builds get their `versionName`/`versionCode` from
`--build-name`/`--build-number` at build time (per client); the repo's
`app_version` field does not set them (the app reads it from the bundled
`pubspec.yaml` as `AppInfo.version`). Publishing any higher version
code triggers the prompt.

Verification: the real flow cannot be exercised locally - it requires a build
installed from Google Play (internal testing track with a lower version code
on the device).

## Version gate (app and core version)

When the backend's system info says the app may not run against it, the main
shell is replaced by a full-screen, non-dismissible gate (the back button does
not leave it), with:

- **Update required** (`AppVersionTooOld`) - the backend declares an optional
  `min_supported_app_version` (semver) in `GET /api/v1/system-info` (`null` =
  not enforced) above the app's internal `app_version`. A `0.0.0` build is
  never blocked. **Update** is shown whenever the store lookup resolves, with no
  version comparison: the store lists the per-client build version, which is
  not comparable with `app_version`.
- **Compatibility issue** (`CoreVersionUnsupported`) - the core version is
  outside `EnvironmentConfig.CORE_VERSION_CONSTRAINT`. **Update** is shown only
  when the store version is newer than the app's `app_version`.

**Logout** is always shown and logs the user out. When both apply, the too-old
app wins.

```
SystemInfoRepository (cached value at start, then infoStream)
  -> AppBloc -> AppCompatibilityResolver.resolve(systemInfo, AppInfo.version, CORE_VERSION_CONSTRAINT)
       |- min_supported_app_version above app_version -> AppVersionTooOld
       |- core version outside the constraint         -> CoreVersionUnsupported
       '- else                                        -> AppCompatible
  -> state.appCompatibility
  -> AppRouter.onMainShellRouteGuardNavigation
       |- AppVersionTooOld       -> replaceAll([UpdateRequiredScreenPageRoute])
       |- CoreVersionUnsupported -> replaceAll([CompatibilityIssueScreenPageRoute])
       '- AppCompatible          -> agreements, permissions, main shell
  gate screen: Update -> StoreInfoExtractor.getStoreInfo(packageName)
                         -> launchUrl(viewUrl, externalApplication)
```

The main shell is what connects the signaling socket, so behind a gate it stays
unconnected. A gate screen sends the user back to the main shell once the state
no longer holds (the server lowered the minimum, the core is back in range) or
the user logged out. At login, `LoginCubit` and `AutoprovisionCubit` run the
same resolver on the fetched system info; an incompatible result shows an error
(a notification in `LoginCubit`, an error state in `AutoprovisionCubit`) and no
session is created.

The store lookup runs **only** when a gate screen opens - it answers "can an
app update fix this?", not "is there an update".

### store_info_extractor package

`StoreInfoExtractor.getStoreInfo(appPackageName)` picks a client by platform:

| Platform    | Client                  | Method                                                                                      |
|-------------|-------------------------|---------------------------------------------------------------------------------------------|
| Android     | `GooglePlayStoreClient` | HTTP GET `play.google.com/store/apps/details?id=<pkg>`, regex `[[["x.y.z"]]]` over the HTML |
| iOS / macOS | `AppleAppStoreClient`   | iTunes lookup JSON API (`itunes.apple.com/lookup?bundleId=<pkg>`)                           |
| Web         | `StubStoreClient`       | always `null`                                                                               |

Known limitations: the Android HTML scraping is fragile and is now redundant
for the soft-update use case (Play Core covers it); it remains only as the
Update-button source of the two gate screens.

## Redesign / in progress

| Mechanism                   | Trigger                                                              | UX                                                             | Status                      |
|-----------------------------|----------------------------------------------------------------------|----------------------------------------------------------------|-----------------------------|
| Soft update prompt (above)  | newer build published in Google Play                                 | native Play Core prompt, app keeps working                     | shipped                     |
| Core compatibility (above)  | core version outside the app's constraint                            | full-screen gate, Update button when the store is newer        | shipped                     |
| Backend-driven force update | backend declares `min_supported_app_version` above the app's version | full-screen gate + signaling socket not connected              | shipped                     |
| iOS soft update             | newer version in the App Store                                       | custom prompt -> App Store (no native API on iOS)              | future                      |

- **iOS soft update (future)**: plug into the same `AppUpdateCheck` seam (a
  single `check()` per session); extract an interface from `AppUpdateService`
  with platform implementations. iOS has no native update UI, so its
  implementation must surface a custom prompt (service code cannot touch
  `BuildContext` - emit an event/notification instead) and needs a version
  source: the kept `AppleAppStoreClient`, or Firebase Remote Config if a
  priority-like signal is wanted.
- **Scraper cleanup**: `GooglePlayStoreClient` is still the Update-button
  source of both gate screens on Android, so it stays until they have another
  one. It also contains a stray debug `print` to drop with it.
