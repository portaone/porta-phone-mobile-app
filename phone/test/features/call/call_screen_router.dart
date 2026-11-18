// The router a call screen sits under in the tests: a route with the call
// screen's pages as its children, as the app has. Used by the phone's
// scaffold harness and the watch's face harness alike.
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';

/// [child] where the app puts the call screen: under a route that has the
/// call screen's pages (callScreenRoutes) as its children, so the screen's
/// own routes - the phone's default screen, the watch's face and pages - work
/// as in the app. The router lives as long as this widget does, so a test can
/// pump the screen over and over with new calls and keep the pages it opened.
class CallScreenRouter extends StatefulWidget {
  const CallScreenRouter({super.key, required this.child});

  final Widget child;

  @override
  State<CallScreenRouter> createState() => _CallScreenRouterState();
}

class _CallScreenRouterState extends State<CallScreenRouter> {
  final _router = _Routes();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Hosted(
    face: widget.child,
    child: Router.withConfig(config: _router.config()),
  );
}

class _Hosted extends InheritedWidget {
  const _Hosted({required this.face, required super.child});

  final Widget face;

  @override
  bool updateShouldNotify(_Hosted oldWidget) => face != oldWidget.face;
}

class _Routes extends RootStackRouter {
  static final _screen = PageInfo(
    'CallScreen',
    builder: (_) => Builder(builder: (context) => context.dependOnInheritedWidgetOfExactType<_Hosted>()!.face),
  );

  @override
  List<AutoRoute> get routes => [AutoRoute(page: _screen, initial: true, children: callScreenRoutes)];
}
