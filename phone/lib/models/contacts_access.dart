/// How much of the device address book the system lets the app read.
enum ContactsAccess {
  /// Nothing: not asked yet, refused, or restricted by the device.
  none,

  /// Only the contacts the user picked (iOS 18 and later). Reading the address
  /// book succeeds and returns just those.
  selected,

  /// The whole address book.
  all;

  bool get canRead => this != none;
}
