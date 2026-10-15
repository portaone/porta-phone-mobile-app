---
name: core-endpoint
description: Adds a call to a WebTrit Core REST endpoint (model, `WebtritApiClient` method, failure rules, tests) and hides a feature behind a backend capability (`adapter.supported` flag, `CoreSupport`, `FeatureAccess`). Load it when a request says new or changed Core endpoint, API call, `packages/api`, `system-info`, capability, adapter flag, feature gate, "hide when the backend does not support it", or `EndpointNotSupportedException`.
---

# Core endpoint and backend capability

When: the app starts calling a Core endpoint it did not call before, an endpoint's payload or
errors change, or a feature must appear only on backends that advertise it.

## Steps

1. Model in `phone/packages/api/lib/src/models/` - `@freezed` + `json_serializable`, export it
   from `models.dart`. Rules: [packages/api/AGENTS.md](../../../phone/packages/api/AGENTS.md).
   - Every enum read from the wire gets a fallback: `@JsonKey(unknownEnumValue: X.unknown)`
     (see `cdr.dart`, `user_session.dart`), or `X.values.asNameMap()[raw] ?? X.unknown` in
     hand-written code (see `packages/signaling/lib/src/events/global/dialog_info.dart`).
     Never `X.values.byName(raw)` on a backend or stored value.
   - Fields the backend may omit are nullable or have a default.
2. Method in `phone/packages/api/lib/src/api_client.dart`. An endpoint an adapter may lack uses
   `_optionalEndpoint` (or its own `ResponseOptions(optionalEndpoint: true, failures: [...])`),
   so 501 or a bare 404 becomes `EndpointNotSupportedException`.
3. Endpoint-specific errors: a `FailureRule` keyed on Core's `code` in
   `phone/packages/api/lib/src/api_failure_rules.dart`, a typed exception in `exceptions.dart`,
   passed through `ResponseOptions.failures`. Which codes exist and which end the session:
   [core_error_codes.md](../../../phone/docs/architecture/core_error_codes.md).
4. Regenerate the model code - see the `codegen-l10n` skill
   (`fvm dart run build_runner build --delete-conflicting-outputs` in `phone/packages/api`).
5. API tests next to `phone/packages/api/test/api_client_optional_endpoint_test.dart` and
   `api_client_failure_rules_test.dart`: `MockClient`, assert method/URL/headers, one case per
   status + code, and one payload with an unknown enum value (see `cdr_record_decoding_test.dart`).
6. Capability flag, when the feature is gated:
   - constant `k<Name>FeatureFlag` in `phone/lib/app/constants.dart`, spelled as the backend
     sends it in `adapter.supported`;
   - getter on `CoreSupport` / `CoreSupportImpl` in `phone/lib/utils/core_support.dart`
     (or on `AdapterInfo` for call-level flags), test in `phone/test/utils/core_support_test.dart`;
   - the answer exposed from `FeatureAccess` / its mapper in `phone/lib/data/feature_access.dart`.
   How the value reaches a session: [feature_access.md](../../../phone/docs/features/feature_access.md).
7. A second, per-user gate ("is this user an agent") stays out of `FeatureAccess`:
   [feature_gates.md](../../../phone/docs/architecture/feature_gates.md).
8. Repository: a periodic read is a `Refreshable` that rethrows failures, registered on
   `PollingService`: [polling.md](../../../phone/docs/architecture/polling.md#refresh-completion-contract).
9. Screens and strings: the `codegen-l10n` skill. A new `WEBTRIT_APP_*` dart-define goes into
   `phone/lib/environment_config.dart`, `phone/dart_define.json` and
   [environment.md](../../../phone/docs/reference/environment.md).
10. Describe the feature in `phone/docs/features/` and keep the failure table in
    `packages/api/AGENTS.md` in step with the new exceptions.

## Before handing over

- `fvm flutter test` in `phone/packages/api` and the touched `phone/test/` files, `fvm flutter analyze`.
- No `$enumDecode(` without `unknownValue:` in the `.g.dart` you generated:
  `grep -n '\$enumDecode' phone/packages/api/lib/src/models/<file>.g.dart`.
- Tests that mock `AdapterInfo`, `WebtritSystemInfo` or `FeatureAccess` (mocktail, in
  `phone/test/mocks/feature_access_mocks.dart` and others) still pass with the new getter.
- The capability was checked both ways: flag absent -> feature hidden, flag present -> shown
  (Settings -> About -> Backend capabilities lists what the session runs on).

## Traps

- One unknown enum value kills the whole list, and a paging cursor built on it never moves:
  give every wire enum a fallback; `favorites`, `sip_subscriptions`, `system_notification`,
  `user_info` and `app_push_token` still lack one, so do not copy them - [AGENTS.md](../../../phone/packages/api/AGENTS.md).
- A rule on an adapter code (`access_token_invalid`) never fires, and a logout on any 401 signs
  users out on one refused request: match Core codes only - [core_error_codes.md](../../../phone/docs/architecture/core_error_codes.md#traps).
- An optional endpoint answering a bare 404 for a missing item reads as "route absent" and can
  switch the feature off for good: give the item-missing case its own code rule, as voicemail and
  call queues do - [AGENTS.md](../../../phone/packages/api/AGENTS.md#exceptions).
- A repository that catches and logs instead of rethrowing keeps backoff off and polling green:
  throw the original error - [polling.md](../../../phone/docs/architecture/polling.md#refresh-completion-contract).
- A capability flipped on the backend reaches the app only at the next session start, not live:
  test with a restart - [feature_access.md](../../../phone/docs/features/feature_access.md#the-one-rule-a-session-runs-on-a-snapshot).
- A per-user answer computed into `FeatureAccess`, a global cache key, a "yes" default or a lazy
  writer provider: [feature_gates.md](../../../phone/docs/architecture/feature_gates.md#traps).
- Gating on the Core version when the backend can advertise a flag or field: the version string
  is not raised with every change, so gate on the flag; a version range is for Core-only
  endpoints with no adapter flag - [session_tracking.md](../../../phone/docs/features/session_tracking.md).
- An older Core does not refuse an unknown signaling request, it closes the socket with 4600:
  ask the capability first - [call_conference.md](../../../phone/docs/features/call_conference.md).
- A new getter on a class that tests mock with mocktail (`MockAdapterInfo`, `FeatureAccess`
  mocks) returns null wherever it is not stubbed: run the whole `phone/test` suite, not one file.
- An old backend may answer the new endpoint with 501, 404 or not at all: test against a
  backend without the capability before calling it done.
