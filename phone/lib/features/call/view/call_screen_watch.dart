// The call screen on a watch: the call screen's routes over the whole face,
// their first page the face (CallWatchFace) and each other page one tap
// away. Used by CallActiveScaffold in its watch layout; the phone's
// counterpart is CallScreenHandset, on the same routes.
//
// Steps: the pages read what they show from CallWatchScope; whether a page
// or the keypad takes the face is reported to the screen, which keeps it from
// hiding; when the calls change, a page that no longer applies is closed
// (_closeWhatNoLongerApplies).
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/models/models.dart';

import '../widgets/call_controls.dart';
import '../widgets/call_screen_home_scope.dart';
import '../widgets/watch/call_watch_face.dart';

/// The call on a watch face.
///
/// The phone's call screen holds about seventy functions; a face holds a
/// name, a line under it, three controls and the end button. So the face
/// keeps what a call needs every minute - mute, the audio route, more - and
/// moves the rest one tap away, each a page of the call screen's routes: a
/// grid of the call's other actions, the audio devices, the transfer menu, the
/// calls, the room. A ringing call takes the face with its two choices, and
/// the in-call keypad takes it while open.
///
/// Like [CallControls] it only presents: what each control does arrives in
/// [params] from the screen, which keeps the state, the remote picture and
/// the hiding of the controls over it. The pages read them from
/// [CallWatchScope]; when the calls change under an open page, the page that
/// no longer applies is closed.
class CallScreenWatch extends StatefulWidget {
  const CallScreenWatch({
    super.key,
    required this.callStatus,
    required this.params,
    required this.video,
    this.onPageOpenChanged,
  });

  final CallStatus callStatus;
  final CallScreenParams params;
  final CallWatchVideoOptions video;

  /// Whether something other than the call itself takes the face - a page or
  /// the keypad - so the screen keeps it from hiding while it is read.
  final ValueChanged<bool>? onPageOpenChanged;

  @override
  State<CallScreenWatch> createState() => _CallScreenWatchState();
}

class _CallScreenWatchState extends State<CallScreenWatch> {
  final _pages = GlobalKey<AutoRouterState>();
  late final _pagesShown = _PagesShown(_reportPageOpen);
  bool? _pageOpen;

  @override
  void didUpdateWidget(covariant CallScreenWatch oldWidget) {
    super.didUpdateWidget(oldWidget);
    final before = oldWidget.params;
    final now = widget.params;
    final focusMoved = before.focusedCall.callId != now.focusedCall.callId;
    final callsChanged =
        focusMoved ||
        before.focusedCall.isIncomingRinging != now.focusedCall.isIncomingRinging ||
        before.activeCalls.length != now.activeCalls.length ||
        before.conference != now.conference;
    if (callsChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeWhatNoLongerApplies(focusMoved: focusMoved));
    }
    if (before.keypadShown != now.keypadShown) _reportPageOpen();
  }

  void _reportPageOpen() {
    if (!mounted) return;
    final open = widget.params.keypadShown || _pagesShown.count > 1;
    if (open == _pageOpen) return;
    _pageOpen = open;
    widget.onPageOpenChanged?.call(open);
  }

  /// A page is about the call it was opened for: when the focus moves or a
  /// call rings, the face shows the call. The calls become the room once
  /// they are merged, as on the phone; the calls with one call left, the room
  /// once it has ended and a participant who left it are closed.
  void _closeWhatNoLongerApplies({required bool focusMoved}) {
    final router = _pages.currentState?.controller;
    if (!mounted || router == null || router.stack.length < 2) return;
    final params = widget.params;
    final conference = params.conference;
    final names = router.stack.map((page) => page.name).toSet();
    final top = router.topRoute;

    if (top.name == CallWatchCallsScreenPageRoute.name &&
        conference.isPresent &&
        !params.focusedCall.isIncomingRinging) {
      // Merged: the calls are the room now, wherever the focus went.
      router.replace(const CallWatchConferenceScreenPageRoute());
    } else if (focusMoved ||
        params.focusedCall.isIncomingRinging ||
        (names.contains(CallWatchCallsScreenPageRoute.name) &&
            params.activeCalls.length < 2 &&
            !conference.isPresent) ||
        ((names.contains(CallWatchConferenceScreenPageRoute.name) ||
                names.contains(CallWatchParticipantScreenPageRoute.name)) &&
            !conference.isPresent)) {
      router.popUntilRoot();
    } else if (top.name == CallWatchParticipantScreenPageRoute.name &&
        !conference.isLeg(top.argsAs<CallWatchParticipantScreenPageRouteArgs>().callId)) {
      router.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pageOpen == null) WidgetsBinding.instance.addPostFrameCallback((_) => _reportPageOpen());
    final params = widget.params;
    final keypad = params.keypadShown && !params.focusedCall.isIncomingRinging;

    return CallScreenHomeScope(
      builder: (_) => const CallWatchFace(),
      child: CallWatchScope(
        params: params,
        video: widget.video,
        callStatus: widget.callStatus,
        // Off the system's areas, as the face and its pages are laid out.
        child: Padding(
          padding: MediaQuery.paddingOf(context),
          // The keypad is the screen's, shared with the phone, and closes as
          // the phone's does: back hides it.
          child: keypad
              ? PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, _) => didPop ? null : params.onKeypadToggle(false),
                  child: CallWatchKeypad(params: params),
                )
              : AutoRouter(key: _pages, navigatorObservers: () => [_pagesShown]),
        ),
      ),
    );
  }
}

/// Counts the pages on the face, the call's own included, as they come and go.
class _PagesShown extends NavigatorObserver {
  _PagesShown(this.onChanged);

  final VoidCallback onChanged;
  int count = 0;

  void _set(int value) {
    count = value;
    WidgetsBinding.instance.addPostFrameCallback((_) => onChanged());
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(count + 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(count - 1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _set(count - 1);
}
