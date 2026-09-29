import 'punycode.dart';

final _scheme = RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false);

/// The address a detected link opens: the link as written, with `https://` in front when it carries
/// no scheme, and a non-ASCII host in its `xn--` form.
///
/// Returns null when the result is still not a URI.
Uri? linkUri(String link) {
  final withScheme = _scheme.hasMatch(link) ? link : 'https://$link';
  return Uri.tryParse(_asciiHost(withScheme));
}

/// Rewrites the host of [url] (which has a scheme) to ASCII, leaving everything else untouched.
String _asciiHost(String url) {
  final authorityStart = url.indexOf('://') + 3;
  var authorityEnd = url.length;
  for (var i = authorityStart; i < url.length; i++) {
    final c = url[i];
    if (c == '/' || c == '?' || c == '#') {
      authorityEnd = i;
      break;
    }
  }

  final authority = url.substring(authorityStart, authorityEnd);
  final hostStart = authority.lastIndexOf('@') + 1;
  var hostEnd = authority.length;
  if (!authority.startsWith('[', hostStart)) {
    final port = authority.lastIndexOf(':');
    if (port >= hostStart) hostEnd = port;
  }

  final host = authority.substring(hostStart, hostEnd);
  if (!host.runes.any((c) => c >= 0x80)) return url;

  return url.replaceRange(authorityStart + hostStart, authorityStart + hostEnd, hostToAscii(host));
}
