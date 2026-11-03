/// Renders screens as a person sees them - real typefaces instead of the test
/// font's blocks - into `build/look/`, to look at, never to compare against.
///
/// A layout change is judged by eye before it is judged by a test; these
/// pictures are what the eye gets. They are not goldens: nothing checks them,
/// the repository keeps none, and they run only when asked
/// (`LOOK=1 fvm flutter test test/look --update-goldens`).
library;

import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether the pictures were asked for.
bool get lookRequested => Platform.environment['LOOK'] == '1';

/// Why a look test is skipped in an ordinary run.
String? get lookSkipReason => lookRequested ? null : 'renders pictures only with LOOK=1';

/// Loads Roboto and the Material icons from the Flutter SDK running the
/// tests, so text and icons draw as they do on a device.
Future<void> loadRealFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '';
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String file) async => ByteData.sublistView(File('$dir/$file').readAsBytesSync());

  final roboto = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    roboto.addFont(read('Roboto-$weight.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('MaterialIcons-Regular.otf'))).load();
}

/// Writes the app on screen to `build/look/<name>.png`.
Future<void> lookAt(String name) {
  return expectLater(find.byType(MaterialApp).first, matchesGoldenFile('../../build/look/$name.png'));
}
