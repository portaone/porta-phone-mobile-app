import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/widgets/widgets.dart';
import 'package:webtrit_phone/app/constants.dart';

export 'login_switch_screen_style.dart';
export 'login_switch_screen_styles.dart.dart';

enum SafeAreaSide { top, bottom, left, right }

@RoutePage()
class LoginSwitchScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const LoginSwitchScreenPage({
    required this.bodySafeAreaSides,
    this.forceLoginTypes,
    this.isLogoVisible = true,
    this.isAppBarVisible = true,
    this.style,
  });

  final Set<SafeAreaSide> bodySafeAreaSides;
  final List<LoginType>? forceLoginTypes;
  final bool isLogoVisible;
  final bool isAppBarVisible;
  final LoginSwitchScreenStyle? style;

  @override
  Widget build(BuildContext context) {
    // On a watch the ways in are the first tab, in front of the forms. Both
    // arrangements are the same widget, so crossing the class keeps the tabs
    // router in place.
    return AdaptiveLayout(
      handset: (_) => _LoginSwitchTabs(page: this, offersTypeSelect: false),
      watch: (_) => _LoginSwitchTabs(page: this, offersTypeSelect: true),
    );
  }
}

/// The tabs router of the ways in and their forms.
class _LoginSwitchTabs extends StatelessWidget {
  const _LoginSwitchTabs({required this.page, required this.offersTypeSelect});

  final LoginSwitchScreenPage page;

  /// Whether the ways in are a tab of their own in front of the forms, with
  /// going back from a form returning to them.
  final bool offersTypeSelect;

  @override
  Widget build(BuildContext context) {
    final LoginSwitchScreenPage(:bodySafeAreaSides, :forceLoginTypes, :isLogoVisible, :isAppBarVisible, :style) = page;
    final themeData = Theme.of(context);
    final LoginSwitchScreenStyles? loginPageStyles = themeData.extension<LoginSwitchScreenStyles>();
    final LoginSwitchScreenStyle? localStyle = style ?? loginPageStyles?.primary;

    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          whenLoginSwitchScreenPageActive(current) && previous.supportedLoginTypes != current.supportedLoginTypes,
      builder: (context, state) {
        final supportedLoginTypes = forceLoginTypes ?? state.supportedLoginTypes!;
        final hasTypeSelect = offersTypeSelect && LoginTypeWatch.opensOnTypeSelect(supportedLoginTypes);
        return AutoTabsRouter(
          routes: [
            if (hasTypeSelect) LoginTypeSelectScreenPageRoute(supportedLoginTypes: supportedLoginTypes),
            ...supportedLoginTypes.map((e) => e.toPageRouteInfo()),
          ],
          duration: Duration.zero,
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);
            final tab = tabsRouter.current.name;
            final onTypeSelect = tab == LoginTypeSelectScreenPageRoute.name;
            // The grid fills the face; the insets belong to the forms.
            final safeAreaSides = onTypeSelect ? const <SafeAreaSide>{} : bodySafeAreaSides;
            // The outer builder rebuilds only when the ways in change, so the
            // request's progress is read on its own.
            return BlocSelector<LoginCubit, LoginState, bool>(
              selector: (state) => state.processing,
              builder: (context, processing) => _WatchBack(
                enabled: offersTypeSelect,
                processing: processing,
                onForm: hasTypeSelect && !onTypeSelect,
                backToTypeSelect: () =>
                    tabsRouter.navigate(LoginTypeSelectScreenPageRoute(supportedLoginTypes: supportedLoginTypes)),
                child: LoginSwitchScreen(
                  appBar: isAppBarVisible
                      ? AppBar(
                          leading: ExtBackButton(disabled: processing),
                          flexibleSpace: BlurredSurface.fromStyle(localStyle?.appBarBlurredSurface),
                        )
                      : null,
                  header: isLogoVisible
                      ? Column(
                          children: [
                            ConfigurableThemeImage(style: localStyle?.pictureLogoStyle),
                            const SizedBox(height: kInset),
                          ],
                        )
                      : null,
                  body: SafeArea(
                    top: safeAreaSides.contains(SafeAreaSide.top),
                    bottom: safeAreaSides.contains(SafeAreaSide.bottom),
                    left: safeAreaSides.contains(SafeAreaSide.left),
                    right: safeAreaSides.contains(SafeAreaSide.right),
                    child: child,
                  ),
                  currentLoginType: supportedLoginTypes.firstWhere(
                    (type) => type.toPageRouteInfo().routeName == tab,
                    orElse: () => supportedLoginTypes.first,
                  ),
                  supportedLoginTypes: supportedLoginTypes,
                  onLoginTypeChanged: (loginType) => tabsRouter.navigate(loginType.toPageRouteInfo()),
                  processing: processing,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Back on a watch: from a form to the ways in, and nowhere while a form's
/// request is in flight.
///
/// A `PopScope` and not the tabs router's `homeIndex`, which moves to its home
/// tab without asking the page, so it would leave a form mid-request.
class _WatchBack extends StatelessWidget {
  const _WatchBack({
    required this.enabled,
    required this.processing,
    required this.onForm,
    required this.backToTypeSelect,
    required this.child,
  });

  final bool enabled;
  final bool processing;
  final bool onForm;
  final VoidCallback backToTypeSelect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return PopScope(
      canPop: !processing && !onForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !processing && onForm) backToTypeSelect();
      },
      child: child,
    );
  }
}

/// The ways in on a watch face, the tab in front of the forms.
@RoutePage()
class LoginTypeSelectScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const LoginTypeSelectScreenPage({required this.supportedLoginTypes});

  final List<LoginType> supportedLoginTypes;

  @override
  Widget build(BuildContext context) {
    final tabsRouter = AutoTabsRouter.of(context);
    return LoginTypeSelectScreen(
      supportedLoginTypes: supportedLoginTypes,
      onChosen: (type) => tabsRouter.navigate(type.toPageRouteInfo()),
    );
  }
}
