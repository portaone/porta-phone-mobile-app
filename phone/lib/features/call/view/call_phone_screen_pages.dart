// The first page of the call screen's routes (callScreenRoutes of the app
// router): the call itself, on a phone or on a watch. The watch's other pages
// are in call_watch_screen_pages.dart. The page reads what it shows from the
// scope its host puts over the routes: CallPhoneScope from CallScreenHandset;
// without it the page is the watch's face under CallControlsWatch.
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import '../utils/compact_auto_reset_controller.dart';
import '../widgets/call_controls.dart';
import 'call_screen_handset.dart';
import '../widgets/watch/call_controls_watch.dart';

/// The call itself: the default screen on a phone, the face on a watch.
@RoutePage()
class CallHomeScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallHomeScreenPage();

  @override
  Widget build(BuildContext context) {
    final phone = CallPhoneScope.maybeOf(context);
    if (phone == null) {
      assert(
        context.getInheritedWidgetOfExactType<CallWatchScope>() != null,
        'CallHomeScreenPage is built under CallScreenHandset or CallControlsWatch',
      );
      return const CallWatchFace();
    }
    return _ClosingMenusWhenPutAway(
      compact: phone.compact,
      child: Padding(
        padding: phone.padding,
        child: CallControls(callStatus: phone.callStatus, popupMenuItems: phone.popupMenuItems, params: phone.params),
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
