import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/features/voicemail/widgets/voicemail_flavor_overlay.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// Every badge the bottom menu can carry, each drawn by the feature it belongs
/// to and silent where its section is not configured or its state not provided.
final mainTabIconDecorator = composeTabIconDecorators([MessagingFlavorOverlay.forTab, VoicemailFlavorOverlay.forTab]);

@RoutePage()
class MainScreenPage extends StatefulWidget {
  // ignore: use_key_in_widget_constructors
  const MainScreenPage();

  @override
  State<MainScreenPage> createState() => _MainScreenPageState();
}

class _MainScreenPageState extends State<MainScreenPage> {
  /// The tab set and the active tab's path as of the last frame - what a
  /// configuration reload is detected against.
  List<BottomMenuTab>? _lastTabs;
  String? _lastActivePath;

  @override
  Widget build(BuildContext context) {
    final mainScreenRouteStateRepository = context.read<MainScreenRouteStateRepository>();

    final featureAccess = context.read<FeatureAccess>();
    final bottomMenuManager = featureAccess.bottomMenuConfig;
    final tabs = bottomMenuManager.tabs;

    // Reactive: rebuilds when the adapter capability becomes available (e.g. system-info loads async).
    final callToActionsEnabled = context.select<FeatureAccess, bool>(
      (features) => features.coreSupport.supportsCallToActions,
    );

    final systemNotificationsFeature = featureAccess.systemNotificationsConfig;
    final systemNotificationsEnabled = systemNotificationsFeature.systemNotificationsSupport;

    // On a watch the hub is the first tab, in front of the sections.
    final autoTabsRouter = AdaptiveLayout(
      handset: (_) => _tabsRouter(
        hasHub: false,
        tabs: tabs,
        callToActionsEnabled: callToActionsEnabled,
        mainScreenRouteStateRepository: mainScreenRouteStateRepository,
      ),
      watch: (_) => _tabsRouter(
        hasHub: true,
        tabs: tabs,
        callToActionsEnabled: callToActionsEnabled,
        mainScreenRouteStateRepository: mainScreenRouteStateRepository,
      ),
    );
    final content = callToActionsEnabled
        ? BlocProvider<CallToActionsCubit>(
            create: (context) => CallToActionsCubit(
              callToActionsRepository: context.read<CallToActionsRepository>(),
              userRepository: context.read<UserRepository>(),
              locale: context.read<AppBloc>().state.locale,
            ),
            child: CallToActionsShell(child: autoTabsRouter),
          )
        : autoTabsRouter;

    return BlocBuilder<CallPullCubit, List<DialogInfo>>(
      builder: (context, dialogs) {
        return AppBarParams(
          systemNotificationsEnabled: systemNotificationsEnabled,
          pullableCallDialogs: dialogs,
          child: content,
        );
      },
    );
  }

  /// The sections' tabs, with the hub in front of them when [hasHub].
  Widget _tabsRouter({
    required bool hasHub,
    required List<BottomMenuTab> tabs,
    required bool callToActionsEnabled,
    required MainScreenRouteStateRepository mainScreenRouteStateRepository,
  }) {
    final positions = MainTabPositions(hasHub: hasHub);

    return AutoTabsRouter(
      // The router reads homeIndex once, so a window that changes class gets a
      // router of its own.
      key: ValueKey(hasHub),
      routes: [if (hasHub) const MainHubScreenPageRoute(), ..._buildRoutePages(tabs)],
      homeIndex: hasHub ? 0 : -1,
      duration: Duration.zero,
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        final section = positions.sectionOf(tabsRouter.activeIndex);

        _restoreActiveTabAfterConfigChange(tabsRouter, tabs, positions);

        if (callToActionsEnabled) {
          final isRouteActive = context.router.isRouteActive(MainScreenPageRoute.name);
          // The flavor belongs to the active tab, not to the position: the tab
          // set is configured per install, so an index into the enum points at
          // the wrong flavor and walks off it once more tabs are configured
          // than the enum has values. Looked up softly: a configuration
          // reload can shrink the tab set while the router still reports the
          // old index for a frame, and the cubit accepts a null flavor.
          final flavor = section == null ? null : tabs.elementAtOrNull(section)?.flavor;

          context.read<CallToActionsCubit>()
            ..getActions(flavor)
            ..changeVisibility(isRouteActive);
        }

        // Tabs are guaranteed to be non-empty due to validation during the bootstrap phase.
        // The screen itself decides whether a bar is drawn at all - the
        // single-section rule lives there, shared with the previews.
        //
        // Read rather than decided: a feature that wants somebody chosen
        // leaves its request here, and this screen never learns which features
        // those are. It is also why the purpose is not built here - the
        // previews build the same screen and have nothing to be choosing for.
        final pickPurpose = context.select<DestinationPickingCubit, DestinationPickPurpose?>(
          (cubit) => cubit.state.purpose,
        );

        return MainScreen(
          // Above the sections, so every list they build can ask whether a
          // choice is being made without reaching into the feature that wants
          // one. The presenter is the other end of the same arrangement: what
          // a feature has to say about a finished choice reaches the person
          // wherever the lists left them.
          body: DestinationPickReportPresenter(
            child: DestinationPicking(purpose: pickPurpose, child: child),
          ),
          tabs: tabs,
          pickPurpose: pickPurpose,
          onCancelPick: context.read<DestinationPickingCubit>().cancel,
          // The shell above provides the unread state this reads.
          decorateTabIcon: mainTabIconDecorator,
          // Be aware to use activeIndex from tabsRouter, not from bottomMenuManager
          // to handle navigation changes correctly, especially when the user navigates by url.
          // e.g router.navigate(const MainScreenPageRoute(['favorites']));
          // Clamped for the same one-frame window as the flavor above:
          // the bar asserts its index is within the entries it draws.
          currentIndex: section?.clamp(0, tabs.length - 1),
          onTabSelected: (index) => BottomMenuTabHandler.handleTap(
            context,
            index: index,
            tabs: tabs,
            tabsRouter: tabsRouter,
            positions: positions,
          ),
        );
      },
      navigatorObservers: () => [MainScreenNavigatorObserver(mainScreenRouteStateRepository)],
    );
  }

  /// When its routes are replaced on a configuration reload, the tabs router
  /// re-matches the active tab by route name, and every embedded section
  /// shares one - the user landed on the first of them whichever was open.
  /// Reactivate the tab that was open, identified by its path, once the
  /// frame settles.
  void _restoreActiveTabAfterConfigChange(TabsRouter tabsRouter, List<BottomMenuTab> tabs, MainTabPositions positions) {
    final section = positions.sectionOf(tabsRouter.activeIndex);
    final index = BottomMenuTabHandler.reactivationIndex(
      previousTabs: _lastTabs,
      previousPath: _lastActivePath,
      tabs: tabs,
      activeIndex: section,
    );
    _lastTabs = tabs;
    if (index != null) {
      _lastActivePath = tabs[index].routePath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tabsRouter.setActiveIndex(positions.tabOf(index));
      });
    } else if (section != null && section < tabs.length) {
      _lastActivePath = tabs[section].routePath;
    }
  }

  List<PageRouteInfo> _buildRoutePages(List<BottomMenuTab> tabs) {
    return tabs.map<PageRouteInfo<dynamic>>((tab) {
      switch (tab) {
        case FavoritesBottomMenuTab():
          return const FavoritesRouterPageRoute();
        case KeypadBottomMenuTab():
          return const KeypadScreenPageRoute();
        case MessagingBottomMenuTab():
          return const ConversationsScreenPageRoute();
        case RecentsBottomMenuTab():
          return recentsRouteOf(tab);
        case ContactsBottomMenuTab():
          return contactsRouteOf(tab);
        case VoicemailBottomMenuTab():
          return const VoicemailRouterPageRoute();
        case CallCenterBottomMenuTab():
          return const CallCenterTabPageRoute();
        case EmbeddedBottomMenuTab():
          return EmbeddedTabPageRoute(id: tab.id);
      }
    }).toList();
  }
}

