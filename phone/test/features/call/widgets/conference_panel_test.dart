import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:signaling/signaling.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

ActiveCall _call(String callId, {int line = 0, String? displayName}) => ActiveCall(
  callId: callId,
  direction: CallDirection.incoming,
  line: line,
  handle: const CallkeepHandle.number('+380991234567'),
  createdTime: DateTime(2024),
  video: false,
  processingStatus: CallProcessingStatus.connected,
  acceptedTime: DateTime.now().subtract(const Duration(seconds: 65)),
  displayName: displayName,
);

/// A room of two, both wired by the server unless [participants] says
/// otherwise.
ConferenceState _room({
  List<ConferenceParticipant> participants = const [
    ConferenceParticipant(line: 0, callId: 'a'),
    ConferenceParticipant(line: 1, callId: 'b'),
  ],
}) => ConferenceState(room: 7, phase: ConferencePhase.active, legs: const {'a': 0, 'b': 1}, participants: participants);

Widget _maybeScroll(bool scrollable, Widget child) => scrollable ? SingleChildScrollView(child: child) : child;

void main() {
  late List<({String callId, bool muted})> participantMutes;
  late List<String> hangups;
  late List<String> switched;

  setUp(() {
    participantMutes = [];
    hangups = [];
    switched = [];
  });

  Widget subject({
    ConferenceState? conference,
    List<ActiveCall>? calls,
    bool scrollable = false,
    bool roomParked = false,
  }) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      // The screen gives the block a scrollable slot of its own, so only the
      // row's own width is in question here.
      body: _maybeScroll(
        scrollable,
        ConferencePanel(
          conference: conference ?? _room(),
          calls: calls ?? [_call('a', displayName: 'Anna Marchenko'), _call('b', line: 1, displayName: 'Boris Klein')],
          roomParked: roomParked,
          onSwitchToConference: switched.add,
          onParticipantMutedChanged: (callId, muted) => participantMutes.add((callId: callId, muted: muted)),
          onParticipantHangup: hangups.add,
        ),
      ),
    ),
  );

  group('ConferencePanel', () {
    testWidgets('lists every leg, by line, and no row of the host', (tester) async {
      // The screen around the list is the host's, and his microphone is the
      // screen's own mute: a row of his only repeated the two.
      await tester.pumpWidget(subject());
      final context = tester.element(find.byType(ConferencePanel));

      expect(find.text(context.l10n.call_ConferencePanel_you), findsNothing);
      expect(find.bySemanticsIdentifier(conferenceSelfMuteId), findsNothing);
      expect(find.text('Anna Marchenko'), findsOneWidget);
      expect(find.text('Boris Klein'), findsOneWidget);
      expect(find.text(context.l10n.call_ConferencePanel_header(2).toUpperCase()), findsOneWidget);

      // Ordered by line, whatever order the legs were recorded in.
      final names = tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).toList();
      expect(names.indexOf('Anna Marchenko'), lessThan(names.indexOf('Boris Klein')));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a participant's controls step back while the room is not in use, and still work", (tester) async {
      // Dimmed rather than disabled on purpose: a room-wide mute and a hangup
      // still reach the room while the host is on another call, so taking them
      // away would cost a real capability to tidy the screen.
      await tester.pumpWidget(subject(roomParked: true));
      final dimmed = tester.widgetList<Opacity>(find.byType(Opacity)).map((o) => o.opacity).toSet();

      expect(dimmed.contains(1.0), isFalse, reason: 'every participant control is stepped back');

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 0)));
      await tester.pump();
      expect(participantMutes, [(callId: 'a', muted: true)], reason: 'and it still acts');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('no row of the room carries the frame', (tester) async {
      // The frame marks the conversation in use among several; the room's
      // participants are one conversation, and while the room stands aside the
      // frame belongs to the call outside it.
      for (final parked in [false, true]) {
        await tester.pumpWidget(subject(roomParked: parked));
        final frames = tester.widgetList<CallRowFrame>(find.byType(CallRowFrame));
        expect(frames.any((frame) => frame.focused), isFalse, reason: 'parked: $parked');
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('any row of the room is the way back into it', (tester) async {
      // The room's rows used to do nothing at all, so the only way back from a
      // call outside it was pressing Hold on that call.
      await tester.pumpWidget(subject(roomParked: true));

      await tester.tap(find.text('Anna Marchenko'));
      await tester.pump();
      expect(switched, ['a'], reason: 'a leg row names its own leg');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('says the host is elsewhere while the room stands aside', (tester) async {
      // The room neither hears him nor is heard (CallState.conferenceMustPark);
      // a list that said nothing would read as a conference that had quietly died.
      await tester.pumpWidget(subject());
      final context = tester.element(find.byType(ConferencePanel));
      expect(find.text(context.l10n.call_ConferencePanel_parkedNote), findsNothing);
      expect(find.bySemanticsIdentifier(conferenceParkedNoteId), findsNothing);

      await tester.pumpWidget(subject(roomParked: true));
      expect(find.text(context.l10n.call_ConferencePanel_parkedNote), findsOneWidget);
      expect(
        find.bySemanticsIdentifier(conferenceParkedNoteId),
        findsOneWidget,
        reason: 'automation tells a room standing aside from one in use without reading the words',
      );
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('every row leads with a picture', (tester) async {
      // The panel and the roster are the same kind of list, so a leg says who
      // it is with the same way a call outside the room does.
      await tester.pumpWidget(subject());

      expect(find.byType(CallRowAvatar), findsNWidgets(2), reason: 'one per leg');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a participant's menu opens under its trigger, so a second tap does not end the call", (tester) async {
      await tester.pumpWidget(subject());
      final trigger = find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1));
      await tester.tap(trigger);
      await tester.pumpAndSettle();

      final end = find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1));
      expect(tester.getRect(end).top, greaterThanOrEqualTo(tester.getRect(trigger).bottom));
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets("a participant's menu closes when their row goes", (tester) async {
      // Boris leaves the room with his menu open: End would act on a call that
      // is gone.
      await tester.pumpWidget(subject());
      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1)));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)), findsOneWidget);

      await tester.pumpWidget(
        subject(
          conference: ConferenceState(
            room: 7,
            phase: ConferencePhase.active,
            legs: const {'a': 0},
            participants: const [ConferenceParticipant(line: 0, callId: 'a')],
          ),
          calls: [_call('a', displayName: 'Anna Marchenko')],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)), findsNothing);
      expect(hangups, isEmpty);
      await tester.pumpWidget(const SizedBox());
    });

    group('cameras of the room', () {
      // What the platform was asked of the renderers, in order.
      late List<String> rendererCalls;
      late int textures;
      const webrtc = MethodChannel('FlutterWebRTC.Method');

      TestDefaultBinaryMessenger messenger() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

      /// The renderer of [textureId] drew its first frame.
      Future<void> firstFrame(WidgetTester tester, int textureId) async {
        await messenger().handlePlatformMessage(
          'FlutterWebRTC/Texture$textureId',
          const StandardMethodCodec().encodeSuccessEnvelope({'event': 'didFirstFrameRendered', 'id': textureId}),
          (_) {},
        );
        await tester.pump();
      }

      /// Lets a renderer's release reach the platform: it waits on its event
      /// channel first.
      Future<void> releases(WidgetTester tester) async {
        for (var turn = 0; turn < 10; turn++) {
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump();
        }
      }

      double cameraOpacity(WidgetTester tester) => tester
          .widget<Opacity>(find.ancestor(of: find.byType(RTCVideoView), matching: find.byType(Opacity)).first)
          .opacity;

      setUp(() {
        rendererCalls = [];
        textures = 0;
        // The plugin's own event stream, which the renderers' calls start.
        messenger().setMockMethodCallHandler(const MethodChannel('FlutterWebRTC.Event'), (_) async => null);
        messenger().setMockMethodCallHandler(webrtc, (call) async {
          rendererCalls.add(call.method);
          if (call.method != 'createVideoRenderer') return null;
          final textureId = ++textures;
          // The renderer listens to its texture's events.
          messenger().setMockMethodCallHandler(MethodChannel('FlutterWebRTC/Texture$textureId'), (_) async => null);
          return {'textureId': textureId};
        });
      });

      tearDown(() {
        messenger().setMockMethodCallHandler(webrtc, null);
        messenger().setMockMethodCallHandler(const MethodChannel('FlutterWebRTC.Event'), null);
      });

      // The room's feeds are keyed by line + 2: Anna (line 0) is 2, Boris 3.
      ConferenceState roomWith(Map<int, ParticipantCamera> feeds) => _room().copyWith(videoFeeds: feeds);

      testWidgets('the picture stands until the camera has drawn a frame, then the camera shows', (tester) async {
        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));
        await tester.pump();

        expect(find.byType(CallRowAvatar), findsNWidgets(2), reason: 'both pictures, Boris\'s under his camera');
        expect(cameraOpacity(tester), 0, reason: 'no frame yet: not an empty circle');
        expect(find.bySemanticsIdentifier(numberedId(conferenceParticipantCameraId, 1)), findsNothing);

        await firstFrame(tester, 1);

        expect(cameraOpacity(tester), 1);
        expect(find.bySemanticsIdentifier(numberedId(conferenceParticipantCameraId, 1)), findsOneWidget);
        expect(find.bySemanticsIdentifier(conferenceParticipantCameraId), findsNothing, reason: 'Anna has none');
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a camera that comes or goes does not move the rows', (tester) async {
        Rect row(String callId) => tester.getRect(find.byKey(ValueKey('ConferenceParticipant-$callId')));
        await tester.pumpWidget(subject());
        final before = (a: row('a'), b: row('b'), name: tester.getTopLeft(find.text('Boris Klein')));

        // The first camera of the room arrives, and draws.
        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));
        await tester.pump();
        await firstFrame(tester, 1);

        expect(row('a'), before.a);
        expect(row('b'), before.b);
        expect(tester.getTopLeft(find.text('Boris Klein')), before.name);

        // And goes: the room's last.
        await tester.pumpWidget(subject());
        await tester.pump();

        expect(row('a'), before.a);
        expect(row('b'), before.b);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('the camera is round and of the picture\'s size', (tester) async {
        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));
        await tester.pump();
        await firstFrame(tester, 1);

        final avatars = find.byType(CallRowAvatar);
        expect(tester.getSize(find.byType(RTCVideoView)), tester.getSize(avatars.first));
        expect(find.ancestor(of: find.byType(RTCVideoView), matching: find.byType(ClipOval)), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a rebuild with the same camera asks nothing more of its renderer', (tester) async {
        final conference = roomWith({3: _camera('boris')});
        // The same camera object on every rebuild.
        await tester.pumpWidget(subject(conference: conference));
        await tester.pump();
        final asked = rendererCalls.length;

        await tester.pumpWidget(subject(conference: conference, roomParked: true));
        await tester.pumpWidget(subject(conference: conference));
        await tester.pump();

        expect(rendererCalls, hasLength(asked));
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a camera that goes gives the picture back and releases its renderer', (tester) async {
        final anna = _camera('anna');
        await tester.pumpWidget(subject(conference: roomWith({2: anna, 3: _camera('boris')})));
        await tester.pump();
        expect(find.byType(RTCVideoView), findsNWidgets(2));

        await tester.pumpWidget(subject(conference: roomWith({2: anna})));
        await tester.pump();

        expect(find.byType(RTCVideoView), findsOneWidget);
        expect(find.byType(CallRowAvatar), findsNWidgets(2));
        await releases(tester);
        expect(rendererCalls.where((method) => method == 'videoRendererDispose'), hasLength(1));
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a row that goes while its renderer is being made releases it, with no stream', (tester) async {
        final made = Completer<void>();
        messenger().setMockMethodCallHandler(webrtc, (call) async {
          rendererCalls.add(call.method);
          if (call.method != 'createVideoRenderer') return null;
          await made.future;
          messenger().setMockMethodCallHandler(const MethodChannel('FlutterWebRTC/Texture1'), (_) async => null);
          return {'textureId': 1};
        });
        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));

        await tester.pumpWidget(const SizedBox());
        made.complete();
        await releases(tester);

        expect(rendererCalls, isNot(contains('videoRendererSetSrcObject')));
        expect(rendererCalls, contains('videoRendererDispose'));
      });

      testWidgets("each row shows its participant's own track, though the streams share an id", (tester) async {
        final shown = <String>[];
        final calls = <MethodCall>[];
        messenger().setMockMethodCallHandler(webrtc, (call) async {
          calls.add(call);
          if (call.method != 'createVideoRenderer') return null;
          final textureId = ++textures;
          messenger().setMockMethodCallHandler(MethodChannel('FlutterWebRTC/Texture$textureId'), (_) async => null);
          return {'textureId': textureId};
        });
        await tester.pumpWidget(subject(conference: roomWith({2: _camera('anna'), 3: _camera('boris')})));
        await tester.pump();
        await tester.pump();
        for (final call in calls.where((call) => call.method == 'videoRendererSetSrcObject')) {
          shown.add((call.arguments as Map)['trackId'] as String);
        }

        expect(shown..sort(), ['anna-video', 'boris-video']);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a new stream for the same participant waits for its own first frame', (tester) async {
        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));
        await tester.pump();
        await firstFrame(tester, 1);
        expect(cameraOpacity(tester), 1);

        // The subscription is made again: a new connection, the same track id.
        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris', connection: 'subscriber-2')})));
        await tester.pump();

        expect(cameraOpacity(tester), 0, reason: 'the avatar until the new stream draws');
        expect(find.bySemanticsIdentifier(numberedId(conferenceParticipantCameraId, 1)), findsNothing);
        await firstFrame(tester, 1);
        expect(cameraOpacity(tester), 1);
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a renegotiation hands the same camera over in a new stream, and it stays seen', (tester) async {
        // The platform reports a first frame only for a new track: waiting for
        // one here would leave the avatar for good.
        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));
        await tester.pump();
        await firstFrame(tester, 1);
        final asked = rendererCalls.length;

        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));
        await tester.pump();

        expect(cameraOpacity(tester), 1);
        expect(rendererCalls.skip(asked), ['videoRendererSetSrcObject'], reason: 'handed over again, not waited for');
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('the picture under a camera is not made again when the camera comes or goes', (tester) async {
        await tester.pumpWidget(subject());
        final before = tester.state(find.byType(CallRemoteAvatar).last);

        await tester.pumpWidget(subject(conference: roomWith({3: _camera('boris')})));
        await tester.pump();
        await tester.pumpWidget(subject());
        await tester.pump();

        expect(tester.state(find.byType(CallRemoteAvatar).last), same(before));
        await tester.pumpWidget(const SizedBox());
      });

      testWidgets('a room without cameras asks nothing of the platform', (tester) async {
        await tester.pumpWidget(subject());

        expect(find.byType(RTCVideoView), findsNothing);
        expect(rendererCalls, isEmpty);
        await tester.pumpWidget(const SizedBox());
      });
    });

    testWidgets('a leg falls back to its number, and to its id before the call is known', (tester) async {
      await tester.pumpWidget(subject(calls: [_call('a')]));

      expect(find.text('+380991234567'), findsOneWidget);
      expect(find.text('b'), findsOneWidget, reason: 'the call is gone but the server still lists the leg');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a participant is muted for everyone, and said to be', (tester) async {
      await tester.pumpWidget(
        subject(
          conference: _room(
            participants: const [
              ConferenceParticipant(line: 0, callId: 'a'),
              ConferenceParticipant(line: 1, callId: 'b', muted: true),
            ],
          ),
        ),
      );
      final context = tester.element(find.byType(ConferencePanel));

      // The status line carries the duration beside it now.
      expect(find.textContaining(context.l10n.call_ConferencePanel_participantMuted), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 0)));
      expect(participantMutes, [(callId: 'a', muted: true)]);

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)));
      expect(participantMutes.last, (callId: 'b', muted: false), reason: 'a muted one is unmuted');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a leg the server has not listed cannot be muted yet', (tester) async {
      // Core answers line_not_ready until the participant appears in a list,
      // so the control waits rather than asking and failing.
      await tester.pumpWidget(
        subject(
          conference: _room(participants: const [ConferenceParticipant(line: 0, callId: 'a')]),
        ),
      );

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 1)));
      expect(participantMutes, isEmpty);

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMuteId, 0)));
      expect(participantMutes, hasLength(1), reason: 'the listed one is ready');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a participant is dropped by ending their call', (tester) async {
      await tester.pumpWidget(subject());

      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantMenuId, 1)));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier(numberedId(conferenceParticipantHangupId, 1)));
      await tester.pumpAndSettle();
      expect(hangups, ['b']);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a long call does not push the controls off a narrow row', (tester) async {
      // Past an hour the duration grows to HH:MM:SS; beside two tap targets
      // on a small screen at a large text scale there was nowhere to put it.
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: subject(
            scrollable: true,
            calls: [
              _call(
                'a',
                displayName: 'Oleksandr Marchenko',
              ).copyWith(acceptedTime: DateTime.now().subtract(const Duration(hours: 2, minutes: 5))),
              _call('b', line: 1, displayName: 'Kateryna Bondarenko'),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });
}

/// A participant's camera as the room sends it: a stream of the id every
/// track of the subscription shares, and its own track.
ParticipantCamera _camera(String name, {String connection = 'subscriber-1'}) =>
    ParticipantCamera(stream: _Stream(connection), trackId: '$name-video');

class _Stream extends Fake implements MediaStream {
  _Stream(this.ownerTag);

  @override
  String get id => 'janus';

  /// The connection the stream arrived on.
  @override
  final String ownerTag;

  @override
  List<MediaStreamTrack> getVideoTracks() => const [];
}
