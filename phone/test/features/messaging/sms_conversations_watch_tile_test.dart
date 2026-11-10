import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

import '../../helpers/screen_presets.dart';

class _MockSmsRepository extends Mock implements SmsRepository {}

class _MockUnreadCountCubit extends MockCubit<UnreadCountState> implements UnreadCountCubit {}

/// The other side of an SMS conversation on a watch is the number that is not
/// one of the user's own: the row names nobody until those are known.
void main() {
  const own = '+380000000001';
  const peer = '+380000000002';

  testWidgets('the user\'s own number is never named as the other side', (tester) async {
    watchPresets.last.apply(tester);
    final numbers = StreamController<List<String>>();
    addTearDown(numbers.close);
    final smsRepository = _MockSmsRepository();
    when(smsRepository.watchUserSmsNumbers).thenAnswer((_) => numbers.stream);
    final unreadCount = _MockUnreadCountCubit();
    when(() => unreadCount.state).thenReturn(UnreadCountState.initial());
    final now = DateTime(2026, 11, 11, 12);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepositoryProvider<SmsRepository>.value(
          value: smsRepository,
          child: BlocProvider<UnreadCountCubit>.value(
            value: unreadCount,
            child: Scaffold(
              body: SmsConversationsWatchTile(
                // The user's own number first, as a conversation may store it.
                conversation: SmsConversation(
                  id: 1,
                  firstPhoneNumber: own,
                  secondPhoneNumber: peer,
                  createdAt: now,
                  updatedAt: now,
                ),
                message: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text(own), findsNothing);
    expect(find.text(peer), findsNothing);

    numbers.add(const [own]);
    await tester.pump();

    expect(find.text(peer), findsOneWidget);
    expect(find.text(own), findsNothing);
  });
}
