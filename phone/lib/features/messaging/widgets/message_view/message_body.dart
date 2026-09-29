import 'package:material_ui/material_ui.dart';

import 'package:quiver/collection.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';

import 'package:text_entities/text_entities.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/utils/utils.dart';

class MessageBody extends StatefulWidget {
  const MessageBody({required this.text, required this.isMine, this.style, super.key});

  final String text;
  final bool isMine;
  final TextStyle? style;

  @override
  State<MessageBody> createState() => _MessageBodyState();
}

class _MessageBodyState extends State<MessageBody> {
  static final previewsCache = LruMap<String, LinkPreview>(maximumSize: 100);
  LinkPreview? preview;
  Uri? _previewUrl;

  @override
  void initState() {
    super.initState();
    findLink(widget.text);
  }

  @override
  void didUpdateWidget(covariant MessageBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) findLink(widget.text);
  }

  void findLink(String text) {
    final url = firstLink(text)?.uri;
    _previewUrl = url;

    if (url == null) {
      if (mounted) setState(() => preview = null);
      return;
    }

    final cached = previewsCache[url.toString()];
    if (cached != null) {
      preview = cached;
      if (mounted) setState(() {});
      return;
    }

    fetchLinkPreview(url).then((value) {
      if (value != null) previewsCache[url.toString()] = value;
      // The text may have changed while the fetch ran; only the current link's preview is shown.
      if (mounted && _previewUrl == url) setState(() => preview = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final style = widget.style ?? theme.contentStyle;
    final previewDecoration = theme.roundQuoteDecoration(widget.isMine);
    final quoteDecoration = theme.strongQuoteDecoration(widget.isMine);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 600),
          sizeCurve: Curves.elasticOut,
          firstCurve: Curves.easeInExpo,
          alignment: Alignment.center,
          firstChild: Container(
            decoration: previewDecoration,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                if (preview?.imageUrl != null) ...[Image.network(preview!.imageUrl!), const SizedBox(height: 8)],
                if (preview?.title != null) ...[
                  Text(preview?.title ?? '', style: style.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                ],
                if (preview?.description != null) ...[
                  Text(preview?.description ?? '', style: style),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          secondChild: const SizedBox(),
          crossFadeState: preview != null ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        ),
        ParsedText(
          parse: TextMatchers.matchers(style, quoteDecoration),
          regexOptions: const RegexOptions(multiLine: true, dotAll: true, caseSensitive: false),
          style: style.copyWith(fontFamily: theme.textTheme.bodyMedium?.fontFamily, overflow: .ellipsis),
          softWrap: true,
          text: widget.text,
          textWidthBasis: TextWidthBasis.longestLine,
        ),
      ],
    );
  }
}
