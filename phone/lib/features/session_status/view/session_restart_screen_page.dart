import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'session_restart_screen.dart';

@RoutePage()
class SessionRestartScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const SessionRestartScreenPage({this.sessionEnded});

  /// See [SessionRestartScreen.sessionEnded].
  final Future<void>? sessionEnded;

  @override
  Widget build(BuildContext context) {
    return SessionRestartScreen(sessionEnded: sessionEnded);
  }
}
