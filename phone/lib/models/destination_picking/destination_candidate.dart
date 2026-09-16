import 'package:webtrit_phone/models/contact.dart';

/// What a row hands over when somebody picks it.
///
/// The lists the app sends people to are not alike: a contact row knows a
/// person, a call-history row knows a number that may belong to nobody, and
/// the keypad knows only what was typed. Rather than make every purpose cope
/// with three shapes, each row offers what it has and the purpose says whether
/// that is enough.
class DestinationCandidate {
  const DestinationCandidate({this.number, this.contact});

  /// The number this row would dial, if it has one.
  final String? number;

  /// The person behind the row, where the row knows one.
  ///
  /// Null on the keypad and on a call from a stranger. A purpose that needs an
  /// account rather than a number - forwarding a message to a colleague, say -
  /// is the reason this is carried at all.
  final Contact? contact;
}
