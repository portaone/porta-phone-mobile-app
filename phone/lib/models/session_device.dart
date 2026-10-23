import 'package:equatable/equatable.dart';

/// What the User-Agent a session was created with says about the device.
///
/// The app sends `AppName/AppVersion (DeviceName; OSName: OSVersion)` and the
/// core keeps the string as received, so a row of the session list reads the
/// device back out of it. A User-Agent of another shape - a browser's, an
/// older build's - gives null, and the row falls back to what else it knows.
class SessionDevice extends Equatable {
  const SessionDevice({
    required this.appName,
    required this.appVersion,
    required this.deviceName,
    required this.osName,
    required this.osVersion,
  });

  /// `PortaPhone`.
  final String appName;

  /// `1.18.0+0`, as the app wrote it.
  final String appVersion;

  /// `Samsung Galaxy XCover 5`, `iPhone 12 mini`; the hardware code when the
  /// build that opened the session knew no better name.
  final String deviceName;

  /// `Android`, `iOS`.
  final String osName;

  /// `14`, `27.0.1`.
  final String osVersion;

  /// The app name is the launch label, which a brand may give a space.
  static final _format = RegExp(r'^(.+?)/(\S+)\s*\((.*?);\s*([^:;()]+):\s*([^()]*)\)\s*$');

  /// The device out of [userAgent], or null when the string is not one the app
  /// writes.
  static SessionDevice? parse(String? userAgent) {
    if (userAgent == null) return null;
    final match = _format.firstMatch(userAgent.trim());
    if (match == null) return null;
    return SessionDevice(
      appName: match[1]!,
      appVersion: match[2]!,
      deviceName: _decode(match[3]!.trim()),
      osName: match[4]!.trim(),
      osVersion: match[5]!.trim(),
    );
  }

  /// The name as the app encoded it for the header: anything outside ASCII is
  /// percent-encoded as UTF-8. A `%` that is not an encoding, or one that
  /// does not decode to UTF-8 (any client may send any User-Agent, and the
  /// core keeps it as it came), leaves the name as it is.
  static String _decode(String name) {
    try {
      return Uri.decodeComponent(name);
    } on ArgumentError {
      return name;
    } on FormatException {
      return name;
    }
  }

  /// `Android 14`, `iOS 27.0.1`.
  String get osLabel => osVersion.isEmpty ? osName : '$osName $osVersion';

  @override
  List<Object?> get props => [appName, appVersion, deviceName, osName, osVersion];
}
