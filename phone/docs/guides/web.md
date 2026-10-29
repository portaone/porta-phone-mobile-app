# Flutter web support

Status: experimental / in progress. All web-specific code is gated on `kIsWeb`;
native (Android/iOS) behavior is unchanged.

## Run / build

```bash
# dev - debug, no icon tree-shaking, no extra flag needed
flutter run -d chrome --dart-define-from-file=dart_define.json

# release build (use the configured web bundle_id - see below)
flutter build web --no-tree-shake-icons \
  --dart-define=WEBTRIT_APP_WEB_BUNDLE_ID=<bundle-id-registered-on-the-server>

# compile verification only (defaults from dart_define.json)
flutter build web --dart-define-from-file=dart_define.json --no-tree-shake-icons
```

`--no-tree-shake-icons` is mandatory for any web build: `flutter build web` is release by default,
and the icon tree-shaker rejects the runtime `IconData` built by `String.toIconData()`. It fails
only after the full Dart compile (~4 min), so leaving it out costs a whole build cycle - see
[Verifying a Change Compiles](build_verification.md).

The web runs without Firebase: there are no web Firebase options (they are not generated for
the brands), so `main.dart` starts it on `FirebaseIntegrationDisabled`, and the push tokens bloc,
the permission request and the WebRTC initialize skip the web. No pipeline builds the web
version, so `web/index.html` and `web/manifest.json` carry plain values rather than placeholders.

Against a backend (the local stand, for one):

```bash
flutter run -d web-server --web-hostname localhost --web-port <free port> \
  --dart-define-from-file=dart_define.json \
  --dart-define=WEBTRIT_APP_WEB_BUNDLE_ID=<bundle-id-registered-on-the-server> \
  --dart-define=WEBTRIT_APP_CORE_URL=<core url>
```

The browser console still shows a 404 per contact without a Gravatar picture: the avatar is
asked for with `d=404` on purpose, so that a missing picture falls back to the initials.

## Important dart-defines on web

- `WEBTRIT_APP_WEB_BUNDLE_ID` - the `bundle_id` sent in the session (login) and
  autoprovision requests. Web has no platform bundle identifier, so without this
  the app falls back to the pubspec project name and the server rejects it with
  `unconfigured_bundle_id` (login fails). Set it to a bundle_id registered on the
  server for the `web` app type. (Long term: register the web bundle_id
  server-side so this override is unnecessary.)
- `WEBTRIT_APP_CORE_URL` / `WEBTRIT_APP_DEMO_CORE_URL`, `WEBTRIT_APP_NAME`, etc. -
  same as other platforms.

## Web assets

`web/sqlite3.wasm` (sqlite3 3.5.2) and `web/drift_worker.js` (drift 2.35.3) back
the drift `WasmDatabase` and are served from the app root. Keep them version-matched
to the `drift` / `sqlite3` dependencies.

## What works

Login, contacts, and audio+video calls (WebRTC + signaling over `wss`).

## Not available on web (intentionally skipped / guarded)

- Push notifications (FCM + local notifications) - deferred; there is no Firebase app on the web.
- Background services (WorkManager, callkeep background isolate, persistent
  signaling) - the web platform has none; signaling runs in the main isolate.
- Native lock-screen control and native audio routing - the browser owns the
  audio device.
- Persistent local DB needs OPFS/IndexedDB. In private/incognito mode (or older
  browsers) drift falls back to an in-memory database: local data is lost on
  reload and a warning is logged.

## Architecture notes

- Signaling: federated `signaling_service_web` package runs the WebSocket
  signaling in the main isolate (same model as iOS), since web has no background
  service.
- Database: `IsolateDatabase.openWeb()` opens the drift `WasmDatabase` directly
  (no `DriftIsolate` server, `dart:isolate` spawning is unsupported on web).
- Networking: the internal `_web_socket_channel` / `_http_client` / `_tcp_proxy`
  packages select web implementations via conditional imports.
- Remote Config renders from activated and locally cached values, then performs
  a five-second-bounded refresh after the first frame; its realtime stream is
  skipped on web. Firebase Installations init remains bounded during startup.
