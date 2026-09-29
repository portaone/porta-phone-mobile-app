import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart' as html_parser show parse;
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'destination.dart';
import 'link_preview.dart';

final _logger = Logger('LinkPreviewFetcher');

/// Whether this is compiled for a browser.
const _onWeb = bool.fromEnvironment('dart.library.js_interop');

/// Fetches a [LinkPreview] for a link, within fixed bounds.
///
/// The bounds are the point: the fetch starts on its own, for every link a message carries, on the
/// device that received it. So it is limited in time (one deadline over the whole exchange, body
/// included), in size (the body is streamed and cut, never read whole), and in destination (https
/// only, no local network, every redirect checked again). The numbers follow Signal's link previews:
/// 2 MB, and a deadline of the order of OkHttp's default 10 s.
///
/// What a response is comes from its `Content-Type`, not from the address, and anything that is
/// neither an image nor HTML is left alone. The page's image is downloaded here too, under the same
/// rules and within the same deadline, and handed over as bytes: an address handed to the app would
/// be fetched again by `Image.network`, which checks nothing.
class LinkPreviewFetcher {
  LinkPreviewFetcher({
    http.Client Function()? client,
    this.timeout = const Duration(seconds: 10),
    this.maxBytes = 2 * 1024 * 1024,
    this.maxImageBytes = 2 * 1024 * 1024,
    this.maxRedirects = 5,
    bool? clientFollowsRedirects,
  }) : _client = client ?? http.Client.new,
       _clientFollowsRedirects = clientFollowsRedirects ?? _onWeb;

  final http.Client Function() _client;

  /// Whether redirects are left to the HTTP client instead of being followed here.
  ///
  /// True in a browser, and only there: `BrowserClient` turns `followRedirects: false` into Fetch's
  /// `redirect: 'error'`, so a redirect never reaches this code - it fails the request. There the
  /// browser follows them, and the address it ended on is checked like the first one; the hops in
  /// between cannot be seen, which is what a browser page gets anyway.
  final bool _clientFollowsRedirects;

  /// Deadline for the whole fetch, redirects and body included.
  final Duration timeout;

  /// How much of an HTML body is read; the head of any real page fits well within it.
  final int maxBytes;

  /// The largest image kept; a bigger one is dropped rather than cut, since a cut image is broken.
  final int maxImageBytes;

  final int maxRedirects;

  /// Some sites, Twitter among them, only serve Open Graph tags to a user agent they recognise as a
  /// link unfurler. Signal uses the same one for the same reason.
  static const userAgent = 'WhatsApp/2';

  /// The preview of [url], or null when there is none or it could not be fetched within the bounds.
  Future<LinkPreview?> fetch(Uri url) async {
    if (!isPreviewable(url)) return null;

    final client = _client();
    final abort = Completer<void>();
    final body = _BodyReading();
    final elapsed = Stopwatch()..start();
    try {
      final page = await _page(client, url, abort.future, body).timeout(timeout);
      if (page == null) return null;

      final image =
          page.image ??
          (page.imageUrl == null
              ? null
              : await _optionalImage(client, page.imageUrl!, abort.future, body, timeout - elapsed.elapsed));

      // A title alone repeats what the link already says - a card for example.com would read only
      // "Example Domain". Show a preview only when it adds something: an image or a description.
      if (page.description == null && image == null) return null;
      return LinkPreview(title: page.title, description: page.description, image: image);
    } on TimeoutException {
      _logger.info('Link preview timed out for $url');
      return null;
    } catch (e) {
      _logger.info('Link preview failed for $url', e);
      return null;
    } finally {
      // The deadline only stops the waiting: the fetch behind it goes on unless it is stopped here.
      // The trigger aborts the request, headers or body, on clients that support it; cancelling the
      // body is what stops a browser, whose close() no longer reaches a response once its headers
      // have arrived; and close() covers everything else.
      // Not awaited: a cancel can wait on the transport indefinitely, and the fetch must return now.
      if (!abort.isCompleted) abort.complete();
      unawaited(body.cancel());
      client.close();
    }
  }

  /// The page at [url]: its text and the address of its image - or, when the link is itself an
  /// image, that image.
  Future<({String? title, String? description, Uri? imageUrl, Uint8List? image})?> _page(
    http.Client client,
    Uri url,
    Future<void> abort,
    _BodyReading body,
  ) async {
    final page = await _get(client, url, abort, body, accept: 'text/html,application/xhtml+xml,image/*;q=0.8');
    if (page == null) return null;
    final (response, landed) = page;

    final contentType = _ContentType.parse(response.headers['content-type']);
    if (contentType.isImage) {
      final image = await _readImage(response, contentType, body);
      return image == null ? null : (title: null, description: null, imageUrl: null, image: image);
    }
    if (!contentType.isHtml) {
      await body.discard(response);
      return null;
    }

    final bytes = await body.readUpTo(response.stream, maxBytes);
    final (:title, :description, :imageUrl) = _meta(html_parser.parse(_decode(bytes, contentType.charset)), landed);
    return (title: title, description: description, imageUrl: imageUrl, image: null);
  }

  /// The page's image, or null - never an error. The text is already in hand by now, and an image
  /// that fails, or does not arrive within what is left of the deadline, must not take it away.
  Future<Uint8List?> _optionalImage(
    http.Client client,
    Uri url,
    Future<void> abort,
    _BodyReading body,
    Duration left,
  ) async {
    if (left <= Duration.zero) return null;
    try {
      return await _fetchImage(client, url, abort, body).timeout(left);
    } catch (e) {
      _logger.info('Link preview image skipped for $url', e);
      return null;
    }
  }

