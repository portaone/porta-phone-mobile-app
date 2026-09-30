import 'dart:async';

import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:api/api.dart';
import 'package:webtrit_phone/features/register_status/cubit/register_status_cubit.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockAppRepository extends Mock implements AppRepository {}

class _MockRegisterStatusRepository extends Mock implements RegisterStatusRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAppRepository appRepository;
  late _MockRegisterStatusRepository registerStatusRepository;
  late Completer<bool> pendingRead;
  late Completer<void> pendingWrite;
  late RegisterStatusCubit cubit;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('dev.fluttercommunity.plus/connectivity_status'),
      MockStreamHandler.inline(onListen: (_, _) {}),
    );

    appRepository = _MockAppRepository();
    registerStatusRepository = _MockRegisterStatusRepository();
    pendingRead = Completer<bool>();
    pendingWrite = Completer<void>();
    var reads = 0;
    when(() => registerStatusRepository.getRegisterStatus()).thenReturn(true);
    when(() => registerStatusRepository.setRegisterStatus(any())).thenAnswer((_) async {});
    // The fetch the constructor starts answers at once; the next one stays out.
    when(() => appRepository.getRegisterStatus())
        .thenAnswer((_) => reads++ == 0 ? Future.value(true) : pendingRead.future);
    when(() => appRepository.setRegisterStatus(any())).thenAnswer((_) => pendingWrite.future);

    cubit = RegisterStatusCubit(appRepository, registerStatusRepository);
    await pumpEventQueue();
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  final sessionGone = SessionMissingException(
    url: Uri.https('core.example', '/api/v1/app/status'),
    requestId: 'r',
    statusCode: 401,
  );

  // The shell closes this cubit when the user is logged out, and a request it
  // sent a moment earlier still completes afterwards. Nothing may then reach
  // the closed cubit: an emit throws, and the error used to escape into the
  // zone, where it was reported as a fatal crash.
  group('a request that completes after the cubit closed', () {
    test('a fetched value is dropped', () async {
      final fetch = cubit.fetchStatus();
      await cubit.close();

      pendingRead.complete(false);

      expect(await fetch, isFalse);
    });

    test('a rejected fetch is dropped', () async {
      final fetch = cubit.fetchStatus();
      await cubit.close();

      pendingRead.completeError(sessionGone);

      expect(await fetch, isFalse);
    });

    test('an accepted change is dropped', () async {
      final change = cubit.setStatus(false);
      await cubit.close();

      pendingWrite.complete();

      expect(await change, isTrue);
    });

    test('a refused change is dropped', () async {
      final change = cubit.setStatus(false);
      await cubit.close();

      pendingWrite.completeError(sessionGone);

      expect(await change, isFalse);
    });
  });

  group('while the cubit is open', () {
    test('a fetched value becomes the state', () async {
      final fetch = cubit.fetchStatus();
      pendingRead.complete(false);

      expect(await fetch, isTrue);
      expect(cubit.state.value, isFalse);
      verify(() => registerStatusRepository.setRegisterStatus(false)).called(1);
    });

    test('a refused change snaps the switch back', () async {
      final change = cubit.setStatus(false);
      expect(cubit.state.isUpdating, isTrue);

      pendingWrite.completeError(sessionGone);

      expect(await change, isFalse);
      expect(cubit.state.value, isTrue);
      expect(cubit.state.isUpdating, isFalse);
    });
  });
}
