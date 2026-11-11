import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The account's calls with one number on a watch: who, a row per call record
/// and the history fetch's spinner at the end, and the buttons that call back.
class NumberCdrsScreenWatch extends StatelessWidget {
  const NumberCdrsScreenWatch({
    super.key,
    required this.number,
    required this.controller,
    required this.videoVisible,
    required this.onCall,
  });

  final String number;

  /// The list's scroll controller, which fetches older records near the end.
  final ScrollController controller;

  final bool videoVisible;

  /// Calls [number] back, with video when [video] is set.
  final void Function(String number, String? name, bool video) onCall;

  @override
  Widget build(BuildContext context) {
    final timeOrDateFormat = context.read<AppTime>().timeOrDateFormat(Localizations.localeOf(context));
    return ThemedScaffold(
      background: Theme.of(context).extension<NumberCdrsScreenStyles>()?.primary?.background,
      body: ContactInfoBuilder(
        source: ContactSourcePhone(number),
        builder: (context, contact) {
          final name = contact?.maybeName;
          return BlocBuilder<NumberCdrsLogCubit, CdrsListState>(
            builder: (context, state) {
              final records = state.records;
              return CallLogWatchPage(
                title: contact?.displayTitle ?? number,
                number: number,
                loading: state.isLoading,
                controller: controller,
                // One more for the history fetch's spinner, as on the phone;
                // it stays while an empty list walks the history further back.
                itemCount: records.isEmpty && !state.fetchingHistory ? 0 : records.length + 1,
                itemBuilder: (context, index) {
                  if (index == records.length) return HistoryFetchIndicator(state.fetchingHistory);
                  final cdr = records[index];
                  return CallLogWatchRow(
                    key: Key(cdr.callId),
                    direction: cdr.direction,
                    complete: cdr.status == CdrStatus.accepted,
                    missed: cdr.isMissedIncoming,
                    status: cdr.isMissedIncoming
                        ? context.l10n.recents_HistoryTile_missedCallText
                        : cdr.duration.format(),
                    time: timeOrDateFormat.format(cdr.connectTime),
                  );
                },
                onCall: () => onCall(number, name, false),
                onVideoCall: videoVisible ? () => onCall(number, name, true) : null,
              );
            },
          );
        },
      ),
    );
  }
}
