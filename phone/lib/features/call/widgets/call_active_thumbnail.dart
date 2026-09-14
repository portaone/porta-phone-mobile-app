import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../models/models.dart';
import '../utils/utils.dart';
import 'stream_thumbnail.dart';
import 'thumbnail_frame.dart';

class CallActiveThumbnail extends StatefulWidget {
  const CallActiveThumbnail({
    required this.activeCall,
    required this.orientation,
    super.key,
    this.contactResolver,
    this.onTap,
    this.smallerSide = ThumbnailLayout.defaultSmallerSide,
  });

  final ActiveCall activeCall;
  final Orientation orientation;
  final ContactResolver? contactResolver;
  final GestureTapCallback? onTap;
  final double smallerSide;

  @override
  State<CallActiveThumbnail> createState() => _CallActiveThumbnailState();
}

class _CallActiveThumbnailState extends State<CallActiveThumbnail> {
  /// Looks at the remote video and says whether it shows a picture; it
  /// follows the call handed to it in [didUpdateWidget].
  late final RemoteFrameProbe _remoteFrameProbe;

  @override
  void initState() {
    super.initState();
    _remoteFrameProbe = RemoteFrameProbe()
      ..stream = widget.activeCall.remoteStream
      ..addListener(_onRemoteFrameChanged)
      ..start();
  }

  @override
  void didUpdateWidget(CallActiveThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new stream forgets the picture of the old one, so nothing stale
    // flashes while the new one is probed.
    _remoteFrameProbe.stream = widget.activeCall.remoteStream;
  }

  @override
  void dispose() {
    _remoteFrameProbe.removeListener(_onRemoteFrameChanged);
    _remoteFrameProbe.dispose();
    super.dispose();
  }

  void _onRemoteFrameChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Hide video when held to avoid showing frozen/last frames, and also when the
    // frame analyser hasn't confirmed renderable content yet (black/empty guard).
    final displayStream = widget.activeCall.held == false && _remoteFrameProbe.renderable;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAccepted = widget.activeCall.wasAccepted;

    final duration = isAccepted ? const Duration(milliseconds: 2500) : const Duration(milliseconds: 1500);

    final baseAlpha = 0.75;
    final highlightAlpha = 0.95;

    final baseColor = isAccepted
        ? colorScheme.primary.withValues(alpha: baseAlpha)
        : colorScheme.surfaceContainerHighest.withValues(alpha: highlightAlpha);

    final highlightColor = isAccepted
        ? colorScheme.surface.withValues(alpha: baseAlpha)
        : colorScheme.surface.withValues(alpha: highlightAlpha);

    return ThumbnailFrame(
      orientation: widget.orientation,
      smallerSide: widget.smallerSide,
      onTap: widget.onTap,
      // It is the only way back into a call once the user has moved on, so it
      // says where it leads rather than what it shows.
      label: context.l10n.callThumbnail_SemanticsLabel_returnToCall,
      identifier: callActiveThumbnailId,
      raised: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Shimmer(duration: duration, baseColor: baseColor, highlightColor: highlightColor),
          if (displayStream)
            StreamThumbnail(stream: widget.activeCall.remoteStream)
          else
            _AvatarOverlay(
              activeCall: widget.activeCall,
              contactResolver: widget.contactResolver,
              smallerSide: widget.smallerSide,
            ),
        ],
      ),
    );
  }
}

class _AvatarOverlay extends StatelessWidget {
  const _AvatarOverlay({required this.activeCall, required this.smallerSide, this.contactResolver});

  static const double _padding = 8;

  final ActiveCall activeCall;
  final ContactResolver? contactResolver;

  /// Smaller side of the window the avatar sits in; it is what the avatar is sized
  /// from, so a window configured larger or smaller carries it along.
  final double smallerSide;

  /// Half of what the window leaves after its padding, and never less than nothing:
  /// a window narrower than the padding it carries would otherwise ask for a negative
  /// radius, which is not a size any box can take.
  double get _radius => math.max(0.0, smallerSide - _padding * 2) / 2;

  @override
  Widget build(BuildContext context) {
    // The window stretches whatever fills it to its own 9:16 shape. The avatar is a
    // circle of a fixed size, so it has to be let out of those constraints: taken
    // tight, it is drawn as an ellipse the shape of the window and the photo inside
    // it is cropped to match.
    return Padding(
      padding: const EdgeInsets.all(_padding),
      child: Center(
        child: FutureBuilder<Contact?>(
          future: contactResolver?.resolve(activeCall.handle.value),
          builder: (context, snapshot) => LeadingAvatar(
            radius: _radius,
            username: snapshot.data?.maybeName ?? activeCall.displayName ?? '',
            thumbnailUrl: snapshot.data?.thumbnailUrl,
            placeholderIcon: Icons.phone_in_talk_outlined,
          ),
        ),
      ),
    );
  }
}
