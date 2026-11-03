/// Puts a consent screen - the terms, the contacts consent, the permissions
/// and their tips - on a test window as the app shows it: the shipped theme,
/// a router, an [AppBloc] with nothing agreed yet and a [PermissionsCubit].
library;

import 'package:material_ui/material_ui.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/permissions/permissions.dart';
import 'package:webtrit_phone/models/models.dart';

import '../helpers/shipped_theme.dart';
import '../helpers/stack_router.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockPermissionsCubit extends MockCubit<PermissionsState> implements PermissionsCubit {}

/// Made per test, so no stub or recorded call carries over to the next.
class ConsentHarness {
  ConsentHarness() {
    when(() => appBloc.state).thenReturn(
      const AppState(
        themeMode: ThemeMode.light,
        locale: Locale('en'),
        userAgreementStatus: AgreementStatus.pending,
        contactsAgreementStatus: AgreementStatus.pending,
      ),
    );
    when(() => permissionsCubit.state).thenReturn(const PermissionsState());
  }

  final AppBloc appBloc = _MockAppBloc();
  final PermissionsCubit permissionsCubit = _MockPermissionsCubit();

  Widget wrap(Widget screen) {
    return withShippedTheme(
      withRootStackRouter(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>.value(value: appBloc),
            BlocProvider<PermissionsCubit>.value(value: permissionsCubit),
          ],
          child: screen,
        ),
      ),
    );
  }
}
