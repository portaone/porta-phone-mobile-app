import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

import '../bloc/call_log_bloc.dart';
import '../widgets/widgets.dart';

/// The device's own calls with one number on a watch: who, a row per call,
/// and the buttons that call back.
class CallLogScreenWatch extends StatelessWidget {
  const CallLogScreenWatch({super.key, required this.videoVisible, required this.onCall});

  final bool videoVisible;

  /// Calls [number] back, with video when [video] is set.
  final void Function(String number, String? name, bool video) onCall;

  @override
  Widget build(BuildContext context) {
    final timeOrDateFormat = context.read<AppTime>().timeOrDateFormat(Localizations.localeOf(context));
    return Scaffold(
      body: BlocBuilder<CallLogBloc, CallLogState>(
        builder: (context, state) {
          final number = state.number;
          final name = state.contact?.maybeName;
          final callLog = state.callLog ?? const <CallLogEntry>[];
          return CallLogWatchPage(
            title: state.contact?.displayTitle ?? number,
            number: number,
            loading: state.callLog == null,
            itemCount: callLog.length,
            itemBuilder: (context, index) {
              final entry = callLog[index];
              return CallLogWatchRow(
                key: ObjectKey(entry),
                direction: entry.direction,
                complete: entry.isComplete,
                missed: entry.isMissedIncoming,
                // A call that never connected says Missed, as the phone's
                // row does; only an incoming one is red.
                status: entry.isComplete
                    ? (entry.duration ?? Duration.zero).format()
                    : context.l10n.recents_HistoryTile_missedCallText,
                time: timeOrDateFormat.format(entry.createdTime),
                video: entry.video,
              );
            },
            onCall: () => onCall(number, name, false),
            onVideoCall: videoVisible ? () => onCall(number, name, true) : null,
          );
        },
      ),
    );
  }
}
