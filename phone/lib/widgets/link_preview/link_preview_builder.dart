import 'package:material_ui/material_ui.dart';

import 'package:quiver/collection.dart';

import 'package:text_entities/text_entities.dart';

import 'package:webtrit_phone/utils/link_preview.dart';

/// Loads the preview of a link; [fetchLinkPreview] unless a test says otherwise.
typedef LinkPreviewLoader = Future<LinkPreview?> Function(Uri url);

/// Builds [builder] with the preview of the first link in [text], once it has arrived.
///
/// The one place a message's link becomes a preview: the link is the one `text_entities` finds - the
/// same address a tap on it opens - and previews are shared across every text on screen through one
/// cache. The cache holds downloaded images, so it is kept small.
///
/// When [text] changes while a preview is still loading, the late result is dropped: an edited
/// message never shows the preview of the link it no longer has.
class LinkPreviewBuilder extends StatefulWidget {
  const LinkPreviewBuilder({required this.text, required this.builder, this.load = fetchLinkPreview, super.key});

  final String text;

  /// [preview] is null until it has arrived, and when there is none; [url] is the link it is for.
  final Widget Function(BuildContext context, LinkPreview? preview, Uri? url) builder;

  final LinkPreviewLoader load;

  static final _cache = LruMap<String, LinkPreview>(maximumSize: 30);

  @visibleForTesting
  static void clearCache() => _cache.clear();

  @override
  State<LinkPreviewBuilder> createState() => _LinkPreviewBuilderState();
}

class _LinkPreviewBuilderState extends State<LinkPreviewBuilder> {
  LinkPreview? _preview;
  Uri? _url;

  @override
  void initState() {
    super.initState();
    _find(widget.text);
  }

  @override
  void didUpdateWidget(covariant LinkPreviewBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _find(widget.text);
  }

  void _find(String text) {
    final url = firstLink(text)?.uri;
    _url = url;

    if (url == null) {
      if (mounted) setState(() => _preview = null);
      return;
    }

    final cached = LinkPreviewBuilder._cache[url.toString()];
    if (cached != null) {
      _preview = cached;
      if (mounted) setState(() {});
      return;
    }

    widget.load(url).then(_arrived(url));
  }

  void Function(LinkPreview?) _arrived(Uri url) => (preview) {
    if (preview != null) LinkPreviewBuilder._cache[url.toString()] = preview;
    // The text may have changed while the fetch ran; only the current link's preview is shown.
    if (mounted && _url == url) setState(() => _preview = preview);
  };

  @override
  Widget build(BuildContext context) => widget.builder(context, _preview, _url);
}
