import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/call/call.dart';

import '../../../helpers/screen_presets.dart';

/// The app's routes in their shape, with plain pages: the shell under the
/// root, the main screen and the call screen in it, and under the call screen
/// a router of its own whose first page has the empty path, as the call's
/// pages on a watch.
final _home = PageInfo('Home', builder: (_) => const Text('home'));
const _call = PageInfo.emptyShell('Call');
final _face = PageInfo('Face', builder: (_) => const Text('face'));
final _more = PageInfo('More', builder: (_) => const Text('more'));
final _text = PageInfo('Text', builder: (_) => const Text('text'));

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}

RootStackRouter _router() => RootStackRouter.build(
  routes: [
    // A page over the whole app, as a watch's text page.
    AutoRoute(page: _text, path: '/text'),
    AutoRoute(
      page: const PageInfo.emptyShell(AppShellRoute.name),
      path: '/',
      children: [
        RedirectRoute(path: '', redirectTo: MainShellRoute.name),
        AutoRoute(
          page: const PageInfo.emptyShell(MainShellRoute.name),
          path: MainShellRoute.name,
          children: [
            AutoRoute(page: _home, path: ''),
            AutoRoute(
              page: _call,
              path: 'call',
              children: [
                AutoRoute(page: _face, path: '', initial: true),
                AutoRoute(page: _more, path: 'more'),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

void main() {
  for (final preset in watchPresets) {
    testWidgets('on $preset a call screen with its own pages is left for the main screen', (tester) async {
      preset.apply(tester);
      final router = _router();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);

      unawaited(router.push(const _Route('Call')));
      await tester.pumpAndSettle();
      expect(find.text('face'), findsOneWidget);

      CallShell.backToMainScreen(router);
      await tester.pumpAndSettle();

      expect(find.text('face'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  }

  testWidgets('a page opened over the call\'s face is left with it', (tester) async {
    watchPresets.last.apply(tester);
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    unawaited(router.push(const _Route('Call')));
    await tester.pumpAndSettle();
    unawaited(
      router
          .innerRouterOf<StackRouter>(AppShellRoute.name)!
          .innerRouterOf<StackRouter>(MainShellRoute.name)!
          .innerRouterOf<StackRouter>('Call')!
          .push(const _Route('More')),
    );
    await tester.pumpAndSettle();
    expect(find.text('more'), findsOneWidget);

    CallShell.backToMainScreen(router);
    await tester.pumpAndSettle();

    expect(find.text('more'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a page over the whole app stays open when the call ends', (tester) async {
    watchPresets.last.apply(tester);
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();
    unawaited(router.push(const _Route('Call')));
    await tester.pumpAndSettle();
    unawaited(router.push(const _Route('Text')));
    await tester.pumpAndSettle();
    expect(find.text('text'), findsOneWidget);

    CallShell.backToMainScreen(router);
    await tester.pumpAndSettle();

    expect(find.text('text'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('face'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
