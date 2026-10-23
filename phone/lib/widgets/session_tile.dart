import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:intl/intl.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:api/api.dart' show AppType;

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// Activity younger than this is "active now": the core stamps a session on
/// every request, and an app in the foreground asks it more often than that.
const _activeNowWithin = Duration(minutes: 5);

/// How often a row re-reads the clock: the ages it shows are in minutes.
const _seenAtTick = Duration(seconds: 30);

/// Between the parts of a row's second line: a middle dot.
const _separator = ' \u00B7 ';

/// The rows of a list of devices on one surface, a divider between them,
/// edge to edge like the list tiles of the settings screens - the same look
/// wherever [SessionTile]s are listed.
class SessionTiles extends StatelessWidget {
  const SessionTiles({super.key, required this.children});

  final List<SessionTile> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceBright,
      child: Column(
        children: [
          for (final (index, tile) in children.indexed) ...[if (index > 0) const Divider(height: 1, indent: 72), tile],
        ],
      ),
    );
  }
}

/// One device the account is signed in on: its name, what runs on it, where
/// and when it was last seen, and the way to sign it out.
///
/// The name and the system come out of the User-Agent the session was created
/// with ([SessionDevice]); a session whose User-Agent the app did not write
/// falls back to the app type the core reported. Nothing is repeated: the
/// platform is said once, by the system line, and the app version only when it
/// is not the one this build runs - a session opened by an older build keeps
/// that build's User-Agent, hardware code and all, until the device signs in
/// again.
class SessionTile extends StatelessWidget {
  const SessionTile({
    super.key,
    required this.session,
    required this.index,
    required this.dateFormat,
    required this.revoking,
    required this.onRevoke,
    this.ownAppVersion,
  });

  final ActiveSession session;

  /// Position among the other devices shown, for the identifiers of the row
  /// and its button; the row of this device has an identifier of its own.
  final int index;

  final DateFormat dateFormat;

  final bool revoking;

  final ValueChanged<ActiveSession> onRevoke;

  /// The version of this build; a session created by another one says its
  /// version. Null leaves every version unsaid.
  final Version? ownAppVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;
    final textTheme = themeData.textTheme;
    final device = SessionDevice.parse(session.userAgent);

