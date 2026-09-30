/// Whether a preview may be fetched from [url].
///
/// Only https, and never a host that names this device or the local network: the fetch runs on
/// the device that received the message, so a link to `http://192.168.1.1/...` would otherwise make
/// every recipient's phone call their own router. Only literal addresses and reserved names are
/// recognised - a public name that resolves to a private address still passes, since resolving it
/// here would take a lookup of its own.
bool isPreviewable(Uri url) {
  if (url.scheme != 'https' || url.host.isEmpty) return false;

  // `localhost.` and `127.0.0.1.` name the same hosts as without the dot; left in, the dot would
  // defeat every check below - the name suffixes and the address parsing alike.
  var host = url.host.toLowerCase();
  while (host.endsWith('.')) {
    host = host.substring(0, host.length - 1);
  }
  if (host.isEmpty) return false;

  if (host == 'localhost' || _reservedSuffixes.any(host.endsWith)) return false;

  if (host.contains(':')) {
    final v6 = _tryIPv6(host);
    return v6 != null && !_isLocalIPv6(v6);
  }

  // A host whose last label is a number is an IPv4 address to a browser (WHATWG) and to the system
  // resolver alike, in forms a strict parser does not accept: 127.1, 2130706433, 0x7f000001 all
  // mean 127.0.0.1, and 0177.0.0.1 is octal there but decimal 177 to Uri.parseIPv4Address. Only the
  // canonical dotted-decimal form is read the same way by everyone, so only it may pass.
  if (_numericLabel.hasMatch(host.split('.').last)) {
    if (!_canonicalIPv4.hasMatch(host)) return false;
    final v4 = _tryIPv4(host);
    return v4 != null && !_isLocalIPv4(v4);
  }

  return true;
}

final _numericLabel = RegExp(r'^(?:0x[0-9a-f]*|[0-9]+)$');

/// Four decimal parts, no leading zeros - the one IPv4 spelling with a single reading.
final _canonicalIPv4 = RegExp(r'^(?:0|[1-9][0-9]{0,2})(?:\.(?:0|[1-9][0-9]{0,2})){3}$');

const _reservedSuffixes = ['.localhost', '.local', '.internal', '.home.arpa', '.test', '.invalid', '.onion'];

List<int>? _tryIPv4(String host) {
  try {
    return Uri.parseIPv4Address(host);
  } on FormatException {
    return null;
  }
}

List<int>? _tryIPv6(String host) {
  try {
    return Uri.parseIPv6Address(host);
  } on FormatException {
    return null;
  }
}

bool _isLocalIPv4(List<int> a) {
  return a[0] == 0 || // this network
      a[0] == 10 ||
      a[0] == 127 ||
      (a[0] == 100 && a[1] >= 64 && a[1] <= 127) || // carrier-grade NAT
      (a[0] == 169 && a[1] == 254) || // link-local
      (a[0] == 172 && a[1] >= 16 && a[1] <= 31) ||
      (a[0] == 192 && a[1] == 168) ||
      a[0] >= 224; // multicast and reserved
}

bool _isLocalIPv6(List<int> bytes) {
  final allZeroPrefix = bytes.take(15).every((b) => b == 0);
  if (allZeroPrefix && (bytes[15] == 0 || bytes[15] == 1)) return true; // :: and ::1

  // IPv4-mapped ::ffff:a.b.c.d
  final mapped = bytes.take(10).every((b) => b == 0) && bytes[10] == 0xff && bytes[11] == 0xff;
  if (mapped) return _isLocalIPv4(bytes.sublist(12));

  return (bytes[0] & 0xfe) == 0xfc || // unique local fc00::/7
      (bytes[0] == 0xfe && (bytes[1] & 0xc0) == 0x80) || // link-local fe80::/10
      bytes[0] == 0xff; // multicast
}
