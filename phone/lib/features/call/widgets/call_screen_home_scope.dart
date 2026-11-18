// What the first page of the call screen's routes shows, put over the routes
// by their host: CallScreenHandset hands over the phone's default screen,
// CallControlsWatch the face. The page is CallHomeScreenPage
// (view/call_home_screen_page.dart).
import 'package:material_ui/material_ui.dart';

/// The call itself, as the host of the call screen's routes shows it on
/// their first page.
class CallScreenHomeScope extends InheritedWidget {
  const CallScreenHomeScope({super.key, required this.builder, required super.child});

  /// Builds the call itself in the first page's own context, below the
  /// routes' navigator: the default screen on a phone, the face on a watch.
  final WidgetBuilder builder;

  /// The [CallScreenHomeScope] of the host the routes are under; there is always
  /// one, since the routes are built by a host only.
  static CallScreenHomeScope of(BuildContext context) {
    final home = context.dependOnInheritedWidgetOfExactType<CallScreenHomeScope>();
    assert(home != null, 'The call screen routes are built under CallScreenHandset or CallControlsWatch');
    return home!;
  }

  // The host hands over a new builder with every build of its own, carrying
  // what changed with the calls.
  @override
  bool updateShouldNotify(CallScreenHomeScope oldWidget) => true;
}
