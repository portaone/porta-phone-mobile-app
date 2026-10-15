# _tcp_proxy

`TcpProxy`: a TCP proxy for tests, from a local plain-TCP listener to a remote host (TLS by
default, `host` as SNI), with `pause()` / `resume()` to simulate a dead network path. A dev
dependency of `signaling`, used by `test/live_signaling_test.dart`. Usage: [README.md](README.md).

- The listener binds `127.0.0.1` only: put `127.0.0.1` in test URLs, not `localhost`, which may
  resolve to `::1` first.
- `pause()` drops bytes in both directions without closing either socket - no FIN, no RST - so
  the client sees silence, not a disconnect. That is the point: keepalive and timeout tests.
- `rewriteHostHeader` rewrites only the first request on a connection: it buffers up to 64 KB
  of headers (more destroys both sockets) and then relays raw. Bytes that arrive while paused
  before the headers are complete are lost, request included.
- `stop()` closes the listener only; relayed connections live on until either side closes.

No tests of its own. `live_signaling_test.dart` skips unless the `WEBTRIT_APP_TEST_*` core URL and
credentials are set in the environment (see the header of that file).
