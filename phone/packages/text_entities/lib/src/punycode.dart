/// Punycode (RFC 3492) and the IDNA host conversion built on it.
///
/// `Uri` percent-encodes a non-ASCII host, which no resolver accepts; a browser and a DNS lookup
/// expect the `xn--` form instead. This covers the encoding step only - labels are lowercased, not
/// run through the full IDNA 2008 mapping, which is what a chat link needs.
library;

const _base = 36;
const _tMin = 1;
const _tMax = 26;
const _skew = 38;
const _damp = 700;
const _initialBias = 72;
const _initialN = 128;

/// Encodes [input] as Punycode, without the `xn--` prefix: `b\u00fccher` -> `bcher-kva`.
String punycodeEncode(String input) {
  final codePoints = input.runes.toList();
  final output = StringBuffer();

  for (final c in codePoints) {
    if (c < 0x80) output.writeCharCode(c);
  }

  final basicCount = output.length;
  var handled = basicCount;
  if (basicCount > 0) output.write('-');

  var n = _initialN;
  var delta = 0;
  var bias = _initialBias;

  while (handled < codePoints.length) {
    var m = 0x10FFFF;
    for (final c in codePoints) {
      if (c >= n && c < m) m = c;
    }

    delta += (m - n) * (handled + 1);
    n = m;

    for (final c in codePoints) {
      if (c < n) delta++;
      if (c != n) continue;

      var q = delta;
      for (var k = _base; ; k += _base) {
        final t = k <= bias ? _tMin : (k >= bias + _tMax ? _tMax : k - bias);
        if (q < t) break;
        output.writeCharCode(_digit(t + (q - t) % (_base - t)));
        q = (q - t) ~/ (_base - t);
      }
      output.writeCharCode(_digit(q));

      bias = _adapt(delta, handled + 1, handled == basicCount);
      delta = 0;
      handled++;
    }

    delta++;
    n++;
  }

  return output.toString();
}

/// Converts every non-ASCII label of [host] to its `xn--` form and leaves ASCII labels as they are.
String hostToAscii(String host) {
  return host
      .split('.')
      .map((label) => label.runes.any((c) => c >= 0x80) ? 'xn--${punycodeEncode(label.toLowerCase())}' : label)
      .join('.');
}

int _digit(int d) => d < 26 ? 0x61 + d : 0x30 + d - 26;

int _adapt(int delta, int numPoints, bool firstTime) {
  var d = firstTime ? delta ~/ _damp : delta ~/ 2;
  d += d ~/ numPoints;

  var k = 0;
  while (d > ((_base - _tMin) * _tMax) ~/ 2) {
    d ~/= _base - _tMin;
    k += _base;
  }

  return k + ((_base - _tMin + 1) * d) ~/ (d + _skew);
}
