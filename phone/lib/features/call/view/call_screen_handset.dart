// The call screen on a phone: the call screen's routes, a stack of one page,
// the default screen with the call's controls (CallControls). Used by
// CallActiveScaffold in its handset layout; the watch's counterpart is
// CallControlsWatch, on the same routes.
//
// The page reads what it shows from CallPhoneScope, which this widget puts
// over the routes; the page itself lives in call_phone_screen_pages.dart, the
// routes in callScreenRoutes of the app router. The routes cover the whole
// screen and the page keeps off the system's areas, so the menus the controls
// open in them are placed and dimmed against the screen, and close with it.
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/models/models.dart';

import '../utils/compact_auto_reset_controller.dart';
import '../widgets/call_controls.dart';

class CallScreenHandset extends StatelessWidget {
  const CallScreenHandset({
    super.key,
    required this.compact,
    required this.padding,
    required this.callStatus,
    required this.popupMenuItems,
    required this.params,
  });

  /// Whether the controls are put away; the page closes the menus the
  /// controls left open in the routes when they are.
  final CompactAutoResetController compact;

  /// The area the system reserves around the screen, which the routes cover.
  final EdgeInsets padding;

  final CallStatus callStatus;
  final List<PopupMenuEntry<void>> popupMenuItems;
  final CallControlsParams params;

  @override
  Widget build(BuildContext context) {
    return CallPhoneScope(
      params: params,
      compact: compact,
      padding: padding,
      callStatus: callStatus,
      popupMenuItems: popupMenuItems,
      // A container of its own: each page's route puts a barrier that blocks
      // the semantics painted before it in its container, and without one the
      // screen's own nodes under the controls - the gesture that hides them -
      // would drop out of what a screen reader can reach.
      //
      // The stack is declared, not pushed to: a phone shows the first page
      // only, so a link or a restored stack naming a watch page never builds
      // one here.
      child: Semantics(
        container: true,
        child: AutoRouter.declarative(routes: (_) => const [CallHomeScreenPageRoute()]),
      ),
    );
  }
}

/// What the call screen's phone pages read: the controls the screen hands
/// over, rebuilt with every change of the calls.
class CallPhoneScope extends InheritedWidget {
  const CallPhoneScope({
    super.key,
    required this.params,
    required this.compact,
    required this.padding,
    required this.callStatus,
    required this.popupMenuItems,
    required super.child,
  });

  final CallControlsParams params;
  final CompactAutoResetController compact;
  final EdgeInsets padding;
  final CallStatus callStatus;
  final List<PopupMenuEntry<void>> popupMenuItems;

  static CallPhoneScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<CallPhoneScope>();

  // The scaffold hands over new params and menu items with every build of
  // its own, so the page is rebuilt with each.
  @override
  bool updateShouldNotify(CallPhoneScope oldWidget) => true;
}
