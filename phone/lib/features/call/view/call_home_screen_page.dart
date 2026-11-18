// The first page of the call screen's routes (callScreenRoutes of the app
// router): the call itself. It shows what the routes' host hands over in
// CallScreenHomeScope - the default screen from CallScreenHandset, the face from
// CallControlsWatch. The watch's other pages are in
// call_watch_screen_pages.dart.
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import '../widgets/call_screen_home_scope.dart';

/// The call itself: the default screen on a phone, the face on a watch.
@RoutePage()
class CallHomeScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const CallHomeScreenPage();

  @override
  Widget build(BuildContext context) => CallScreenHomeScope.of(context).builder(context);
}
