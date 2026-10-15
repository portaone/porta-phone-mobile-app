# AGENTS.md - signaling

Pure Dart client of the WebTrit Core signaling protocol over WebSocket: no Flutter, no code
generation, models hand-written with `Equatable`. The connection the app keeps open - reconnect,
buffering, background - is `../signaling_service`, not this package. Before you change what the
app sends or how a call reacts to an event, read
[signaling_architecture_target.md](../../docs/architecture/signaling_architecture_target.md)
and use the skill `callbloc-change` ([SKILL.md](../../../.agents/skills/callbloc-change/SKILL.md)).
Protocol docs: <https://github.com/WebTrit/webtrit_docs/blob/main/signaling/index.md>.

## Client lifecycle

`WebtritSignalingClient` is the entry point:

```dart
// 1. Connect (static factory); force takes the session over from another device.
final client = await WebtritSignalingClient.connect(
  baseUrl, tenantId, token, force,
  connectionTimeout: timeout,   // optional
  certs: certs,                 // optional, TrustedCertificates.empty by default
);

// 2. Register callbacks, once; a second call throws StateError.
client.listen(
  onStateHandshake: (sh) { ... },
  onEvent: (e) { ... },
  onError: (e, st) { ... },
  onDisconnect: (code, reason) { ... },
);

// 3. Send a request and await its ack.
await client.execute(HangupRequest(...));

// 4. Disconnect.
await client.disconnect();
```

The URL is `<baseUrl>/tenant/<tenantId>/signaling/v1?token=<token>&force=<true|false>`
(`buildTenantUrl`, `@visibleForTesting`, adds the tenant segment and replaces one the base URL
already has; an empty tenant id adds none), subprotocol `webtrit-protocol`.

## Message hierarchy

```
Event / Request
  GlobalEvent                         NumberPresenceUpdate, NumberDialogsUpdate
  SessionEvent / SessionRequest       (transaction)
    RegisteringEvent, RegisteredEvent, UnregisteredEvent, RegistrationFailedEvent, ...
    Conference*: ConferenceOfferEvent, ConferenceUpdatedEvent, ...,
                 MergeRequest, ConferenceAddRequest, ConferenceMuteRequest, ...
    LineEvent / LineRequest           (line, an address)
      IceTrickleEvent, IceHangupEvent, TransferEvent, ...
      CallEvent / CallRequest         (callId)
        IncomingCallEvent, CallingEvent, RingingEvent, AcceptedEvent, HangupEvent, ...
        OutgoingCallRequest, AcceptRequest, DeclineRequest, HangupRequest, ...
```

`Conference*` classes are session-level even when they carry `line`: there it is a participant
index, not an address. Never register them as `LineEvent` / `LineRequest`. Their wire format is
[docs/conference_protocol.md](docs/conference_protocol.md); read it before touching any
`Conference*` class and update it in the same change when the wire format moves.

Inbound messages, as `_onMessage` tells them apart:

| Kind | JSON key | Class |
|---|---|---|
| Handshake | `handshake` | `StateHandshake` (with `conference: ConferenceInfo?`), `KeepaliveHandshake` |
| Event | `event` | `GlobalEvent`, `SessionEvent`, `LineEvent`, `CallEvent` |
| Response | `response` | `AckResponse`, `ErrorResponse` |

## Decoding

- Events and requests decode through static maps keyed by the `event` / `request` value, one per
  level: `_globalEventFromJsonDecoders`, `_sessionEventFromJsonDecoders`,
  `_lineEventFromJsonDecoders`, `_callEventFromJsonDecoders`, and the `_...RequestFromJsonDecoders`
  of `SessionRequest`, `LineRequest`, `CallRequest`. Each level tries its map, then the level
  below; an event level ends with its error event (`SessionErrorEvent`, `CallErrorEvent`, ...).
- A few decoders switch instead: `Response.fromJson` on `response`, `PeerMessageEvent` and
  `PeerMessageRequest` on the `type` inside the message, `NotifyEvent` on `notify`. The peer
  message event and notify event fall back to `UnknownPeerMessageEvent` / `UnknownNotifyEvent`.

### Adding an event or a request

- A class extending the right level (`SessionEvent`, `LineEvent`, `CallEvent`, or the request
  counterpart) with `typeValue`, `fromJson`, `toJson` and `props`; export it from that level's
  barrel (`call_events.dart`, `line_requests.dart`, ...).
- Register `typeValue: X.fromJson` in that level's decoder map. An unregistered event type is
  unknown: `Event.fromJson` throws `ArgumentError`, the client hands it to `onError`, and
  `SignalingModuleImpl` treats any `onError` as a failed connection (`SignalingConnectionFailed`)
  and drops the client. An event the server sends before the app knows it therefore costs a
  reconnect; so does a `fromJson` that throws on a field.
