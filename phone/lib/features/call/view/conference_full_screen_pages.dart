// The room's pages of the call screen's routes on a phone (callScreenRoutes
// of the app router): the room in full screen as tiles, and one participant
// of it. CallScreenHandset declares them over the default screen and reads
// what they show to them through CallScreenHandsetScope; the screen itself
// is ConferenceFullScreen (widgets/conference_full_screen.dart).
//
// The routes are shared with the watch, which hosts them in a router of its
// own: the room's pages are a phone's, and under any other host - a link or
// a restored stack naming one - they show nothing and leave (_RoomPage).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import '../widgets/conference_full_screen.dart';
import 'call_screen_handset.dart';

/// The room in full screen, as video tiles.
@RoutePage()
class ConferenceFullScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const ConferenceFullScreenPage();

  @override
  Widget build(BuildContext context) => const _RoomPage(callId: null);
}

/// One participant of the room in full screen.
@RoutePage()
class ConferenceParticipantPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const ConferenceParticipantPage({required this.callId});

  final String callId;

  @override
  Widget build(BuildContext context) => _RoomPage(callId: callId);
}

/// A page of the room: [callId] names its participant, `null` the tiles.
class _RoomPage extends StatelessWidget {
  const _RoomPage({required this.callId});

  final String? callId;

  /// Leaves a page that has no phone's call screen around it.
  static void _leave(BuildContext context) {
    if (context.mounted) unawaited(Navigator.maybeOf(context)?.maybePop());
  }

  @override
  Widget build(BuildContext context) {
    final scope = CallScreenHandsetScope.maybeOf(context);
    if (scope == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _leave(context));
      return const SizedBox.shrink();
    }
    // Off the system's areas, as the default screen is.
    return Padding(
      padding: MediaQuery.paddingOf(context),
      child: ConferenceFullScreen(
        params: scope.params,
        callId: callId,
        // The tiles under a participant's page are not seen: they hold no
        // cameras while it is open.
        covered: callId == null && scope.participant != null,
        // The stack is declared, so back changes what is open: a participant
        // to the tiles, the tiles to the default screen.
        onBack: callId == null ? scope.onRoomClosed : scope.onParticipantClosed,
        onParticipantOpened: scope.onParticipantOpened,
        onKeypad: () => _showKeypad(scope),
      ),
    );
  }

  /// The keypad of More is the default screen's: the room closes for it.
  static void _showKeypad(CallScreenHandsetScope scope) {
    scope.onRoomClosed();
    scope.params.onKeypadToggle(true);
  }
}
