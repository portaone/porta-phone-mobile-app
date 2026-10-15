# _tcp_proxy

Internal test utility - raw TCP proxy with pause/resume for network condition simulation.

> **Not published.** This package is part of the WebTrit Phone monorepo and is used
> exclusively in tests via workspace path dependency.

## Usage

```dart
import 'package:_tcp_proxy/_tcp_proxy.dart';

// Connect to a TLS server, rewriting the Host header for WebSocket upgrade.
final proxy = TcpProxy(
  host: 'signaling.example.com',
  rewriteHostHeader: 'signaling.example.com',
);

final port = await proxy.start();

// Point your WebSocket client at 127.0.0.1 (not localhost - see note below).
final client = await WebSocket.connect('ws://127.0.0.1:$port/path');

// Simulate a network blackhole (NAT timeout, Wi-Fi drop, firewall).
proxy.pause();

// Restore transparent forwarding.
proxy.resume();

await proxy.stop();
```

> **Note:** Always use `127.0.0.1` instead of `localhost` in test URLs.
> The proxy binds on IPv4 loopback only; `localhost` may resolve to IPv6 (`::1`) first
> on some systems, causing a connection failure.

## How it works

The proxy opens a plain-TCP listener on a random local port. For each incoming connection it
opens a TLS connection to the remote server (using the correct SNI hostname) and relays bytes
transparently in both directions.

When `rewriteHostHeader` is set, the proxy buffers the first HTTP request until the end of
headers (`\r\n\r\n`), rewrites the `Host` header to the real server hostname, and then switches
to a raw byte relay for the rest of the connection lifetime.

Calling `pause()` sets an internal flag that causes all byte forwarding to be silently
discarded - simulating a network path that is physically broken but where the TCP connection
itself has not been reset (the most realistic scenario for keepalive timeout testing).
