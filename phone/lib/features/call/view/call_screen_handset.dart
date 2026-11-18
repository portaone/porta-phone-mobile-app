// The call screen on a phone: the call screen's routes, a stack of one page,
// the default screen with the call's controls (CallControls). Used by
// CallActiveScaffold in its handset layout; the watch's counterpart is
// CallControlsWatch, on the same routes.
//
// The first page shows what this widget hands over in CallScreenHomeScope; the
// routes are callScreenRoutes of the app router. They cover the whole screen
// and the default screen keeps off the system's areas itself, so the menus
// the controls open in them are placed and dimmed against the screen, and
// close with it.
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/app/router/app_router_observer.dart';
import 'package:webtrit_phone/models/models.dart';

import '../utils/compact_auto_reset_controller.dart';
import '../widgets/call_controls.dart';
import '../widgets/call_screen_home_scope.dart';

class CallScreenHandset extends StatelessWidget {
  const CallScreenHandset({
    super.key,
    required this.compact,
    required this.callStatus,
    required this.popupMenuItems,
    required this.params,
  });

  /// Whether the controls are put away; the menus they left open in the
  /// routes are closed when they are.
  final CompactAutoResetController compact;

  final CallStatus callStatus;
  final List<PopupMenuEntry<void>> popupMenuItems;
  final CallControlsParams params;

  @override
  Widget build(BuildContext context) {
    return CallScreenHomeScope(
      builder: (context) => _ClosingMenusWhenPutAway(
        compact: compact,
        child: Padding(
          padding: MediaQuery.paddingOf(context),
          child: CallControls(callStatus: callStatus, popupMenuItems: popupMenuItems, params: params),
        ),
      ),
      // A container of its own: each page's route puts a barrier that blocks
      // the semantics painted before it in its container, and without one the
      // screen's own nodes under the controls - the gesture that hides them -
      // would drop out of what a screen reader can reach.
      //
      // The stack is declared, not pushed to: a phone shows the first page
      // only, so a link or a restored stack naming a watch page never builds
      // one here. Analytics stays with the app's routes, the default screen
      // being the call screen they already report; the router's log and
      // route awareness come along.
      child: Semantics(
        container: true,
        child: AutoRouter.declarative(
          inheritNavigatorObservers: false,
          navigatorObservers: () => [AppRouterObserver(), AutoRouteObserver()],
          routes: (_) => const [CallHomeScreenPageRoute()],
        ),
      ),
    );
  }
}

/// Closes the menus the controls opened in the routes once the controls are
/// put away: they hide with them, and one left open would come back with
/// them, or take the first Back unseen.
class _ClosingMenusWhenPutAway extends StatefulWidget {
  const _ClosingMenusWhenPutAway({required this.compact, required this.child});

  final CompactAutoResetController compact;
  final Widget child;

  @override
  State<_ClosingMenusWhenPutAway> createState() => _ClosingMenusWhenPutAwayState();
}

class _ClosingMenusWhenPutAwayState extends State<_ClosingMenusWhenPutAway> {
  @override
  void initState() {
    super.initState();
    widget.compact.addListener(_onCompactChanged);
  }

  @override
  void didUpdateWidget(covariant _ClosingMenusWhenPutAway oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.compact != widget.compact) {
      oldWidget.compact.removeListener(_onCompactChanged);
      widget.compact.addListener(_onCompactChanged);
    }
  }

  @override
  void dispose() {
    widget.compact.removeListener(_onCompactChanged);
    super.dispose();
  }

  void _onCompactChanged() {
    if (widget.compact.compact && mounted) Navigator.of(context).popUntil((route) => route is! PopupRoute);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
