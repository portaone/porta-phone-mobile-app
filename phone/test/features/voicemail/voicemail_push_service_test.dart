import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/features/voicemail/voicemail.dart';
import 'package:webtrit_phone/push_notification/push_notifications.dart';
import 'package:webtrit_phone/repositories/repositories.dart';

class _RemotePush extends Mock implements RemotePushRepository {}

class _LocalPush extends Mock implements LocalPushRepository {}

void main() {
  setUpAll(() => registerFallbackValue(AppLocalPush(0, '', '')));

  group('AppRemotePush.fromFCM', () {
    test('reads the push Core sends for a new voicemail', () {
      final push = AppRemotePush.fromFCM(
        const RemoteMessage(
          messageId: 'm1',
          data: {'voicemail_id': 'abc', 'voicemail_type': 'voice'},
          notification: RemoteNotification(title: 'New voicemail', body: 'From 555014'),
        ),
      );

      expect(push, isA<VoicemailPush>());
      push as VoicemailPush;
      expect(push.voicemailId, 'abc');
      expect(push.voicemailType, 'voice');
      expect(push.title, 'New voicemail');
      expect(push.body, 'From 555014');
    });
  });

  group('VoicemailPushService', () {
    late StreamController<VoicemailPush> foreground;
    late StreamController<VoicemailPush> opened;
    late StreamController<AppLocalPushAction> actions;
    late _LocalPush localPush;
    late int refreshes;
    late int opens;
    late VoicemailPushService service;

    setUp(() {
      foreground = StreamController<VoicemailPush>();
      opened = StreamController<VoicemailPush>();
      actions = StreamController<AppLocalPushAction>();
      final remotePush = _RemotePush();
      localPush = _LocalPush();
      when(() => remotePush.voicemailForegroundPushs).thenAnswer((_) => foreground.stream);
      when(() => remotePush.voicemailOpenedPushs).thenAnswer((_) => opened.stream);
      when(() => localPush.voicemailActions).thenAnswer((_) => actions.stream);
      when(() => localPush.displayPush(any())).thenAnswer((_) async {});
      refreshes = 0;
      opens = 0;
      service = VoicemailPushService(
        remotePush,
        localPush,
        requestRefresh: () => refreshes++,
        openVoicemail: () => opens++,
      )..init();
    });

    tearDown(() => service.dispose());

    test('a push in the foreground is shown locally and asks for the mailbox', () async {
      foreground.add(VoicemailPush('m1', 'abc', title: 'New voicemail', body: 'From 555014'));
      await pumpEventQueue();

      final shown = verify(() => localPush.displayPush(captureAny())).captured.single as AppLocalPush;
      expect(shown.id, AppLocalPush.voicemailIdOf('abc'));
      expect(shown.id, isNegative);
      expect(shown.title, 'New voicemail');
      expect(shown.body, 'From 555014');
      expect(shown.payload?['source'], kLocalPushSourceVoicemail);
      expect(refreshes, 1);
      expect(opens, 0);
    });

    test('a push without text still asks for the mailbox but shows nothing', () async {
      foreground.add(VoicemailPush('m1', 'abc'));
      await pumpEventQueue();

      verifyNever(() => localPush.displayPush(any()));
      expect(refreshes, 1);
    });

    test('a push that opened the app asks for and opens the mailbox', () async {
      opened.add(VoicemailPush('m1', 'abc', title: 'New voicemail', body: 'From 555014'));
      await pumpEventQueue();

      verifyNever(() => localPush.displayPush(any()));
      expect(refreshes, 1);
      expect(opens, 1);
    });

    test('a tap on the local push opens the mailbox', () async {
      actions.add(AppLocalPushAction(id: 1, type: LocalPushActionType.tap, payload: const {}));
      await pumpEventQueue();

      expect(opens, 1);
    });
  });
}
