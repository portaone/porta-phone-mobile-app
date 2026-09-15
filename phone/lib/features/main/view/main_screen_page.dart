import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/features/voicemail/models/models.dart';
import 'package:webtrit_phone/features/voicemail/widgets/voicemail_flavor_overlay.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/utils/utils.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// Every badge the bottom menu can carry, each drawn by the feature it belongs
/// to and silent where its section is not configured or its state not provided.
final _decorateTabIcon = composeTabIconDecorators([MessagingFlavorOverlay.forTab, VoicemailFlavorOverlay.forTab]);

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

    final autoTabsRouter = AutoTabsRouter(
      routes: _buildRoutePages(tabs),
      duration: Duration.zero,
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        _restoreActiveTabAfterConfigChange(tabsRouter, tabs);

        if (callToActionsEnabled) {
          final isRouteActive = context.router.isRouteActive(MainScreenPageRoute.name);
          // The flavor belongs to the active tab, not to the position: the tab
          // set is configured per install, so an index into the enum points at
          // the wrong flavor and walks off it once more tabs are configured
          // than the enum has values. Looked up softly: a configuration
          // reload can shrink the tab set while the router still reports the
          // old index for a frame, and the cubit accepts a null flavor.
          final flavor = tabs.elementAtOrNull(tabsRouter.activeIndex)?.flavor;

          context.read<CallToActionsCubit>()
            ..getActions(flavor)
            ..changeVisibility(isRouteActive);
        }

        // Tabs are guaranteed to be non-empty due to validation during the bootstrap phase.
        // The screen itself decides whether a bar is drawn at all - the
        // single-section rule lives there, shared with the previews.
        // Built here rather than inside the screen: the screen is also built
        // by the previews, which have nothing to be choosing for. This is the
        // one place that decides what is being picked, which is what keeps the
        // lists below from each knowing about the features that ask.
        //
        // Only one at a time, and a call in hand comes first: somebody holding
        // a call they are trying to hand on cannot wait while a message finds
        // a recipient.
        final forwarding = context.select<VoicemailForwardingCubit, Voicemail?>((cubit) => cubit.state.pending);
        final handingCallOver = context.select<CallBloc, bool>((bloc) => bloc.state.isBlingTransferInitiated);

        final DestinationPickPurpose? pickPurpose;
        if (handingCallOver) {
          pickPurpose = BlindTransferPurpose(
            announcement: context.l10n.main_Text_blindTransferInitiated,
            pickLabel: context.l10n.contact_SemanticsLabel_transfer,
            controller: CallControllerScope.of(context),
          );
        } else if (forwarding != null) {
          pickPurpose = ForwardVoicemailPurpose(
            announcement: context.l10n.voicemail_Label_forwardChoosing,
            pickLabel: context.l10n.voicemail_SemanticsLabel_forwardTo,
            messageId: forwarding.id,
            onPicked: (recipient) => context.read<VoicemailForwardingCubit>().sendTo(recipient),
            onCancel: context.read<VoicemailForwardingCubit>().cancel,
          );
        } else {
          pickPurpose = null;
        }

        return MainScreen(
          // Above the sections, so every list they build can ask whether a
          // choice is being made without reaching into the feature that wants
          // one.
          // The outcome is said here rather than on the voicemail screen: by
          // the time there is one the person is in the address book, and the
          // screen that started this is two tabs away.
          body: BlocListener<VoicemailForwardingCubit, VoicemailForwardingState>(
            listenWhen: (previous, current) => previous.report != current.report && current.report != null,
            listener: _reportForward,
            child: DestinationPicking(purpose: pickPurpose, child: child),
          ),
          tabs: tabs,
          pickPurpose: pickPurpose,
          // The shell above provides the unread state this reads.
          decorateTabIcon: _decorateTabIcon,
          // Be aware to use activeIndex from tabsRouter, not from bottomMenuManager
          // to handle navigation changes correctly, especially when the user navigates by url.
          // e.g router.navigate(const MainScreenPageRoute(['favorites']));
          // Clamped for the same one-frame window as the flavor above:
          // the bar asserts its index is within the entries it draws.
          currentIndex: tabsRouter.activeIndex.clamp(0, tabs.length - 1),
          onTabSelected: (index) =>
              BottomMenuTabHandler.handleTap(context, index: index, tabs: tabs, tabsRouter: tabsRouter),
        );
      },
      navigatorObservers: () => [MainScreenNavigatorObserver(mainScreenRouteStateRepository)],
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

  /// When its routes are replaced on a configuration reload, the tabs router
  /// re-matches the active tab by route name, and every embedded section
  /// shares one - the user landed on the first of them whichever was open.
  /// Reactivate the tab that was open, identified by its path, once the
  /// frame settles.
  void _restoreActiveTabAfterConfigChange(TabsRouter tabsRouter, List<BottomMenuTab> tabs) {
    final index = BottomMenuTabHandler.reactivationIndex(
      previousTabs: _lastTabs,
      previousPath: _lastActivePath,
      tabs: tabs,
      activeIndex: tabsRouter.activeIndex,
    );
    _lastTabs = tabs;
    if (index != null) {
      _lastActivePath = tabs[index].routePath;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) tabsRouter.setActiveIndex(index);
      });
    } else if (tabsRouter.activeIndex < tabs.length) {
      _lastActivePath = tabs[tabsRouter.activeIndex].routePath;
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
          return const VoicemailTabPageRoute();
        case EmbeddedBottomMenuTab():
          return EmbeddedTabPageRoute(id: tab.id);
      }
    }).toList();
  }
}

