import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubits/cubits.dart';

class VoicemailFlavorOverlay extends StatelessWidget {
  const VoicemailFlavorOverlay({required this.child, super.key});

  final Widget child;

  /// Bottom-bar icon decoration: overlays the unread counter on the voicemail
  /// section and leaves every other one untouched. Hand it to the bar from a
  /// host that provides a [VoicemailSessionCubit] - the bar itself does not
  /// require one.
  static Widget forTab(BottomMenuTab tab, Widget icon) {
    return tab.flavor == MainFlavor.voicemail ? VoicemailFlavorOverlay(child: icon) : icon;
  }

  @override
  Widget build(BuildContext context) {
    // A host that hands [forTab] to the bar without providing the count gets a
    // bare icon, not a screen-wide provider error: the badge is an ornament and
    // must not be able to take the navigation down.
    //
    // The count alone: the session cubit also carries the mailbox, and the
    // badge has no reason to rebuild when a message changes.
    final unreadCount = context.select<VoicemailSessionCubit?, int>((cubit) => cubit?.state.unreadCount ?? 0);

    return TabIconCountBadge(icon: child, count: unreadCount);
  }
}
