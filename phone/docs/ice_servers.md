# ICE servers

Where the STUN/TURN servers used for WebRTC come from, how they are cached, and what happens when
the deployment offers none.

Last reviewed: 2026-09-25

## Why it exists

A public STUN server only lets a peer discover its own reflexive address; it cannot relay media, so
calls behind a symmetric NAT fail. Deployments can bundle their own coturn, and the core then serves
its address together with short-lived TURN credentials. The app uses that configuration when it is
there and keeps the public STUN server as its fallback.

## Backend contract

`GET /api/v1/system-info` advertises the capability under `core` - not in `adapter.supported`:

```json
{"core": {"version": "0.36.0", "ice_servers_configured": true}}
```

`GET /api/v1/user/ice-servers` (bearer token) serves the configuration:

```json
{
  "ttl": 43200,
  "ice_servers": [
    {"urls": ["stun:host:3478"]},
    {"username": "1788215689:8", "urls": ["turn:host:3478?transport=udp"], "credential": "..."},
    {"username": "1788215689:8", "urls": ["turns:host:443?transport=tcp"], "credential": "..."}
  ],
  "expires_at": "2026-08-31T22:34:49.607820Z",
  "trusted_certificates": ["-----BEGIN CERTIFICATE-----\n...\n-----END CERTIFICATE-----"]
}
```

The TURN credentials expire (twelve hours in the example), so a session that outlives the window has
to fetch them again.

