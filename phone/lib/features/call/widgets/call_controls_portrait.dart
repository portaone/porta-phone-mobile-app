import 'package:flutter/material.dart';

import 'call_action_area.dart';
import 'call_controls.dart';
import 'call_info_block.dart';
import 'call_remote_avatar.dart';

/// The portrait arrangement of the call screen body: the info block on top,
/// the avatar flexing into the leftover height, the action area at the bottom.
///
/// It only places the shared pieces ([CallInfoBlock], [CallActionArea]) - what
/// each control does arrives in [params] as callbacks, and the toolbar belongs
/// to [CallControls], which picks this layout or the landscape one by
/// orientation.
class CallControlsPortrait extends StatelessWidget {
  const CallControlsPortrait({super.key, required this.params});

  final CallControlsParams params;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: _buildBody);
  }

  Widget _buildBody(BuildContext context, BoxConstraints constraints) {
    final mediaQueryData = MediaQuery.of(context);

    // Portrait has the room: controls render at natural size and the
    // avatar flexes into what is left.
    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // A room can hold more than the screen does - several participants
          // and a call waiting outside - so while one stands the block takes
          // all the height the action area leaves and scrolls within it
          // instead of pushing the controls off the screen. Only one child of
          // this column can be the flexible one, and with a room it is this:
          // the avatar below is the other, and it has nobody to show anyway.
          _Flexed(
            flexed: params.conference.isPresent,
            child: CallInfoBlock(
              activeCalls: params.activeCalls,
              focusedCall: params.focusedCall,
              onCallSelected: params.onCallSelected,
              mergeSupported: params.callConfig.isConferenceEnabled,
              onMergePressed: params.onMerge,
              conference: params.conference,
              onSelfMutedChanged: params.onConferenceSelfMuted,
              onParticipantMutedChanged: params.onConferenceParticipantMuted,
              onParticipantHangup: params.onConferenceParticipantHangup,
              onConferenceEndPressed: params.onConferenceEnd,
              onAddPressed: params.onConferenceAdd,
            ),
          ),
          // Nothing to render in the video area (audio-only call,
          // remote camera off, or a held call): the remote party's
          // avatar takes its place, between the info block and the
          // action area. The avatar takes only the height LEFT OVER
          // by the info block and the action area and scales itself
          // down into it - so growing content (e.g. the open in-call
          // keypad) shrinks the avatar, never the controls.
          if (!params.conference.isPresent && !params.remotePictureShown && !params.keypadShown)
            Flexible(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  // The focused call, not the derived current one: the
                  // roster and the actions act on the focused call, and
                  // the picture must show the same person.
                  child: CallRemoteAvatar(
                    activeCall: params.focusedCall,
                    radius: CallRemoteAvatar.preferredRadius(mediaQueryData),
                    contactResolver: params.contactResolver,
                  ),
                ),
              ),
            ),
          CallActionArea(params: params),
        ],
      ),
    );
  }
}

/// Puts [child] in the column's flexible slot, scrolling within it, or leaves
/// it at its natural size.
///
/// Two flexible children would divide the free space between them by their
/// flex factors rather than one taking what it needs and the other the rest,
/// so the column has exactly one at a time.
class _Flexed extends StatelessWidget {
  const _Flexed({required this.flexed, required this.child});

  final bool flexed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!flexed) return child;
    return Flexible(child: SingleChildScrollView(child: child));
  }
}
