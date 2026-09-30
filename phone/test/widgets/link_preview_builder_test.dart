import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/utils/link_preview.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

void main() {
  late List<Uri> requested;
  late Map<Uri, Completer<LinkPreview?>> pending;

  setUp(() {
    LinkPreviewBuilder.clearCache();
    requested = [];
    pending = {};
  });

  Future<LinkPreview?> load(Uri url) {
    requested.add(url);
    return (pending[url] = Completer<LinkPreview?>()).future;
  }

  /// What the builder was last built with.
  (LinkPreview?, Uri?)? shown;

  Widget host(String text) => MaterialApp(
    home: Scaffold(
      body: LinkPreviewBuilder(
        text: text,
        load: load,
        builder: (context, preview, url) {
          shown = (preview, url);
          return Text(preview?.title ?? 'none');
        },
      ),
    ),
  );

  const page = LinkPreview(title: 'Page', description: 'D');
  const other = LinkPreview(title: 'Other', description: 'D');

  group('LinkPreviewBuilder', () {
    testWidgets('text without a link loads nothing', (tester) async {
      await tester.pumpWidget(host('no link here'));

      expect(requested, isEmpty);
      expect(shown, (null, null));
    });

    testWidgets('loads the first link, as the address a tap on it opens', (tester) async {
      await tester.pumpWidget(host('see example.com/a and other.org'));

      expect(requested, [Uri.parse('https://example.com/a')]);
    });

    testWidgets('builds with the preview once it has arrived', (tester) async {
      await tester.pumpWidget(host('see example.com'));
      expect(find.text('none'), findsOneWidget);

      pending[Uri.parse('https://example.com')]!.complete(page);
      await tester.pumpAndSettle();

      expect(find.text('Page'), findsOneWidget);
      expect(shown, (page, Uri.parse('https://example.com')));
    });

    testWidgets('a preview that arrives after the text changed is dropped', (tester) async {
      await tester.pumpWidget(host('see first.com'));
      await tester.pumpWidget(host('see second.com'));

      pending[Uri.parse('https://first.com')]!.complete(page);
      await tester.pumpAndSettle();
      expect(find.text('none'), findsOneWidget);

      pending[Uri.parse('https://second.com')]!.complete(other);
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);
    });

    testWidgets('a text that loses its link loses its preview', (tester) async {
      await tester.pumpWidget(host('see example.com'));
      pending[Uri.parse('https://example.com')]!.complete(page);
      await tester.pumpAndSettle();

      await tester.pumpWidget(host('no link any more'));

      expect(find.text('none'), findsOneWidget);
      expect(shown, (null, null));
    });

    testWidgets('a preview is loaded once and shared through the cache', (tester) async {
      await tester.pumpWidget(host('see example.com'));
      pending[Uri.parse('https://example.com')]!.complete(page);
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host('again example.com'));

      expect(requested, hasLength(1));
      expect(find.text('Page'), findsOneWidget);
    });

    testWidgets('a link without a preview is asked again next time', (tester) async {
      await tester.pumpWidget(host('see example.com'));
      pending[Uri.parse('https://example.com')]!.complete(null);
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(host('see example.com'));

      expect(requested, hasLength(2));
    });

    testWidgets('a preview that arrives after the widget is gone does no harm', (tester) async {
      await tester.pumpWidget(host('see example.com'));
      await tester.pumpWidget(const SizedBox());

      pending[Uri.parse('https://example.com')]!.complete(page);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('LinkPreviewReveal', () {
    Widget reveal(LinkPreview? preview) => MaterialApp(
      home: Scaffold(
        body: LinkPreviewReveal(preview: preview, card: (preview) => Text('card ${preview.title}')),
      ),
    );

    testWidgets('builds no card while there is no preview', (tester) async {
      await tester.pumpWidget(reveal(null));

      expect(find.textContaining('card'), findsNothing);
    });

    testWidgets('shows the card for a preview', (tester) async {
      await tester.pumpWidget(reveal(page));
      await tester.pumpAndSettle();

      expect(find.text('card Page'), findsOneWidget);
    });
  });

  group('LinkPreviewImage', () {
    testWidgets('decodes no wider than a phone screen, and never scales a small image up', (tester) async {
      await tester.pumpWidget(MaterialApp(home: LinkPreviewImage(Uint8List.fromList([1, 2, 3]))));

      final provider = tester.widget<Image>(find.byType(Image)).image as ResizeImage;
      expect(provider.width, LinkPreviewImage.decodeWidth);
      expect(provider.allowUpscaling, isFalse);
      expect(provider.imageProvider, isA<MemoryImage>());
    });
  });
}
