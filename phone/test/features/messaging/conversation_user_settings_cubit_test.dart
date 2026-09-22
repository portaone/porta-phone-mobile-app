import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/features/messaging/messaging.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _MockChatsRepository extends Mock implements ChatsRepository {}

class _MockSmsRepository extends Mock implements SmsRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockChatsRepository chatsRepository;
  late _MockSmsRepository smsRepository;
  late StreamController<Map<int, ConversationUserSettings>> chatSettings;
  late StreamController<Map<int, ConversationUserSettings>> smsSettings;

  setUp(() {
    chatsRepository = _MockChatsRepository();
    smsRepository = _MockSmsRepository();
    chatSettings = StreamController.broadcast(sync: true);
    smsSettings = StreamController.broadcast(sync: true);
    when(() => chatsRepository.watchChatUserSettings()).thenAnswer((_) => chatSettings.stream);
    when(() => smsRepository.watchConversationUserSettings()).thenAnswer((_) => smsSettings.stream);
  });

  tearDown(() async {
    await chatSettings.close();
    await smsSettings.close();
  });

  ConversationUserSettings muted({DateTime? until}) {
    return ConversationUserSettings(mute: NotificationMute(muted: true, mutedUntil: until));
  }

  ConversationUserSettingsCubit start(FakeAsync async) {
    final cubit = ConversationUserSettingsCubit(chatsRepository: chatsRepository, smsRepository: smsRepository)..init();
    async.flushMicrotasks();
    return cubit;
  }

  // A timed mute expires silently: the core sends nothing at the moment it
  // lapses. What is stored still says "muted until T" after T, and only the
  // clock can say otherwise - so the answer is derived, and re-derived when
  // the clock reaches the nearest expiry.
  group('a timed mute lapses on its own', () {
    test('muted until T is muted before T and not after it, with no event in between', () {
      fakeAsync((async) {
        final cubit = start(async);
        final until = clock.now().add(const Duration(hours: 1));
        chatSettings.add({42: muted(until: until)});

        expect(cubit.state.isChatMuted(42), isTrue);

        async.elapse(const Duration(minutes: 59));
        expect(cubit.state.isChatMuted(42), isTrue);

        async.elapse(const Duration(minutes: 1));
        expect(cubit.state.isChatMuted(42), isFalse);
        // The stored value is still what the core last said; only the answer changed.
        expect(cubit.state.chatMute(42), NotificationMute(muted: true, mutedUntil: until));

        cubit.close();
      });
    });

    test('a mute forever never arms a timer', () {
      fakeAsync((async) {
        final cubit = start(async);
        chatSettings.add({42: muted()});

        expect(async.pendingTimers, isEmpty);
        async.elapse(const Duration(days: 365));
        expect(cubit.state.isChatMuted(42), isTrue);

        cubit.close();
      });
    });

    test('two timed mutes share one timer, aimed at the nearer expiry', () {
      fakeAsync((async) {
        final cubit = start(async);
        final now = clock.now();
        chatSettings.add({
          1: muted(until: now.add(const Duration(hours: 8))),
          2: muted(until: now.add(const Duration(hours: 1))),
        });
        smsSettings.add({7: muted(until: now.add(const Duration(days: 2)))});

        expect(async.pendingTimers, hasLength(1));
        expect(cubit.state.mutedChatIds, {1, 2});
        expect(cubit.state.mutedSmsConversationIds, {7});

        async.elapse(const Duration(hours: 1));
        expect(cubit.state.mutedChatIds, {1});
        expect(async.pendingTimers, hasLength(1));

        async.elapse(const Duration(hours: 7));
        expect(cubit.state.mutedChatIds, isEmpty);
        expect(cubit.state.mutedSmsConversationIds, {7});

        async.elapse(const Duration(days: 2));
        expect(cubit.state.mutedSmsConversationIds, isEmpty);
        expect(async.pendingTimers, isEmpty);

        cubit.close();
      });
    });

    test('lifting a mute early re-arms the timer rather than leaving it aimed at the old moment', () {
      fakeAsync((async) {
        final cubit = start(async);
        final now = clock.now();
        chatSettings.add({42: muted(until: now.add(const Duration(hours: 1)))});
        expect(async.pendingTimers, hasLength(1));

        chatSettings.add({42: ConversationUserSettings.none});

        expect(cubit.state.isChatMuted(42), isFalse);
        expect(async.pendingTimers, isEmpty);

        cubit.close();
      });
    });
  });

  // The web runtime hands a timer's milliseconds to setTimeout, which reads
  // anything past 2^31-1 as zero: a month-long mute would fire at once and
  // spin. The timer is capped and re-armed instead.
  test('a far-off expiry arms a timer of at most a day, and re-arms from there', () {
    fakeAsync((async) {
      final cubit = start(async);
      final now = clock.now();
      chatSettings.add({42: muted(until: now.add(const Duration(days: 30)))});

      expect(async.pendingTimers, hasLength(1));
      expect(async.pendingTimers.single.duration, lessThanOrEqualTo(const Duration(days: 1)));

      async.elapse(const Duration(days: 29, hours: 23));
      expect(cubit.state.isChatMuted(42), isTrue);
      expect(async.pendingTimers, hasLength(1));

      async.elapse(const Duration(hours: 2));
      expect(cubit.state.isChatMuted(42), isFalse);

      cubit.close();
    });
  });

  // A timer sleeps with the app. A mute that lapsed while the app was in the
  // background is still shown as a mute on the first frame after the resume
  // unless the resume itself re-reads the clock.
  test('coming back to the foreground re-reads the clock', () {
    fakeAsync((async) {
      final cubit = start(async);
      final now = clock.now();
      chatSettings.add({42: muted(until: now.add(const Duration(minutes: 5)))});

      // The timer never fires: the fake clock is moved without running timers,
      // which is what suspension looks like to a Dart timer.
      async.elapseBlocking(const Duration(minutes: 10));
      expect(cubit.state.isChatMuted(42), isTrue);

      cubit.didChangeAppLifecycleState(AppLifecycleState.resumed);

      expect(cubit.state.isChatMuted(42), isFalse);

      cubit.close();
    });
  });

  // A pending timer outlives the cubit in a widget test and fails it, and in
  // the app it would fire into a closed cubit.
  test('closing leaves no timer behind', () {
    fakeAsync((async) {
      final cubit = start(async);
      chatSettings.add({42: muted(until: clock.now().add(const Duration(hours: 1)))});
      expect(async.pendingTimers, hasLength(1));

      cubit.close();
      async.flushMicrotasks();

      expect(async.pendingTimers, isEmpty);
    });
  });
}
