import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/main/widgets/widgets.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'main_screen_params.dart';

/// The main screen on a phone: the open section over the whole screen and
/// the tab bar floating over its bottom, with what is being chosen said
/// above the bar.
///
/// A menu of one section shows no bar - there is nothing to switch to - and
/// the section's own scaffolding fills the screen. The choice still has to be
/// said, and with no bar to float over it there is nothing to keep it clear
/// of.
class MainScreenHandset extends StatelessWidget {
  const MainScreenHandset({super.key, required this.params});

  final MainScreenParams params;

  @override
  Widget build(BuildContext context) {
    final pick = params.pickInSection;
    final banner = pick == null
        ? null
        : DestinationPickingBanner(pick.announcement, onCancel: pick.onCancel, cancelLabel: pick.cancelLabel);

    if (params.tabs.length < 2) {
      if (banner == null) return params.body;
      return Scaffold(
        body: params.body,
        bottomNavigationBar: BlurredSurface(sigmaX: 10.0, sigmaY: 10.0, child: banner),
      );
    }

    return Scaffold(
      extendBody: true,
      body: params.body,
      // Above the bar, not behind it, and under one pane of glass with it:
      // both belong to this screen, so they are a single bottom-of-the-screen
      // widget the body is inset by. Blurring them apart would show the seam,
      // two filters sampling different backdrops.
      bottomNavigationBar: BlurredSurface(
        sigmaX: 10.0,
        sigmaY: 10.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          // Both are bars across the screen. Left to itself a Column hands
          // each child only the width it asks for, and the banner - a box
          // around a line of text - would sit centred and half as wide as
          // the bar under it, reading as a label rather than as the state of
          // the screen.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?banner,
            MainBottomNavigationBar(
              tabs: params.tabs,
              currentIndex: params.currentIndex ?? 0,
              onTap: params.onTabSelected,
              decorateIcon: params.decorateTabIcon,
            ),
          ],
        ),
      ),
    );
  }
}
