/// Finds links, email addresses and inline markup in chat text, as typed ranges.
///
/// Pure Dart: what a message contains, not how it looks. Rendering is the app's.
library;

export 'src/link_detector.dart' show detectLinks, firstLink;
export 'src/link_uri.dart' show linkUri;
export 'src/message_parser.dart' show ParsedMessage, parseMessage;
export 'src/punycode.dart' show hostToAscii, punycodeEncode;
export 'src/text_entity.dart';
