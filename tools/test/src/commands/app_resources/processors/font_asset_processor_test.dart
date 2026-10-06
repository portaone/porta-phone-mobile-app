import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

import 'package:webtrit_phone_tools/src/commands/app_resources/processors/font_asset_processor.dart';

/// Which typeface a build fetches, and what it leaves in the app for it.
///
/// It used to be whatever the configuration mentioned anywhere, collected by
/// walking every nested object - so the style of the initials drawn on an avatar
/// placeholder counted as a second choice, and a second choice was refused. That
/// refusal blocked three brands in production. A theme declares its typeface in
/// one place, and that is the one place this reads.
void main() {
  late Directory target;
  late _GoogleFonts service;
  late FontAssetProcessor processor;

  setUp(() {
    target = Directory.systemTemp.createTempSync('font_asset_processor_test');
    service = _GoogleFonts();
    processor = FontAssetProcessor(
      logger: Logger(level: Level.quiet),
      client: MockClient(service.answer),
      retryPause: Duration.zero,
    );
  });

  tearDown(() => target.deleteSync(recursive: true));

  Map<String, dynamic> config({String? declared, String? nested}) => {
        if (declared != null) 'fonts': {'fontFamily': declared},
        if (nested != null)
          'avatar': {
            'metadata': {
              'initialsTextStyle': {'fontFamily': nested, 'fontSize': 16},
            },
          },
      };

  Future<void> build({String? declared = 'Be Vietnam Pro'}) => processor.process(
        lightConfig: config(declared: declared),
        darkConfig: config(declared: declared),
        resolvePath: (path) => '${target.path}/$path',
      );

  Directory bundled() => Directory('${target.path}/${FontAssetProcessor.directory}');

  List<String> filesIn(Directory directory) =>
      [for (final entry in directory.listSync()) entry.uri.pathSegments.last]..sort();

  test('a font named inside an avatar style is not a second choice', () {
    // Ten applications in production carry exactly this: a nested style whose
    // family differs from the theme's. Only one family is ever bundled.
    final request = processor.requestFor(
      lightConfig: config(declared: 'Be Vietnam Pro', nested: 'Montserrat'),
      darkConfig: config(declared: 'Be Vietnam Pro'),
    );

    expect(request?.family, 'Be Vietnam Pro', reason: 'the declared family is what gets fetched');
  });

  test('the faces go straight into the directory the app declares', () async {
    // An asset directory is not recursive. Faces used to be written into a
    // folder named after the family below it, which no pubspec entry covers,
    // so a build fetched them and then shipped without them.
    await build();

    expect(FontAssetProcessor.directory, 'assets/fonts', reason: 'the entry in phone/pubspec.yaml');
    expect(filesIn(bundled()), [
      'Be Vietnam Pro-Bold.ttf',
      'Be Vietnam Pro-Medium.ttf',
      'Be Vietnam Pro-Regular.ttf',
      'Be Vietnam Pro-SemiBold.ttf',
      'OFL.txt',
    ]);
  });

  test('a build replaces what the one before it left and nothing else', () async {
    bundled().createSync(recursive: true);
    File('${bundled().path}/Old Family-Regular.ttf').writeAsStringSync('stale');
    File('${bundled().path}/OFL.txt').writeAsStringSync('the licence of the old family');
    File('${bundled().path}/.gitkeep').writeAsStringSync('');
    service.licence = 404;

    await build();

    expect(filesIn(bundled()), [
      '.gitkeep',
      'Be Vietnam Pro-Bold.ttf',
      'Be Vietnam Pro-Medium.ttf',
      'Be Vietnam Pro-Regular.ttf',
      'Be Vietnam Pro-SemiBold.ttf',
    ]);
  });

  test('a theme that declares nothing leaves no typeface behind', () async {
    // The directory is bundled whole: the faces of another brand left in a
    // reused workspace would ship with this one.
    bundled().createSync(recursive: true);
    File('${bundled().path}/Old Family-Regular.ttf').writeAsStringSync('stale');
    File('${bundled().path}/.gitkeep').writeAsStringSync('');

    await build(declared: null);

    expect(filesIn(bundled()), ['.gitkeep']);
    expect(service.asked, isEmpty, reason: 'nothing to fetch');
  });

  test('a face that cannot be fetched leaves no part of the family', () async {
    // The app registers whatever faces the directory holds as the whole
    // family: two out of four would be drawn as if nothing were missing.
    service.failing = 'SemiBold';

    await expectLater(build(), throwsA(isA<HttpException>()));

    expect(bundled().existsSync() ? filesIn(bundled()) : <String>[], isEmpty);
  });

  test('a request the network drops is made again', () async {
    service.dropFirst = 2;

    await build();

    expect(filesIn(bundled()), hasLength(5));
  });

  test('the weights the app draws are fetched whatever the theme names', () {
    // The stock theme names 500, 600 and 700 and never 400: a weight appears
    // in a theme only where it overrides a style. Fetching just those left a
    // build without the regular face.
    final request = processor.requestFor(
      lightConfig: {
        ...config(declared: 'Montserrat'),
        'button': {
          'textStyle': {
            'fontWeight': {'weight': 800},
          },
        },
      },
      darkConfig: config(declared: 'Montserrat'),
    );

    expect(request?.weights, {400, 500, 600, 700, 800});
  });

  test('a weight no font file is named after is left out', () {
    final request = processor.requestFor(
      lightConfig: {
        ...config(declared: 'Montserrat'),
        'button': {
          'fontWeight': {'weight': 550},
        },
      },
      darkConfig: config(declared: 'Montserrat'),
    );

    expect(request?.weights, FontAssetProcessor.appWeights);
  });

  test('every weight a theme can name has a file name', () {
    expect(FontAssetProcessor.weightNames.keys, [100, 200, 300, 400, 500, 600, 700, 800, 900]);
    expect(FontAssetProcessor.weightNames.values.toSet(), hasLength(9), reason: 'two weights must not share a file');
  });
}

/// The three hosts a build talks to, answering from memory.
class _GoogleFonts {
  /// Every request made, in order.
  final asked = <Uri>[];

  /// The weight name whose face the service refuses, if any.
  String? failing;

  /// How many requests are dropped before one gets through.
  int dropFirst = 0;

  /// The status the licence is answered with.
  int licence = 200;

  Future<http.Response> answer(http.Request request) async {
    asked.add(request.url);
    if (dropFirst > 0) {
      dropFirst--;
      throw const SocketException('connection reset');
    }
    return switch (request.url.host) {
      'fonts.googleapis.com' => http.Response(_css(request.url.queryParameters['family']!), 200),
      'fonts.gstatic.com' => _face(request.url),
      _ => http.Response('licence', licence),
    };
  }

  http.Response _face(Uri url) =>
      failing != null && url.path.contains(failing!) ? http.Response('', 404) : http.Response('face', 200);

  String _css(String family) => [
        for (final weight in family.split('@').last.split(';'))
          "@font-face { font-weight: $weight; src: url(https://fonts.gstatic.com/s/${_name(weight)}.ttf) format('truetype'); }",
      ].join('\n');

  String _name(String weight) => FontAssetProcessor.weightNames[int.parse(weight)]!;
}
