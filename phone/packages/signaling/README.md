# signaling

The Dart client of the Core signaling protocol over WebSocket: it opens one connection, sends
requests and waits for their answers, and hands the app the state handshake and the events Core
sends. Pure Dart - no Flutter, no code generation; the models are written by hand with
`Equatable`.

It holds one connection and nothing more. Reconnecting, queueing requests while disconnected and
keeping the connection alive in the background belong to
[`signaling_service`](../signaling_service/README.md): its `SignalingModuleImpl` creates this
client for each connection, and the app talks to `signaling_service`, not to the client.

## Usage

```dart
// Connect; force takes the session over from another device.
final client = await WebtritSignalingClient.connect(
  baseUrl, tenantId, token, force,
  connectionTimeout: const Duration(seconds: 10), // optional
);

// Register the callbacks, once.
client.listen(
  onStateHandshake: (handshake) { ... }, // the first frame of every connection
  onEvent: (event) { ... },
  onError: (error, stackTrace) { ... },  // signaling_service drops the connection on any error
  onDisconnect: (code, reason) { ... },
);

// Send a request and wait for its ack; an error answer throws.
await client.execute(HangupRequest(transaction: 'tx-1', line: 0, callId: 'call-abc'));

await client.disconnect();
```

The URL is `<baseUrl>/tenant/<tenantId>/signaling/v1?token=<token>&force=<true|false>`, the
subprotocol `webtrit-protocol`. A request waits 10 s for its answer
(`WebtritSignalingClient.defaultExecuteTransactionTimeoutDuration`); the failures are the
exceptions of `lib/src/exceptions.dart`.

[`example/signaling_example.dart`](example/signaling_example.dart) connects, prints what comes for
5 s and disconnects:

```bash
dart run example/signaling_example.dart <core-url> <token>
```

## Docs

| Document | What it covers |
| --- | --- |
| [docs/connection_liveness.md](docs/connection_liveness.md) | The keepalive and the receive watchdog, what Core does, how a connection that dies without being closed is noticed and given up |
| [docs/conference_protocol.md](docs/conference_protocol.md) | The wire format of the conference requests and events |
| [AGENTS.md](AGENTS.md) | The message hierarchy, decoding, how to add an event or a request, the exceptions, the tests |
| [Signaling architecture](../../docs/architecture/signaling_architecture_target.md) | The three layers of the app's signaling stack and where this package sits |
| [Core signaling protocol](https://github.com/WebTrit/webtrit_docs/blob/main/signaling/index.md) | The protocol itself |

## Tests

```bash
dart test
```

The client is tested over a mocked `WebSocketChannel` with `fake_async`
(`test/signaling_integration_test.dart`); the models round-trip their JSON under `test/src/`.

## License

[MIT](../../LICENSE)
