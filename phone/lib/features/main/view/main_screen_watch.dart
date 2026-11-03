import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/features/main/widgets/widgets.dart';
import 'package:webtrit_phone/features/session_status/session_status.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'main_screen_params.dart';

/// The main screen on a watch face.
///
/// A bar of five tabs takes a quarter of a 192-point face and its captions do
/// not fit, so the watch opens on a hub instead: the configured sections as a
/// grid of round buttons, each with the count its tab shows, and Settings
/// last, with the connection state the phone's account button carries.
/// Choosing one opens the section on the whole face; going back returns to
/// the hub. A section is kept, hidden, while the hub shows, as a phone keeps
/// its tabs; one opened from elsewhere opens on the face.
///
/// The hub stays even with a single section: it is where Settings lives.
class MainScreenWatch extends StatelessWidget {
  const MainScreenWatch({super.key, required this.params});

  final MainScreenParams params;

  @override
  Widget build(BuildContext context) {
    final onTabSelected = params.onTabSelected;
    final sectionPick = params.pickInSection;
    return WatchDrillIn(
      menuFirst: true,
      keepContent: true,
      // A section opened from elsewhere - a notification, a link - shows on
      // the face rather than behind the hub.
      openOn: params.currentIndex,
      menu: (context, open) => Scaffold(
        body: _Hub(
          tabs: params.tabs,
          decorateTabIcon: params.decorateTabIcon,
          pick: params.pick,
          onChosen: onTabSelected == null
              ? null
              : (index) {
                  onTabSelected(index);
                  open();
                },
        ),
      ),
      content: Scaffold(
        body: Column(
          children: [
            if (sectionPick != null) _PickBanner(pick: sectionPick),
            Expanded(child: params.body),
          ],
        ),
      ),
    );
  }
}

/// The sections and Settings, last, as a grid of round buttons, under what
/// is being chosen when something is - so a choice that starts while the hub
/// shows is said where the person is.
class _Hub extends StatelessWidget {
  const _Hub({required this.tabs, required this.decorateTabIcon, required this.pick, required this.onChosen});

  final List<BottomMenuTab> tabs;
  final TabIconDecorator? decorateTabIcon;
  final MainScreenPick? pick;

  /// Null leaves the hub inert, as the phone's bar without a handler.
  final ValueChanged<int>? onChosen;

  @override
  Widget build(BuildContext context) {
    final onChosen = this.onChosen;
    final pick = this.pick;
    final onCancel = pick?.onCancel;
    // A call that left the screen is shown in the title's place, to go back to.
    final call = context.select<CallBloc, ActiveCall?>(
      (bloc) => bloc.state.display == CallDisplay.overlay && bloc.state.activeCalls.isNotEmpty
          ? bloc.state.activeCalls.current
          : null,
    );
    // What is being chosen comes first: it is what the person is in the
    // middle of, and giving it up - Cancel, below - returns to the call.
    final header = pick != null
        ? _PickHeader(announcement: pick.announcement)
        : call != null
        ? _CallInProgress(call: call)
        : null;
    return WatchIconGrid(
      title: header == null ? EnvironmentConfig.APP_NAME : null,
      header: header,
      items: [
        for (final (index, tab) in tabs.indexed)
          WatchIconGridItem(
            icon: tab.decoratedIcon(decorateTabIcon),
            caption: context.parseL10n(tab.titleL10n),
            identifier: tab.navBarId,
            buttonKey: tab.navBarKey,
            onPressed: onChosen == null ? null : () => onChosen(index),
          ),
        // While a choice is being made, the way out of it takes Settings'
        // place: the face has room for one more button, and the choice is
        // what the person is in the middle of.
        if (pick != null && onCancel != null)
          WatchIconGridItem(
            icon: const Icon(Icons.close),
            caption: pick.cancelLabel,
            emphasis: WatchRoundEmphasis.outlined,
            onPressed: onCancel,
          )
        else
          WatchIconGridItem(
            icon: const _AccountStatusIcon(),
            caption: context.l10n.main_Button_settings,
            // The name and the id of the phone's account button, which opens
            // the same place.
            semanticLabel: context.l10n.settings_AppBarTitle_myAccount,
            identifier: mainAppBarId,
            buttonKey: mainAppBarKey,
            emphasis: WatchRoundEmphasis.outlined,
            onPressed: onChosen == null ? null : () => context.router.navigate(const SettingsRouterPageRoute()),
          ),
      ],
    );
  }
}

