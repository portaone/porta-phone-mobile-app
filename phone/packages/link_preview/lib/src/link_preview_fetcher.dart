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

/// Fetches a [LinkPreview] for a link, within fixed bounds.
///
/// The bounds are the point: the fetch starts on its own, for every link a message carries, on the
/// device that received it. So it is limited in time (one deadline over the whole exchange, body
/// included), in size (the body is streamed and cut, never read whole), and in destination (https
/// only, no local network, every redirect checked again). The numbers follow Signal's link previews:
/// 2 MB, and a deadline of the order of OkHttp's default 10 s.
///
/// What a response is comes from its `Content-Type`, not from the address: an image is recognised
/// without reading its body, and anything that is neither an image nor HTML is left alone.
class LinkPreviewFetcher {
  LinkPreviewFetcher({
    http.Client Function()? client,
    this.timeout = const Duration(seconds: 10),
    this.maxBytes = 2 * 1024 * 1024,
    this.maxRedirects = 5,
  }) : _client = client ?? http.Client.new;

  final http.Client Function() _client;

  /// Deadline for the whole fetch, redirects and body included.
  final Duration timeout;

  /// How much of an HTML body is read; the head of any real page fits well within it.
  final int maxBytes;

  final int maxRedirects;

  /// Some sites, Twitter among them, only serve Open Graph tags to a user agent they recognise as a
  /// link unfurler. Signal uses the same one for the same reason.
  static const userAgent = 'WhatsApp/2';

  /// The preview of [url], or null when there is none or it could not be fetched within the bounds.
  Future<LinkPreview?> fetch(Uri url) async {
    if (!isPreviewable(url)) return null;

    final client = _client();
    try {
      return await _fetch(client, url).timeout(timeout);
    } on TimeoutException {
      _logger.info('Link preview timed out for $url');
      return null;
    } catch (e) {
      _logger.info('Link preview failed for $url', e);
      return null;
    } finally {
      // Also aborts a request the deadline left behind.
      client.close();
    }
  }

  Future<LinkPreview?> _fetch(http.Client client, Uri url) async {
    var current = url;
    for (var redirects = 0; ; redirects++) {
      final request = http.Request('GET', current)
        ..followRedirects = false
        ..headers['User-Agent'] = userAgent
        ..headers['Accept'] = 'text/html,application/xhtml+xml,image/*;q=0.8';

      final response = await client.send(request);

      if (response.statusCode >= 300 && response.statusCode < 400) {
        await _discard(response);
        final location = response.headers['location'];
        if (location == null || redirects >= maxRedirects) return null;

        current = current.resolve(location);
        if (!isPreviewable(current)) return null;
        continue;
      }

      if (response.statusCode != 200) {
        await _discard(response);
        return null;
      }

      final contentType = _ContentType.parse(response.headers['content-type']);
      if (contentType.isImage) {
        await _discard(response);
        return LinkPreview(imageUrl: current.toString());
      }
      if (!contentType.isHtml) {
        await _discard(response);
        return null;
      }

      final body = await _readUpTo(response.stream, maxBytes);
      return _parse(html_parser.parse(_decode(body, contentType.charset)), current);
    }
  }

  static Future<void> _discard(http.StreamedResponse response) => response.stream.listen(null).cancel();

  /// Reads [stream] until [limit] bytes, then stops listening - which stops the download.
  static Future<Uint8List> _readUpTo(Stream<List<int>> stream, int limit) {
    final bytes = BytesBuilder(copy: false);
    final completer = Completer<Uint8List>();
    late final StreamSubscription<List<int>> subscription;

    subscription = stream.listen(
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

    return completer.future;
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

  static LinkPreview? _parse(Document document, Uri base) {
    String? meta(String key) {
      for (final element in document.getElementsByTagName('meta')) {
        if (element.attributes['property'] == key || element.attributes['name'] == key) {
          final content = element.attributes['content']?.trim();
          if (content != null && content.isNotEmpty) return content;
        }
      }
      return null;
    }

    final title = meta('og:title') ?? meta('twitter:title') ?? _nonEmpty(document.querySelector('title')?.text);
    final description = meta('og:description') ?? meta('description') ?? meta('twitter:description');
    final imageUrl = _absoluteHttpUrl(meta('og:image') ?? meta('og:image:url') ?? meta('twitter:image'), base);

    if (title == null && description == null && imageUrl == null) return null;
    return LinkPreview(title: title, description: description, imageUrl: imageUrl);
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String? _absoluteHttpUrl(String? value, Uri base) {
    if (value == null) return null;
    final resolved = Uri.tryParse(value);
    if (resolved == null) return null;

    final absolute = base.resolveUri(resolved);
    return absolute.scheme == 'https' || absolute.scheme == 'http' ? absolute.toString() : null;
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

  bool get isHtml => mimeType == 'text/html' || mimeType == 'application/xhtml+xml';
}
