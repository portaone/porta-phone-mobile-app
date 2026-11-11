import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/router/app_router.dart';
import 'package:webtrit_phone/features/recents/view/recents_screen_style.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/full_recent_cdrs_cubit.dart';
import '../cubit/missed_recent_cdrs_cubit.dart';
import '../widgets/cdrs_refresh_indicator.dart';
import '../widgets/cdrs_watch_list.dart';

/// The account's call history on a watch: one list at a time, the filter
/// flipped by the chip over it; clearing the history stays on the phone.
class RecentCdrsScreenWatch extends StatelessWidget {
  const RecentCdrsScreenWatch({
    super.key,
    required this.title,
    required this.filters,
    required this.selected,
    required this.onSelected,
    this.style,
  });

  /// The section's name, heading the list.
  final String title;
  final List<RecentsVisibilityFilter> filters;

  /// The filter whose list is shown.
  final RecentsVisibilityFilter selected;
  final ValueChanged<RecentsVisibilityFilter> onSelected;
  final RecentsScreenStyle? style;

  void _openCallLog(BuildContext context, String number) {
    context.router.navigate(NumberCdrsScreenPageRoute(number: number));
  }

  @override
  Widget build(BuildContext context) {
    final section = WatchSection(title: title, options: filters, selected: selected, onSelected: onSelected);

    final refresh = switch (selected) {
      RecentsVisibilityFilter.missed => context.read<MissedRecentCdrsCubit>().refresh,
      _ => context.read<FullRecentCdrsCubit>().refresh,
    };
    final list = switch (selected) {
      RecentsVisibilityFilter.missed => CdrsWatchList<MissedRecentCdrsCubit>(
        section: section,
        emptyMessage: context.l10n.cdrs_noMissedCalls_message,
        onOpen: (number) => _openCallLog(context, number),
        onRefresh: refresh,
      ),
      // The server answers one list of call records; only the missed filter
      // has a narrowed variant, the rest show them all.
      _ => CdrsWatchList<FullRecentCdrsCubit>(
        section: section,
        emptyMessage: context.l10n.cdrs_noRecentCalls_message,
        onOpen: (number) => _openCallLog(context, number),
        onRefresh: refresh,
      ),
    };

    return ThemedScaffold(
      background: style?.background,
      contentThemeOverride: style?.contentThemeOverride ?? ThemeMode.system,
      body: CdrsRefreshIndicator(onRefresh: refresh, child: list),
    );
  }
}
