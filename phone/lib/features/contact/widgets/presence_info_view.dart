import 'package:clock/clock.dart';
import 'package:intl/intl.dart';

import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/extensions/extensions.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import 'presence_legend_dialog.dart';

class PresenceInfoView extends StatelessWidget {
  const PresenceInfoView({
    required this.presenceInfo,
    required this.timeFormat,
    this.registered,
    this.registeredAsOf,
    super.key,
  });

  final List<PresenceInfo> presenceInfo;

  /// Whether the contact's phone is registered on the PBX. Listed, with
  /// `registration` named as the source, only when [presenceInfo] is empty:
  /// it is what the status mark of such a contact is drawn from.
  final bool? registered;

  /// When [registered] was read from the contact list. It is a snapshot of
  /// that moment and not a live signal, so its age is shown next to it.
  final DateTime? registeredAsOf;

  /// The contact's local time.
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final records = _listedRecords;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          const _Title(),
          // One entry per source that has something to say. A published
          // status always outranks the registration, so the registration is
          // listed only when nothing was published.
          if (records.isNotEmpty)
            for (final (index, record) in records.indexed)
              _PublishedEntry(
                info: record.info,
                viaBothSources: record.viaBothSources,
                ordinal: records.length > 1 ? index + 1 : null,
                timeFormat: timeFormat,
              )
          else if (registered case final registered?)
            _RegistrationEntry(registered: registered, asOf: registeredAsOf),
        ],
      ),
    );
  }

  /// The records as they are listed: a device that publishes both through
  /// Core and through the PBX arrives as two records under one id, and is
  /// shown once, from its direct record, with both sources named.
  List<({PresenceInfo info, bool viaBothSources})> get _listedRecords {
    bool heard(String id, PresenceInfoSource source) =>
        presenceInfo.any((other) => other.id == id && other.source == source);

    return [
      for (final info in presenceInfo)
        // The SIP copy of a device that is also heard directly is the one
        // left out; every other record is listed, whatever else shares its id.
        if (info.source != PresenceInfoSource.sip || !heard(info.id, PresenceInfoSource.direct))
          (
            info: info,
            viaBothSources: info.source == PresenceInfoSource.direct && heard(info.id, PresenceInfoSource.sip),
          ),
    ];
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          l10n.presence_infoView_title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        // The section names its sources but not their order or what the
        // forms of the mark stand for; this is where the user can ask.
        SemanticAction(
          label: l10n.presence_infoView_legendButton,
          identifier: contactPresenceLegendId,
          child: IconButton(icon: const Icon(Icons.info_outline), onPressed: () => PresenceLegendDialog.show(context)),
        ),
      ],
    );
  }
}

/// A status somebody published: what one device of the contact says.
class _PublishedEntry extends StatelessWidget {
  const _PublishedEntry({
    required this.info,
    required this.viaBothSources,
    required this.ordinal,
    required this.timeFormat,
  });

  final PresenceInfo info;

  /// Whether the same device was heard both through Core and through the PBX.
  final bool viaBothSources;

  /// Number of the device among several, or null when it is the only one and
  /// needs no heading.
  final int? ordinal;

  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final ordinal = this.ordinal;
    final timeOffsetMin = info.timeOffsetMin;
    final statusIcon = info.statusIcon;
    final device = info.device;

    final activities = info.activities.map((activity) => activity.l10n(l10n)).toList();
    final status = activities.isNotEmpty
        ? activities.join(', ')
        : (info.available ? l10n.presence_infoView_available_true : l10n.presence_infoView_available_false);

    // A preset repeats its activity in the note, for clients too old to read
    // activities. Here both are understood, so the copy is not shown twice.
    final showNote = info.note.isNotEmpty && !activities.contains(info.note.trim());

    final source = switch ((viaBothSources, info.source)) {
      (true, _) => l10n.presence_infoView_source_sipAndDirect,
      (false, PresenceInfoSource.sip) => l10n.presence_infoView_source_sip,
      (false, _) => l10n.presence_infoView_source_direct,
    };

