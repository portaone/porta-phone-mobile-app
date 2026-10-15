# webtrit_callkeep_android

Android implementation of [`webtrit_callkeep`](../webtrit_callkeep). Integrates Android Telecom,
foreground services, and background Flutter isolates to deliver VoIP call management on Android.

---

## Architecture

The implementation runs across **two OS processes**:

| Process          | Key class                | Role                                                        |
|------------------|--------------------------|-------------------------------------------------------------|
| `main`           | `ForegroundService`      | Flutter engine host, Pigeon host API, Telecom bridge        |
| `:callkeep_core` | `PhoneConnectionService` | Android `ConnectionService`, owns `PhoneConnection` objects |

Full architecture documentation lives in [`docs/`](docs/):

| Document                                                             | What it covers                                        |
|----------------------------------------------------------------------|-------------------------------------------------------|
| [docs/architecture.md](docs/architecture.md)                         | Overview, component index, high-level diagram         |
| [docs/dual-process.md](docs/dual-process.md)                         | Process boundaries, IPC design                        |
| [docs/call-flows.md](docs/call-flows.md)                             | Incoming, outgoing, teardown flows step by step       |
| [docs/foreground-service.md](docs/foreground-service.md)             | `ForegroundService` — Pigeon host, broadcast receiver |
| [docs/phone-connection-service.md](docs/phone-connection-service.md) | `PhoneConnectionService` — Telecom integration        |
| [docs/ipc-broadcasting.md](docs/ipc-broadcasting.md)                 | Cross-process event catalogue                         |
| [docs/pigeon-apis.md](docs/pigeon-apis.md)                           | All Pigeon host and Flutter APIs                      |

Diagrams: [docs/incoming-call-handling.md](docs/incoming-call-handling.md) — background-handling
decision and terminal outcomes.

---

## Integration tests

The public API is covered by integration tests located in
[`../webtrit_callkeep/example/integration_test/`](../webtrit_callkeep/example/integration_test/).

| Test file                                  | What it covers                                                                                 |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------- |
| `callkeep_lifecycle_test.dart`             | `setUp` / `tearDown` state machine, `isSetUp`, `statusStream` transitions                      |
| `callkeep_call_scenarios_test.dart`        | Incoming call answer, decline, hang-up, hold/unhold, mute/unmute, DTMF                         |
| `callkeep_state_machine_test.dart`         | Full answer-hold-mute-unmute-unhold-end sequence, two-call hold swap                           |
| `callkeep_foreground_service_test.dart`    | Main-process signaling path: answer/end timing, deduplication, cold-start adoption             |
| `callkeep_background_services_test.dart`   | Push notification isolate path: registration, deduplication, answer, end, tearDown             |
| `callkeep_connections_test.dart`           | `getConnection`, `getConnections`, `cleanConnections`                                          |
| `callkeep_delegate_edge_cases_test.dart`   | `setDelegate(null)` mid-call, delegate swap, `didPresentIncomingCall`, audio session callbacks |
| `callkeep_client_scenarios_test.dart`      | `answerCall` idempotency, ringback sound, async `performEndCall` contract                      |
| `callkeep_reportendcall_reasons_test.dart` | All `CallkeepEndCallReason` values via `reportEndCall`                                         |
| `callkeep_delivery_mode_test.dart`         | `getCallDeliveryMode` query (Android only) and the no-op behaviour on non-Android              |
| `callkeep_stress_test.dart`                | Concurrent duplicate reports, rapid tearDown, spam scenarios                                   |
| `a5_concurrent_calls_probe_test.dart`      | Whether the device holds a second call once the first is active, and groups two answered calls |

`all_tests.dart` is an aggregator entry point that runs every suite above except the a5 probe in a
single driver invocation (used for web `flutter drive` and full-suite device runs).

Run on a connected device or emulator from the example app directory:

```bash
cd ../webtrit_callkeep/example
flutter test integration_test/<test_file>.dart
```

---

## Related packages

| Package            | Path                                                                               |
|--------------------|------------------------------------------------------------------------------------|
| Platform interface | [`../webtrit_callkeep_platform_interface`](../webtrit_callkeep_platform_interface) |
| Aggregator         | [`../webtrit_callkeep`](../webtrit_callkeep)                                       |
| iOS implementation | [`../webtrit_callkeep_ios`](../webtrit_callkeep_ios)                               |

See [AGENTS.md](AGENTS.md) for contribution guidelines, detailed architecture notes, and
Android-specific rules.
