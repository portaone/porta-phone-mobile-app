/// The argument names an ICU message refers to, read the way `gen-l10n`
/// reads them with `use-escaping` off: an apostrophe is plain text.
class IcuPlaceholders {
  /// `{name}`, and the selector of `{count, plural, ...}` together with
  /// whatever its branches refer to. The branch keys (`one`, `other`, `=0`) are
  /// not arguments and are not counted. Null when the message does not parse:
  /// an unclosed `{`, a stray `}`, an argument that is not an identifier.
  static Set<String>? namesIn(String message) => _Scanner(message).scan();
}

class _Scanner {
  _Scanner(this._message);

  static final _identifier = RegExp(r'^[A-Za-z_]\w*$');

  final String _message;
  final _names = <String>{};
  var _position = 0;

  bool get _atEnd => _position >= _message.length;

  String get _char => _message[_position];

  Set<String>? scan() => _readText(inBranch: false) ? _names : null;

  /// Plain text up to the `}` that closes a branch, left for the caller, or to
  /// the end of a top-level message.
  bool _readText({required bool inBranch}) {
    while (!_atEnd) {
      if (_char == '}') return inBranch;
      if (_char == '{') {
        _position++;
        if (!_readArgument()) return false;
      } else {
        _position++;
      }
    }
    return !inBranch;
  }

  /// An argument after its `{`, up to and including its `}`.
  bool _readArgument() {
    final name = _readSegment().trim();
    if (_atEnd || !_identifier.hasMatch(name)) return false;
    _names.add(name);
    if (_char == '}') {
      _position++;
      return true;
    }

    // `, plural` or `, select`, then the branches.
    _position++;
    _readSegment();
    if (_atEnd) return false;
    if (_char == '}') {
      _position++;
      return true;
    }

    _position++;
    while (!_atEnd && _char != '}') {
      if (_char == '{') {
        _position++;
        if (!_readText(inBranch: true)) return false;
      }
      _position++;
    }
    if (_atEnd) return false;
    _position++;
    return true;
  }

  String _readSegment() {
    final start = _position;
    while (!_atEnd && _char != ',' && _char != '}') {
      _position++;
    }
    return _message.substring(start, _position);
  }
}