/// Where the sections sit among the tabs, the one place that knows: a watch has
/// the hub in front of them.
class MainTabPositions {
  const MainTabPositions({required this.hasHub});

  final bool hasHub;

  int get _firstSection => hasHub ? 1 : 0;

  /// The tab of a section's position in the configured tabs.
  int tabOf(int section) => section + _firstSection;

  /// The section of a tab; null for the hub.
  int? sectionOf(int tab) => tab < _firstSection ? null : tab - _firstSection;
}

/// The hub on a watch face, the tab in front of the sections.
@RoutePage()
class MainHubScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const MainHubScreenPage();

  @override
  Widget build(BuildContext context) {
    final tabs = context.read<FeatureAccess>().bottomMenuConfig.tabs;
    final tabsRouter = AutoTabsRouter.of(context);
    final purpose = context.select<DestinationPickingCubit, DestinationPickPurpose?>((cubit) => cubit.state.purpose);

    return MainHub(
      tabs: tabs,
      decorateTabIcon: mainTabIconDecorator,
      pick: MainScreenPick.of(context, purpose, context.read<DestinationPickingCubit>().cancel),
      onChosen: (index) => BottomMenuTabHandler.handleTap(
        context,
        index: index,
        tabs: tabs,
        tabsRouter: tabsRouter,
        positions: const MainTabPositions(hasHub: true),
      ),
    );
  }
}

/// Handles the logic for bottom menu tab interactions and persistence.
abstract final class BottomMenuTabHandler {
  /// Processes a tab tap by persisting the selection and updating the UI router.
  static void handleTap(
    BuildContext context, {
    required int index,
    required List<BottomMenuTab> tabs,
    required TabsRouter tabsRouter,
    MainTabPositions positions = const MainTabPositions(hasHub: false),
  }) {
    final tappedTab = tabs[index];

    // Persist the selection by the tab's path: with several embedded sections
    // in the menu the kind alone cannot say which of them to restore.
    context.read<ActiveMainTabRepository>().setActiveTabPath(tappedTab.routePath);

    // Update the actual UI state via AutoRoute
    tabsRouter.setActiveIndex(positions.tabOf(index));
  }

  /// Index of the tab to reactivate after the configured tab set changed, or
  /// null when the current activation needs no correction.
  ///
  /// The correction applies only when the tab set really changed, the tab
  /// that was open (identified by [previousPath]) is still configured, and
  /// the router did not land on it by itself. A null [activeIndex] is the hub
  /// of a watch, where the person chose to be: there is nothing to restore.
  static int? reactivationIndex({
    required List<BottomMenuTab>? previousTabs,
    required String? previousPath,
    required List<BottomMenuTab> tabs,
    required int? activeIndex,
  }) {
    if (activeIndex == null || previousTabs == null || previousPath == null) return null;
    if (listEquals(previousTabs, tabs)) return null;
    final index = tabs.indexWhere((tab) => tab.routePath == previousPath);
    if (index < 0 || index == activeIndex) return null;
    return index;
  }
}
