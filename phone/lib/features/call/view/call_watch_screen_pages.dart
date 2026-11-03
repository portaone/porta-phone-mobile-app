import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';

import '../widgets/watch/call_controls_watch.dart';
import '../widgets/watch/call_watch_menus.dart';

/// The call's face on a watch: the first page of the call screen's routes.
@RoutePage()
class CallWatchFaceScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallWatchFaceScreenPage();

  @override
  Widget build(BuildContext context) => const CallWatchFace();
}

/// The call's other actions.
@RoutePage()
class CallWatchMoreScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallWatchMoreScreenPage();

  @override
  Widget build(BuildContext context) {
    final scope = CallWatchScope.of(context);
    return CallWatchMore(params: scope.params, video: scope.video, onOpen: (route) => context.router.push(route));
  }
}

/// The audio devices.
@RoutePage()
class CallWatchAudioScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallWatchAudioScreenPage();

  @override
  Widget build(BuildContext context) =>
      CallWatchAudio(params: CallWatchScope.of(context).params, onDone: () => context.router.popUntilRoot());
}

/// The transfer menu.
@RoutePage()
class CallWatchTransferScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallWatchTransferScreenPage();

  @override
  Widget build(BuildContext context) =>
      CallWatchTransfer(params: CallWatchScope.of(context).params, onDone: () => context.router.popUntilRoot());
}

/// The calls, while there is more than one and no room.
@RoutePage()
class CallWatchCallsScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallWatchCallsScreenPage();

  @override
  Widget build(BuildContext context) =>
      CallWatchCalls(params: CallWatchScope.of(context).params, onDone: () => context.router.popUntilRoot());
}

/// The room.
@RoutePage()
class CallWatchConferenceScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallWatchConferenceScreenPage();

  @override
  Widget build(BuildContext context) => CallWatchConference(
    params: CallWatchScope.of(context).params,
    onParticipantOpened: (callId) => context.router.push(CallWatchParticipantScreenPageRoute(callId: callId)),
    onDone: () => context.router.popUntilRoot(),
  );
}

/// One participant of the room.
@RoutePage()
class CallWatchParticipantScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallWatchParticipantScreenPage({required this.callId});

  final String callId;

  @override
  Widget build(BuildContext context) => CallWatchParticipant(
    params: CallWatchScope.of(context).params,
    callId: callId,
    onDone: () => context.router.pop(),
  );
}
