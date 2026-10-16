import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

final _logger = Logger('SessionRestartScreen');

/// Stands between the sign-in and a main shell that is about to be built:
/// after a session that is being stopped, and before the first session of a
/// start that has no system info stored.
///
/// The main shell cannot be swapped for another in place: call integration
/// and the signaling service are single per process, and a shell that starts
/// while the previous one is still letting go of them has its own set-up undone
/// by that teardown. Replacing the shell with this screen unmounts it; the
/// screen goes back to the main shell once the old one has let go, and the
/// guard of that route builds the session the way it does after a sign-in.
///
/// A session is mounted on one configuration and keeps it (see `MainShell`),
/// and the router builds the routes of its sections from the configuration it
/// was last handed. Both must already be built from system info when the shell
/// is built, or the session runs without the backend's capabilities - a
/// Contacts screen with no Cloud PBX among its sources. So the screen leaves
/// only once system info is stored, can be read back the way the guard reads
/// it, and the app-wide configuration has been rebuilt from it: at the end of
/// that frame, when the router has been handed it too. A host that supplies
/// its own configuration is not waited for.
///
/// When the core cannot be reached the screen says so and offers to try again
/// or to log out. Logging out is the only way to enter another core; refusing
/// the main shell without a screen in its place is a white screen. Whenever
/// the session ends - logged out here or elsewhere - the screen goes back to
/// the main shell, whose guard sends the app on to the teardown or the login.
///
/// It says why it is there: the person did nothing to leave the screen they
/// were on.
class SessionRestartScreen extends StatefulWidget {
  const SessionRestartScreen({super.key, this.sessionEnded});

  /// Completes when the shell that asked for the restart has stopped what it
  /// started. Null when the route was reached without one: nothing is being
  /// stopped then, the system info is what is missing.
  final Future<void>? sessionEnded;

  @override
  State<SessionRestartScreen> createState() => _SessionRestartScreenState();
}

class _SessionRestartScreenState extends State<SessionRestartScreen> {
  /// Set once system info is stored and reads back from the cache.
  bool _stored = false;

  bool _unreachable = false;

  bool _leaving = false;

  StreamSubscription<AppState>? _sessionStates;

  @override
  void initState() {
    super.initState();
    final appBloc = context.read<AppBloc>();
    _sessionStates = appBloc.stream.listen(_onSessionState);
    _onSessionState(appBloc.state);
    unawaited(_startAnew());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _leaveWhenConfigured(Provider.of<FeatureAccess>(context));
  }

  @override
  void dispose() {
    unawaited(_sessionStates?.cancel());
    super.dispose();
  }

  void _onSessionState(AppState state) {
    if (state.status != AppLifecycleStatus.authenticated) {
      _logger.info('the session has ended (${state.status}), leaving for the main shell guard');
      unawaited(SchedulerBinding.instance.endOfFrame.then((_) => _leave()));
    }
  }

  Future<void> _startAnew() async {
    final sessionEnded = widget.sessionEnded;
    if (sessionEnded != null) {
      await sessionEnded;
      if (!mounted) {
        return;
      }
      _logger.info('the previous session has stopped, starting anew');
    }
    await _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    final repository = context.read<SystemInfoRepository>();
    try {
      final loaded = await repository.getSystemInfo(fetchPolicy: FetchPolicy.cacheFirst);
      if (loaded == null) {
        throw StateError('the core answered without system info');
      }
      // The main shell guard reads the cache only; a value it cannot read back
      // would send the app here again, round and round.
      final stored = await repository.getSystemInfo(fetchPolicy: FetchPolicy.cacheOnly);
      if (stored == null) {
        throw StateError('the system info was loaded but does not read back from the cache');
      }
    } catch (e, s) {
      _logger.warning('the system info could not be loaded', e, s);
      if (mounted) setState(() => _unreachable = true);
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _stored = true);
    _leaveWhenConfigured(context.read<FeatureAccess>());
  }

  /// Leaves for the main shell once [featureAccess] was built from system info,
  /// at the end of the frame that rebuilds the app with it: the router is
  /// handed the configuration in that frame.
  void _leaveWhenConfigured(FeatureAccess featureAccess) {
    if (!_stored || _leaving) return;
    final followsBackend = context.read<StartupFeatureAccessCheck>().followsBackend;
    if (followsBackend && !featureAccess.hasSystemInfo) return;
    unawaited(SchedulerBinding.instance.endOfFrame.then((_) => _leave()));
  }

  void _retry() {
    setState(() => _unreachable = false);
    unawaited(_loadSystemInfo());
  }

  /// Ends the session. The screen leaves once it has ended (see
  /// [_onSessionState]): the bloc takes the request a turn later, and the
  /// guards send a session that still runs back here.
  void _logOut() {
    context.read<AppBloc>().add(const AppLogoutRequested(reason: AppLogoutReason.coreUnreachable));
  }

  void _leave() {
    if (!mounted || _leaving) return;
    _leaving = true;
    unawaited(context.router.replaceAll([const MainShellRoute()]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _unreachable
                ? [
                    Text(l10n.session_Restart_unreachableText, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    SemanticAction(
                      identifier: sessionRestartRetryButtonId,
                      child: FilledButton(
                        key: sessionRestartRetryButtonKey,
                        onPressed: _retry,
                        child: Text(l10n.session_Restart_retryButton),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SemanticAction(
                      identifier: sessionRestartLogoutButtonId,
                      child: TextButton(
                        key: sessionRestartLogoutButtonKey,
                        onPressed: _logOut,
                        child: Text(l10n.session_Restart_logoutButton),
                      ),
                    ),
                  ]
                : [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      widget.sessionEnded != null
                          ? l10n.session_Restart_progressText
                          : l10n.session_Restart_loadingText,
                      textAlign: TextAlign.center,
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}
