import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:text_entities/text_entities.dart';

/// A link the chat underlines has to be one the platform lets the app open.
///
/// `canLaunchUrl` answers false for a scheme the app has not declared - `<queries>` on Android 11+,
/// `LSApplicationQueriesSchemes` on iOS - and the tap handler then does nothing at all, with no
/// message. So every scheme `detectLinks` accepts must be declared on both platforms.
void main() {
  final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
  final plist = File('ios/Runner/Info.plist').readAsStringSync();

  Set<String> androidQueriedSchemes() {
    final queries = RegExp(r'<queries>(.*?)</queries>', dotAll: true).firstMatch(manifest)?.group(1) ?? '';
    return RegExp(r'android:scheme="([^"]+)"').allMatches(queries).map((m) => m.group(1)!).toSet();
  }

  Set<String> iosQueriedSchemes() {
    final array =
        RegExp(
          r'<key>LSApplicationQueriesSchemes</key>\s*<array>(.*?)</array>',
          dotAll: true,
        ).firstMatch(plist)?.group(1) ??
        '';
    return RegExp(r'<string>([^<]+)</string>').allMatches(array).map((m) => m.group(1)!).toSet();
  }

  const samples = {
    'http': 'http://example.com/x',
    'https': 'https://example.com/x',
    'ftp': 'ftp://files.example.net/x.txt',
    'ws': 'ws://example.com/socket',
  };

  samples.forEach((scheme, url) {
    final linkified = firstLink(url)?.value == url;

    test('$scheme: underlined only if Android may open it', () {
      if (linkified) expect(androidQueriedSchemes(), contains(scheme));
    });

    test('$scheme: underlined only if iOS may open it', () {
      if (linkified) expect(iosQueriedSchemes(), contains(scheme));
    });
  });

  test('http and https links are linkified, so the checks above are not vacuous', () {
    expect(firstLink(samples['http']!)?.value, samples['http']);
    expect(firstLink(samples['https']!)?.value, samples['https']);
  });
}
