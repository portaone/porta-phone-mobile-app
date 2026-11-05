import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
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

  /// The pick [purpose] asks for, or null when nothing is being chosen. The way
  /// out is offered only where the purpose says a person needs one: a transfer
  /// is left by returning to the call, a message looking for a recipient has no
  /// such screen behind it.
  static MainScreenPick? of(BuildContext context, DestinationPickPurpose? purpose, VoidCallback? onCancel) {
    if (purpose == null) return null;
    return MainScreenPick(
      announcement: purpose.announcement,
      onCancel: purpose.cancellable ? onCancel : null,
      cancelLabel: context.l10n.main_Button_cancelPicking,
    );
  }
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

  /// Position of the open tab in [tabs]; null while a watch shows its hub,
  /// which is a tab of no section.
  final int? currentIndex;

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