  Future<Uint8List?> _fetchImage(http.Client client, Uri url, Future<void> abort, _BodyReading body) async {
    if (!isPreviewable(url)) return null;

    final got = await _get(client, url, abort, body, accept: 'image/*');
    if (got == null) return null;
    final (response, _) = got;

    final contentType = _ContentType.parse(response.headers['content-type']);
    if (!contentType.isImage) {
      await body.discard(response);
      return null;
    }
    return _readImage(response, contentType, body);
  }

  Future<Uint8List?> _readImage(http.StreamedResponse response, _ContentType contentType, _BodyReading body) async {
    // The app draws the image with Flutter's codecs, which do not decode SVG.
    if (!contentType.isDrawableImage) {
      await body.discard(response);
      return null;
    }

    final bytes = await body.readUpTo(response.stream, maxImageBytes + 1);
    return bytes.isEmpty || bytes.length > maxImageBytes ? null : bytes;
  }

  /// GETs [url], following redirects under the same destination rules as the first address, and
  /// returns the 200 response with the address it came from - or null, with the body let go.
  Future<(http.StreamedResponse, Uri)?> _get(
    http.Client client,
    Uri url,
    Future<void> abort,
    _BodyReading body, {
    required String accept,
  }) async {
    var current = url;
    for (var redirects = 0; ; redirects++) {
      final request = http.AbortableRequest('GET', current, abortTrigger: abort)
        ..followRedirects = _clientFollowsRedirects
        ..maxRedirects = maxRedirects
        ..headers['User-Agent'] = userAgent
        ..headers['Accept'] = accept;

      final response = await client.send(request);

      if (_clientFollowsRedirects) {
        final landed = switch (response) {
          http.BaseResponseWithUrl(:final url) => url,
          _ => current,
        };
        if (!isPreviewable(landed)) {
          await body.discard(response);
          return null;
        }
        current = landed;
      } else if (response.statusCode >= 300 && response.statusCode < 400) {
        await body.discard(response);
        final location = response.headers['location'];
        if (location == null || redirects >= maxRedirects) return null;

        current = current.resolve(location);
        if (!isPreviewable(current)) return null;
        continue;
      }

      if (response.statusCode != 200) {
        await body.discard(response);
        return null;
      }
      return (response, current);
    }
  }

  static String _decode(Uint8List bytes, String? charset) {
    final encoding = charset == null ? null : Encoding.getByName(charset);
    if (encoding == null || encoding is Utf8Codec) return utf8.decode(bytes, allowMalformed: true);

    try {
      return encoding.decode(bytes);
    } on FormatException {
      return utf8.decode(bytes, allowMalformed: true);
    }
  }

  static ({String? title, String? description, Uri? imageUrl}) _meta(Document document, Uri base) {
    String? meta(String key) {
      for (final element in document.getElementsByTagName('meta')) {
        if (element.attributes['property'] == key || element.attributes['name'] == key) {
          final content = element.attributes['content']?.trim();
          if (content != null && content.isNotEmpty) return content;
        }
      }
      return null;
    }

    return (
      title: meta('og:title') ?? meta('twitter:title') ?? _nonEmpty(document.querySelector('title')?.text),
      description: meta('og:description') ?? meta('description') ?? meta('twitter:description'),
      imageUrl: _absolute(meta('og:image') ?? meta('og:image:url') ?? meta('twitter:image'), base),
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// [value] resolved against the page; where it may be fetched from is decided by the fetch.
  static Uri? _absolute(String? value, Uri base) {
    if (value == null) return null;
    final resolved = Uri.tryParse(value);
    return resolved == null ? null : base.resolveUri(resolved);
  }
}

/// The response body a fetch is reading, so the fetch can stop it from outside - on its deadline -
/// and not only when the cap is reached.
class _BodyReading {
  StreamSubscription<List<int>>? _subscription;
  var _cancelled = false;

  Future<void> discard(http.StreamedResponse response) => response.stream.listen(null).cancel();

  /// Reads [stream] until [limit] bytes, then stops listening - which stops the download.
  Future<Uint8List> readUpTo(Stream<List<int>> stream, int limit) {
    final bytes = BytesBuilder(copy: false);
    final completer = Completer<Uint8List>();
    late final StreamSubscription<List<int>> subscription;

    subscription = _subscription = stream.listen(
      (chunk) {
        final room = limit - bytes.length;
        bytes.add(chunk.length <= room ? chunk : chunk.sublist(0, room));
        if (bytes.length >= limit && !completer.isCompleted) {
          subscription.cancel();
          completer.complete(bytes.takeBytes());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) completer.completeError(error, stackTrace);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(bytes.takeBytes());
      },
      cancelOnError: true,
    );

    // A fetch the deadline already gave up on can still get here, once its headers arrive late.
    if (_cancelled) subscription.cancel();
    return completer.future;
  }

  Future<void> cancel() async {
    _cancelled = true;
    await _subscription?.cancel();
  }
}

class _ContentType {
  const _ContentType(this.mimeType, this.charset);

  /// A missing header is read as HTML: plenty of small sites send none.
  factory _ContentType.parse(String? header) {
    if (header == null || header.trim().isEmpty) return const _ContentType('text/html', null);

    final parts = header.split(';');
    String? charset;
    for (final parameter in parts.skip(1)) {
      final pair = parameter.split('=');
      if (pair.length == 2 && pair[0].trim().toLowerCase() == 'charset') {
        charset = pair[1].trim().replaceAll('"', '').toLowerCase();
      }
    }
    return _ContentType(parts.first.trim().toLowerCase(), charset);
  }

  final String mimeType;
  final String? charset;

  bool get isImage => mimeType.startsWith('image/');

  bool get isDrawableImage => isImage && !mimeType.startsWith('image/svg');

  bool get isHtml => mimeType == 'text/html' || mimeType == 'application/xhtml+xml';
}
