import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_callkeep/webtrit_callkeep.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/orientations/orientations.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';
import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/extensions/extensions.dart';

import '../call.dart';

class CallShell extends StatefulWidget {
  const CallShell({required this.child, this.stickyPadding = kStickyOverlayPadding, super.key});

  final Widget child;
  final EdgeInsets stickyPadding;

  /// Programmatic back navigation to the main screen.
  ///
  /// Uses [StackRouter.navigatePath] to `MainShellRoute` instead of `popUntil`.
  /// This avoids issues on iOS where `popUntil` executes prematurely while the app
  /// is backgrounded, and prevents router redirects bug associated with empty sub-routes.
  ///
  /// Detailed Context:
  /// 1. `router.navigate(const MainScreenPageRoute())` wasn't used to avoid a bug that triggers
  ///    redirect('') from an empty MainScreenPageRoute subroute to the initial (last remembered) flavor.
  /// 2. On iOS, using `popUntil` doesn't work when the app is collapsed because pushing routes isn't
  ///    allowed until the app resumes. As a result, `popUntil` is called too early.
  /// 3. Using `navigatePath` with a path-based approach fixes this by properly restoring state.
  /// 4. The navigation runs on the app shell's router: a path is matched from the innermost router
  ///    up, and the router of the call screen's watch pages takes any path for its page of the empty
  ///    path, so a path left the watch on the call screen after the call had ended; and the root,
  ///    with a page over the whole app such as a watch's text page, is left as it is.
  /// What floats over the call screen for the focused call of [state]: what goes out from this
  /// phone, in one window on every call screen - a call's, the room's panel, the room's full
  /// screen - at the same place. The camera preview while the camera is on: the call's own, the
  /// room's for a leg of the room (the host sees what his room gets), the camera published to the
  /// room an invitation came through. A screen shown from this call - on its own sender, to the
  /// host's own room from a leg of it, or to the room its far end invited it to - has a tile in
  /// the preview's place. Nothing goes out: nothing floats.
  static CallFloating floatingOf(CallState state) {
    if (state.activeCalls.isEmpty) return CallFloating.none;
    final call = state.activeCalls.current;
    final leg = state.conference.isLeg(call.callId);
    if (leg && state.roomScreenShare == ScreenShareStatus.sharing) return CallFloating.screenShareTile;
    final ownShare = switch (state.screenShare?.target) {
      CallScreenShareTarget(:final callId) ||
      RoomScreenShareTarget(invitedCallId: final callId?) => callId == call.callId,
      _ => false,
    };
    if (ownShare && state.screenShareOf(call.callId) == ScreenShareStatus.sharing) return CallFloating.screenShareTile;
    if (leg) return state.conference.selfVideo == null ? CallFloating.none : CallFloating.cameraPreview;
    return call.isCameraActive || _invitedCamera(state, call) != null ? CallFloating.cameraPreview : CallFloating.none;
  }

  /// The camera the preview shows for [call]: the room's for a leg of the host's room; the camera
  /// published to the room an invitation to somebody else's room came through - a voice call
  /// sends none of its own, the camera goes to that room; the call's own otherwise.
  static MediaStream? cameraOf(CallState state, ActiveCall call) => state.conference.isLeg(call.callId)
      ? state.conference.selfVideo
      : _invitedCamera(state, call) ?? call.localStream;

  /// Whether the room's camera is the front one: the way the legs that share it show; the front
  /// one, as it is published first, where none says.
  static bool roomFrontCamera(CallState state) =>
      state.activeCalls.firstWhereOrNull((call) => state.conference.isLeg(call.callId) && call.video)?.frontCamera ??
      true;

  static MediaStream? _invitedCamera(CallState state, ActiveCall call) {
    final invited = state.invitedVideo;
    return invited != null && call.line == invited.line ? invited.selfVideo : null;
  }

  static void backToMainScreen(StackRouter router) {
    final shell = router.root.innerRouterOf<StackRouter>(AppShellRoute.name) ?? router;
    shell.navigate(const MainShellRoute());
  }

  @override
  State<CallShell> createState() => _CallShellState();
}