/// What is being chosen, in the hub's title place: small, two lines at most,
/// and read out when it arrives, as the phone's banner is.
class _PickHeader extends StatelessWidget {
  const _PickHeader({required this.announcement});

  final String announcement;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Text(
        announcement,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: themeData.textTheme.bodySmall?.copyWith(
          color: themeData.colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Settings with the connection state the phone's account button shows: a
/// dot in the state's colour, the top session issue's badge, and the state
/// as an id on a node of its own, which a screen reader passes by.
class _AccountStatusIcon extends StatelessWidget {
  const _AccountStatusIcon();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionStatusCubit, SessionStatusState>(
      buildWhen: (p, c) => p.status != c.status || p.topIssue != c.topIssue,
      builder: (context, state) {
        final topIssue = state.topIssue;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Semantics(
              container: true,
              identifier: state.status.isReady
                  ? mainAppBarConnectionStatusConnectedId
                  : mainAppBarConnectionStatusConnectingId,
              child: const Icon(Icons.settings_outlined),
            ),
            Positioned(
              right: -3,
              top: -3,
              child: ExcludeSemantics(
                child: SizedBox.square(
                  dimension: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: state.status.color(context), shape: BoxShape.circle),
                  ),
                ),
              ),
            ),
            if (topIssue != null)
              Positioned(
                right: -3,
                bottom: -3,
                child: ExcludeSemantics(child: SessionIssueBadge(color: topIssue.color(context), size: 10)),
              ),
          ],
        );
      },
    );
  }
}

/// What is being chosen, over the open section: one line at the top of the
/// face, where its width allows it - the phone's banner is a strip across the
/// bottom, which a round face cuts at the corners and where the edge button
/// sits - with the way out as a small close button. Read out when it
/// arrives, as on the phone.
class _PickBanner extends StatelessWidget {
  const _PickBanner({required this.pick});

  final MainScreenPick pick;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final onCancel = pick.onCancel;
    final padding = context.watchContentPadding();
    final foreground = themeData.colorScheme.onSecondary;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(padding.left, padding.top, padding.right, 2),
        child: DecoratedBox(
          decoration: ShapeDecoration(color: themeData.colorScheme.secondary, shape: const StadiumBorder()),
          child: Padding(
            padding: EdgeInsets.only(left: 10, right: onCancel == null ? 10 : 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    pick.announcement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: onCancel == null ? TextAlign.center : TextAlign.start,
                    style: themeData.textTheme.labelSmall?.copyWith(color: foreground),
                  ),
                ),
                if (onCancel != null)
                  IconButton(
                    onPressed: onCancel,
                    tooltip: pick.cancelLabel,
                    icon: Icon(Icons.close, size: 16, color: foreground),
                    constraints: const BoxConstraints.tightFor(width: 32, height: 28),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The call going on while the hub is shown: a green pill with how long it
/// has lasted and who it is with, which returns to it.
class _CallInProgress extends StatelessWidget {
  const _CallInProgress({required this.call});

  final ActiveCall call;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final name = call.nameOrNumber;
    // The scheme colour the call screen's Answer falls back to, so a brand
    // recolours both.
    final background = themeData.colorScheme.tertiary;

    // Narrower than the face where it stands: the top of a round face is
    // its narrowest part.
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.56),
      child: SemanticAction(
        label: context.l10n.callThumbnail_SemanticsLabel_returnToCall,
        identifier: callActiveThumbnailId,
        child: Material(
          color: background,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.router.navigate(const CallScreenPageRoute()),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ExcludeSemantics(
                  child: CallDuration(
                    since: call.acceptedTime,
                    builder: (context, elapsed) => Text(
                      [
                        if (elapsed != null) elapsed.format(),
                        if (call.held) context.l10n.call_description_held,
                        name,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: themeData.textTheme.labelMedium?.copyWith(
                        color: themeData.colorScheme.onTertiary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
