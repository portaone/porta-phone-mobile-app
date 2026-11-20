// The call screen on a phone: the call screen's routes, the default screen
// with the call's controls (CallControls) first, the room in full screen and
// one participant of it over it. Used by CallActiveScaffold in its handset
// layout; the watch's counterpart is CallScreenWatch, on the same routes.
//
// Steps: the screen opens the room through openConferenceFullScreen; the
// stack is declared from what is open and what still applies - a call
// ringing, the focus moving out of the room or the room ending bring back
// the default screen, a participant who leaves takes his page with him; back
// pops the top page (_onPopRoute).
//
// The first page shows what this widget hands over in CallScreenHomeScope,
// the room's pages read CallScreenHandsetScope (conference_full_screen_pages
// .dart); the routes are callScreenRoutes of the app router. They cover the
// whole screen and each page keeps off the system's areas itself, so the
// menus the controls open in them are placed and dimmed against the screen,
// and close with it.
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/app/router/app_router_observer.dart';
import 'package:webtrit_phone/models/models.dart';

import '../models/models.dart';
import '../utils/compact_auto_reset_controller.dart';
import '../widgets/call_controls.dart';
import '../widgets/call_screen_home_scope.dart';

class CallScreenHandset extends StatefulWidget {
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
  final CallScreenParams params;

  @override
  State<CallScreenHandset> createState() => CallScreenHandsetState();
}

class CallScreenHandsetState extends State<CallScreenHandset> {
  /// Whether the room is open in full screen, and which participant of it.
  bool _room = false;
  String? _participant;

  /// Opens the room in full screen over the default screen.
  void openConferenceFullScreen() {
    if (_roomApplies(widget.params)) setState(() => _room = true);
  }

  /// Whether the room may be in full screen: the focused call is one of its
  /// legs and nothing rings.
  static bool roomApplies(ConferenceState conference, ActiveCall focusedCall) =>
      conference.isPresent && !focusedCall.isIncomingRinging && conference.isLeg(focusedCall.callId);

  static bool _roomApplies(CallScreenParams params) => roomApplies(params.conference, params.focusedCall);

  @override
  void didUpdateWidget(covariant CallScreenHandset oldWidget) {
    super.didUpdateWidget(oldWidget);
    final params = widget.params;
    // Calling somebody in through Add moves the focus out of the room: the
    // default screen shows that call, as it shows a ringing one and the end
    // of the room. The focus moving from one leg to another - the first leg
    // leaving a room that goes on - keeps the room open.
    if (!_roomApplies(params)) {
      _room = false;
      _participant = null;
    } else if (_participant != null && !params.conference.isLeg(_participant!)) {
      _participant = null;
    }
  }

  void _openParticipant(String callId) => setState(() => _participant = callId);

  void _closeParticipant() => setState(() => _participant = null);

  void _closeRoom() => setState(() {
    _room = false;
    _participant = null;
  });

  /// Back pops the top page: a participant to the tiles, the tiles to the
  /// default screen.
  void _onPopRoute(RouteMatch route, Page<Object?> page) {
    if (route.name == ConferenceParticipantPageRoute.name) {
      _closeParticipant();
    } else if (route.name == ConferenceFullScreenPageRoute.name) {
      _closeRoom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final participant = _participant;
    return CallScreenHandsetScope(
      params: widget.params,
      participant: _room ? participant : null,
      onParticipantOpened: _openParticipant,
      onParticipantClosed: _closeParticipant,
      onRoomClosed: _closeRoom,
      child: _routes(
        routes: [
          const CallHomeScreenPageRoute(),
          if (_room) const ConferenceFullScreenPageRoute(),
          if (_room && participant != null) ConferenceParticipantPageRoute(callId: participant),
        ],
      ),
    );
  }

  Widget _routes({required List<PageRouteInfo> routes}) {
    return CallScreenHomeScope(
      builder: (context) => _ClosingMenusWhenPutAway(
        compact: widget.compact,
        child: Padding(
          padding: MediaQuery.paddingOf(context),
          child: CallControls(
            callStatus: widget.callStatus,
            popupMenuItems: widget.popupMenuItems,
            params: widget.params,
          ),
        ),
      ),
      // A container of its own: each page's route puts a barrier that blocks
      // the semantics painted before it in its container, and without one the
      // screen's own nodes under the controls - the gesture that hides them -
      // would drop out of what a screen reader can reach.
      //
      // The stack is declared, not pushed to: a phone shows its own pages
      // only, so a link or a restored stack naming a watch page never builds
      // one here. Analytics stays with the app's routes, the default screen
      // being the call screen they already report; the router's log and
      // route awareness come along.
      child: Semantics(
        container: true,
        child: AutoRouter.declarative(
          inheritNavigatorObservers: false,
          navigatorObservers: () => [AppRouterObserver(), AutoRouteObserver()],
          routes: (_) => routes,
          onPopRoute: _onPopRoute,
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

/// What the room's pages on a phone read: the controls the screen hands over
/// and the steps between the pages, rebuilt with every change of the calls.
class CallScreenHandsetScope extends InheritedWidget {
  const CallScreenHandsetScope({
    super.key,
    required this.params,
    required this.participant,
    required this.onParticipantOpened,
    required this.onParticipantClosed,
    required this.onRoomClosed,
    required super.child,
  });

  final CallScreenParams params;

  /// The participant whose page is over the tiles, by call id; `null` while
  /// the tiles are on top.
  final String? participant;

  /// Opens one participant of the room over the tiles.
  final ValueChanged<String> onParticipantOpened;

  /// Brings back the tiles from one participant.
  final VoidCallback onParticipantClosed;

  /// Brings back the default screen.
  final VoidCallback onRoomClosed;

  /// The scope of the phone's call screen; `null` under any other host of the
  /// call screen's routes - a watch, which never opens the room's pages.
  static CallScreenHandsetScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CallScreenHandsetScope>();

  // The screen hands over new params with every build of its own.
  @override
  bool updateShouldNotify(CallScreenHandsetScope oldWidget) => true;
}
