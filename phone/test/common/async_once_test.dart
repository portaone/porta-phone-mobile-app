import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/common/async_once.dart';

void main() {
  group('AsyncOnce', () {
    test('callers that arrive while the first run is pending share that run', () async {
      var runs = 0;
      final gate = Completer<void>();
      final once = AsyncOnce<Object>(() async {
        runs++;
        await gate.future;
        return Object();
      });

      final first = once();
      final second = once();
      expect(runs, 1, reason: 'the second caller must wait on the first run, not start another');

      gate.complete();
      expect(identical(await first, await second), isTrue);
      expect(runs, 1);
    });

    test('a run that succeeded is kept for later callers', () async {
      var runs = 0;
      final once = AsyncOnce<int>(() async => ++runs);

      expect(await once(), 1);
      expect(await once(), 1);
      expect(runs, 1);
    });

    test('a run that failed is forgotten, so the next caller tries again', () async {
      var runs = 0;
      final once = AsyncOnce<int>(() async {
        runs++;
        if (runs == 1) throw StateError('first run fails');
        return runs;
      });

      await expectLater(once(), throwsStateError);
      expect(await once(), 2);
      expect(runs, 2);
    });
  });
}
