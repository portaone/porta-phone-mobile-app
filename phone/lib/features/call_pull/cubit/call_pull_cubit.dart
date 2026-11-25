import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import 'own_call_ids.dart';

final _logger = Logger('CallPullCubit');

class CallPullCubit extends Cubit<List<DialogInfo>> {
  CallPullCubit({
    required this.userRepository,
    required this.dialogInfoRepository,
    required this.linesStateRepository,
    required this.callPullVideoStrategy,
  }) : super([]);

  final UserRepository userRepository;
  final DialogInfoRepository dialogInfoRepository;
  final LinesStateRepository linesStateRepository;
  final CallPullVideoStrategy callPullVideoStrategy;
  final _ownCallIds = OwnCallIds();
  StreamSubscription? _userSub;
  StreamSubscription? _dialogInfoSub;
  StreamSubscription? _linesStateSub;
  List<DialogInfo> _dialogInfos = [];
  String? _mainNumber;

  void init() {
    _userSub = userRepository.getAndListen().listen(_onUserInfo, onError: _onUserError, cancelOnError: false);

    _linesStateSub = linesStateRepository.getStateAndListen().listen(_onLinesState);
  }

  void _onUserInfo(UserInfo userInfo) {
    if (isClosed) return;
    _mainNumber = userInfo.numbers.main;
    _logger.info('Main number updated: $_mainNumber');
    _subscribeToDialogs();
  }

  void _onUserError(Object error, StackTrace stackTrace) {
    _logger.warning('Failed to get user info', error, stackTrace);
  }

  void _onLinesState(LinesState linesState) {
    if (isClosed) return;
    final now = DateTime.now();
    final inUseLines = [
      ...linesState.mainLines.whereType<InUseLineState>(),
      if (linesState.guestLine case final InUseLineState guestLine) guestLine,
    ];
    _ownCallIds.update(inUseLines, now);
    _logger.info('Lines state updated: $linesState, onLine: ${_ownCallIds.onLineCount}, own: ${_ownCallIds.ownCount}');
    _computeState();
  }

  void _subscribeToDialogs() {
    _dialogInfoSub?.cancel();
    if (_mainNumber == null) return;
    _dialogInfoSub = dialogInfoRepository.watchNumberDialogs(_mainNumber!).listen(_onDialogs);
  }

  void _onDialogs(List<DialogInfo> dialogs) {
    if (isClosed) return;
    _logger.info('Dialogs updated: ${dialogs.length} dialogs');
    _dialogInfos = dialogs;
    _computeState();
  }

  void _computeState() {
    final now = DateTime.now();
    final otherDevices = _dialogInfos
        .where((dialog) => dialog.callId != null && !_ownCallIds.contains(dialog.callId!, now))
        .toList();

    // Show only pullable for this feature
    // because showing other states have more troubles than advantages
    // e.g log dublicates on call forking, ghost calls on app restart and state sync gapps
    //
    // Under the hide-video strategy, also exclude known-video dialogs from the pull
    // list (the soft-mute strategy keeps them pullable; see CallPullVideoStrategy).
    final hideVideo = callPullVideoStrategy == CallPullVideoStrategy.hideVideo;
    final pullable = otherDevices.where((e) => e.pullable && !(hideVideo && e.hasVideo == true)).toList();

    _logger.info(
      'Computed: '
      'user:${_dialogInfos.length}/'
      'otherDevices:${otherDevices.length}/'
      'pullable:${pullable.length}',
    );

    emit(pullable);
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    _dialogInfoSub?.cancel();
    _linesStateSub?.cancel();
    return super.close();
  }
}
