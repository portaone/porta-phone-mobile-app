/// How the recents section arranges what it shows.
///
/// Both arrangements show the same lists and offer the same actions; they
/// differ in where the filter and the actions sit, which a deployment picks to
/// match the rest of its screens.
enum RecentsLayout {
  /// The filters as tabs under the title, the list's actions on a floating
  /// button at its corner.
  tabbed,

  /// The filter as a chooser on the line under the title, the list's actions
  /// on a menu button at the other end of that line - the unified contacts
  /// screen's header.
  unified,
}
