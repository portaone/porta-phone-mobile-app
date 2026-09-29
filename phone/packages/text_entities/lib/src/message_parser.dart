import 'link_detector.dart';
import 'text_entity.dart';

/// A message as it is shown: the text with markup characters removed, and the entities over it.
final class ParsedMessage {
  const ParsedMessage(this.text, this.entities);

  /// The text to display: emphasis markers, code backticks and quote prefixes removed.
  final String text;

  /// Entities over [text], ordered by start, an enclosing entity before the ones it contains.
  final List<TextEntity> entities;

  @override
  String toString() => 'ParsedMessage("$text", $entities)';
}

const _markers = {
  '*': TextEntityType.bold,
  '_': TextEntityType.italic,
  '~': TextEntityType.strikethrough,
  '+': TextEntityType.underline,
};

final _alphanumeric = RegExp(r'[\p{L}\p{N}]', unicode: true);
final _quotePrefix = RegExp(r'^>[ \t]*');

/// Parses chat text into what is shown and how.
///
/// Links and email addresses are found first, on the raw text, and are atomic: markup is looked for
/// only around them, may wrap a whole link, and never starts or ends inside one. This is what keeps
/// `rename my_file then open https://x.com/a_b` from turning into an italic span that swallows half
/// the link - the order Telegram, Signal and CommonMark (links bind tighter than emphasis) all use.
///
/// Markup, one line at a time:
/// - `*bold*`, `_italic_`, `~strikethrough~`, `+underline+`: a marker opens only at the start of a
///   word (not after a letter or digit, and not before a space) and closes only at its end, so
///   `snake_case`, `1+1`, `2 * 3` and `~/tmp` stay text;
/// - `` `code` ``: its content is shown as written, with no emphasis inside;
/// - `> quote`: only at the start of a line; the quoted text is parsed like any other.
ParsedMessage parseMessage(String source) {
  final out = StringBuffer();
  final ranges = <(TextEntityType, int, int)>[];

  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) out.write('\n');

    var line = lines[i];
    final prefix = _quotePrefix.firstMatch(line);
    final quoted = prefix != null && prefix.end < line.length;
    if (quoted) line = line.substring(prefix.end);

    final start = out.length;
    _LineParser(line, out, ranges).parse();
    if (quoted) ranges.add((TextEntityType.quote, start, out.length));
  }

  final text = out.toString();
  final entities = [
    for (final (type, start, end) in ranges)
      TextEntity(type: type, start: start, end: end, value: text.substring(start, end)),
  ]..sort(_outerFirst);

  return ParsedMessage(text, entities);
}

/// Orders by start; of two entities starting together the longer encloses the shorter, and of two
/// with the same range the wrapper - a quote, then formatting - comes before the link it wraps.
int _outerFirst(TextEntity a, TextEntity b) {
  if (a.start != b.start) return a.start - b.start;
  if (a.end != b.end) return b.end - a.end;
  return _depth(a.type) - _depth(b.type);
}

int _depth(TextEntityType type) => switch (type) {
  TextEntityType.quote => 0,
  TextEntityType.link || TextEntityType.email => 3,
  TextEntityType.code => 2,
  _ => 1,
};

/// Inline markup of one line.
///
/// Every closer is found by binary search over positions computed once, so the parse stays linear
/// in the length of the line whatever the markers - a long run of unclosed ones included.
class _LineParser {
  _LineParser(this.line, this.out, this.ranges) {
    for (final atom in detectLinks(line)) {
      _atomAt[atom.start] = atom;
      _covered.fillRange(atom.start, atom.end, true);
    }

    for (var j = 0; j < line.length; j++) {
      if (_covered[j]) continue;
      final c = line[j];
      if (c == '`') {
        _backticks.add(j);
      } else if (_markers.containsKey(c) && _canClose(j)) {
        _closers[c]!.add(j);
      }
    }
  }

  final String line;
  final StringBuffer out;
  final List<(TextEntityType, int, int)> ranges;

  late final _covered = List.filled(line.length, false);
  final _atomAt = <int, TextEntity>{};
  final _backticks = <int>[];
  final _closers = {for (final marker in _markers.keys) marker: <int>[]};

  void parse() => _inline(0, line.length, const {});

  void _inline(int from, int to, Set<String> open) {
    var i = from;
    while (i < to) {
      if (_emitAtom(i) case final end?) {
        i = end;
        continue;
      }

      final c = line[i];
      if (c == '`') {
        final close = _next(_backticks, i + 2, to);
        if (close >= 0) {
          final start = out.length;
          _literal(i + 1, close);
          ranges.add((TextEntityType.code, start, out.length));
          i = close + 1;
          continue;
        }
      } else if (_markers[c] case final type? when !open.contains(c) && _canOpen(i)) {
        final close = _next(_closers[c]!, i + 2, to);
        if (close >= 0) {
          final start = out.length;
          _inline(i + 1, close, {...open, c});
          ranges.add((type, start, out.length));
          i = close + 1;
          continue;
        }
      }

      out.write(c);
      i++;
    }
  }

  /// Code content: shown as written, links kept.
  void _literal(int from, int to) {
    var i = from;
    while (i < to) {
      if (_emitAtom(i) case final end?) {
        i = end;
      } else {
        out.write(line[i++]);
      }
    }
  }

  /// Writes the link or email starting at [i], if there is one, and returns where it ends.
  int? _emitAtom(int i) {
    final atom = _atomAt[i];
    if (atom == null) return null;

    final start = out.length;
    out.write(atom.value);
    ranges.add((atom.type, start, out.length));
    return atom.end;
  }

  bool _canOpen(int i) {
    if (i + 1 >= line.length || _isSpace(line[i + 1])) return false;
    return i == 0 || !_isAlphanumeric(line[i - 1]);
  }

  bool _canClose(int j) {
    if (j == 0 || _isSpace(line[j - 1])) return false;
    return j + 1 >= line.length || !_isAlphanumeric(line[j + 1]);
  }

  /// The first position in the sorted [positions] within `[from, to)`, or -1.
  static int _next(List<int> positions, int from, int to) {
    var low = 0;
    var high = positions.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (positions[mid] < from) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low < positions.length && positions[low] < to ? positions[low] : -1;
  }

  static bool _isSpace(String c) => c.trim().isEmpty;

  static bool _isAlphanumeric(String c) => _alphanumeric.hasMatch(c);
}
