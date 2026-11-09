import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/keypad/keypad.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';

/// The calls with one number on a watch - the device's own log of them or
/// the account's history: who, the number under the name when the name is a
/// contact's, a row per call, a video call after them when video is on, and
/// the call along the bottom of the face, as the keypad has it.
///
/// No avatar and no copy of the number: a face has room for the calls.
/// While the calls are on their way the list is a spinner and the call is
/// already there, as on the phone; with no calls the list says so.
class CallLogWatchPage extends StatelessWidget {
  const CallLogWatchPage({
    super.key,
    required this.title,
    required this.number,
    required this.loading,
    required this.itemCount,
    required this.itemBuilder,
    required this.onCall,
    this.onVideoCall,
    this.controller,
  });

  /// The contact's name, or the number when it is nobody's.
  final String title;

  final String number;

  /// Whether the calls are still on their way.
  final bool loading;

  /// How many rows [itemBuilder] builds.
  final int itemCount;

  /// Builds the row at an index, a [CallLogWatchRow] or what the list ends with.
  final IndexedWidgetBuilder itemBuilder;

  final VoidCallback onCall;

  /// Null when video calls are off.
  final VoidCallback? onVideoCall;

  /// The list's scroll controller, for a history that loads more as it scrolls.
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final onVideoCall = this.onVideoCall;
    // With nothing to list the page says so in the list's place, so a number
    // with no calls left is not a blank face above the call.
    final empty = !loading && itemCount == 0;
    final rows = loading || empty ? 1 : itemCount;

    return WatchScrollList.builder(
      title: title,
      header: [
        if (number != title)
          Text(
            number,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: themeData.textTheme.labelSmall?.copyWith(color: themeData.colorScheme.onSurfaceVariant),
          ),
      ],
      controller: controller,
      // The video call closes the list, where the design puts what the page
      // offers besides the call: under the name it pushed the calls off a
      // small face.
      itemCount: rows + (onVideoCall != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == rows) {
          return Padding(
            padding: EdgeInsets.only(top: context.adaptiveMetrics.gap),
            child: WatchPillButton(
              buttonKey: callLogWatchVideoCallKey,
              identifier: callLogWatchVideoCallId,
              icon: Icons.videocam,
              label: context.l10n.numberActions_videoCall,
              semanticsLabel: context.l10n.numberActions_videoCall,
              onPressed: onVideoCall,
            ),
          );
        }
        if (loading) return Center(child: WatchSpinner(label: context.l10n.common_SemanticsLabel_loading));
        if (empty) return WatchListNote(context.l10n.cdrs_noRecentCalls_message);
        return itemBuilder(context, index);
      },
      edge: (context, overlay) => WatchCallEdgeButton(
        overlay: overlay,
        buttonKey: callLogWatchCallKey,
        identifier: callLogWatchCallId,
        label: context.l10n.numberActions_audioCall,
        onPressed: onCall,
      ),
    );
  }
}

/// One call with the number on a watch: the direction's arrow, its status -
/// how long it took or that it was missed - and when; read out as one line. Nothing to
/// tap - deleting a call stays on the phone.
class CallLogWatchRow extends StatelessWidget {
  const CallLogWatchRow({
    super.key,
    required this.direction,
    required this.complete,
    required this.missed,
    required this.status,
    required this.time,
    this.video = false,
  });

  final CallDirection direction;

  /// Whether the call was answered.
  final bool complete;

  /// Whether it is a call nobody answered: red.
  final bool missed;

  /// How long it took, or that nobody answered - each page decides, as its
  /// phone row does.
  final String status;

  /// When, as the recents list writes it.
  final String time;

  final bool video;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final l10n = context.l10n;
    final way = direction == CallDirection.incoming ? l10n.call_CallList_incoming : l10n.call_CallList_outgoing;
    final color = missed ? colorScheme.error : colorScheme.onSurfaceVariant;

    return Semantics(
      container: true,
      label: video ? '$way, ${l10n.numberActions_videoCall}, $status, $time' : '$way, $status, $time',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            spacing: 4,
            children: [
              Icon(direction.icon(complete), size: 14, color: color),
              if (video) Icon(Icons.videocam, size: 14, color: colorScheme.onSurfaceVariant),
              Expanded(
                child: Text(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: themeData.textTheme.labelMedium?.copyWith(color: missed ? colorScheme.error : null),
                ),
              ),
              Text(
                time,
                maxLines: 1,
                style: themeData.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
