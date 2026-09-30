import 'text_entity.dart';

/// Top-level domains a bare host (no scheme, no `www.`) may end in.
///
/// The list is what keeps ordinary text from being linkified: without it any dotted pair reads as a
/// host, so `string.digits`, `random.choice`, `report.pdf` and - the common one - `here.Then`, a full
/// stop with the space missing after it, would all become links. Every entry is a delegated TLD, and
/// none is a common file extension. `[a-z]{2}` covers the ccTLDs, which is why `main.rs` and
/// `user.id` still read as links, the same way they do in other messengers. The Cyrillic entries are
/// escaped because source files stay ASCII: .ukr, .bel, .srb, .mkd, .kaz, .mon, .bg.
const _tlds = [
  'com', 'org', 'net', 'edu', 'gov', 'mil', 'int', 'info', 'biz', 'name', 'pro', 'mobi', 'asia', //
  'travel', 'jobs', 'aero', 'coop', 'museum', 'cat', 'post', 'tel', 'online', 'site', 'shop',
  'store', 'blog', 'cloud', 'tech', 'space', 'website', 'xyz', 'club', 'live', 'life', 'world',
  'today', 'news', 'media', 'agency', 'company', 'group', 'team', 'digital', 'studio', 'design',
  'solutions', 'services', 'support', 'systems', 'network', 'center', 'zone', 'host', 'press', 'app',
  'dev', 'page', 'link', 'email', 'date', 'top', 'new', 'wiki', 'art', 'bar', 'fun', 'run', 'one',
  'ltd', 'inc', 'llc', 'chat', 'video', 'games', 'photo', 'photos', 'tools', 'works', 'expert',
  'global', 'business', 'best', 'guru', 'cool', 'buzz', 'academy', 'ninja', 'social', 'software',
  'marketing', 'consulting', 'education', 'events', 'community', 'finance', 'money', 'health',
  'school', 'university', 'science', 'gallery', 'photography', 'restaurant', 'kitchen', 'city',
  'family', 'fitness', 'legal', 'kyiv', 'london', 'berlin', 'paris', 'tokyo', 'nyc', 'africa', 'eco',
  'green', 'energy', 'capital', 'ventures', 'partners',
  '\u0443\u043a\u0440', '\u0431\u0435\u043b', '\u0441\u0440\u0431', '\u043c\u043a\u0434',
  '\u049b\u0430\u0437', '\u043c\u043e\u043d', '\u0431\u0433',
];

/// A host label: letters and digits of any script, with `_` and `-` inside but not at either end -
/// so the marker closing `_https://x.com_` is not read as part of the host. 63 is the DNS limit.
const _label = r'[\p{L}\p{N}](?:[\p{L}\p{N}_-]{0,61}[\p{L}\p{N}])?';
const _domain = '$_label(?:\\.$_label){0,10}';

/// Where a link starts and what its host is. The path is not part of the pattern: it is read by
/// [_linkEnd] in a single pass, which is where the rules about brackets and punctuation live.
///
/// The lookbehinds are load-bearing: without them the host is re-scanned from every offset inside
/// a long run of word characters, so a message that is one unbroken token costs O(n^2) on the UI
/// thread - ~7 s for 19k characters, an ANR on Android and a watchdog kill on iOS. They also keep an
/// email's domain (`@`), and the host behind an unsupported scheme (`ws://host`, `ftp://host`), from
/// being read as a link of its own. A bare host additionally may not continue a dotted name or a
/// `snake_case` word, so neither the tail of `ws://sub.example.com` nor `file.py` in `my_file.py`
/// is picked up; a scheme may follow `_`, which is how `_https://x.com_` stays an italic link.
final _linkStart = RegExp(
  r'(?:'
  // Userinfo is bounded so a colon-heavy token cannot make the host search quadratic.
  r"(?<![\p{L}\p{N}@-])https?://(?:[\p{L}\p{N}._~%!$&'()*+,;=:-]{1,256}@)?(?:"
  '$_domain'
  r'|\[[0-9a-f:.]{2,45}\])'
  r'|(?<![\p{L}\p{N}_@/:.-])(?:'
  'www\\.$_domain'
  '|$_domain\\.(?:${_tlds.join('|')}|[a-z]{2}|xn--[a-z0-9-]{1,59})(?![\\p{L}\\p{N}@-])'
  // A fully qualified host may end in a dot (`example.com./path`); it stays in the link only when
  // a path, query, fragment or port follows, so a full stop ending a sentence is still left out.
  r'))(?:\.(?=[/?#]|:\d))?(?::\d{1,5})?',
  caseSensitive: false,
  unicode: true,
);

