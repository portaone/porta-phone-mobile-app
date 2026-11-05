import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/main/widgets/widgets.dart';
import 'package:webtrit_phone/models/models.dart';

/// What somebody is being sent to the sections to choose, as the screen says
/// it: the wording of whatever is asking, and a way out where there is one.
@immutable
class MainScreenPick {
  const MainScreenPick({required this.announcement, required this.onCancel, required this.cancelLabel});

  final String announcement;

  /// Null where the person cannot give up on the choice from here.
  final VoidCallback? onCancel;
  final String cancelLabel;
}

/// Everything both arrangements of the main screen show and dispatch, built
/// once by [MainScreen] above the switch.
@immutable
class MainScreenParams {
  const MainScreenParams({
    required this.body,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.decorateTabIcon,
    required this.pick,
    required this.pickOfferedHere,
  });

  /// The open section.
  final Widget body;
  final List<BottomMenuTab> tabs;

  /// Position of the open tab in [tabs].
  final int currentIndex;

  /// Null leaves the sections inert - a static preview shows them without
  /// wiring.
  final ValueChanged<int>? onTabSelected;

  /// Null draws icons bare; see [TabIconDecorator].
  final TabIconDecorator? decorateTabIcon;

  /// What is being chosen in the sections; null when nothing is.
  final MainScreenPick? pick;

  /// Whether the open section has a destination to offer for [pick]. Told on
  /// a page of conversations, the choice could not be made there.
  final bool pickOfferedHere;

  /// [pick], where the open section can answer it.
  MainScreenPick? get pickInSection => pickOfferedHere ? pick : null;
}
