import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

Widget _buildSubject({
  required CallStatus callStatus,
  CallNetworkQuality? networkQuality,
  IceConnectionIssue? iceConnectionIssue,
  bool voiceNoiseReductionFailed = false,
}) {
  return MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: CallToolbarStatus(
        callStatus: callStatus,
        networkQuality: networkQuality,
        iceConnectionIssue: iceConnectionIssue,
        voiceNoiseReductionFailed: voiceNoiseReductionFailed,
      ),
    ),
  );
}

const _quality = CallNetworkQuality(
  severity: CallNetworkQualitySeverity.severe,
  uplink: true,
  media: CallMediaKind.audio,
);

void main() {
  group('CallToolbarStatus', () {
    testWidgets('says so when the noise reduction did not start', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready, voiceNoiseReductionFailed: true));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.call_ToolbarStatus_noiseReductionOff), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('a connection problem takes the line from the noise reduction', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.connectivityNone, voiceNoiseReductionFailed: true));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.callStatus_connectivityNone), findsOneWidget);
      expect(find.text(context.l10n.call_ToolbarStatus_noiseReductionOff), findsNothing);
    });

    testWidgets('a media failure takes the line from the noise reduction', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          callStatus: CallStatus.ready,
          iceConnectionIssue: IceConnectionIssue.iceFail,
          voiceNoiseReductionFailed: true,
        ),
      );
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.iceConnectionIssue_iceFail), findsOneWidget);
      expect(find.text(context.l10n.call_ToolbarStatus_noiseReductionOff), findsNothing);
    });

    testWidgets('weak network quality takes the line from the noise reduction', (tester) async {
      await tester.pumpWidget(
        _buildSubject(callStatus: CallStatus.ready, networkQuality: _quality, voiceNoiseReductionFailed: true),
      );
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.callNetworkQuality_yourAudioWeak), findsOneWidget);
      expect(find.text(context.l10n.call_ToolbarStatus_noiseReductionOff), findsNothing);
    });

    testWidgets('a media failure is found by the quality status identifier', (tester) async {
      await tester.pumpWidget(
        _buildSubject(callStatus: CallStatus.ready, iceConnectionIssue: IceConnectionIssue.iceFail),
      );
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(
        find.descendant(
          of: find.bySemanticsIdentifier(callScreenQualityStatusId),
          matching: find.text(context.l10n.iceConnectionIssue_iceFail),
        ),
        findsOneWidget,
      );
    });

    testWidgets('weak or recovered media is found by the quality status identifier', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready, networkQuality: _quality));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(
        find.descendant(
          of: find.bySemanticsIdentifier(callScreenQualityStatusId),
          matching: find.text(context.l10n.callNetworkQuality_yourAudioWeak),
        ),
        findsOneWidget,
      );
    });

    testWidgets('one quality status identifier while a media failure gives way to weak media', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildSubject(callStatus: CallStatus.ready, iceConnectionIssue: IceConnectionIssue.iceFail),
      );
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready, networkQuality: _quality));
      await tester.pump(const Duration(milliseconds: 100));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.iceConnectionIssue_iceFail), findsOneWidget, reason: 'still fading out');
      // What a phone's accessibility tree holds, not what the widgets carry.
      final nodes = find.semantics.byPredicate((node) => node.identifier == callScreenQualityStatusId).evaluate();
      expect(nodes, hasLength(1));
      expect(
        nodes.single.getSemanticsData().label + nodes.single.getSemanticsData().value,
        contains(context.l10n.callNetworkQuality_yourAudioWeak),
      );
      semantics.dispose();
    });

    testWidgets('a connection state and a healthy call carry no quality status identifier', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.connectivityNone));
      expect(find.bySemanticsIdentifier(callScreenQualityStatusId), findsNothing);

      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready));
      await tester.pumpAndSettle();
      expect(find.bySemanticsIdentifier(callScreenQualityStatusId), findsNothing);
    });

    testWidgets('renders nothing while everything is healthy', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready));
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('no internet: hard state with its own message only', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.connectivityNone));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.callStatus_connectivityNone), findsOneWidget);
      expect(find.text(context.l10n.call_ToolbarStatus_reconnecting), findsNothing);
      expect(find.text(context.l10n.call_ToolbarStatus_connecting), findsNothing);
    });

    testWidgets('unregistered: hard state with its own message', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.appUnregistered));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.callStatus_appUnregistered), findsOneWidget);
    });

    testWidgets('first connection shows Connecting', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.inProgress));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.call_ToolbarStatus_connecting), findsOneWidget);
      expect(find.text(context.l10n.call_ToolbarStatus_reconnecting), findsNothing);
    });

    testWidgets('a drop after being connected shows Reconnecting (debounced)', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready));
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.connectError));
      // Transient statuses are debounced to avoid reconnect-backoff flicker.
      await tester.pump(kSignalingStatusDebounce + const Duration(milliseconds: 50));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.call_ToolbarStatus_reconnecting), findsOneWidget);
      expect(find.text(context.l10n.call_ToolbarStatus_connecting), findsNothing);
      // Stop the pulsing dot animation cleanly.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('network quality: bars + arrow + always-visible label, no media glyph', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready, networkQuality: _quality));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.byType(CallNetworkQualityMeter), findsOneWidget);
      // The toolbar renders the label itself; the meter label is suppressed,
      // so the text appears exactly once even at severe.
      expect(find.text(context.l10n.callNetworkQuality_yourAudioWeak), findsOneWidget);
      // Direction arrow stays, the mic/camera glyph does not (the label
      // already says audio/video).
      expect(find.byIcon(Icons.north), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('quality label is visible below severe too', (tester) async {
      const mild = CallNetworkQuality(
        severity: CallNetworkQualitySeverity.mild,
        uplink: false,
        media: CallMediaKind.audio,
      );
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.ready, networkQuality: mild));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.callNetworkQuality_theirAudioWeak), findsOneWidget);
    });

    testWidgets('connectivity trouble wins over network quality', (tester) async {
      await tester.pumpWidget(_buildSubject(callStatus: CallStatus.connectivityNone, networkQuality: _quality));
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.callStatus_connectivityNone), findsOneWidget);
      expect(find.byType(CallNetworkQualityMeter), findsNothing);
    });

    testWidgets('a media failure wins over network quality', (tester) async {
      await tester.pumpWidget(
        _buildSubject(
          callStatus: CallStatus.ready,
          networkQuality: _quality,
          iceConnectionIssue: IceConnectionIssue.iceFail,
        ),
      );
      final context = tester.element(find.byType(CallToolbarStatus));

      expect(find.text(context.l10n.iceConnectionIssue_iceFail), findsOneWidget);
      expect(find.byType(CallNetworkQualityMeter), findsNothing);
    });
  });
}
