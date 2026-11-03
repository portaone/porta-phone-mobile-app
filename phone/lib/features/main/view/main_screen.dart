import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/main/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'main_screen_handset.dart';
import 'main_screen_params.dart';
import 'main_screen_watch.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    Key? key,
    required this.body,
    required this.tabs,
    required this.currentIndex,
    this.onTabSelected,
    this.decorateTabIcon,
    this.pickPurpose,
    this.onCancelPick,
  }) : super(key: key ?? const ValueKey<String>('MainScreen'));

  final Widget body;

  /// The screen owns its navigation bar: hosts hand over the configured tabs
  /// and the selection instead of a bar-shaped widget, so every host - the
  /// app and the previews - shows the real control.
  final List<BottomMenuTab> tabs;

  /// Position of the open tab in [tabs].
  final int currentIndex;

  /// Null renders the bar inert - a static preview shows it without wiring.
  final ValueChanged<int>? onTabSelected;

  /// Null draws icons bare; see [TabIconDecorator].
  final TabIconDecorator? decorateTabIcon;

  /// What somebody is being sent to the sections to choose, or null when
  /// nothing is.
  ///
  /// Said here rather than by each section, because the bottom of the screen
  /// belongs to this screen: a section drawing its own banner draws it beneath
  /// the bar this one floats over, where nobody sees it.
  final DestinationPickPurpose? pickPurpose;

  /// Gives up on whatever [pickPurpose] is asking for, where it says a person
  /// can give up on it at all. Null in a preview, which has nothing to give up.
  final VoidCallback? onCancelPick;

  @override
  Widget build(BuildContext context) {
    // Only where the open section has a destination to offer. Told on a page
    // of conversations, the banner would announce a choice that cannot be made
    // there. Looked up softly for the same one-frame window the host clamps
    // for: a configuration reload can shrink the tab set while the index still
    // points past it.
    final flavor = tabs.elementAtOrNull(currentIndex)?.flavor;
    final announces = pickPurpose != null && flavor != null && pickPurpose!.offeredBy(flavor);

    // The wording belongs to whatever is doing the asking, not to this screen:
    // the bar is the same bar whether a call is being handed on or a message
    // is being passed to a colleague.
    // A way out is offered only where the purpose says the person needs one:
    // a transfer is left by returning to the call, a message looking for a
    // recipient has no such screen behind it.
    final cancels = pickPurpose?.cancellable ?? false;
    final params = MainScreenParams(
      body: body,
      tabs: tabs,
      currentIndex: currentIndex,
      onTabSelected: onTabSelected,
      decorateTabIcon: decorateTabIcon,
      pick: pickPurpose == null
          ? null
          : MainScreenPick(
              announcement: pickPurpose!.announcement,
              onCancel: cancels ? onCancelPick : null,
              cancelLabel: context.l10n.main_Button_cancelPicking,
            ),
      pickOfferedHere: announces,
    );

    return AdaptiveLayout(
      handset: (_) => MainScreenHandset(params: params),
      watch: (_) => MainScreenWatch(params: params),
    );
  }
}
