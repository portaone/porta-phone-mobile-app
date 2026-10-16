import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:mocktail/mocktail.dart';

class _MockStackRouter extends Mock implements StackRouter {}

/// Puts [child] under a router that has nowhere to go back to, which is what a
/// screen with an `ExtBackButton` (auto_route's leading button) needs to build
/// in a widget test: the button asks the router whether it can pop.
Widget withRootStackRouter(Widget child) {
  final router = _MockStackRouter();
  when(
    () => router.canPop(
      ignoreChildRoutes: any(named: 'ignoreChildRoutes'),
      ignoreParentRoutes: any(named: 'ignoreParentRoutes'),
      ignorePagelessRoutes: any(named: 'ignorePagelessRoutes'),
    ),
  ).thenReturn(false);
  when(() => router.topPage).thenReturn(null);
  when(() => router.pagelessRoutesObserver).thenReturn(PagelessRoutesObserver());

  return RouterScope(
    controller: router,
    inheritableObserversBuilder: () => const [],
    stateHash: 0,
    navigatorObservers: const [],
    child: StackRouterScope(controller: router, stateHash: 0, child: child),
  );
}
