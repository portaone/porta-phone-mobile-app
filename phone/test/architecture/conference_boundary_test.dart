import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The conference is a module of the call feature that its bloc composes:
/// what lives in lib/features/call/conference is handed everything it needs
/// and knows nothing of CallBloc, its state or its events. A file there that
/// reached for the bloc would work, and nothing else would notice: this test
/// is what keeps the seam.
///
/// The bloc is reached by an import as well as by a name, and by a chain of
/// imports as well as by one: a barrel of the feature that exports a file
/// which imports the bloc brings the bloc along. So the test follows the
/// imports of every file of the module through the call feature and names the
/// chain it found, and refuses a direct import of the barrels above the
/// feature (`features.dart`, the router), which carry every feature.
///
/// What it does not follow: a chain that leaves the call feature. The app's
/// own barrels (lib/models, lib/extensions, lib/repositories) import the
/// router and with it every feature, so from nearly any file of the app such
/// a walk reaches the bloc; that cycle is the app's, not this module's.
const _feature = 'lib/features/call';
const _module = '$_feature/conference';
const _bloc = '$_feature/bloc/';

final _directive = RegExp(r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''', multiLine: true);
final _aboveTheFeature = RegExp(
  r'''^\s*(?:import|export)\s+['"][^'"]*(features/features\.dart|app/router/)''',
  multiLine: true,
);
final _blocTypes = RegExp(r'\b(CallBloc|CallState|CallEvent|CallControlEvent|Emitter)\b');

/// The source of [file] without its comments, which may name the bloc freely.
String _code(File file) => file.readAsLinesSync().map((line) => line.replaceFirst(RegExp(r'//.*$'), '')).join('\n');

/// The files of the app [path] imports, exports or has as parts.
Iterable<String> _imports(String path) sync* {
  final file = File(path);
  if (!file.existsSync()) return;
  for (final match in _directive.allMatches(file.readAsStringSync())) {
    final uri = match.group(1)!;
    if (uri.startsWith('package:webtrit_phone/')) {
      yield 'lib/${uri.substring('package:webtrit_phone/'.length)}';
    } else if (!uri.contains(':')) {
      yield File(path).parent.uri.resolve(uri).toFilePath();
    }
  }
}

/// The chain of imports from [start] to the bloc's library, inside the call
/// feature; `null` when there is none.
List<String>? _chainToBloc(String start) {
  final cameFrom = <String, String?>{start: null};
  final queue = [start];
  while (queue.isNotEmpty) {
    final file = queue.removeAt(0);
    for (final imported in _imports(file)) {
      if (!imported.startsWith('$_feature/') || cameFrom.containsKey(imported)) continue;
      cameFrom[imported] = file;
      if (imported.startsWith(_bloc)) {
        final chain = <String>[];
        for (String? step = imported; step != null; step = cameFrom[step]) {
          chain.add(step);
        }
        return chain.reversed.toList();
      }
      queue.add(imported);
    }
  }
  return null;
}

void main() {
  final files = Directory(_module)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  test('nothing in the conference module names the call bloc, its state or its events', () {
    final offenders = files.where((file) => _blocTypes.hasMatch(_code(file))).map((file) => file.path).toSet();

    expect(offenders, isEmpty);
  });

  test('the walk finds a chain where there is one: the barrel of the models', () {
    // models.dart exports a file that imports the bloc; a walk that misses it
    // would pass the test below whatever the module imports.
    expect(_chainToBloc('$_feature/models/models.dart'), isNotNull);
  });

  test('nothing in the conference module imports a barrel above the call feature', () {
    final offenders = files.where((file) => _aboveTheFeature.hasMatch(_code(file))).map((file) => file.path).toSet();

    expect(offenders, isEmpty);
  });

  test('no chain of imports leads from the conference module to the call bloc', () {
    final chains = {
      for (final file in files)
        if (_chainToBloc(file.path) case final chain?) file.path: chain.join(' -> '),
    };

    expect(chains, isEmpty);
  });
}
