# link_preview

Pure Dart (no Flutter). Fetches the title, description and image of a web page for the preview
under a link. The app calls it through `fetchLinkPreview` (`lib/utils/link_preview.dart`), which
runs it on a background isolate; which URL to fetch comes from `text_entities`.

## Public API

- `LinkPreviewFetcher({client, timeout, maxBytes, maxImageBytes, maxRedirects}).fetch(Uri)` -> `LinkPreview?`
- `isPreviewable(Uri)` - whether a URL may be fetched at all
- `LinkPreview(title, description, image)` - `image` is the downloaded bytes, for `Image.memory`

`fetch` never throws: anything that goes wrong is logged and gives null.

## Bounds, and why

The fetch starts by itself, for links in messages that arrived, on the recipient's device. So:

| Bound | Value | Why |
|---|---|---|
| deadline | 10 s over the whole fetch, body included; on expiry the request is aborted and the body read cancelled | a timeout on headers alone does not stop a trickling body |
| body | streamed, cut at 2 MB | the head of any real page fits; a link to a file must not be downloaded |
| content type | read before the body | an image is recognised without reading it; anything but HTML/XHTML is left alone |
| image | `og:image` / `twitter:image`, downloaded here under the same destination and redirect rules as the page, `image/*` but not SVG, at most 2 MB (a bigger one is dropped, not cut), within the same deadline; handed over as bytes | an address given to `Image.network` would be fetched again with redirects nobody checks; Flutter's codecs do not decode SVG |
| shown when | there is an image or a description; a title alone gives no preview | a card reading only "Example Domain" repeats the link |
| scheme | https only | |
| destination | no localhost, reserved names, private/loopback/link-local/multicast literals | a link to `https://192.168.1.1` must not make every recipient call their router |
| redirects | followed by hand, at most 5, each checked like the first URL; in a browser followed by the browser (it refuses to hand a redirect over) and the address it lands on checked | |

The numbers follow Signal's link previews (2 MB, OkHttp's default 10 s). A public
name that resolves to a private address is not caught - that needs a DNS lookup of its own.

The User-Agent is `WhatsApp/2`: some sites (Twitter) serve Open Graph tags only to an unfurler
they recognise. Signal sends the same one for the same reason.

Nothing here depends on running on the recipient: the same fetcher works on the sender's device
or a server, which is where end-to-end messengers build previews so the recipient never contacts
the linked site.

## Commands

```bash
flutter test
flutter analyze
dart format --line-length 120 .
```

The package is pure Dart, but it is a member of the phone workspace, which needs the Flutter SDK
to resolve - so `flutter test` (or the Flutter SDK's own `dart`), not a `dart` from PATH.

Tests inject a `MockClient`; no real network. Not part of `flutter test` in `phone/`; the
pre-push hook runs it as `link-preview-test`.