`trusted_certificates` is optional and absent from almost every response - see
[Trusting a `turns:` certificate](#trusting-a-turns-certificate) for what it is for and why a
deployment might serve it.

## Pieces

| Piece | Where | Role |
|-------|-------|------|
| `getUserIceServers` | `packages/api/lib/src/api_client.dart` | the request; declared an optional endpoint, so a core without it fails quietly instead of logging a server error |
| `IceServersConfig` | [`../lib/models/ice_servers_config.dart`](../lib/models/ice_servers_config.dart) | the servers, already in `RTCIceServer` shape, plus the single instant their credentials expire |
| `IceServersRepository` | [`../lib/repositories/ice_servers/`](../lib/repositories/ice_servers/) | fetch, cache, renew, and the fallback |
| `CoreSupport.supportsBundledIceServers` | [`../lib/utils/core_support.dart`](../lib/utils/core_support.dart) | the capability flag, read from `core.ice_servers_configured` |
| `IceServersResolver` | [`../lib/features/call/utils/peer_connection_factory.dart`](../lib/features/call/utils/peer_connection_factory.dart) | how a consumer asks for the current configuration |
| `rtcConfigurationFrom` | the same file | the one place the map handed to `createPeerConnection` is built - servers, anchors and certificate policy together |
| `TurnCertificateVerification` | [`../lib/models/ice_settings.dart`](../lib/models/ice_settings.dart) | `verify` or `disabled`, stored per device |
| `IceConfig` | [`../lib/models/feature_access/ice_config.dart`](../lib/models/feature_access/ice_config.dart) | what the build decided: the default policy, and whether the control is offered at all |

## Resolution

Both WebRTC paths take an `IceServersResolver` - a callback, not a list - so each new peer connection
reads whatever is current at that moment and a renewed TURN credential needs no rebuild:

- calls: `DefaultPeerConnectionFactory`, wired in `lib/app/router/main_shell_blocs.dart`, applies the
  resolved servers whenever the caller passes no explicit configuration;
- the diagnostic network test: `NetworkTesterCubit`, wired in
  `lib/features/settings/features/diagnostic/view/diagnostic_screen_page.dart`, so the candidates it
  gathers are the ones a real call would gather.

`resolveIceServers()` never throws and never returns an empty list. It serves a fresh cached
configuration; otherwise it awaits a first fetch for at most `kIceServersFirstFetchTimeout` (3 s) and
returns `kFallbackRtcIceServers` on timeout or failure. A configuration that is past its renewal
point but not yet expired is served as-is while the renewal runs in the background, so call setup
never waits on it.

Nothing propagates out of a fetch: a failure is logged, reported through
`CrashlyticsUtils.recordError`, and answered with `null`. There is no caller that could act on a
throw - a call resolves the fallback and the next poll retries - and `PollingService` therefore never
sees a failing tick, so its exponential backoff does not apply here and the cadence stays flat.

## Renewal

The repository is a `Refreshable` registered with `PollingService` in
`lib/app/router/main_shell_services.dart` (interval
`WEBTRIT_APP_ICE_SERVERS_REPOSITORY_POLLING_INTERVAL_SECONDS`, 300 s by default) and only when the
core bundles servers - otherwise `EmptyIceServersRepository` is provided, which is not `Refreshable`
at all and so cannot be registered. Only the implementation carries `Refreshable` and `Disposable`;
`IceServersRepository` itself is the one method its consumers call.

Whether the deployment has anything to serve is decided once, by
`CoreSupport.supportsBundledIceServers`, before the repository is built; the repository itself holds
no second opinion and stays `isActive` for the whole session, treating every failure as transient.

A tick is a **noop** unless the cached configuration is due, so a twelve-hour expiration costs one
request per twelve hours rather than one per five minutes. Due means `now` has reached
`expires_at - IceServersConfig.renewalLeadTime` (15 minutes) - renewing ahead of the deadline keeps a
call that starts near the boundary off credentials that expire mid-setup, and leaves room for a
failed attempt to be retried by the next poll.

The model holds no ICE type of its own: `servers` is the list of `RTCIceServer` dictionaries a peer
connection is handed as-is, built once by `IceServersApiMapper` - which is also where an entry
without a URL is dropped, so nothing downstream has to re-check.

The model holds one absolute instant, so the mapper normalizes whatever the backend declared:
`expires_at` when present, otherwise `now + ttl`, and a response carrying neither is treated as
already expired - its servers still serve the call that fetched them, and the next poll asks again.
A backend granting a lifetime shorter than the lead time is therefore refetched every tick, which is
the correct reading of credentials that never live long enough to be renewed early.

A failed fetch is deliberately not cached: the configuration stays due, so the next tick retries
instead of the failure being remembered as a result.

The cache is in memory only. Nothing is written to preferences, so expired credentials cannot
outlive the session, and the cost is one fetch after a cold start.

## Limits

- Applies to **new** peer connections. A call restored after a signaling reconnect does an ICE restart
  on its existing connection and keeps the servers it was created with.
- Background isolates never create peer connections (`CallBloc` is the only site), so they need no ICE
  wiring.
- `IceSettings` also carries the certificate policy described below, so media settings and this
  configuration meet in one place. Its other members - the transport and network filters - remain a
  separate concern.

## Trusting a `turns:` certificate

A `turns:` server presents a certificate, and **libwebrtc does not consult the platform trust store
to judge it.** It verifies against a root list compiled into the shared object, and that list holds
no Let's Encrypt root - measured on `android-150.7871.01.aar`, zero ISRG entries against 62 older
roots present. A TURN server secured the way the rest of the deployment is secured is therefore
refused with a fatal `unknown_ca`, no relay candidate is gathered, and nothing reports an error:
coturn logs a closed socket, the core was never involved, and the app logs nothing at all.

The app's own `packages/ssl_certificates` cannot help. That builds a `dart:io` `SecurityContext`,
which reaches the Dart VM's TLS stack - the REST client and the signaling socket - and has no path
to the BoringSSL inside `libjingle_peerconnection_so.so`. The two are separate TLS clients in one
process, which is why the API works against a certificate the relay connection refuses.

Two independent mechanisms address it, and neither is a default.

**Trust anchors.** Whatever arrives in `trusted_certificates` is installed as an Android
`SSLCertificateVerifier` for the connection. Verification is kept - the supplied anchors decide in
place of the compiled-in list. libwebrtc hands the verifier a SINGLE certificate rather than a
chain, so **the anchor has to be the issuer, not the root**: supply the intermediate that signed the
server's certificate. Serving them from the backend rather than building them into the app is what
keeps a CA rotation from needing an application release.

A deployment serves the chain its TURN server presents - with certbot, the `chain.pem` beside the
certificate coturn is given, rewritten on every renewal. The direct issuer is the anchor that
decides; a root in the file goes unused, and extra certificates are harmless. A private CA, or a
chain that is not on the same host, is assembled by hand instead.

An empty list must never reach the plugin, which is why the key is written only when the deployment
sent something: a verifier holding no anchor of its own replaces the library's verdict and would
refuse what the built-in list accepts.

**The anchors decide the chain and nothing else.** libwebrtc still checks the hostname afterwards,
and does it itself - measured: a certificate naming only `turn.example.com`, reached at the server's
IP address, is refused with `Error(ContinueSSL, -1)` even though the supplied anchor accepted its
chain and the library logged `Validated certificate chain using custom callback`; the same build
reaches a relay the moment the address matches the name. So supplying a public CA as an anchor does
not amount to trusting every certificate that CA has ever issued.

**Certificate policy.** `TurnCertificateVerification`, stored in `IceSettings`:

| Value | Effect |
|---|---|
| `verify` | writes no `tlsCertPolicy`, leaving the native default, which already verifies |
| `disabled` | writes `tlsCertPolicy: insecure_no_check` on every entry, and withholds the anchors |

There is no third value stating `secure`: the native builder already initialises that field to
`TLS_CERT_POLICY_SECURE`, so writing it would say nothing `verify` does not.

`disabled` is wider than it reads. Measured: it drops the **hostname** check as well as the chain,
so any certificate for any name is accepted - a `turns:` host dialled by IP accepted a certificate
whose SAN named only a different hostname. Media stays protected by DTLS-SRTP either way, and the
Janus fingerprint arrives over the signaling socket, which is verified properly; what an attacker on
that connection gains is the TURN credentials, short-lived and scoped to one subscriber.

The default comes from the build (`callConfig.ice` in the app config, see
[application_config.md](application_config.md)) and a device overrides it in media settings, where
the section appears only if the deployment asked for it. The stored value is nullable so that "never
touched" and "chose the same as the default" stay distinguishable, and a later change of the brand
default still moves everyone who never touched it.

Both the call path and the diagnostic network test resolve the policy through the same
`IceSettingsRepository` method, so the screen cannot report a different verdict from the one a call
would get.

## Seeing why gathering failed

Nothing in Dart reports what the native ICE stack did. A peer connection publishes its state, not
the reasons behind it, so a server that never answers - or one whose TLS certificate libwebrtc
refuses - looks exactly like candidates that simply never arrived, with no error logged anywhere.

`WEBTRIT_APP_WEBRTC_NATIVE_LOG_SEVERITY` bridges libwebrtc's own log into the application log under
the `WebRTC.Native` logger, so it reaches the device log file and the remote sink like every other
record. `none`, `error`, `warning`, `info` (the default), `verbose`.

The default is `info` rather than something quieter because of where this library draws the line,
measured on one gathering round against a TURN server that refuses the handshake:

| Threshold | Failure visible | Lines per round |
|---|---|---|
| `none` | no | 0 |
| `warning` | **no** - codec and socket housekeeping only | 99 |
| `info` | yes | ~700 |
| `verbose` | yes, with the TLS exchange | ~990 |

So `warning` buys noise without the answer: nothing about ICE or TURN is written above `info`.

```sh
flutter run --dart-define-from-file=dart_define.json \
  --dart-define=WEBTRIT_APP_WEBRTC_NATIVE_LOG_SEVERITY=verbose
```

What a gathering round looks like when it is on:

```
Port[...:relay:Net[wlan0...]]: Starting TURN host lookup for turn.example.com:5349
Port[...]: Trying to connect to TURN server via tls @ turn.example.com:5349
OpenSSLAdapter::BeginSSL: turn.example.com
Port[...]: TURN allocate request sent, id=...
Port[...]: Received TURN allocate error response, code=401      <- the normal challenge
Port[...]: TURN allocate requested successfully, code=0
Port[...]: Gathered candidate: Cand[...:relay:...]
```

Android and iOS only: on web there is no native stack to log - WebRTC there is the browser's - so
the value is ignored. Keep it off outside an investigation - `verbose` writes several hundred lines per round. The
severity is read once, when the native factory is created, so it cannot be raised on a running
process; `initializeNativeWebrtcLogging` is called between `bootstrap` and `runApp` for that reason.
