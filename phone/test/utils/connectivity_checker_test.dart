import 'package:flutter_test/flutter_test.dart';

import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/utils/connectivity_checker.dart';

class _MockWebtritApiClient extends Mock implements WebtritApiClient {}

void main() {
  // For this file's tests only: the root level is global and outlives the file.
  final previousLevel = Logger.root.level;
  setUpAll(() => Logger.root.level = Level.OFF);
  tearDownAll(() => Logger.root.level = previousLevel);

  group('DefaultConnectivityChecker', () {
    late _MockWebtritApiClient oldClient;
    late _MockWebtritApiClient newClient;

    setUp(() {
      oldClient = _MockWebtritApiClient();
      newClient = _MockWebtritApiClient();
      when(() => oldClient.healthCheck()).thenAnswer((_) async => true);
      when(() => newClient.healthCheck()).thenAnswer((_) async => true);
    });

    // Regression guard for WT-1540: the probe must resolve a fresh client on
    // every check so that a core-URL switch after login is picked up, rather
    // than sticking to the client captured at bootstrap (default URL).
    test('resolves the current client on each probe after a URL switch', () async {
      var current = oldClient;
      final checker = DefaultConnectivityChecker(createApiClient: () => current);

      expect(await checker.checkConnection(), isTrue);
      verify(() => oldClient.healthCheck()).called(1);

      // Simulate login / core-URL switch: the factory now hands out a client
      // bound to the new session URL.
      current = newClient;

      expect(await checker.checkConnection(), isTrue);
      verify(() => newClient.healthCheck()).called(1);
      verifyNoMoreInteractions(oldClient);
    });

    test('resolves the client lazily on every probe, not once at construction', () async {
      var resolveCount = 0;
      final checker = DefaultConnectivityChecker(
        createApiClient: () {
          resolveCount++;
          return oldClient;
        },
      );

      await checker.checkConnection();
      await checker.checkConnection();

      expect(resolveCount, 2);
    });

    // healthCheck() swallows transport failures and returns false instead of
    // throwing, so the checker must propagate that boolean rather than report
    // a live connection.
    test('returns false when the health check reports failure', () async {
      when(() => oldClient.healthCheck()).thenAnswer((_) async => false);
      final checker = DefaultConnectivityChecker(createApiClient: () => oldClient);

      expect(await checker.checkConnection(), isFalse);
    });

    // Defensive guard: if resolving or probing the client ever throws, the
    // checker reports no connection instead of propagating the error.
    test('returns false when probing the client throws', () async {
      when(() => oldClient.healthCheck()).thenThrow(Exception('timeout'));
      final checker = DefaultConnectivityChecker(createApiClient: () => oldClient);

      expect(await checker.checkConnection(), isFalse);
    });
  });
}
