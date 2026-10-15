# SSL Certificates

`lib/data/app_certificates.dart` loads every file in `assets/certificates/` as a trusted
certificate, in addition to the platform trust store, for the app's HTTP and WebSocket connections.

- A PKCS12 password goes in `assets/certificates/credentials.json`, keyed by file name:
  `{"<file name>": "<password>"}`.
- The files are listed through `lib/app/assets.gen.dart`; after adding or removing one, regenerate
  it with `dart run build_runner build`.
- With no certificate files, or no certificate assets bundled at all, only the platform trust store
  is used.
- `melos run configurator:generate` brings a brand's certificates when a production keystore is
  present under `KEYSTORES_ROOT/<APP_ID>`.
