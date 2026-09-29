import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:link_preview/link_preview.dart';
import 'package:test/test.dart';

const _html = {'content-type': 'text/html; charset=utf-8'};

String page({String? title, Map<String, String> meta = const {}}) {
  final tags = meta.entries.map((e) => '<meta property="${e.key}" content="${e.value}">').join();
  return '<html><head>${title == null ? '' : '<title>$title</title>'}$tags</head><body></body></html>';
}

/// The first bytes of a PNG file - not valid UTF-8, which is the point.
final _pngBytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13, 0x49, 0x48]);

/// A response that says where the client ended up after following redirects, as a browser's does.
class _LandedResponse extends http.StreamedResponse implements http.BaseResponseWithUrl {
  _LandedResponse(super.stream, super.statusCode, {required this.url, super.headers});

  @override
  final Uri url;
}

/// A client that answers with a given response as is - MockClient rebuilds the response and would
/// drop its url.
class _PassThroughClient extends http.BaseClient {
  _PassThroughClient(this.respond, this.requests);

  final Future<http.StreamedResponse> Function(http.BaseRequest) respond;
  final List<http.BaseRequest> requests;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    requests.add(request);
    return respond(request);
  }
}

void main() {
  late List<http.BaseRequest> requests;

  setUp(() => requests = []);

  /// A client that records every request and answers it with [respond].
  LinkPreviewFetcher fetcher(
    Future<http.StreamedResponse> Function(http.BaseRequest) respond, {
    int? maxBytes,
    bool clientFollowsRedirects = false,
  }) {
    return LinkPreviewFetcher(
      client: () => MockClient.streaming((request, _) {
        requests.add(request);
        return respond(request);
      }),
      maxBytes: maxBytes ?? 2 * 1024 * 1024,
      clientFollowsRedirects: clientFollowsRedirects,
    );
  }

  /// A fetcher that leaves redirects to its client, over a client that keeps the landed url.
  LinkPreviewFetcher landing(Future<http.StreamedResponse> Function(http.BaseRequest) respond) =>
      LinkPreviewFetcher(client: () => _PassThroughClient(respond, requests), clientFollowsRedirects: true);

  Future<http.StreamedResponse> ok(String body, [Map<String, String> headers = _html]) async =>
      http.StreamedResponse(Stream.value(utf8.encode(body)), 200, headers: headers);

  Future<http.StreamedResponse> bytes(List<int> body, Map<String, String> headers) async =>
      http.StreamedResponse(Stream.value(body), 200, headers: headers);

  Future<http.StreamedResponse> redirect(String location, [int status = 302]) async =>
      http.StreamedResponse(const Stream.empty(), status, headers: {'location': location});

  group('what a page contributes', () {
    test('the title element', () async {
      final preview = await fetcher((_) => ok(page(title: 'Example page'))).fetch(Uri.parse('https://example.com'));

      expect(preview, const LinkPreview(title: 'Example page'));
    });

    test('Open Graph tags win over the title element', () async {
      final preview = await fetcher(
        (_) => ok(
          page(
            title: 'Plain title',
            meta: {
              'og:title': 'OG title',
              'og:description': 'OG description',
              'og:image': 'https://cdn.example.com/a.png',
            },
          ),
        ),
      ).fetch(Uri.parse('https://example.com'));

      expect(
        preview,
        const LinkPreview(title: 'OG title', description: 'OG description', imageUrl: 'https://cdn.example.com/a.png'),
      );
    });

    test('Twitter tags when there are no Open Graph ones', () async {
      final preview = await fetcher(
        (_) =>
            ok(page(meta: {'twitter:title': 'T', 'twitter:description': 'D', 'twitter:image': 'https://x.com/i.png'})),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview, const LinkPreview(title: 'T', description: 'D', imageUrl: 'https://x.com/i.png'));
    });

    test('the description meta tag by name', () async {
      final preview = await fetcher(
        (_) => ok('<html><head><meta name="description" content="By name"></head></html>'),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview?.description, 'By name');
    });

    test('a relative image resolves against the page', () async {
      final preview = await fetcher(
        (_) => ok(page(title: 'T', meta: {'og:image': '/img/a.png'})),
      ).fetch(Uri.parse('https://example.com/blog/post'));

      expect(preview?.imageUrl, 'https://example.com/img/a.png');
    });

    test('a protocol-relative image gets the page scheme', () async {
      final preview = await fetcher(
        (_) => ok(page(title: 'T', meta: {'og:image': '//cdn.example.com/a.png'})),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview?.imageUrl, 'https://cdn.example.com/a.png');
    });

    test('an image that is not http(s) is dropped', () async {
      final preview = await fetcher(
        (_) => ok(page(title: 'T', meta: {'og:image': 'data:image/png;base64,AAAA'})),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview, const LinkPreview(title: 'T'));
    });

    test('whitespace around values is trimmed', () async {
      final preview = await fetcher((_) => ok(page(title: '  Spaced  '))).fetch(Uri.parse('https://example.com'));

      expect(preview?.title, 'Spaced');
    });

    test('a page with nothing to show has no preview', () async {
      final preview = await fetcher((_) => ok('<html><head></head></html>')).fetch(Uri.parse('https://example.com'));

      expect(preview, isNull);
    });

    test('the request names itself as a link unfurler', () async {
      await fetcher((_) => ok(page(title: 'T'))).fetch(Uri.parse('https://example.com'));

      expect(requests.single.headers['User-Agent'], LinkPreviewFetcher.userAgent);
    });
  });

  group('what a response is comes from its content type, not its address', () {
    const pages = ['https://www.gifs.com', 'https://www.jpeg.org/about', 'https://example.com/logo.png.html'];

    for (final url in pages) {
      test('$url served as HTML is a page', () async {
        final preview = await fetcher((_) => ok(page(title: 'Example page'))).fetch(Uri.parse(url));

        expect(preview, const LinkPreview(title: 'Example page'));
      });
    }

    test('an address ending in an image extension served as an image is an image', () async {
      final preview = await fetcher(
        (_) => bytes(_pngBytes, {'content-type': 'image/png'}),
      ).fetch(Uri.parse('https://example.com/logo.png'));

      expect(preview, const LinkPreview(imageUrl: 'https://example.com/logo.png'));
    });

    test('an image without an extension in its address', () async {
      final preview = await fetcher(
        (_) => bytes(_pngBytes, {'content-type': 'image/png'}),
      ).fetch(Uri.parse('https://example.com/avatar'));

      expect(preview, const LinkPreview(imageUrl: 'https://example.com/avatar'));
    });

    test('an image body is not read', () async {
      var listened = false;
      final preview = await fetcher((_) async {
        final body = Stream<List<int>>.fromIterable([_pngBytes]).handleError((_) {});
        return http.StreamedResponse(
          body.map((chunk) {
            listened = true;
            return chunk;
          }),
          200,
          headers: {'content-type': 'image/jpeg'},
        );
      }).fetch(Uri.parse('https://example.com/photo'));

      expect(preview?.imageUrl, 'https://example.com/photo');
      expect(listened, isFalse);
    });

    const others = ['application/pdf', 'application/octet-stream', 'video/mp4', 'application/json'];

    for (final type in others) {
      test('$type has no preview', () async {
        final preview = await fetcher(
          (_) => bytes([1, 2, 3], {'content-type': type}),
        ).fetch(Uri.parse('https://example.com/file'));

        expect(preview, isNull);
      });
    }

    test('XHTML is a page', () async {
      final preview = await fetcher(
        (_) => ok(page(title: 'X'), {'content-type': 'application/xhtml+xml'}),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview?.title, 'X');
    });

    test('a response without a content type is read as HTML', () async {
      final preview = await fetcher((_) => ok(page(title: 'Untyped'), {})).fetch(Uri.parse('https://example.com'));

      expect(preview?.title, 'Untyped');
    });

    test('the charset of the content type is honoured', () async {
      final preview = await fetcher(
        (_) => bytes(latin1.encode(page(title: 'Café')), {'content-type': 'text/html; charset=ISO-8859-1'}),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview?.title, 'Café');
    });

    test('malformed UTF-8 does not lose the page', () async {
      final body = [...utf8.encode('<html><head><title>Broken '), 0xff, 0xfe, ...utf8.encode('</title></head></html>')];
      final preview = await fetcher((_) => bytes(body, _html)).fetch(Uri.parse('https://example.com'));

      expect(preview?.title, startsWith('Broken'));
    });

    test('an error status has no preview', () async {
      final preview = await fetcher(
        (_) async => http.StreamedResponse(Stream.value(utf8.encode(page(title: 'Not found'))), 404, headers: _html),
      ).fetch(Uri.parse('https://example.com/missing'));

      expect(preview, isNull);
    });
  });

  group('where a preview may be fetched from', () {
    const refused = {
      'no scheme': 'httpbin.org/get',
      'plain http': 'http://example.com',
      'another scheme': 'ftp://example.com/file',
      'localhost': 'https://localhost/admin',
      'a .local name': 'https://printer.local/',
      'a .localhost name': 'https://app.localhost/',
      'a .internal name': 'https://metadata.google.internal/',
      'loopback': 'https://127.0.0.1/',
      'a private 10/8 address': 'https://10.1.2.3/',
      'a private 172.16/12 address': 'https://172.20.0.1/',
      'a private 192.168/16 address': 'https://192.168.1.1/',
      'link-local': 'https://169.254.169.254/latest/meta-data',
      'carrier-grade NAT': 'https://100.64.0.1/',
      'the unspecified address': 'https://0.0.0.0/',
      'IPv6 loopback': 'https://[::1]/',
      'IPv6 unique local': 'https://[fd00::1]/',
      'IPv6 link-local': 'https://[fe80::1]/',
      'IPv4-mapped private': 'https://[::ffff:192.168.1.1]/',
    };

    refused.forEach((description, url) {
      test('$description is refused without a request', () async {
        final preview = await fetcher((_) => ok(page(title: 'T'))).fetch(Uri.parse(url));

        expect(preview, isNull);
        expect(requests, isEmpty);
      });
    });

    const allowed = {
      'a public name': 'https://example.com/a',
      'a public IPv4 address': 'https://93.184.216.34/',
      'a public IPv6 address': 'https://[2606:2800:220:1::1]/',
      'a name that merely starts like a private one': 'https://10.example.com/',
    };

    allowed.forEach((description, url) {
      test('$description is fetched', () async {
        final preview = await fetcher((_) => ok(page(title: 'T'))).fetch(Uri.parse(url));

        expect(preview?.title, 'T');
        expect(requests.single.url, Uri.parse(url));
      });
    });
  });

  group('redirects', () {
    test('are followed to the page', () async {
      final preview = await fetcher(
        (request) => request.url.path == '/old' ? redirect('https://example.com/new', 301) : ok(page(title: 'New')),
      ).fetch(Uri.parse('https://example.com/old'));

      expect(preview?.title, 'New');
      expect(requests.map((r) => r.url.path), ['/old', '/new']);
    });

    test('a relative location resolves against the current address', () async {
      final preview = await fetcher(
        (request) => request.url.path == '/a/old' ? redirect('../new') : ok(page(title: 'New')),
      ).fetch(Uri.parse('https://example.com/a/old'));

      expect(preview?.title, 'New');
      expect(requests.last.url, Uri.parse('https://example.com/new'));
    });

    test('are not left to the client, so each one is checked', () async {
      await fetcher((_) => ok(page(title: 'T'))).fetch(Uri.parse('https://example.com'));

      expect(requests.single.followRedirects, isFalse);
    });

    const refusedTargets = {
      'to plain http': 'http://example.com/new',
      'to a private address': 'https://192.168.1.1/admin',
      'to localhost': 'https://localhost/',
    };

    refusedTargets.forEach((description, location) {
      test('$description is not followed', () async {
        final preview = await fetcher(
          (request) => request.url.host == 'example.com' && request.url.scheme == 'https' && request.url.path == '/'
              ? redirect(location)
              : ok(page(title: 'Should not be reached')),
        ).fetch(Uri.parse('https://example.com/'));

        expect(preview, isNull);
        expect(requests, hasLength(1));
      });
    });

    test('stop after five', () async {
      var hops = 0;
      final preview = await fetcher(
        (_) => redirect('https://example.com/${++hops}'),
      ).fetch(Uri.parse('https://example.com/0'));

      expect(preview, isNull);
      expect(requests, hasLength(6));
    });

    test('without a location give no preview', () async {
      final preview = await fetcher(
        (_) async => http.StreamedResponse(const Stream.empty(), 302),
      ).fetch(Uri.parse('https://example.com/'));

      expect(preview, isNull);
    });
  });

  group('the fetch is bounded', () {
    test('in time, when the server never answers', () {
      fakeAsync((async) {
        LinkPreview? result;
        var completed = false;
        fetcher((_) => Completer<http.StreamedResponse>().future).fetch(Uri.parse('https://example.com/slow')).then((
          value,
        ) {
          result = value;
          completed = true;
        });

        async.elapse(const Duration(seconds: 9));
        expect(completed, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(completed, isTrue);
        expect(result, isNull);
      });
    });

    test('in time, when the body never ends', () {
      fakeAsync((async) {
        var completed = false;
        final body = StreamController<List<int>>();
        body.add(utf8.encode('<html><head><title>Slow'));

        fetcher(
          (_) async => http.StreamedResponse(body.stream, 200, headers: _html),
        ).fetch(Uri.parse('https://example.com/trickle')).whenComplete(() => completed = true);

        async.elapse(const Duration(seconds: 11));
        expect(completed, isTrue);
      });
    });

    test('in size: a huge page is cut, and its head still read', () async {
      const chunkSize = 64 * 1024;
      var served = 0;
      final head = utf8.encode(page(title: 'Huge'));
      final filler = Uint8List(chunkSize)..fillRange(0, chunkSize, 0x61);

      final preview = await fetcher((_) async {
        final chunks = Stream<List<int>>.fromIterable([head, ...List.filled(800, filler)]).map((chunk) {
          served += chunk.length;
          return chunk;
        });
        return http.StreamedResponse(chunks, 200, headers: _html);
      }).fetch(Uri.parse('https://example.com/huge'));

      expect(preview?.title, 'Huge');
      expect(served, lessThan(3 * 1024 * 1024));
    });

    test('in size: the cut is configurable', () async {
      var served = 0;
      final preview = await fetcher((_) async {
        final chunks =
            Stream<List<int>>.fromIterable([
              utf8.encode(page(title: 'Small')),
              ...List.filled(100, List.filled(1024, 0x61)),
            ]).map((chunk) {
              served += chunk.length;
              return chunk;
            });
        return http.StreamedResponse(chunks, 200, headers: _html);
      }, maxBytes: 4096).fetch(Uri.parse('https://example.com/x'));

      expect(preview?.title, 'Small');
      expect(served, lessThan(8 * 1024));
    });

    test('a failing connection gives no preview instead of an error', () async {
      final preview = await fetcher(
        (_) => Future.error(http.ClientException('connection refused')),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview, isNull);
    });

    test('a body that fails midway gives no preview instead of an error', () async {
      final preview = await fetcher(
        (_) async => http.StreamedResponse(Stream.error(http.ClientException('reset')), 200, headers: _html),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview, isNull);
    });
  });

  group('an image that Flutter cannot draw is dropped', () {
    const svgs = ['/logo.svg', 'https://cdn.example.com/logo.SVG?v=2', '/logo.svgz'];

    for (final image in svgs) {
      test('og:image $image', () async {
        final preview = await fetcher(
          (_) => ok(page(title: 'T', meta: {'og:image': image})),
        ).fetch(Uri.parse('https://example.com'));

        expect(preview, const LinkPreview(title: 'T'));
      });
    }

    test('a raster image with svg in its name is kept', () async {
      final preview = await fetcher(
        (_) => ok(page(title: 'T', meta: {'og:image': '/svg-logo.png'})),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview?.imageUrl, 'https://example.com/svg-logo.png');
    });

    test('a GIF is kept, since Flutter decodes it', () async {
      final preview = await fetcher(
        (_) => ok(page(title: 'T', meta: {'og:image': '/a.gif'})),
      ).fetch(Uri.parse('https://example.com'));

      expect(preview?.imageUrl, 'https://example.com/a.gif');
    });
  });

  group('when the client follows redirects itself, as a browser does', () {
    // A browser refuses to hand a redirect to the page: followRedirects: false fails the request.
    test('the request lets the client follow them, within the same limit', () async {
      await fetcher((_) => ok(page(title: 'T')), clientFollowsRedirects: true).fetch(Uri.parse('https://example.com'));

      expect(requests.single.followRedirects, isTrue);
      expect(requests.single.maxRedirects, 5);
    });

    test('the page it landed on is previewed, relative images resolved against it', () async {
      final preview = await landing(
        (_) async => _LandedResponse(
          Stream.value(utf8.encode(page(title: 'Landed', meta: {'og:image': 'img.png'}))),
          200,
          url: Uri.parse('https://www.example.com/new/'),
          headers: _html,
        ),
      ).fetch(Uri.parse('https://example.com/old'));

      expect(preview, const LinkPreview(title: 'Landed', imageUrl: 'https://www.example.com/new/img.png'));
    });

    const refusedLandings = {
      'a private address': 'https://192.168.1.1/admin',
      'localhost': 'https://localhost/',
      'plain http': 'http://example.com/',
    };

    refusedLandings.forEach((description, landed) {
      test('landing on $description gives no preview', () async {
        var bodyRead = false;
        final preview = await landing(
          (_) async => _LandedResponse(
            Stream.value(utf8.encode(page(title: 'Should not be read'))).map((chunk) {
              bodyRead = true;
              return chunk;
            }),
            200,
            url: Uri.parse(landed),
            headers: _html,
          ),
        ).fetch(Uri.parse('https://example.com/'));

        expect(preview, isNull);
        expect(bodyRead, isFalse);
      });
    });

    test('a redirect the client gave up on gives no preview', () async {
      final preview = await fetcher(
        (_) => redirect('https://example.com/loop'),
        clientFollowsRedirects: true,
      ).fetch(Uri.parse('https://example.com/'));

      expect(preview, isNull);
    });
  });

  group('the deadline stops the fetch, not only the waiting', () {
    test('the request is aborted', () {
      fakeAsync((async) {
        http.BaseRequest? sent;
        fetcher((request) {
          sent = request;
          return Completer<http.StreamedResponse>().future;
        }).fetch(Uri.parse('https://example.com/slow'));

        async.flushMicrotasks();
        var aborted = false;
        (sent! as http.Abortable).abortTrigger!.then((_) => aborted = true);

        async.elapse(const Duration(seconds: 9));
        expect(aborted, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(aborted, isTrue);
      });
    });

    test('a body that never ends stops being read', () {
      fakeAsync((async) {
        var cancelled = false;
        final body = StreamController<List<int>>(onCancel: () => cancelled = true);
        body.add(utf8.encode('<html><head><title>Slow'));

        fetcher(
          (_) async => http.StreamedResponse(body.stream, 200, headers: _html),
        ).fetch(Uri.parse('https://example.com/trickle'));

        async.elapse(const Duration(seconds: 9));
        expect(cancelled, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(cancelled, isTrue);
      });
    });

    test('headers that arrive after the deadline do not start a body read', () {
      fakeAsync((async) {
        var listened = false;
        final headers = Completer<http.StreamedResponse>();

        fetcher((_) => headers.future).fetch(Uri.parse('https://example.com/late'));
        async.elapse(const Duration(seconds: 11));

        final body = StreamController<List<int>>(onListen: () => listened = true);
        headers.complete(http.StreamedResponse(body.stream, 200, headers: _html));
        async.flushMicrotasks();

        expect(body.hasListener, isFalse, reason: listened ? 'listened and then cancelled' : 'never listened');
      });
    });

    test('a fetch that finishes in time is not cut short', () async {
      final preview = await fetcher((_) => ok(page(title: 'Fast'))).fetch(Uri.parse('https://example.com'));

      expect(preview?.title, 'Fast');
    });
  });
}
