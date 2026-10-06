import 'package:app_database/src/app_database.dart';

/// Where a word of the query was found in a contact, best first.
///
/// The declaration order IS the ranking: a contact whose name starts with the
/// word is listed above one that carries it in the email alone.
enum ContactSearchMatch {
  /// The first name, the last name or the alias starts with the word.
  nameStart,

  /// A later word of a name starts with it: a middle name, a double surname.
  nameWordStart,

  /// The word is somewhere inside a name.
  insideName,

  /// The word is in a phone number and in no name.
  number,

  /// The word is in an email address and nowhere else.
  email,
}

/// One word of a query, and the one definition of "the text contains it".
///
/// The database narrows the list with [pattern] and the ranking reads the
/// kept contacts with the same pattern, so the two cannot disagree about a
/// letter case or a special character.
class ContactSearchWord {
  ContactSearchWord(String word) : pattern = RegExp.escape(word);

  /// The word as a regular expression that finds it as typed and nothing
  /// else - `.*` finds a contact with `.*` in it. Matched in any letter case.
  final String pattern;

  late final _regExp = RegExp(pattern, caseSensitive: false);

  bool isIn(String text) => _regExp.hasMatch(text);

  /// Every position the word starts at in [text], the earliest first.
  Iterable<int> startsIn(String text) sync* {
    for (var from = 0; from <= text.length;) {
      final match = _regExp.allMatches(text, from).firstOrNull;
      if (match == null) return;
      yield match.start;
      from = match.start + 1;
    }
  }
}

/// Which contacts a search keeps, and in which order.
///
/// A contact is kept when EVERY word of the query is found in it, so a second
/// word narrows the list. It is as relevant as its weakest word. Among
/// contacts of one relevance the one carrying the word EARLIER in its name
/// comes first - `Yevhen Dem` before `Andriy Yevtushenko` for "yev" - and
/// what is still equal stays in the order it came, the alphabetical one.
///
/// Keeping is the database's part: it is asked for the contacts that carry
/// every one of [words], so the rest of the list is never read. Ordering is
/// [rank], over the contacts the database handed back.
class ContactSearch {
  ContactSearch(Iterable<String> words)
    : words = [
        for (final word in words)
          if (word.isNotEmpty) ContactSearchWord(word),
      ];

  final List<ContactSearchWord> words;

  /// [contacts] with the most relevant first.
  ///
  /// Nothing is dropped here. A contact that does not answer the query -
  /// which the database is not supposed to hand over - goes to the end.
  List<FullContactData> rank(List<FullContactData> contacts) {
    if (words.isEmpty) return contacts;

    final placed = [
      for (final (incoming, contact) in contacts.indexed) (contact: contact, hit: _hitOf(contact), incoming: incoming),
    ];

    // List.sort is not stable, so the incoming position breaks the last tie.
    placed.sort((a, b) {
      final byHit = _Hit.compare(a.hit, b.hit);
      return byHit != 0 ? byHit : a.incoming.compareTo(b.incoming);
    });

    return [for (final entry in placed) entry.contact];
  }

  /// How well [data] answers the query, or null when a word of it is missing.
  ContactSearchMatch? matchOf(FullContactData data) => _hitOf(data)?.match;

  _Hit? _hitOf(FullContactData data) {
    final names = _namesOf(data.contact);

    _Hit? weakest;
    for (final word in words) {
      final hit = _hitOfWord(word, data, names);
      if (hit == null) return null;
      if (weakest == null || hit.compareTo(weakest) > 0) weakest = hit;
    }
    return weakest;
  }

  /// The names of a contact, each with the offset it has in the line it is
  /// read in: the first name opens "first last", the last name follows it,
  /// the alias is a line of its own.
  static List<({String text, int offset})> _namesOf(ContactData contact) {
    final firstName = _nameOrNull(contact.firstName);
    final lastName = _nameOrNull(contact.lastName);
    final aliasName = _nameOrNull(contact.aliasName);

    return [
      if (firstName != null) (text: firstName, offset: 0),
      if (lastName != null) (text: lastName, offset: firstName == null ? 0 : firstName.length + 1),
      if (aliasName != null) (text: aliasName, offset: 0),
    ];
  }

  /// The best place [word] is found in: the best match, and for a name the
  /// earliest position of that match.
  static _Hit? _hitOfWord(ContactSearchWord word, FullContactData data, List<({String text, int offset})> names) {
    _Hit? best;
    for (final name in names) {
      final at = _placeIn(name.text, word);
      if (at == null) continue;
      final hit = _Hit(at.match, name.offset + at.index);
      if (best == null || hit.compareTo(best) < 0) best = hit;
    }
    if (best != null) return best;

    if (data.phones.any((phone) => word.isIn(phone.number))) return const _Hit(ContactSearchMatch.number, 0);
    if (data.emails.any((email) => word.isIn(email.address))) return const _Hit(ContactSearchMatch.email, 0);
    return null;
  }

  /// Where in [name] the word sits at its best: at the very start, else at the
  /// start of a later word, else at its first occurrence.
  static ({ContactSearchMatch match, int index})? _placeIn(String name, ContactSearchWord word) {
    int? first;
    for (final at in word.startsIn(name)) {
      if (at == 0) return (match: ContactSearchMatch.nameStart, index: 0);
      // A later word starts right after something that is neither a letter
      // nor a digit - a space, a hyphen, an opening bracket.
      if (!_letterOrDigit.hasMatch(name[at - 1])) return (match: ContactSearchMatch.nameWordStart, index: at);
      first ??= at;
    }
    return first == null ? null : (match: ContactSearchMatch.insideName, index: first);
  }

  static final _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static String? _nameOrNull(String? name) {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}

/// Where a word was found: the kind of place, then how early in the name.
class _Hit implements Comparable<_Hit> {
  const _Hit(this.match, this.position);

  final ContactSearchMatch match;
  final int position;

  /// A missing hit is after every hit.
  static int compare(_Hit? a, _Hit? b) {
    if (a == null || b == null) return (a == null ? 1 : 0) - (b == null ? 1 : 0);
    return a.compareTo(b);
  }

  @override
  int compareTo(_Hit other) {
    final byMatch = match.index.compareTo(other.match.index);
    return byMatch != 0 ? byMatch : position.compareTo(other.position);
  }
}