- An unregistered request is not caught here, since the client only calls `toJson()`. It fails
  on Android: the foreground-service hub decodes every request it receives from the app isolate
  with `Request.fromJson` (`signaling_hub.dart`) and answers the execute with the error.
- A JSON fixture in `test/src/events/event_jsons.dart` (or a test file next to the others under
  `test/src/events/` / `test/src/requests/`) and a round-trip test.
- Outbound JSON always comes from the request's `toJson()`.

### Enums from the wire

A value the server may extend gets a fallback: `X.values.asNameMap()[raw] ?? X.unknown`, as
`SignalingDialogState` in [events/global/dialog_info.dart](lib/src/events/global/dialog_info.dart).
Never `X.values.byName(raw)`: an unknown value throws inside `fromJson`, which, as above, fails
the connection. Several decoders still use `byName` (`state_handshake.dart`, `hold_request.dart`,
`notify_event.dart`, `ice_media_event.dart`, `ice_slowlink_event.dart`, `presence_info.dart`);
do not copy them.

## Key internals

- Transaction: `execute(request)` registers a `Transaction` (generated id unless the request
  carries one, default timeout `defaultExecuteTransactionTimeoutDuration`, 10 s) and resolves on
  the matching `AckResponse`, throws `WebtritSignalingErrorException` on `ErrorResponse`. A
  response for a transaction already gone (timed out) is logged and ignored.
- Keepalive: a one-shot timer, started after `StateHandshake` with its `keepaliveInterval`
  (30 s when the handshake has none), restarted by every `execute`, and scheduled again after
  each keepalive answer while the socket is open. Timing out raises
  `WebtritSignalingKeepaliveTransactionTimeoutException` through `onError`; a write to a closed
  socket (`WebtritSignalingBadStateException`) just ends the loop.
- `disconnect([code, reason])` stops the timer, terminates open transactions with
  `WebtritSignalingTransactionTerminateByDisconnectException`, cancels the subscription (so
  `onDisconnect` is not called) and closes the sink.
- Close codes: `SignalingDisconnectCode` in
  [signaling_disconnect_code.dart](lib/src/signaling_disconnect_code.dart) (standard WebSocket
  codes and Core's 4xxx, `byCode`). What delay a code gets before reconnecting is decided in
  `signaling_service`: [ARCHITECTURE.md](../signaling_service/ARCHITECTURE.md), "Reconnect".

## Exceptions

All extend `WebtritSignalingException`:

- `WebtritSignalingErrorException` - the server answered with an error code
- `WebtritSignalingDisconnectedException` - `execute()` with no live subscription
- `WebtritSignalingUnknownMessageException` - an inbound message of no known kind
- `WebtritSignalingUnknownResponseException` - a response that is neither ack nor error
- `WebtritSignalingBadStateException` - a write to a closed socket
- `WebtritSignalingTransactionException` (abstract)
  - `WebtritSignalingTransactionTimeoutException`
    - `WebtritSignalingKeepaliveTransactionTimeoutException`
  - `WebtritSignalingTransactionTerminateException` (abstract)
    - `WebtritSignalingTransactionTerminateByDisconnectException`

Static helpers: `generateTransactionId()`, `generateCallId()` (24 characters), `subprotocol`,
`defaultExecuteTransactionTimeoutDuration`.

## Tests

- Unit: fixtures in `test/src/events/event_jsons.dart` and `error_event_jsons.dart`; one test
  file per message family under `test/src/`. `FakeWebtritSignalingClient` in
  `test/src/factories/fake_signaling.dart` for higher-level tests.
- Client: [test/signaling_integration_test.dart](test/signaling_integration_test.dart) drives
  `WebtritSignalingClient.inner` over a mocked `WebSocketChannel` with `fake_async` - keepalive,
  timeouts, disconnect, transaction cleanup. Extend it when you change those.
- Live: `test/live_signaling_test.dart`, tag `live`, against a real server through `TcpProxy`
  (`_tcp_proxy`); the groups skip themselves without credentials. It fetches the token once in
  `setUpAll` over `dart:io` `HttpClient`, so the package stays free of `api`, and connects with
  `force=false`.
- The pre-push gate does not run these tests; Jenkins does. Run them yourself.

## Commands

From `phone/packages/signaling/`:

```bash
fvm dart test
fvm dart test test/signaling_integration_test.dart
fvm dart test --name "buildTenantUrl"
fvm dart analyze
fvm dart format .

# live tests, real server credentials
WEBTRIT_APP_TEST_CUSTOM_CORE_URL=<host> \
WEBTRIT_APP_TEST_EMAIL_CREDENTIAL=<login> \
WEBTRIT_APP_TEST_EMAIL_VERIFY_CREDENTIAL=<password> \
fvm dart test test/live_signaling_test.dart --tags live --reporter expanded
```
