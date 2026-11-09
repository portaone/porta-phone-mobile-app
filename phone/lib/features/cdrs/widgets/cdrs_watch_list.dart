import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/features/features.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The account's call history on a watch, either list of it: a row per call
/// record under the section's title and filter, and the history fetch's
/// spinner at the end while an older page is on its way.
///
/// A tap opens the calls with that number - or, while somebody is being
/// chosen, chooses it; a record with no number to go back to is shown
/// disabled.
///
/// [C] is the list's cubit, the full history's or the missed calls'; the
/// rows follow its state.
class CdrsWatchList<C extends StateStreamable<CdrsListState>> extends StatelessWidget {
  const CdrsWatchList({
    super.key,
    required this.section,
    required this.emptyMessage,
    required this.controller,
    required this.onOpen,
    required this.onRefresh,
  });

  final WatchSection<RecentsVisibilityFilter> section;

  /// What the state page says when the list has no records.
  final String emptyMessage;

  /// The list's scroll controller, which fetches older records near the end.
  final ScrollController controller;

  /// Opens the calls with a number.
  final ValueChanged<String> onOpen;

  /// Fetches the history again; a failure is said in a snackbar, as the
  /// phone's pull to refresh says it, and the list stays as it was.
  final Future<void> Function() onRefresh;

  Future<void> _refresh(BuildContext context) async {
    try {
      await onRefresh();
    } catch (_) {
      if (context.mounted) context.showErrorSnackBar(context.l10n.cdrs_refreshFailed_message);
    }
  }

  @override
  Widget build(BuildContext context) {
    // How a row writes when the call was, as the phone's rows write it.
    final timeOrDateFormat = context.read<AppTime>().timeOrDateFormat(Localizations.localeOf(context));
    return BlocBuilder<C, CdrsListState>(builder: (context, state) => _list(context, state, timeOrDateFormat));
  }

  Widget _list(BuildContext context, CdrsListState state, TimeOrDateFormat timeOrDateFormat) {
    final records = state.records;
    return RecentsWatchBody(
      section: section,
      loading: state.isLoading,
      emptyMessage: emptyMessage,
      controller: controller,
      onRefresh: () => _refresh(context),
      // One more for the history fetch's spinner, as on the phone.
      itemCount: records.isEmpty ? 0 : records.length + 1,
      itemBuilder: (context, index) {
        if (index == records.length) return HistoryFetchIndicator(state.fetchingHistory);
        final cdr = records[index];
        final number = cdr.participantNumber;
        return ContactInfoBuilder(
          key: Key(cdr.callId),
          source: ContactSourcePhone(number ?? cdr.participant),
          builder: (context, contact) {
            final pick = context.pickOfferFor(DestinationCandidate(number: number, contact: contact));
            return RecentsWatchTile(
              name: contact?.maybeName ?? cdr.participant,
              time: timeOrDateFormat.format(cdr.connectTime),
              direction: cdr.direction,
              complete: cdr.status == CdrStatus.accepted,
              missed: cdr.isMissedIncoming,
              thumbnail: contact?.thumbnail,
              thumbnailUrl: contact?.thumbnailUrl,
              onTap: pick != null
                  ? pick.onPressed
                  : number != null
                  ? () => onOpen(number)
                  : null,
            );
          },
        );
      },
    );
  }
}
