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
    final themeData = Theme.of(context);
    final LoginSwitchScreenStyles? loginPageStyles = themeData.extension<LoginSwitchScreenStyles>();
    final LoginSwitchScreenStyle? localStyle = style ?? loginPageStyles?.primary;

    return BlocBuilder<LoginCubit, LoginState>(
      buildWhen: (previous, current) =>
          whenLoginSwitchScreenPageActive(current) && previous.supportedLoginTypes != current.supportedLoginTypes,
      builder: (context, state) {
        final supportedLoginTypes = forceLoginTypes ?? state.supportedLoginTypes!;
        final isWatch = context.formFactor == FormFactor.watch;
        // On a watch the ways in are the first tab, in front of the forms.
        final hasWaysIn = isWatch && LoginTypeWatch.opensOnWaysIn(supportedLoginTypes);
        final firstForm = hasWaysIn ? 1 : 0;
        return AutoTabsRouter(
          routes: [
            if (hasWaysIn) LoginWaysInScreenPageRoute(supportedLoginTypes: supportedLoginTypes),
            ...supportedLoginTypes.map((e) => e.toPageRouteInfo()),
          ],
          duration: Duration.zero,
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);
            // The outer builder rebuilds only when the ways in change, so the
            // request's progress is read on its own.
            return BlocSelector<LoginCubit, LoginState, bool>(
              selector: (state) => state.processing,
              builder: (context, processing) => _WatchBack(
                enabled: isWatch,
                processing: processing,
                onForm: hasWaysIn && tabsRouter.activeIndex != 0,
                backToWaysIn: () => tabsRouter.setActiveIndex(0),
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
                    top: bodySafeAreaSides.contains(SafeAreaSide.top),
                    bottom: bodySafeAreaSides.contains(SafeAreaSide.bottom),
                    left: bodySafeAreaSides.contains(SafeAreaSide.left),
                    right: bodySafeAreaSides.contains(SafeAreaSide.right),
                    child: child,
                  ),
                  currentLoginType:
                      supportedLoginTypes[(tabsRouter.activeIndex - firstForm).clamp(
                        0,
                        supportedLoginTypes.length - 1,
                      )],
                  supportedLoginTypes: supportedLoginTypes,
                  onLoginTypeChanged: (loginType) =>
                      tabsRouter.setActiveIndex(supportedLoginTypes.indexOf(loginType) + firstForm),
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
    required this.backToWaysIn,
    required this.child,
  });

  final bool enabled;
  final bool processing;
  final bool onForm;
  final VoidCallback backToWaysIn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return PopScope(
      canPop: !processing && !onForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !processing && onForm) backToWaysIn();
      },
      child: child,
    );
  }
}

/// The ways in on a watch face, the tab in front of the forms.
@RoutePage()
class LoginWaysInScreenPage extends StatelessWidget {
  // ignore: use_key_in_widget_constructors
  const LoginWaysInScreenPage({required this.supportedLoginTypes});

  final List<LoginType> supportedLoginTypes;

  @override
  Widget build(BuildContext context) {
    final tabsRouter = AutoTabsRouter.of(context);
    return LoginWaysIn(
      supportedLoginTypes: supportedLoginTypes,
      onChosen: (type) => tabsRouter.setActiveIndex(supportedLoginTypes.indexOf(type) + 1),
    );
  }
}
