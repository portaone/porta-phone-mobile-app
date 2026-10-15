# _http_client

`createHttpClient({connectionTimeout, certs})`: an `http.Client` for the platform, picked by
conditional import in `lib/_http_client.dart`. Used by `api` (`WebtritApiClient`); re-exports
`TrustedCertificates` from `ssl_certificates`.

- Native (`dart.library.io`): an `IOClient` over a `dart:io` `HttpClient` with the
  `SecurityContext` from `ssl_certificates` and the connection timeout.
- Web (`dart.library.html`): a `BrowserClient`; `connectionTimeout` and `certs` are ignored -
  the browser owns both.
- Neither: the stub throws `UnsupportedError`.
- `store_info_extractor` keeps a private copy of this without certificates; a change here does
  not reach it.

No tests of its own; it is exercised through the `api` tests (`fvm flutter test` in `../api`).