    final title = device?.deviceName ?? _titleOf(l10n, session.appType);
    // Without a parsed User-Agent the title already names the platform.
    final details = [
      ?device?.osLabel,
      if (session.lastActivityLocation ?? session.location case final location?) location.toUpperCase(),
    ];
    final seenAt = session.lastActivityAt ?? session.createdAt;
    final detailStyle = textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);
    final appVersion = _foreignAppVersion(device);

    final row = Row(
      children: [
        _KindIcon(kind: _kindOf(session.appType, device?.deviceName), current: session.current),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                title,
                style: textTheme.bodyLarge?.copyWith(fontWeight: .w600),
                maxLines: 1,
                overflow: .ellipsis,
              ),
              if (seenAt != null)
                _SeenAt(
                  at: seenAt,
                  dateFormat: dateFormat,
                  builder: (seen) =>
                      Text([...details, seen].join(_separator), style: detailStyle, maxLines: 1, overflow: .ellipsis),
                )
              else if (details.isNotEmpty)
                Text(details.join(_separator), style: detailStyle, maxLines: 1, overflow: .ellipsis),
              if (appVersion != null) Text(l10n.sessions_Tile_appVersion(appVersion), style: detailStyle),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // The current device has no button: signing it out is what logout in
        // settings is for. While a sign-out is on its way the button stays,
        // disabled, with progress in place of its icon: it keeps its name for
        // assistive technology and cannot be pressed twice.
        if (!session.current)
          SemanticAction(
            label: l10n.sessions_Tile_revokeTooltip,
            identifier: numberedId(sessionsTileRevokeButtonId, index),
            child: IconButton(
              icon: revoking
                  ? const SizedCircularProgressIndicator(size: 20, strokeWidth: 2)
                  : const Icon(Icons.logout),
              color: colorScheme.error,
              onPressed: revoking ? null : () => onRevoke(session),
            ),
          ),
      ],
    );

    return SemanticId(
      identifier: session.current ? sessionsCurrentTileId : numberedId(sessionsTileId, index),
      child: Container(
        // The same inset as the list tiles around it, so the leading icon
        // lines up with the row above and the sign-out icon with its chevron
        // (12 here plus the button's own padding make a tile's 16).
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        constraints: const BoxConstraints(minHeight: 64),
        child: row,
      ),
    );
  }

  /// The session's app version where it is not this build's; the own version
  /// goes unsaid because every row would say it. The build number is not a
  /// version a user tells apart, so `1.18.0+4` and `1.18.0+7` are the same. A
  /// version of a shape this app does not write cannot be compared, and goes
  /// unsaid too.
  String? _foreignAppVersion(SessionDevice? device) {
    final own = ownAppVersion;
    if (device == null || own == null) return null;
    final String theirs;
    try {
      theirs = _release(Version.parse(device.appVersion));
    } on FormatException {
      return null;
    }
    return theirs == _release(own) ? null : theirs;
  }

  static String _release(Version version) => '${version.major}.${version.minor}.${version.patch}';

  String _titleOf(AppLocalizations l10n, AppType? appType) {
    return switch (appType) {
      AppType.ios => l10n.sessions_AppType_ios,
      AppType.android || AppType.androidHms => l10n.sessions_AppType_android,
      AppType.web => l10n.sessions_AppType_web,
      AppType.linux => l10n.sessions_AppType_linux,
      AppType.macos => l10n.sessions_AppType_macos,
      AppType.windows => l10n.sessions_AppType_windows,
      AppType.smart => l10n.sessions_AppType_smart,
      null => l10n.sessions_AppType_unknown,
    };
  }

  /// The User-Agent carries no device kind, so a tablet is told by its name,
  /// as far as a name tells: "Galaxy Tab", "Tab M8", "iPad", "MatePad",
  /// "Pixel Tablet". A tablet named otherwise, or one whose session an older
  /// build opened under its hardware code, gets the phone icon.
  static final _tabletName = RegExp('tab|pad', caseSensitive: false);

  _Kind _kindOf(AppType? appType, String? deviceName) {
    return switch (appType) {
      AppType.web => _Kind.web,
      AppType.linux || AppType.macos || AppType.windows => _Kind.desktop,
      null => _Kind.unknown,
      _ => deviceName != null && _tabletName.hasMatch(deviceName) ? _Kind.tablet : _Kind.phone,
    };
  }
}

/// When the device was last seen, kept current while the row is on screen:
/// "active now" or an age while it is recent enough for that to mean
/// something, a date past a day. Read once in `build`, "active now" would
/// still stand after the screen had been open for an hour.
class _SeenAt extends StatefulWidget {
  const _SeenAt({required this.at, required this.dateFormat, required this.builder});

  final DateTime at;
  final DateFormat dateFormat;
  final Widget Function(String seen) builder;

  @override
  State<_SeenAt> createState() => _SeenAtState();
}

class _SeenAtState extends State<_SeenAt> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_seenAtTick, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final elapsed = DateTime.now().difference(widget.at);
    final String seen;
    if (elapsed < _activeNowWithin) {
      seen = l10n.sessions_Tile_activeNow;
    } else if (elapsed.inMinutes < 60) {
      seen = l10n.agoTicker_minutesAgo(elapsed.inMinutes);
    } else if (elapsed.inHours < 24) {
      seen = l10n.agoTicker_hoursAgo(elapsed.inHours);
    } else {
      // A date does not change any more: nothing left to tick for.
      seen = widget.dateFormat.format(widget.at);
      _timer?.cancel();
      _timer = null;
    }
    return widget.builder(seen);
  }
}

enum _Kind { phone, tablet, web, desktop, unknown }

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind, required this.current});

  final _Kind kind;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (kind) {
      _Kind.phone => Icons.smartphone,
      _Kind.tablet => Icons.tablet_android,
      _Kind.web => Icons.language,
      _Kind.desktop => Icons.desktop_windows,
      _Kind.unknown => Icons.devices_other,
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: current ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      ),
      child: Icon(icon, size: 20, color: current ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
    );
  }
}
