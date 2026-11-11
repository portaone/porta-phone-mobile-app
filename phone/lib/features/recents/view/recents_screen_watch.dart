import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/features/recents/view/recents_screen_style.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../recents.dart';

/// The local recents on a watch: a row per call, a tap opening the calls with
/// that number - or, while somebody is being chosen, choosing it. Deleting a
/// call and clearing the log stay on the phone.
class RecentsScreenWatch extends StatelessWidget {
  const RecentsScreenWatch({
    super.key,
    required this.title,
    required this.filters,
    required this.onSelected,
    required this.onOpen,
    this.style,
  });

  /// The section's name, heading the list.
  final String title;
  final List<RecentsVisibilityFilter> filters;
  final ValueChanged<RecentsVisibilityFilter> onSelected;
  final ValueChanged<Recent> onOpen;
  final RecentsScreenStyle? style;

  @override
  Widget build(BuildContext context) {
    // The phone's rows' format: the clock time, in the app's language.
    final timeFormat = context.read<AppTime>().timeFormat(Localizations.localeOf(context));
    return ThemedScaffold(
      background: style?.background,
      contentThemeOverride: style?.contentThemeOverride ?? ThemeMode.system,
      body: BlocBuilder<RecentsBloc, RecentsState>(
        builder: (context, state) {
          final recents = state.recentsFiltered ?? const <Recent>[];
          final filter = state.filter;
          return RecentsWatchBody(
            section: WatchSection(title: title, options: filters, selected: filter, onSelected: onSelected),
            loading: state.recents == null,
            emptyMessage: recentsEmptyMessage(context, filter),
            itemCount: recents.length,
            itemBuilder: (context, index) {
              final recent = recents[index];
              final entry = recent.callLogEntry;
              final contact = recent.contact;
              final pick = context.pickOfferFor(DestinationCandidate(number: entry.number, contact: contact));
              return RecentsWatchTile(
                key: ValueKey(recent),
                name: recent.name,
                time: timeFormat.format(entry.createdTime),
                direction: entry.direction,
                complete: entry.isComplete,
                missed: entry.isMissedIncoming,
                thumbnail: contact?.thumbnail,
                thumbnailUrl: contact?.thumbnailUrl,
                onTap: pick != null ? pick.onPressed : () => onOpen(recent),
              );
            },
          );
        },
      ),
    );
  }
}
