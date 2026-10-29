import 'package:flutter/widgets.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/session_status_cubit.dart';

/// Re-reads the side issues that can change while the app is not looking.
///
/// The microphone and the full-screen call permission are granted on a system
/// screen, so their answers only change when the user leaves and comes back. The
/// issue badge is on every tab, so the refresh lives with the shell, not with
/// one screen.
class SessionIssuesRefresher extends StatefulWidget {
  const SessionIssuesRefresher({super.key, required this.child});

  final Widget child;

  @override
  State<SessionIssuesRefresher> createState() => _SessionIssuesRefresherState();
}

class _SessionIssuesRefresherState extends State<SessionIssuesRefresher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<SessionStatusCubit>().refreshPermissionIssues();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
