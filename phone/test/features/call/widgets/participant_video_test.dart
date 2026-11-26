import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/features/call/call.dart';

/// A participant's picture: the placeholder until the first frame, the picture alone after it - a
/// picture shown whole leaves the place around it open, and the placeholder must not show there.
void main() {
  const texture = 7;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('FlutterWebRTC.Method'),
      (call) async => call.method == 'createVideoRenderer' ? {'textureId': texture} : null,
    );
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('FlutterWebRTC.Method'), null);
    messenger.setMockStreamHandler(const EventChannel('FlutterWebRTC/Texture$texture'), null);
  });

  Widget subject({ValueChanged<double>? onAspectChanged}) => MaterialApp(
    home: SizedBox(
      width: 300,
      height: 400,
      child: ParticipantVideo(
        camera: ParticipantCamera(stream: _Stream(), trackId: 'screen'),
        placeholder: const Text('waiting'),
        fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
        onAspectChanged: onAspectChanged,
      ),
    ),
  );

  testWidgets('the placeholder shows until the first frame', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pump();

    expect(find.text('waiting'), findsOneWidget);
  });

  testWidgets('the placeholder goes once a frame is drawn', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('FlutterWebRTC/Texture$texture'),
      MockStreamHandler.inline(onListen: (arguments, events) => events.success({'event': 'didFirstFrameRendered'})),
    );

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('waiting'), findsNothing);
  });

  testWidgets('the proportions are told once a frame is drawn, and again when they change', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockStreamHandler(
      const EventChannel('FlutterWebRTC/Texture$texture'),
      MockStreamHandler.inline(
        onListen: (arguments, events) {
          events.success({'event': 'didTextureChangeVideoSize', 'width': 1280, 'height': 720});
          events.success({'event': 'didFirstFrameRendered'});
          events.success({'event': 'didTextureChangeVideoSize', 'width': 640, 'height': 360});
          events.success({'event': 'didTextureChangeRotation', 'rotation': 90});
        },
      ),
    );
    final told = <double>[];

    await tester.pumpWidget(subject(onAspectChanged: told.add));
    await tester.pumpAndSettle();

    expect(told, [1280 / 720, 360 / 640], reason: 'the same proportions at another size are no change');
  });
}

class _Stream extends Fake implements MediaStream {
  @override
  String get id => 'screen-stream';

  @override
  String get ownerTag => 'room';

  @override
  List<MediaStreamTrack> getVideoTracks() => const [];
}
