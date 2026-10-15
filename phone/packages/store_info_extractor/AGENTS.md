# store_info_extractor

`StoreInfoExtractor().getStoreInfo(packageName)`: the version and store URL of the app in its
store, or `null` when the store does not list it. Used only by the two version gate screens
(`lib/features/version_gate/view/`) for their Update button; the feature, the platform table and
the known limits are in [app-update.md](../../docs/features/app-update.md).

- The client is picked at run time: `StubStoreClient` (always `null`) only on web; Android gets
  `GooglePlayStoreClient`, iOS and macOS `AppleAppStoreClient`; any other desktop platform
  throws `UnimplementedError`.
- `StoreClient` is an abstract class. The two store clients extend `BaseStoreClient`, which holds
  the `http.Client`; `StubStoreClient` extends `StoreClient` directly.
- Google Play is scraped from the HTML with `RegExp(r'\[\[\["(\d+.\d+.\d+)"\]\]')` (the dots are
  unescaped, so any character matches there); a markup change returns `null`, not an error.
  `GooglePlayStoreClient` also carries a debug `print` of the URL.
- `lib/src/_http_client/` is a private copy of an HTTP client factory without certificates: the
  app's trusted certificates (`ssl_certificates`) do not apply to store lookups.

Tests: `test/src/store_clients/`, with `MockClient`; `fvm flutter test` here. The pre-push gate
does not run them.
