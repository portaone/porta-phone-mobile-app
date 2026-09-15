import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/app_localizations.g.dart';

/// What the user is told when a conference is refused or fails. The server
/// speaks in codes; none of them may reach the screen.
void main() {
  late BuildContext context;

  Future<void> pumpContext(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (inner) {
            context = inner;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  testWidgets('every refusal the server can send reads as a sentence', (tester) async {
    await pumpContext(tester);

    const reasons = [
      'conference_disabled',
      'conference_already_active',
      'not_enough_lines',
      'line_without_active_call',
      'no_conference',
      'line_already_in_conference',
      'line_not_in_conference',
      'line_not_ready',
      'invalid_muted',
      'room_create_failed: AudioBridge said no',
      'attach_failed: plugin not loaded',
      'line_in_conference',
      'something the client has never heard of',
    ];

    for (final reason in reasons) {
      final text = ConferenceRefusedNotification(reason).l10n(context);
      expect(text, isNotEmpty);
      expect(text, isNot(contains('_')), reason: 'a wire code reached the screen for "$reason"');
      expect(text, isNot(contains(':')), reason: 'a server diagnostic reached the screen for "$reason"');
    }
  });

  testWidgets('a refusal the user can act on says what to do about it', (tester) async {
    await pumpContext(tester);

    expect(
      const ConferenceRefusedNotification('conference_already_active').l10n(context),
      isNot(const ConferenceRefusedNotification('attach_failed: x').l10n(context)),
      reason: 'a reason worth telling apart is told apart',
    );
  });

  testWidgets('a failed room names the video leg, and otherwise says only that it failed', (tester) async {
    await pumpContext(tester);

    final video = const ConferenceFailedNotification(reason: 'video_not_supported').l10n(context);
    final other = const ConferenceFailedNotification(reason: 'answer_failed').l10n(context);

    expect(video, contains('video'));
    expect(other, isNot(contains('answer_failed')));
  });
}
