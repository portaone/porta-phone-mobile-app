/// Puts a login screen on a test window as the app shows it: the shipped
/// theme, a [LoginCubit] and the repositories the screens read.
library;

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/notifications/notifications.dart';
import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../../helpers/shipped_theme.dart';
import '../../helpers/stack_router.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockAppInfo extends Mock implements AppInfo {}

class _MockPackageInfo extends Mock implements PackageInfo {}

class _NoHistory implements AutocompleteHistoryRepository {
  @override
  List<String> getHistory(String key) => const [];

  @override
  Future<void> addToHistory(String key, String value, {int maxItems = 8}) async {}
}

class LoginHarness {
  LoginHarness({List<String> signinOrder = const []}) {
    final appInfo = _MockAppInfo();
    when(() => appInfo.version).thenReturn(Version.parse('1.0.0'));
    final packageInfo = _MockPackageInfo();
    when(() => packageInfo.version).thenReturn('1.0.0');
    when(() => packageInfo.buildNumber).thenReturn('1');

    cubit = LoginCubit(
      authRepository: _MockAuthRepository(),
      notificationsBloc: notificationsBloc,
      appInfo: appInfo,
      packageInfo: packageInfo,
      appCompatibilityResolver: const DefaultAppCompatibilityResolver(),
      onLoginSuccess: (_, _) {},
      signinOrder: signinOrder,
    );
  }

  final NotificationsBloc notificationsBloc = NotificationsBloc();
  late final LoginCubit cubit;

  Widget wrap(Widget screen) => wrapCubit(cubit, screen);

  /// [wrap] for a test that brings its own [LoginCubit], a mock of it say.
  static Widget wrapCubit(LoginCubit cubit, Widget screen) {
    return Provider<AutocompleteHistoryRepository>.value(
      value: _NoHistory(),
      child: withShippedTheme(withRootStackRouter(BlocProvider<LoginCubit>.value(value: cubit, child: screen))),
    );
  }

  Future<void> release() async {
    await cubit.close();
    await notificationsBloc.close();
  }
}
