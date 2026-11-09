import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';

/// A recents list on a watch: the section's title, one chip that flips the
/// filter, and a row per call; no app bar, tabs or actions button - a face has
/// room for none of them.
///
/// On the way it is a loading page, and with nothing to show a state page
/// whose edge button goes back to the first filter when another is shown, so a
/// list of no missed calls is never a dead end - or, on the first filter of a
/// list that can be asked again, refreshes it.
class RecentsWatchBody extends StatelessWidget {
  const RecentsWatchBody({
    super.key,
    required this.section,
    required this.loading,
    required this.emptyMessage,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.onRefresh,
  });

  final WatchSection<RecentsVisibilityFilter> section;

  /// Whether the list is still on its way.
  final bool loading;

  /// What the state page says when the list has nothing to show.
  final String emptyMessage;

  /// How many rows [itemBuilder] builds.
  final int itemCount;

  /// Builds the row at an index, a [RecentsWatchTile] or what the list ends with.
  final IndexedWidgetBuilder itemBuilder;

  /// The list's scroll controller, for a list that loads more as it scrolls.
  final ScrollController? controller;

  /// Asks for the list again, for a list that comes from a server: offered on
  /// the edge button of an empty first filter, where a phone pulls to
  /// refresh.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final section = this.section;
    if (loading) {
      return WatchStatePage.loading(title: section.title, progressLabel: context.l10n.common_SemanticsLabel_loading);
    }

    final first = section.options.first;
    if (itemCount == 0) {
      return WatchStatePage(
        title: section.title,
        icon: const Icon(Icons.history),
        message: emptyMessage,
        action: switch (onRefresh) {
          _ when section.selected != first => WatchAction(
            label: first.l10n(context),
            identifier: first.tabId,
            onPressed: () => section.onSelected(first),
          ),
          final onRefresh? => WatchAction(
            label: context.l10n.common_SemanticsLabel_refresh,
            identifier: recentsWatchRefreshId,
            onPressed: onRefresh,
          ),
          null => null,
        },
      );
    }

    return WatchScrollList.builder(
      title: section.title,
      // The filter over the rows, and the bar every list on a watch puts
      // between its controls and its rows.
      header: [
        if (section.choosable) ...[RecentsWatchFilterChip(section: section), const WatchSeparator()],
      ],
      spacing: context.adaptiveMetrics.gap,
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}

/// The filter of a recents list on a watch: one pill naming the filter shown;
/// a tap moves to the next one, so with All and Missed it flips between them.
class RecentsWatchFilterChip extends StatelessWidget {
  const RecentsWatchFilterChip({super.key, required this.section});

  final WatchSection<RecentsVisibilityFilter> section;

  @override
  Widget build(BuildContext context) {
    final label = section.selected.l10n(context);
    return WatchPillButton(
      buttonKey: recentsWatchFilterKey,
      identifier: recentsWatchFilterId,
      icon: Icons.filter_list,
      label: label,
      semanticsLabel: '${context.l10n.recents_FilterPicker_label}: $label',
      onPressed: () => section.onSelected(section.next),
    );
  }
}

/// One call in a recents list on a watch: who, and when after the direction's
/// arrow - red for a missed call, the one the Missed filter keeps, and "Missed" in
/// its name for a screen reader; the name keeps the width of the row. A tap
/// opens what the screen gives it; the call itself is placed from there, so a
/// tap on a small face never dials by accident.
class RecentsWatchTile extends StatelessWidget {
  const RecentsWatchTile({
    super.key,
    required this.name,
    required this.time,
    required this.direction,
    required this.complete,
    this.missed = false,
    this.thumbnail,
    this.thumbnailUrl,
    this.onTap,
  });

  /// Who was on the other end.
  final String name;

  /// When, as the list's phone arrangement writes it.
  final String time;

  final CallDirection direction;

  /// Whether the call was answered.
  final bool complete;

  /// Whether it is a call nobody answered: a red arrow, "Missed" read out.
  final bool missed;

  final Uint8List? thumbnail;
  final Uri? thumbnailUrl;

  /// Null shows the row disabled, as a call without a number to go back to.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return WatchListTile(
      title: name,
      subtitle: time,
      // Red tells the eye; the word tells a screen reader.
      semanticsLabel: missed ? '$name, ${context.l10n.recents_HistoryTile_missedCallText}, $time' : null,
      subtitleIcon: Icon(direction.icon(complete), color: missed ? colorScheme.error : null),
      leading: LeadingAvatar(username: name, thumbnail: thumbnail, thumbnailUrl: thumbnailUrl, radius: 12),
      onTap: onTap,
    );
  }
}
