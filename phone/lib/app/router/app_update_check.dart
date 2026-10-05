import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/services/services.dart';

final _logger = Logger('AppUpdateCheck');

/// Runs the Play update check for the session, and only when Play's screen
/// would cover nothing.
///
/// Play shows the update in an activity of its own, on top of the app's. The
/// app started for an incoming call on a locked phone is let over the keyguard,
/// Play's activity is not: the keyguard came back over a ringing call and left
/// nothing to answer it from.
///
/// So the check follows [CallBloc] and nothing else: it runs when the bloc's
/// state says the session has heard from the server - or has failed to reach
/// it - no call is tracked and the app is in front. A check the rule refused
/// partway, on a locked phone or because a call came in, is run again on the
/// next such state; one that reached its end is the last of the session.
class AppUpdateCheck extends StatefulWidget {
  const AppUpdateCheck({super.key, required this.child, this.createService = _createService, this.isDeviceLocked});

  final Widget child;

  /// Builds the service around the rule this widget supplies; tests substitute
  /// the Play handles here.
  final AppUpdateService Function(CanProceedWithUpdate canProceed) createService;

  /// Defaults to the keyguard state callkeep reports.
  final Future<bool> Function()? isDeviceLocked;

  static AppUpdateService _createService(CanProceedWithUpdate canProceed) => AppUpdateService(canProceed: canProceed);

  @override
  State<AppUpdateCheck> createState() => _AppUpdateCheckState();
}

class _AppUpdateCheckState extends State<AppUpdateCheck> {
  late final CallBloc _callBloc = context.read<CallBloc>();
  late final AppUpdateService _service = widget.createService(_canProceed);

  /// Cancelled once a check has reached its end.
  StreamSubscription<CallState>? _callStates;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _callStates = _callBloc.stream.listen(_onCallState);
    _onCallState(_callBloc.state);
  }

  @override
  void dispose() {
    unawaited(_callStates?.cancel());
    super.dispose();
  }

  /// What Play's screen would cover or miss, as far as the bloc knows; null when nothing.
  ///
  /// The session must have been heard of first: until then the bloc may not
  /// have the call the app was started for. A server that cannot be reached
  /// counts as well - an update is what repairs a build that can no longer
  /// connect. A lifecycle not reported yet is the state the app starts in.
  String? _obstacle(CallState state) {
    final status = state.status;
    final sessionKnown =
        state.isHandshakeEstablished || status == CallStatus.connectError || status == CallStatus.connectIssue;
    if (!sessionKnown) {
      return 'the session is not known yet ($status)';
    }
    if (state.isActive) {
      return 'a call exists';
    }
    final lifecycle = state.currentAppLifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return 'the app is not in front ($lifecycle)';
    }
    return null;
  }

  Future<void> _onCallState(CallState state) async {
    if (_checking || _obstacle(state) != null) {
      return;
    }
    _checking = true;
    final finished = await _service.check();
    _checking = false;
    if (finished) {
      _logger.info('update check finished');
      await _callStates?.cancel();
      _callStates = null;
    }
  }

  /// The lock state is the only await, and it comes first: the bloc is then
  /// read as it stands at the moment of the answer. A session that ended
  /// meanwhile has nothing to offer an update over.
  Future<bool> _canProceed() async {
    if (!mounted) {
      return false;
    }
    final isDeviceLocked = widget.isDeviceLocked ?? AndroidCallkeepUtils.activityControl.isDeviceLocked;
    if (await isDeviceLocked()) {
      _logger.info('update check put off: the phone is locked');
      return false;
    }
    if (!mounted) {
      return false;
    }
    final obstacle = _obstacle(_callBloc.state);
    if (obstacle != null) {
      _logger.info('update check put off: $obstacle');
    }
    return obstacle == null;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
