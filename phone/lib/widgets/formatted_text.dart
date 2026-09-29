import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:text_entities/text_entities.dart';

import 'package:webtrit_phone/utils/mail_to.dart';

final _logger = Logger('FormattedText');

/// Chat text with its links, email addresses and markup rendered.
///
/// What the text contains is decided by `parseMessage` from `text_entities`; this widget only draws
/// it. Links are atomic there, so formatting never cuts one and every tap opens the address the link
/// shows - see that package for the rules.
///
/// Set [interactive] to false where the text is a preview of something else, such as the last
/// message under a conversation row: the links are still drawn as links, but a tap goes to the row
/// underneath instead of to the browser.
class FormattedText extends StatefulWidget {
  const FormattedText({
    required this.text,
    required this.style,
    this.quoteDecoration,
    this.interactive = true,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.softWrap = true,
    this.textWidthBasis = TextWidthBasis.parent,
    super.key,
  });

  final String text;
  final TextStyle style;
  final BoxDecoration? quoteDecoration;
  final bool interactive;
  final int? maxLines;
  final TextOverflow overflow;
  final bool softWrap;
  final TextWidthBasis textWidthBasis;

  @override
  State<FormattedText> createState() => _FormattedTextState();
}

class _FormattedTextState extends State<FormattedText> {
  late ParsedMessage _parsed;
  final _recognizers = <TextEntity, TapGestureRecognizer>{};

  @override
  void initState() {
    super.initState();
    _parse();
  }

  @override
  void didUpdateWidget(covariant FormattedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.interactive != widget.interactive) _parse();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _parse() {
    _disposeRecognizers();
    _parsed = parseMessage(widget.text);
    if (!widget.interactive) return;

    for (final entity in _parsed.entities) {
      if (!entity.type.isLinkable) continue;
      _recognizers[entity] = TapGestureRecognizer()..onTap = () => _open(entity);
    }
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _open(TextEntity entity) async {
    if (entity.type == TextEntityType.email) {
      await launchMailTo(entity.value);
      return;
    }

    final uri = entity.uri;
    if (uri == null) return;
    try {
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on PlatformException catch (error, stackTrace) {
      // Resolving a handler and starting it are two different steps, and the second can still fail;
      // this runs straight from a tap, so a failure is logged rather than reported as a crash.
      _logger.warning('Could not open $uri', error, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <InlineSpan>[];
    var position = 0;

    for (final quote in _parsed.entities.where((e) => e.type == TextEntityType.quote)) {
      children.addAll(_inline(position, quote.start));
      children.add(_quote(quote));
      position = quote.end;
    }
    children.addAll(_inline(position, _parsed.text.length));

    return Text.rich(
      TextSpan(children: children, style: widget.style),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      softWrap: widget.softWrap,
      textWidthBasis: widget.textWidthBasis,
    );
  }

  InlineSpan _quote(TextEntity quote) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        decoration: widget.quoteDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 0),
        child: Text.rich(TextSpan(children: _inline(quote.start, quote.end), style: widget.style)),
      ),
    );
  }

  /// The spans of `[from, to)`, cut wherever an entity starts or ends, each styled by every entity
  /// that covers it.
  List<InlineSpan> _inline(int from, int to) {
    if (from >= to) return const [];

    final entities = _parsed.entities
        .where((e) => e.type != TextEntityType.quote && e.start < to && e.end > from)
        .toList();

    final cuts = <int>{from, to};
    for (final entity in entities) {
      if (entity.start > from) cuts.add(entity.start);
      if (entity.end < to) cuts.add(entity.end);
    }
    final ordered = cuts.toList()..sort();

    return [
      for (var i = 0; i + 1 < ordered.length; i++)
        _span(ordered[i], ordered[i + 1], entities.where((e) => e.start <= ordered[i] && e.end >= ordered[i + 1])),
    ];
  }

  TextSpan _span(int start, int end, Iterable<TextEntity> covering) {
    var style = widget.style;
    final decorations = <TextDecoration>[];
    TextEntity? link;

    for (final entity in covering) {
      switch (entity.type) {
        case TextEntityType.link || TextEntityType.email:
          link = entity;
          decorations.add(TextDecoration.underline);
          style = style.copyWith(color: widget.style.color?.withAlpha(100));
        case TextEntityType.bold:
          style = style.copyWith(fontWeight: FontWeight.bold);
        case TextEntityType.italic:
          style = style.copyWith(fontStyle: FontStyle.italic);
        case TextEntityType.strikethrough:
          decorations.add(TextDecoration.lineThrough);
        case TextEntityType.underline:
          decorations.add(TextDecoration.underline);
        case TextEntityType.code:
          style = style.copyWith(fontFamily: 'Courier');
        case TextEntityType.quote:
          break;
      }
    }

    if (decorations.isNotEmpty) style = style.copyWith(decoration: TextDecoration.combine(decorations));

    return TextSpan(
      text: _parsed.text.substring(start, end),
      style: style,
      recognizer: link == null ? null : _recognizers[link],
    );
  }
}
