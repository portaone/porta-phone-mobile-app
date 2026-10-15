# _web_socket_channel

`connectWebSocket(url, {protocols, connectionTimeout, pingInterval, certs})` opens a platform
socket and `createWebSocketChannel(socket)` wraps it in a `WebSocketChannel`. Used by
`signaling` (`lib/src/signaling_client.dart`); re-exports `TrustedCertificates` from
`ssl_certificates`.

- Native (`dart.library.io`): `io.WebSocket` through an `HttpClient` with the `SecurityContext`
  from `ssl_certificates`, the connection timeout and `pingInterval`.
- Web (`dart.library.js_interop`): `package:web` `WebSocket`; `certs` and `pingInterval` are
  ignored. `connectionTimeout` is a `Future.timeout` on the open, which does not close the
  socket, and an error completes with a plain string - the browser gives no detail.
- `connectWebSocket` returns `Future<dynamic>`: hand `createWebSocketChannel` only the socket the
  same platform file made.

No tests of its own; it is exercised through the `signaling` tests (`fvm flutter test` in
`../signaling`).
