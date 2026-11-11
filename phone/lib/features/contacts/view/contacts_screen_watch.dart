import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/models/models.dart';

import '../contacts.dart';

/// The tabbed contacts screen on a watch. One address book on the face at a
/// time, a chip in place of the tabs; the chip moves the screen's tab
/// controller, so both arrangements remember the same book.
class ContactsScreenWatch extends StatelessWidget {
  const ContactsScreenWatch({
    super.key,
    required this.style,
    required this.title,
    required this.sourceTypes,
    required this.tabController,
    required this.sourceTypeWidgetBuilder,
  });

  final ContactsScreenStyle? style;

  /// The section's name over the list, as the hub shows it.
  final String title;

  final List<ContactSourceType> sourceTypes;

  /// The screen's tabs, kept for the phone's arrangement as well.
  final TabController tabController;

  /// Mounts the list of one address book on a watch.
  final ContactSourceTypeWidgetBuilder sourceTypeWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    final sources = sourceTypes;
    return ContactsWatchSources(
      style: style,
      title: title,
      selections: [for (final sourceType in sources) ContactsSourceSelection(sourceType)],
      shown: (state) => switch (sources.shown(state.sourceType)) {
        final sourceType? => ContactsSourceSelection(sourceType),
        null => null,
      },
      // Only books are offered here.
      onSelected: (selection) =>
          tabController.index = sources.indexOf((selection as ContactsSourceSelection).sourceType),
      listBuilder: (context, selection) => switch (selection) {
        ContactsSourceSelection(:final sourceType) => sourceTypeWidgetBuilder(context, sourceType),
        ContactsFavoritesSelection() => const SizedBox.shrink(),
      },
    );
  }
}