/// What floats over the call screen for the focused call.
enum CallFloating {
  /// The tile that stands in for the camera preview while the screen is on the call's own sender.
  screenShareTile,

  /// The call's own camera preview.
  cameraPreview,

  none,
}

class _CallShellState extends State<CallShell> {
  /// Whether the floating call thumbnail and the camera preview are shown, as
  /// the arrangement picked last said; null until the first one is built.
  bool? _showsOverlays;

  late final ThumbnailOverlayManager _thumbnailManager = ThumbnailOverlayManager(stickyPadding: widget.stickyPadding);

  @override
  Widget build(BuildContext context) {
    // A floating thumbnail would cover a third of a watch face, and so would
    // the camera preview: the hub shows a call to go back to instead, and the
    // camera is switched under the call's More.
    return AdaptiveLayout(
      handset: (_) => _arrangement(showsOverlays: true),
      watch: (_) => _arrangement(showsOverlays: false),
    );
  }

  /// Both arrangements are the same listeners over the same child, so a
  /// window that changes class keeps the app under it; they differ in whether
  /// the overlay is shown.
  Widget _arrangement({required bool showsOverlays}) {
    _onShowsOverlays(showsOverlays);
    return MultiBlocListener(
      listeners: [
        _callDisplayListener(),
        _callScreenDisplayListener(),
        _callVideoListener(),
        // Not about showing a call, but about the same bloc and the same
        // lifetime: while one is being handed over, the lists elsewhere in the
        // app are what the person is choosing from.
        BlindTransferPicking(controller: CallControllerScope.of(context)),
        LinkedCallPicking(),
      ],
      child: widget.child,
    );
  }

