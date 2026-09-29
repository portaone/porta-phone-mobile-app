import 'link_uri.dart';

/// What a range of message text is.
enum TextEntityType {
  link,
  email,
  bold,
  italic,
  strikethrough,
  underline,
  code,
  quote;

  /// Whether a tap on the range opens something.
  bool get isLinkable => this == link || this == email;
}

/// A typed range of text: `[start, end)` in UTF-16 code units, with the text it covers.
///
/// Ranges of one message never cross: two entities are either disjoint or one contains the other,
/// so a renderer can nest them without splitting any.
final class TextEntity {
  const TextEntity({required this.type, required this.start, required this.end, required this.value});

  final TextEntityType type;
  final int start;
  final int end;

  /// The text the range covers, exactly as it is shown.
  final String value;

  /// Where a tap on the entity goes, or null for formatting and for text that is not a valid URI.
  ///
  /// This is the one place a link becomes an address, so a tap and a link preview cannot disagree
  /// about where a link leads.
  Uri? get uri => switch (type) {
    TextEntityType.link => linkUri(value),
    TextEntityType.email => Uri(scheme: 'mailto', path: value),
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is TextEntity && other.type == type && other.start == start && other.end == end && other.value == value;

  @override
  int get hashCode => Object.hash(type, start, end, value);

  @override
  String toString() => 'TextEntity(${type.name}, $start..$end, "$value")';
}
