# ssl_certificates

`TrustedCertificates` (a list of `TrustCertificate`: bytes and an optional password) and
`initializeSecurityContext(certs)`, which builds a `dart:io` `SecurityContext` with the platform
roots plus these certificates. Used by `_http_client`, `_web_socket_channel` and the
signaling_service packages; the app loads the certificates in `lib/data/app_certificates.dart`
([certificates.md](../../docs/guides/certificates.md)).

- `initializeSecurityContext` returns `null` for an empty list, and the caller's `HttpClient`
  then uses its default context. `TrustCertificate` throws `ArgumentError` on empty bytes.
- It reaches only the Dart VM's TLS (REST, signaling socket), never the TLS inside libwebrtc: a
  `turns:` certificate needs another path ([ice_servers.md](../../docs/architecture/ice_servers.md#trusting-a-turns-certificate)).
- `lib/src/securety_context.dart` is an old typo, not a convention. Renaming it touches only the
  barrel `lib/ssl_certificates.dart`; dependents import the barrel.

No tests of its own.