    return _Entry(
      children: [
        if (ordinal != null)
          Text(
            '${l10n.presence_infoView_device} $ordinal',
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        _StatusLine(text: status, presenceInfo: [info]),
        if (showNote)
          Row(
            children: [
              Flexible(child: Text(info.note, style: textTheme.bodySmall)),
              const SizedBox(width: 4),
              if (statusIcon != null && statusIcon.isNotEmpty) Text(statusIcon, style: textTheme.bodySmall),
            ],
          ),
        if (timeOffsetMin != null)
          Row(
            children: [
              Text(l10n.presence_infoView_localTime, style: textTheme.bodySmall),
              const SizedBox(width: 4),
              Text(
                timeFormat.format(clock.now().toUtc().add(Duration(minutes: timeOffsetMin))),
                style: textTheme.bodySmall,
              ),
              Text(' (UTC${timeOffsetMin >= 0 ? '+' : ''}${timeOffsetMin ~/ 60})', style: textTheme.bodySmall),
            ],
          ),
        // The time the records are ordered by, so what is read here is never
        // in the future, whatever the publisher's clock says.
        if (info.timestamp != null) _UpdatedLine(since: info.stateBeganAt),
        _SourceLine(source: source),
        if (device != null && device.isNotEmpty) _ClientLine(device: device),
      ],
    );
  }
}

/// What is known about a contact nobody publishes a status for: whether
/// their phone is registered, and as of when.
///
/// It says "registered", not "available", on purpose. The mark in the lists
/// is drawn as available for such a contact because that is the useful
/// reading at a glance; here, where the sources are named, the fact is given
/// as it is: a registered phone is a device that will ring, not a person who
/// said they are there.
class _RegistrationEntry extends StatelessWidget {
  const _RegistrationEntry({required this.registered, required this.asOf});

  final bool registered;
  final DateTime? asOf;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asOf = this.asOf;

    return _Entry(
      children: [
        _StatusLine(
          text: registered ? l10n.presence_badge_state_registered : l10n.presence_badge_state_unregistered,
          presenceInfo: const [],
          registered: registered,
        ),
        if (asOf != null) _UpdatedLine(since: asOf),
        _SourceLine(source: l10n.presence_infoView_source_registration),
      ],
    );
  }
}

/// The lines of one entry, laid out the same way whatever its source.
class _Entry extends StatelessWidget {
  const _Entry({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 2, children: children);
  }
}

/// The mark as an avatar would carry it, and the status in words beside it.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.text, required this.presenceInfo, this.registered});

  final String text;
  final List<PresenceInfo> presenceInfo;
  final bool? registered;

  static const double _markSide = 16;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox.square(
          dimension: _markSide,
          child: SipPresenceIndicator(
            presenceInfo: presenceInfo,
            dialogInfo: const [],
            presenceRect: const Rect.fromLTWH(0, 0, _markSide, _markSide),
            registered: registered,
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _UpdatedLine extends StatelessWidget {
  const _UpdatedLine({required this.since});

  final DateTime since;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Row(
      children: [
        Text(context.l10n.presence_infoView_updated, style: textStyle),
        const SizedBox(width: 4),
        AgoTicker(
          timestamp: since,
          builder: (ago) => Text(ago, style: textStyle),
        ),
      ],
    );
  }
}

/// Which client published the record. One of ours is spelled out - its name
/// and version, the phone or the browser, the system; what a third-party
/// device calls itself is shown as it came.
class _ClientLine extends StatelessWidget {
  const _ClientLine({required this.device});

  final String device;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;
    final client = PresenceClient.parse(device);
    if (client == null) return Text(device, style: textStyle);

    return Text('${context.l10n.presence_infoView_client} ${client.label}', style: textStyle);
  }
}

class _SourceLine extends StatelessWidget {
  const _SourceLine({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.presence_infoView_source(source), style: Theme.of(context).textTheme.bodySmall);
  }
}