  /// The overlay is decided on the arrangement too: a window that changes
  /// class - a phone in split screen, the configurator's preview - shows or
  /// drops it at once rather than on the next change of the call.
  void _onShowsOverlays(bool showsOverlays) {
    final changed = _showsOverlays != null && showsOverlays != _showsOverlays;
    _showsOverlays = showsOverlays;
    if (changed) {
      final router = context.router;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _updateOverlayContent(context, context.read<CallBloc>().state, router);
      });
    }
  }

  /// Listens to [CallState.display] changes and manages related UI transitions.
  ///
  /// Handles:
  /// - Orientation updates via [OrientationsBloc].
  /// - Navigation between main and call screens.
  /// - Showing or removing the floating thumbnail overlay via [_updateOverlayContent].
  BlocListener<CallBloc, CallState> _callDisplayListener() {
    return BlocListener<CallBloc, CallState>(
      listenWhen: (previous, current) => previous.display != current.display,
      listener: (context, state) => _onCallDisplayChanged(context, state),
    );
  }

  /// Listens for transitions to and from [CallDisplay.screen] to manage
  /// activity visibility and lockscreen behavior dynamically.
  ///
  /// - When entering the call screen (`CallDisplay.screen`), it restores
  ///   normal screen and lockscreen settings.
  /// - When leaving the call screen, it enables showing the activity
  ///   over the lock screen if needed.
  BlocListener<CallBloc, CallState> _callScreenDisplayListener() {
    return BlocListener<CallBloc, CallState>(
      listenWhen: (previous, current) =>
          previous.display != current.display &&
          (previous.display == CallDisplay.screen || current.display == CallDisplay.screen),
      listener: (context, state) => _onCallScreenDisplayChanged(state),
    );
  }

  BlocListener<CallBloc, CallState> _callVideoListener() {
    return BlocListener<CallBloc, CallState>(
      listenWhen: _shouldListenToVideoChanges,
      listener: (context, state) => _updateOverlayContent(context, state, context.router),
    );
  }

  void _onCallDisplayChanged(BuildContext context, CallState state) {
    final router = context.router;
    _updateOrientations(context, state.display);
    _handleNavigation(router, state);
    _updateOverlayContent(context, state, router);
  }

  void _onCallScreenDisplayChanged(CallState state) {
    final isCallScreen = state.display == CallDisplay.screen;
    _updateLockscreenBehavior(isCallScreen);
  }

  bool _shouldListenToVideoChanges(CallState previous, CallState current) {
    if (current.display != CallDisplay.screen) return false;

    final prevCall = previous.activeCalls.isEmpty ? null : previous.activeCalls.current;
    final nextCall = current.activeCalls.isEmpty ? null : current.activeCalls.current;

    // return (prevCall?.isCameraActive ?? false) != (nextCall?.isCameraActive ?? false);

    // Can't compare muted track because its mutated in prev and next states together
    // TODO: optimize later
    // A call joining a room that already stands changes neither the call nor
    // whether there is a room, and its preview goes all the same.
    final nextId = nextCall?.callId;
    final joinedOrLeft = nextId != null && previous.conference.isLeg(nextId) != current.conference.isLeg(nextId);
    return prevCall != nextCall ||
        previous.conference.isPresent != current.conference.isPresent ||
        joinedOrLeft ||
        previous.screenShare != current.screenShare ||
        previous.conference.selfVideo != current.conference.selfVideo ||
        previous.invitedVideo?.selfVideo != current.invitedVideo?.selfVideo;
  }

  void _updateOrientations(BuildContext context, CallDisplay display) {
    final orientationsBloc = context.read<OrientationsBloc>();
    if (display == CallDisplay.screen) {
      orientationsBloc.add(const OrientationsChanged(PreferredOrientation.auto));
    } else {
      orientationsBloc.add(const OrientationsChanged(PreferredOrientation.portrait));
    }
  }

  void _handleNavigation(StackRouter router, CallState state) {
    final callScreenActive = router.isRouteActive(CallScreenPageRoute.name);
    final callScreenShouldDisplay = state.display == CallDisplay.screen;

    if (callScreenShouldDisplay && !callScreenActive) {
      _openCallScreen(router, state.activeCalls.isNotEmpty);
    }
    if (!callScreenShouldDisplay && callScreenActive) {
      CallShell.backToMainScreen(router);
    }
  }

  void _updateOverlayContent(BuildContext context, CallState state, StackRouter router) {
    final hasActiveCalls = state.activeCalls.isNotEmpty;

    if (_showsOverlays == false) {
      _hideOverlay();
      return;
    }

    if (!hasActiveCalls || state.display == CallDisplay.none || state.display == CallDisplay.noneScreen) {
      _hideOverlay();
      return;
    }

    switch (state.display) {
      case CallDisplay.overlay:
        _showActiveCallThumbnail(context, state, router);
        break;

      case CallDisplay.screen:
        switch (CallShell.floatingOf(state)) {
          case CallFloating.screenShareTile:
            _showScreenShareTile(context);
          case CallFloating.cameraPreview:
            _showLocalCameraPreview(context, state);
          case CallFloating.none:
            _hideOverlay();
        }
        break;

      case CallDisplay.none:
      case CallDisplay.noneScreen:
        // Handled by the initial guard clause.
        break;
    }
  }

  void _showActiveCallThumbnail(BuildContext context, CallState state, StackRouter router) {
    if (state.activeCalls.isEmpty) {
      _hideOverlay();
      return;
    }

    final viewSource = PresenceViewParams.of(context).hybridPresenceSupport;
    final blfViaSipSupport = PresenceViewParams.of(context).blfViaSipSupport;
    final presenceViaSipSupport = PresenceViewParams.of(context).presenceViaSipSupport;
    final callBloc = context.read<CallBloc>();
    final contactResolver = context.read<ContactResolver>();

    _thumbnailManager.show(
      context,
      child: BlocBuilder<CallBloc, CallState>(
        bloc: callBloc,
        buildWhen: (previous, current) =>
            previous.activeCalls.isEmpty ||
            current.activeCalls.isEmpty ||
            previous.activeCalls.current != current.activeCalls.current,
        builder: (context, state) {
          if (state.activeCalls.isEmpty) {
            return const SizedBox.shrink();
          }

          final activeCall = state.activeCalls.current;
          final orientation = MediaQuery.of(context).orientation;

          return PresenceViewParams(
            hybridPresenceSupport: viewSource,
            blfViaSipSupport: blfViaSipSupport,
            presenceViaSipSupport: presenceViaSipSupport,
            child: CallActiveThumbnail(
              activeCall: activeCall,
              orientation: orientation,
              onTap: () => _openCallScreen(router, state.activeCalls.isNotEmpty),
              contactResolver: contactResolver,
            ),
          );
        },
      ),
    );
  }

  void _showLocalCameraPreview(BuildContext context, CallState state) {
    final callBloc = context.read<CallBloc>();

    _thumbnailManager.show(
      context,
      child: BlocBuilder<CallBloc, CallState>(
        bloc: callBloc,
        // Safety check: ensure lists are not empty before accessing .current using short-circuit evaluation
        buildWhen: (previous, current) =>
            previous.activeCalls.isEmpty ||
            current.activeCalls.isEmpty ||
            previous.activeCalls.current != current.activeCalls.current ||
            previous.conference.selfVideo != current.conference.selfVideo ||
            previous.invitedVideo?.selfVideo != current.invitedVideo?.selfVideo,
        builder: (context, state) {
          if (state.activeCalls.isEmpty) {
            return const SizedBox.shrink();
          }

          final activeCall = state.activeCalls.current;
          final orientation = MediaQuery.of(context).orientation;
          final stream = CallShell.cameraOf(state, activeCall);
          final hostedRoom = state.conference.isLeg(activeCall.callId);
          // The camera of a room - the host's own, or the one this call was invited to: switched there.
          final inRoom = stream != activeCall.localStream;

          return LocalCameraPreviewThumbnail(
            orientation: orientation,
            frontCamera: hostedRoom
                ? CallShell.roomFrontCamera(state)
                : inRoom
                ? activeCall.frontCamera ?? true
                : activeCall.frontCamera,
            localStream: stream,
            onSwitchCameraPressed: inRoom
                ? () => callBloc.add(const CallControlEvent.conferenceCameraSwitched())
                : activeCall.frontCamera == null
                ? null
                : () => callBloc.add(CallControlEvent.cameraSwitched(activeCall.callId)),
          );
        },
      ),
    );
  }

  void _showScreenShareTile(BuildContext context) {
    final callBloc = context.read<CallBloc>();

    _thumbnailManager.show(
      context,
      child: BlocBuilder<CallBloc, CallState>(
        bloc: callBloc,
        buildWhen: (previous, current) =>
            previous.activeCalls.isEmpty ||
            current.activeCalls.isEmpty ||
            previous.activeCalls.current.callId != current.activeCalls.current.callId,
        builder: (context, state) {
          if (state.activeCalls.isEmpty) return const SizedBox.shrink();
          final callId = state.activeCalls.current.callId;
          return ScreenShareTile(
            orientation: MediaQuery.of(context).orientation,
            onStopPressed: () => callBloc.add(CallControlEvent.screenShareStopped(callId)),
          );
        },
      ),
    );
  }

  void _hideOverlay() {
    _thumbnailManager.hide();
  }

  void _updateLockscreenBehavior(bool isCallScreen) {
    if (isCallScreen) {
      AndroidCallkeepUtils.activityControl.showOverLockscreen();
      AndroidCallkeepUtils.activityControl.wakeScreenOnShow();
    } else {
      AndroidCallkeepUtils.activityControl.showOverLockscreen(false);
      AndroidCallkeepUtils.activityControl.wakeScreenOnShow(false);
    }
  }

  void _openCallScreen(StackRouter router, bool hasActiveCalls) {
    if (hasActiveCalls) {
      // Use navigate to prevent duplicating CallScreenPageRoute in the stack.
      // For example, if the user is on a different route branch like LogRecordsConsoleScreenPageRoute,
      // navigate ensures CallScreenPageRoute is not added again.
      router.navigate(const CallScreenPageRoute());
    } else {
      _hideOverlay();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.call_ThumbnailAvatar_currentlyNoActiveCall), backgroundColor: Colors.grey),
      );
    }
  }

  @override
  void dispose() {
    _thumbnailManager.dispose();
    super.dispose();
  }
}
