import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:logging/logging.dart';

import 'package:webtrit_phone/app/router/app_router.dart';

final _logger = Logger('SessionRestartScreen');

/// Stands between a session that is being stopped and the one that replaces
/// it for the same sign-in.
///
/// The main shell cannot be swapped for another in place: call integration
/// and the signaling service are single per process, and a shell that starts
/// while the previous one is still letting go of them has its own set-up undone
/// by that teardown. Replacing the shell with this screen unmounts it; the
/// screen goes back to the main shell once the old one has let go, and the
/// guard of that route builds the session the way it does after a sign-in.
class SessionRestartScreen extends StatefulWidget {
  const SessionRestartScreen({super.key, this.sessionEnded});

  /// Completes when the shell that asked for the restart has stopped what it
  /// started. Null when the route was reached without one, by its address:
  /// nothing is being stopped then.
  final Future<void>? sessionEnded;

  @override
  State<SessionRestartScreen> createState() => _SessionRestartScreenState();
}

class _SessionRestartScreenState extends State<SessionRestartScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_startAnew());
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
    unawaited(context.router.replaceAll([const MainShellRoute()]));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
