# signaling_service (plugin root)

Federated Flutter plugin — standalone signaling service that owns the WebSocket
lifecycle: in the calling isolate in `pushBound` mode (every platform; what the app passes
unless the user opts into socket mode), and in an Android foreground service in `persistent`
mode (the API default).

## Package Map

| Package | Role |
|---------|------|
| `signaling_service` | Public umbrella — `WebtritSignalingService` façade |
| `signaling_service_platform_interface` | Shared contract - `SignalingServicePlatform`, `SignalingModuleEvent`, `SignalingServiceConfig`, plus the shared `WebtritSignalingServiceDirect` and `SignalingModuleImpl` |
| `signaling_service_android` | Android implementation - direct socket for `pushBound`, foreground service + IsolateNameServer hub for `persistent` |
| `signaling_service_ios` | iOS implementation — main-isolate `SignalingModule` |
| `signaling_service_web` | Web implementation - the same as iOS |

## Sub-package Docs

@signaling_service/AGENTS.md
@signaling_service_platform_interface/AGENTS.md
@signaling_service_android/AGENTS.md
@signaling_service_ios/AGENTS.md
