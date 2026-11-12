import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/call_pull/cubit/call_pull_cubit.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockUserRepository extends Mock implements UserRepository {}

class _MockDialogInfoRepository extends Mock implements DialogInfoRepository {}

const _mainNumber = '555051';

DialogInfo _dialog(String callId) => DialogInfo(
  id: 'dialog-$callId',
  entityNumber: _mainNumber,
  state: DialogState.confirmed,
  callId: callId,
  direction: DialogDirection.recipient,
  localTag: 'local-tag',
  localNumber: _mainNumber,
  localDisplayName: null,
  remoteTag: 'remote-tag',
  remoteNumber: '555014',
  remoteDisplayName: null,
  arrivalVersion: '1',
  arrivalTime: DateTime(2026, 11, 12),
  hasVideo: false,
);

LinesState _lines(List<LineState> mainLines) => LinesState(mainLines: mainLines, guestLine: LineState.idle());

void main() {
  late _MockUserRepository userRepository;
  late _MockDialogInfoRepository dialogInfoRepository;
  late LinesStateRepositoryInMemoryImpl linesStateRepository;
  late StreamController<List<DialogInfo>> dialogs;
  late CallPullCubit cubit;

  setUp(() async {
    userRepository = _MockUserRepository();
    dialogInfoRepository = _MockDialogInfoRepository();
    linesStateRepository = LinesStateRepositoryInMemoryImpl();
    dialogs = StreamController<List<DialogInfo>>.broadcast();
    when(() => userRepository.getAndListen())
        .thenAnswer((_) => Stream.value(const UserInfo(numbers: Numbers(main: _mainNumber))));
    when(() => dialogInfoRepository.watchNumberDialogs(_mainNumber)).thenAnswer((_) => dialogs.stream);
    cubit = CallPullCubit(
      userRepository: userRepository,
      dialogInfoRepository: dialogInfoRepository,
      linesStateRepository: linesStateRepository,
      callPullVideoStrategy: CallPullVideoStrategy.softMute,
    )..init();
    await pumpEventQueue();
  });

  tearDown(() async {
    await cubit.close();
    await dialogs.close();
  });

  Future<void> setLines(List<LineState> mainLines) async {
    linesStateRepository.setState(_lines(mainLines));
    await pumpEventQueue();
  }

  Future<void> setDialogs(List<DialogInfo> value) async {
    dialogs.add(value);
    await pumpEventQueue();
  }

  test('offers a call that rang here and was answered on another device', () async {
    await setLines([LineState.inUse(callId: 'forked', ringingOnly: true)]);
    await setLines([LineState.idle()]);
    await setDialogs([_dialog('forked')]);

    expect(cubit.state, [_dialog('forked')]);
  });

  test('hides a call while it still rings here', () async {
    await setLines([LineState.inUse(callId: 'forked', ringingOnly: true)]);
    await setDialogs([_dialog('forked')]);

    expect(cubit.state, isEmpty);

    await setLines([LineState.idle()]);

    expect(cubit.state, [_dialog('forked')]);
  });

  test('keeps hiding a call answered here after it left the line', () async {
    await setLines([LineState.inUse(callId: 'own', ringingOnly: true)]);
    await setLines([LineState.inUse(callId: 'own', ringingOnly: false)]);
    await setLines([LineState.idle()]);
    await setDialogs([_dialog('own')]);

    expect(cubit.state, isEmpty);
  });

  test('keeps hiding a call placed here after it left the line', () async {
    await setLines([LineState.inUse(callId: 'placed', ringingOnly: false)]);
    await setLines([LineState.idle()]);
    await setDialogs([_dialog('placed')]);

    expect(cubit.state, isEmpty);
  });

  test('offers a call started on another device', () async {
    await setLines([LineState.idle()]);
    await setDialogs([_dialog('elsewhere')]);

    expect(cubit.state, [_dialog('elsewhere')]);
  });
}