/// Handles the logic for bottom menu tab interactions and persistence.
/// Says what came of passing a message on, wherever the person now is.
void _reportForward(BuildContext context, VoicemailForwardingState state) {
  final report = state.report!;
  final cubit = context.read<VoicemailForwardingCubit>();
  final l10n = context.l10n;
  cubit.reportShown();

  if (report.outcome == VoicemailForwardOutcome.sent) {
    context.showSnackBar(l10n.voicemail_Snackbar_forwarded(report.recipientName));
    return;
  }

  final message = switch (report.outcome) {
    VoicemailForwardOutcome.tooLarge => l10n.voicemail_Snackbar_forwardTooLarge,
    VoicemailForwardOutcome.recipientFull => l10n.voicemail_Snackbar_forwardRecipientFull(report.recipientName),
    VoicemailForwardOutcome.unavailable => l10n.voicemail_Snackbar_forwardUnavailable,
    _ => l10n.voicemail_Snackbar_forwardFailed,
  };

  context.showErrorSnackBar(
    message,
    // Offered only where trying again could end differently. A recording that
    // is too big stays too big, and a colleague who is full stays full.
    action: report.outcome.isRetryable
        ? SnackBarAction(label: l10n.voicemail_Label_retry, onPressed: () => cubit.retry(report))
        : null,
  );
}

abstract final class BottomMenuTabHandler {
  /// Processes a tab tap by persisting the selection and updating the UI router.
  static void handleTap(
    BuildContext context, {
    required int index,
    required List<BottomMenuTab> tabs,
    required TabsRouter tabsRouter,
  }) {
    final tappedTab = tabs[index];

    // Persist the selection by the tab's path: with several embedded sections
    // in the menu the kind alone cannot say which of them to restore.
    context.read<ActiveMainTabRepository>().setActiveTabPath(tappedTab.routePath);

    // Update the actual UI state via AutoRoute
    tabsRouter.setActiveIndex(index);
  }

  /// Index of the tab to reactivate after the configured tab set changed, or
  /// null when the current activation needs no correction.
  ///
  /// The correction applies only when the tab set really changed, the tab
  /// that was open (identified by [previousPath]) is still configured, and
  /// the router did not land on it by itself.
  static int? reactivationIndex({
    required List<BottomMenuTab>? previousTabs,
    required String? previousPath,
    required List<BottomMenuTab> tabs,
    required int activeIndex,
  }) {
    if (previousTabs == null || previousPath == null) return null;
    if (listEquals(previousTabs, tabs)) return null;
    final index = tabs.indexWhere((tab) => tab.routePath == previousPath);
    if (index < 0 || index == activeIndex) return null;
    return index;
  }
}
