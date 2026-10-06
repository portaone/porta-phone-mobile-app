import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/theme/theme.dart';

/// Which files of the bundle make up which typeface.
///
/// A build writes one file per weight, `<Family>-<Weight>`, and the app has to
/// read the family back out of the name: the theme names the family, and all
/// of its files are registered under that one name.
void main() {
  test('the files of a family are gathered under its name', () {
    final families = AppFonts.facesByFamily([
      'assets/fonts/Montserrat-Regular.ttf',
      'assets/fonts/Montserrat-Medium.ttf',
      'assets/fonts/Montserrat-Bold.ttf',
    ]);

    expect(families, {
      'Montserrat': [
        'assets/fonts/Montserrat-Regular.ttf',
        'assets/fonts/Montserrat-Medium.ttf',
        'assets/fonts/Montserrat-Bold.ttf',
      ],
    });
  });

  test('a family name keeps its own spaces and hyphens', () {
    final families = AppFonts.facesByFamily([
      'assets/fonts/Be Vietnam Pro-SemiBold.ttf',
      'assets/fonts/Semi-Condensed Sans-Regular.otf',
    ]);

    expect(families.keys, ['Be Vietnam Pro', 'Semi-Condensed Sans']);
  });

  test('a file with no weight in its name is a family of one face', () {
    expect(AppFonts.facesByFamily(['assets/fonts/Lobster.ttf']).keys, ['Lobster']);
  });

  test('what is not a font file of the font directory is left alone', () {
    final families = AppFonts.facesByFamily([
      'assets/fonts/.gitkeep',
      'assets/fonts/OFL.txt',
      'assets/fonts/Montserrat/Montserrat-Regular.ttf',
      'assets/images/logo.svg',
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    ]);

    expect(families, isEmpty);
  });

  test('a face that cannot be read is not a failure of the start', () async {
    // The loader waits on the faces one after another. A later one failing
    // while an earlier one is still being read used to fail with nobody
    // listening - past the handler here, into the app's crash reports.
    final unhandled = <Object>[];
    final registered = Completer<void>();

    runZonedGuarded(() async {
      final bundle = _OneFaceUnreadable();
      final registering = AppFonts.load({'Brand Sans'}, bundle: bundle);
      await bundle.secondRequested.future;
      bundle.second.completeError(StateError('unreadable'));
      await Future<void>.delayed(Duration.zero);
      bundle.first.complete(ByteData(0));
      await registering;
      registered.complete();
    }, (error, _) => unhandled.add(error));

    await registered.future;
    expect(unhandled, isEmpty);
    expect(AppFonts.has('Brand Sans'), isFalse, reason: 'a family is registered whole or not at all');
  });
  test('a bundle whose manifest cannot be read is not a failure of the start', () async {
    await expectLater(AppFonts.load({'Brand Sans'}, bundle: _NoManifest()), completes);

    expect(AppFonts.has('Brand Sans'), isFalse);
  });

  test('only the typefaces the theme names are read', () async {
    // The faces stay in memory and are read before the first frame, so one
    // the theme never names - left in the directory by another build - is
    // not worth either.
    final bundle = _OneFaceUnreadable();

    await AppFonts.load({'Another Family'}, bundle: bundle);

    expect(bundle.secondRequested.isCompleted, isFalse, reason: 'no face of Brand Sans was asked for');
  });
}

class _NoManifest extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) => Future.error(StateError('no $key'));
}

/// A bundle of two faces: the first is slow to read, the second cannot be.
class _OneFaceUnreadable extends CachingAssetBundle {
  static const _regular = 'assets/fonts/Brand Sans-Regular.ttf';
  static const _bold = 'assets/fonts/Brand Sans-Bold.ttf';

  final first = Completer<ByteData>();
  final second = Completer<ByteData>();
  final secondRequested = Completer<void>();

  @override
  Future<ByteData> load(String key) {
    if (key == 'AssetManifest.bin') {
      return Future.value(
        const StandardMessageCodec().encodeMessage({
          for (final face in [_regular, _bold])
            face: [
              {'asset': face},
            ],
        }),
      );
    }
    if (key == _regular) return first.future;
    secondRequested.complete();
    return second.future;
  }
}
