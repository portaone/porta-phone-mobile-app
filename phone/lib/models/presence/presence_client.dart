import 'package:equatable/equatable.dart';

/// What the `device` of a presence record says about the client that
/// published it.
///
/// Our own clients name themselves `Name/Version (Device; System)`: the app
/// sends its User-Agent, `PortaPhone/1.18.0+0 (Galaxy S24; Android: 14)`,
/// and the web dialer `Web-dialer/0.2.13 (Chrome; macOS)`. Anything of another
/// shape - the device id a desk phone puts into its publication - is not
/// ours to interpret, and [parse] gives null for it.
class PresenceClient extends Equatable {
  const PresenceClient({required this.name, required this.version, required this.device, required this.system});

  /// `PortaPhone`, `Web-dialer`.
  final String name;

  /// `1.18.0+0`, `0.2.13`, as the client wrote it.
  final String version;

  /// The phone model, or the browser.
  final String device;

  /// `Android 14`, `macOS`.
  final String system;

  static final _format = RegExp(r'^(.+?)/(\S+)\s*\(([^;()]*)(?:;\s*([^()]*))?\)\s*$');

  static PresenceClient? parse(String? device) {
    if (device == null) return null;
    final match = _format.firstMatch(device.trim());
    if (match == null) return null;
    return PresenceClient(
      name: match[1]!.trim(),
      version: match[2]!,
      device: _decode(match[3]!.trim()),
      // The app writes `Android: 14`; the colon is its separator, not text.
      system: (match[4] ?? '').replaceAll(RegExp(r'\s*:\s*'), ' ').trim(),
    );
  }

  /// The parts on one line, a middle dot between them:
  /// `Web-dialer 0.2.13`, `Chrome`, `macOS`.
  String get label => ['$name $version', device, system].where((part) => part.isNotEmpty).join(' \u00B7 ');

  /// The app percent-encodes what is outside ASCII in a device name. Any
  /// client may put anything here, though: a `%` that is not an encoding, or
  /// one that does not decode to UTF-8, leaves the name as it came.
  static String _decode(String name) {
    try {
      return Uri.decodeComponent(name);
    } on ArgumentError {
      return name;
    } on FormatException {
      return name;
    }
  }

  @override
  List<Object?> get props => [name, version, device, system];
}
