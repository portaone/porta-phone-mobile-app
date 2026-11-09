import 'package:flutter/foundation.dart';

/// What a list section on a watch is headed by: its title, the options its
/// one chip steps through (a recents filter, an address book), the one shown,
/// and how to show another.
class WatchSection<T> {
  const WatchSection({required this.title, required this.options, required this.selected, required this.onSelected});

  /// The section's name, the one the hub shows for it.
  final String title;

  /// The options the section offers, in their order.
  final List<T> options;

  /// The option shown.
  final T selected;

  /// Shows another option.
  final ValueChanged<T> onSelected;

  /// Whether there is anything to choose between.
  bool get choosable => options.length > 1;

  /// The option after the one shown, the first after the last: what the
  /// chip's tap shows.
  T get next => options[(options.indexOf(selected) + 1) % options.length];
}