/// An email address. The local part is RFC 5321's dot-string, so `a+tag@` and `o'brien@` are kept
/// whole - a partial match would open a mail to a different, real address. The match starts with a
/// letter or digit so a quote in front of it stays outside; a formatting marker in front of it is
/// settled by [_emails]. A colon in front is allowed - `Email:user@example.com`, `mailto:user@...` -
/// and credentials before a host (`https://user:pass@host`) stay inside the link, which wins.
final _email = RegExp(
  r'(?<![\p{L}\p{N}.@/])'
  r"[\p{L}\p{N}][\p{L}\p{N}!#$%&'*+/=?^_`{|}~-]{0,63}(?:\.[\p{L}\p{N}!#$%&'*+/=?^_`{|}~-]{1,63}){0,10}"
  r'@(?:[\p{L}\p{N}-]{1,63}\.){1,10}(?:\p{L}{2,63}|xn--[a-z0-9-]{1,59})(?![\p{L}\p{N}-])',
  caseSensitive: false,
  unicode: true,
);

/// A link's path can be long, but not unbounded.
const _maxPathLength = 4096;

const _openers = {'(': ')', '[': ']', '{': '}'};
const _closers = {')', ']', '}'};

/// Characters that end a sentence or a quotation far more often than they end a URL. They stay
/// inside a link and are only dropped from its end - the GitHub autolink rule.
const _trailing = {'?', '!', '.', ',', ':', ';', '*', '_', '~', "'", '"'};

/// Characters no link runs through.
const _stops = {'<', '>', '"', '`'};

bool _isSpace(int codeUnit) => String.fromCharCode(codeUnit).trim().isEmpty;

/// Finds links and email addresses in [text], in order and never overlapping.
///
/// A link wins over an email address it contains, so an address in a query string, or credentials
/// before a host, keep the link a link.
List<TextEntity> detectLinks(String text) {
  final found = <TextEntity>[..._links(text), ..._emails(text)]
    ..sort((a, b) => a.start != b.start ? a.start - b.start : (a.type == TextEntityType.link ? -1 : 1));

  final result = <TextEntity>[];
  var covered = 0;
  for (final entity in found) {
    if (entity.start < covered) continue;
    result.add(entity);
    covered = entity.end;
  }
  return result;
}

/// The first link in [text], or null.
TextEntity? firstLink(String text) {
  for (final entity in detectLinks(text)) {
    if (entity.type == TextEntityType.link) return entity;
  }
  return null;
}

Iterable<TextEntity> _links(String text) sync* {
  var from = 0;
  while (from < text.length) {
    final match = _linkStart.allMatches(text, from).firstOrNull;
    if (match == null) return;

    final end = _linkEnd(text, match.end);
    yield TextEntity(type: TextEntityType.link, start: match.start, end: end, value: text.substring(match.start, end));
    from = end;
  }
}

/// Formatting markers that are also valid characters of an email local part.
const _localPartMarkers = {'_', '*', '~', '+'};

Iterable<TextEntity> _emails(String text) sync* {
  for (final match in _email.allMatches(text)) {
    // A marker in front of an address belongs to it - `_service@example.com` is a real address, and
    // dropping the `_` would open a mail to somebody else - unless the same marker closes right
    // after the address, which makes the pair formatting around it: `_john@example.com_`.
    var start = match.start;
    while (start > 0 && _localPartMarkers.contains(text[start - 1])) {
      final closesAfter = match.end < text.length && text[match.end] == text[start - 1];
      if (closesAfter) break;
      start--;
    }
    yield TextEntity(type: TextEntityType.email, start: start, end: match.end, value: text.substring(start, match.end));
  }
}

/// Where the link whose host ends at [hostEnd] ends.
///
/// A path, query or fragment runs to the first space; then the link is cut at its first bracket
/// that has no partner - so `wiki/Bird_(god)` keeps its parentheses while `(see https://x.com/a)`
/// leaves the closing one to the sentence - and the sentence punctuation at its end is dropped.
int _linkEnd(String text, int hostEnd) {
  if (hostEnd >= text.length || !'/?#'.contains(text[hostEnd])) return hostEnd;

  final limit = (hostEnd + _maxPathLength).clamp(0, text.length);
  var end = hostEnd;
  while (end < limit && !_isSpace(text.codeUnitAt(end)) && !_stops.contains(text[end])) {
    end++;
  }

  final open = <int>[];
  for (var i = hostEnd; i < end; i++) {
    final c = text[i];
    if (_openers.containsKey(c)) {
      open.add(i);
    } else if (_closers.contains(c)) {
      if (open.isEmpty || _openers[text[open.last]] != c) {
        end = i;
        break;
      }
      open.removeLast();
    }
  }
  if (open.isNotEmpty) end = open.first;

  while (end > hostEnd && _trailing.contains(text[end - 1])) {
    end--;
  }

  return end;
}
