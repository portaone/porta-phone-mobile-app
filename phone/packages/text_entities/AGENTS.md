# text_entities

Pure Dart (no Flutter). Turns chat text into typed ranges: links, email addresses and inline
markup. What a message contains, never how it looks - the app's `FormattedText` widget
(`lib/widgets/formatted_text.dart`) draws the result, and the link preview asks it which URL to
fetch.

## Public API

| Symbol | What it does |
|---|---|
| `parseMessage(text)` | `ParsedMessage(text, entities)`: the text with markup removed, and entities over it |
| `detectLinks(text)` | links and emails on the raw text, in order, never overlapping |
| `firstLink(text)` | the first link, for the preview |
| `TextEntity.uri` / `linkUri(link)` | the address a tap opens - the single place a link becomes a `Uri` |
| `hostToAscii`, `punycodeEncode` | IDN host to its `xn--` form (`Uri` alone percent-encodes it) |

Entities never cross: two are disjoint or one contains the other, ordered outer first.

## Rules, and where they come from

- **Links first, markup around them.** A link or email is atomic; `*`, `_`, `~`, `+` and
  backticks are looked for only outside it, may wrap a whole link, never start or end inside one.
  Same order as Telegram, Signal and CommonMark ("links bind tighter than emphasis").
- **Markers need a word boundary.** One opens only when not preceded by a letter or digit and not
  followed by a space; it closes only when not preceded by a space and not followed by a letter
  or digit. No emphasis across a line break. So `snake_case`, `1+1`, `2 * 3`, `~/tmp` stay text.
- **Quote** only at the start of a line (`^>`); its content is parsed like any other text.
- **Where a link ends** is the GitHub autolink rule, applied in code (`_linkEnd`), not in a regex:
  the path runs to a space; the link is cut at its first bracket without a partner; trailing
  `? ! . , : ; * _ ~ ' "` are dropped. `wiki/Bird_(god)` keeps its parentheses,
  `(see https://x.com/a)` does not take the sentence's `)`.
- **Bare hosts need a known TLD** (`_tlds`, plus any 2-letter ccTLD and `xn--`); with `http(s)://`
  or `www.` any host works. The list is what keeps `report.pdf` and `here.Then` plain text - add
  a TLD only if it is not also a common file extension.
- **Schemes**: http and https only. `ws://`, `ftp://` and the like are not linkified at all -
  a match without its scheme would open a different address over https, and the platforms are
  not declared to open them (`test/utils/link_launch_schemes_test.dart` in the app guards that).
- **Email** local part is RFC 5321's dot-string (`a+tag@`, `o'brien@` kept whole). A link wins
  over an address inside it (`?email=a@b.com`, `user:pass@host`).

## Performance is a contract

Both functions run on the UI thread on every rebuild. The lookbehinds in `_linkStart` and
`_email` keep the host search from re-scanning inside a long word (once ~7 s for 19k chars, an
ANR); every repetition is bounded; closers are found by binary search. `test/performance_test.dart`
times every input shape that could go quadratic - add one there with any new rule.

## Commands

```bash
flutter test
flutter analyze
dart format --line-length 120 .
```

The package is pure Dart, but it is a member of the phone workspace, which needs the Flutter SDK
to resolve - so `flutter test` (or the Flutter SDK's own `dart`), not a `dart` from PATH.

Not part of `flutter test` in `phone/`; the pre-push hook runs it as `text-entities-test`.
