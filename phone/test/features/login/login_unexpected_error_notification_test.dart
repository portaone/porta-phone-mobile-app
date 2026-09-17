import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:api/api.dart';

import 'package:webtrit_phone/features/login/login.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

// The fallback notification is what a failure the app cannot word falls back
// to, so the raw response has to stay reachable from it: the snackbar names the
// kind of failure, the action carries the fields support asks for.
void main() {
  Future<SnackBarAction?> actionFor(WidgetTester tester, Object error) async {
    late SnackBarAction? action;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            action = LoginUnexpectedErrorNotification(error).action(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    return action;
  }

  testWidgets('a rejected request keeps its details one tap away', (tester) async {
    final action = await actionFor(
      tester,
      RequestFailure(
        url: Uri.parse('https://demo.example.com/api/v1/session'),
        statusCode: 401,
        requestId: 'test-request-id',
        error: const ErrorResponse(message: 'User authentication error'),
      ),
    );

    expect(action, isNotNull);
    expect(action!.label, 'Details');
  });

  testWidgets('a transport failure does too', (tester) async {
    final action = await actionFor(tester, const SocketException('no route to host'));

    expect(action, isNotNull);
  });

  testWidgets('an error with no fields to show offers no empty screen', (tester) async {
    final action = await actionFor(tester, Exception('something else entirely'));

    expect(action, isNull);
  });
}
