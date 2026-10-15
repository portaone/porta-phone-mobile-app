# AGENTS.md - signaling_service

The federated plugin that owns the signaling WebSocket the app keeps open: in the calling
isolate in `pushBound` mode (every platform; what the app passes unless the user opts into
socket mode), in an Android foreground service in `persistent` mode (the API default). How it
works - modes, the Android hub, the session buffer, the module factory, the background call
handler - is in [ARCHITECTURE.md](ARCHITECTURE.md), the one place for those topics. Each
sub-package's `AGENTS.md` describes its own classes and loads when you read files there.

## Layout

```
signaling_service/                     WebtritSignalingService, the facade the app imports
                                       signaling_service/AGENTS.md
signaling_service_platform_interface/  SignalingServicePlatform, events, config, the shared code:
                                       WebtritSignalingServiceDirect, SignalingModuleImpl,
                                       SignalingRequestQueue, SignalingEventBuffer, SessionSnapshot
                                       signaling_service_platform_interface/AGENTS.md
signaling_service_android/             pushBound: direct socket; persistent: foreground service
                                       and the IsolateNameServer hub; Pigeon, Kotlin
                                       signaling_service_android/AGENTS.md
signaling_service_ios/                 a registration-only subclass of WebtritSignalingServiceDirect
                                       signaling_service_ios/AGENTS.md
signaling_service_web/                 the same for web (WebtritSignalingServiceWeb); no AGENTS.md
docs/request_queue.md                  what execute does without a connection
ARCHITECTURE.md                        the internals
```

Sub-package pages: [signaling_service](signaling_service/AGENTS.md),
[signaling_service_platform_interface](signaling_service_platform_interface/AGENTS.md),
[signaling_service_android](signaling_service_android/AGENTS.md),
[signaling_service_ios](signaling_service_ios/AGENTS.md).

## Rules

- Behaviour shared by iOS, web and Android `pushBound` lives in `WebtritSignalingServiceDirect`
  (platform interface); a change there reaches all three. The iOS and web subclasses only
  register the plugin; the Android one (`WebtritSignalingServiceAndroidDirect`) adds the
  push-isolate handoff.
- Every replay boundary uses `SignalingEventBuffer`; change the buffer rules in the platform
  interface, never in one boundary.
- The app holds a `WebtritSignalingService` (built by `lib/utils/signaling_service_factory.dart`),
  not a platform class or `SignalingModuleImpl` directly.

## Before a particular change

| You are about to | Read first | Skill |
|---|---|---|
| send a request over signaling, or read what `execute` returned | [request_queue.md](docs/request_queue.md) | `callbloc-change` |
| change what a late subscriber sees (the session buffer) | [ARCHITECTURE.md, Session replay buffer](ARCHITECTURE.md#session-replay-buffer), `signaling_service_platform_interface/lib/src/session_snapshot.dart` | |
| change the Android transport: the service, the hub, Pigeon, Kotlin | [signaling_service_android/AGENTS.md](signaling_service_android/AGENTS.md), [ARCHITECTURE.md, Android hub](ARCHITECTURE.md#android-hub) | |
| change how a call reaches the app (push, background, socket) | [incoming_call_scenarios.md](../../docs/architecture/incoming_call_scenarios.md) | |
| change when or how the app reconnects | [signaling_architecture_target.md](../../docs/architecture/signaling_architecture_target.md) | |

## Before handing over

- The tests of these packages are not in the pre-push gate: it runs `flutter analyze` from
  `phone/`, but tests only in `phone/` itself, `text_entities` and `link_preview`. Only Jenkins
  runs them.
  Run them by hand in every sub-package you touched (all but `signaling_service_web` have a
  `test/`):

  ```bash
  fvm flutter analyze
  fvm flutter test
  ```

- A change to the internals updates [ARCHITECTURE.md](ARCHITECTURE.md) in the same change.
