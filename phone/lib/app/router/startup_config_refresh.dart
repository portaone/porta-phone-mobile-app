import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/features.dart';

final _logger = Logger('StartupConfigRefresh');

/// Starts the session anew when the app was started on a configuration the
/// backend no longer offers.
///
/// A session keeps the configuration it was mounted with, and a started app
/// mounts one from what it had stored (see [StartupFeatureAccessCheck]). When
/// the first read of the backend says otherwise, this session is the one that
/// is wrong, and the person has done nothing in it yet.
///
/// Starting anew ends every call, so the restart follows [CallBloc]: it is
/// made when the bloc's state says the session has heard from the server and
/// no call is tracked, by the bloc or by the server. Both are asked because
/// the bloc takes up a call some turns after it learns of it - the calls of a
/// handshake after it reports the handshake, a call the platform presented
/// after it has looked the caller up: an app started by a call shows a
/// session that tracks nothing, with that call ringing or up. The lines of
/// the signaling session carry such a call all along.
///
/// A server that cannot be reached is no answer: nothing then says whether a
/// call is waiting there, so the restart waits for the handshake.
///
/// The session is replaced as a whole. Leaving the shell's route unmounts
/// everything the session built, and coming back to it runs the guard and
/// mounts the shell the way a sign-in does - with whatever the reactive
/// provider holds by then (see [SessionRestartScreen]).
class StartupConfigRefresh extends StatefulWidget {
  const StartupConfigRefresh({
    super.key,
    required this.signalingModule,
    required this.sessionEnded,
    required this.child,
    this.startAnew,
  });

  /// The session's signaling: its lines say which calls the server holds now.
  final SignalingModule signalingModule;

  /// Completes when the shell above has stopped what it started; the session
  /// that replaces it waits for that.
  final Future<void> sessionEnded;

  /// Stands in for the navigation to the restart route in a test.
  final VoidCallback? startAnew;

  final Widget child;

  @override
  State<StartupConfigRefresh> createState() => _StartupConfigRefreshState();
}

class _StartupConfigRefreshState extends State<StartupConfigRefresh> {
  late final CallBloc _callBloc = context.read<CallBloc>();

  /// Set once the session is known to be behind, until it is replaced.
  StreamSubscription<CallState>? _callStates;

  /// The last reason the request was put off, so the log names each one once.
  String? _lastObstacle;

  @override
  void initState() {
    super.initState();
    unawaited(_watch());
  }

  @override
  void dispose() {
    unawaited(_callStates?.cancel());
    super.dispose();
  }

  Future<void> _watch() async {
    final session = context.read<FeatureAccess>();
    final changed = await context.read<StartupFeatureAccessCheck>().changedSince(session);
    if (changed == null || !mounted) {
      return;
    }
    _callStates = _callBloc.stream.listen(_onCallState);
    _onCallState(_callBloc.state);
  }

  /// What a restart would break, or what keeps it from being known; null
  /// when nothing.
  String? _obstacle(CallState state) {
    // The session as the module knows it now: a line that is not free
    // carries a call.
    final session = widget.signalingModule.sessionHandshake;
    if (!state.isHandshakeEstablished || session == null) {
      return 'the session is not known yet (${state.status})';
    }
    if (state.isActive) {
      return 'a call exists';
    }
    if (session.guestLine != null || session.lines.any((line) => line != null)) {
      return 'the server holds a call the session has not taken up yet';
    }
    return null;
  }

  void _onCallState(CallState state) {
    if (_callStates == null) {
      return;
    }
    final obstacle = _obstacle(state);
    if (obstacle != null) {
      if (obstacle != _lastObstacle) {
        _logger.info('restart put off: $obstacle');
      }
      _lastObstacle = obstacle;
      return;
    }
    unawaited(_callStates?.cancel());
    _callStates = null;
    _logger.info('starting the session anew');
    (widget.startAnew ?? _startAnew)();
  }

  /// The reason is said first: a notification is shown only from the screens
  /// of a session, and the bar stays up while they are replaced.
  void _startAnew() {
    context.read<NotificationsBloc>().add(const NotificationsSubmitted(ConfigurationUpdatedNotification()));
    unawaited(context.router.replaceAll([SessionRestartScreenPageRoute(sessionEnded: widget.sessionEnded)]));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
