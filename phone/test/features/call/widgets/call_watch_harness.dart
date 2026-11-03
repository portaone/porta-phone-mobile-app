// The watch call face on its own, with the callbacks it fires recorded.
import 'package:material_ui/material_ui.dart';

import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'package:webtrit_phone/features/call/call.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../view/call_active_scaffold_harness.dart';

/// What the face sent to the screen, by callback.
class CallWatchSent {
  final events = <String>[];
  void add(String event) => events.add(event);
}

const watchSpeaker = CallAudioDevice(type: CallAudioDeviceType.speaker);
const watchEarpiece = CallAudioDevice(type: CallAudioDeviceType.earpiece);
const watchBuds = CallAudioDevice(type: CallAudioDeviceType.bluetooth, id: 'buds', name: 'Pixel Buds');

ActiveCall watchActiveCall({String callId = 'active', String name = 'Thomas Anderson', bool held = false}) =>
    makeCall(callId: callId, acceptedTime: DateTime.now(), held: held, displayName: name);

/// The face over [calls], as the screen hands it over; [wrap] puts it into
/// an app (the test's, or the shipped theme's). [background] stands for the
/// call screen's own.
Widget callWatchFace({
  required List<ActiveCall> calls,
  required CallWatchSent sent,
  ActiveCall? focused,
  List<CallAudioDevice> devices = const [watchSpeaker, watchEarpiece],
  CallAudioDevice? audioDevice = watchEarpiece,
  bool keypadShown = false,
  CallCapabilitiesConfig callConfig = const CallCapabilitiesConfig(),
  ConferenceState conference = const ConferenceState(),
  bool conferenceParked = false,
}) {
  final focusedCall = focused ?? calls.first;
  final state = CallState(linesCount: 3, activeCalls: calls, conference: conference);
  return CallControlsWatch(
    callStatus: CallStatus.ready,
    video: CallWatchVideoOptions(
      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      onFitToggled: () => sent.add('fit'),
      backgroundMode: VideoBackgroundMode.blur,
      onBackgroundToggled: () => sent.add('blur'),
    ),
    params: CallControlsParams(
      activeCalls: calls,
      focusedCall: focusedCall,
      availableAudioDevices: devices,
      audioDevice: audioDevice,
      callConfig: callConfig,
      interactionsEnabled: true,
      remotePictureShown: false,
      keypadShown: keypadShown,
      dtmfInput: ValueNotifier('205'),
      onCallSelected: (callId) => sent.add('select $callId'),
      onKeypadToggle: (shown) => sent.add('keypad $shown'),
      onCameraChanged: (on) => sent.add('camera $on'),
      onCameraPermissionDeniedPressed: () => sent.add('camera settings'),
      onMutedChanged: (muted) => sent.add('muted $muted'),
      onAudioDeviceChanged: (device) => sent.add('audio ${device.type.name}'),
      onBlindTransferInitiated: () => sent.add('blind'),
      onAttendedTransferInitiated: () => sent.add('attended'),
      onAttendedTransferSubmitted: (_, _) => sent.add('hand over'),
      onHeldChanged: (value) => sent.add('held $value'),
      onKeyPressed: (key) => sent.add('dtmf $key'),
      onHangup: () => sent.add('hangup'),
      onAccept: () => sent.add('accept'),
      onMerge: () => sent.add('merge'),
      conference: conference,
      conferenceParked: conferenceParked,
      onConversationSwitched: (callId) => sent.add('switch $callId'),
      handOver: state.handOverFor(focusedCall.callId),
      canStartAttendedTransfer: state.canLinkCallTo(
        focusedCall.callId,
        purpose: LinkedCallPurpose.attendedTransfer,
        isConferenceEnabled: callConfig.isConferenceEnabled,
      ),
      onConferenceSelfMuted: (muted) => sent.add('room muted $muted'),
      onConferenceParticipantMuted: (callId, muted) => sent.add('mute $callId $muted'),
      onConferenceParticipantHangup: (callId) => sent.add('drop $callId'),
    ),
  );
}

/// The face on the call screen's background, in a plain English app.
Widget callWatchApp(Widget face) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  debugShowCheckedModeBanner: false,
  home: CallWatchBackground(child: face),
);

/// The call screen's own background behind [child]: the theme's, as the
/// screen draws it.
class CallWatchBackground extends StatelessWidget {
  const CallWatchBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<CallScreenStyles>()?.primary;
    // Without the shipped theme there is no call background to draw; a plain
    // dark one stands in, which is all the fit tests need.
    if (style == null) return Scaffold(backgroundColor: Colors.blueGrey.shade700, body: child);
    return ThemedScaffold(background: style.background, body: child);
  }
}
