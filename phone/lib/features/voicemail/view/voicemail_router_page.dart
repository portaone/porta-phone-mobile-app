import 'package:auto_route/auto_route.dart';

/// The voicemail section of the bottom menu, and what can be reached from it.
///
/// A router rather than the screen directly, for one reason: a message names
/// the person who left it, and opening that person's card is a screen of its
/// own. Every other tab that can reach a contact declares that route as its
/// own child, because a route lives in exactly one place in the tree and
/// navigating to a sibling tab's copy would carry the person out of voicemail
/// and into that tab.
@RoutePage()
class VoicemailRouterPage extends AutoRouter {
  const VoicemailRouterPage({super.key});
}
