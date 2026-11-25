import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// Explains the status of a contact to the user: which sources it is taken
/// from and in what order, and what each form of the mark stands for.
///
/// The marks in the legend are the real ones, drawn by the same widget as on
/// an avatar, so the explanation cannot drift from what the lists show.
class PresenceLegendDialog extends StatelessWidget {
  const PresenceLegendDialog._();

  static Future<void> show(BuildContext context) {
    return showDialog<void>(context: context, builder: (context) => const PresenceLegendDialog._());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final heading = textTheme.titleSmall;
    final body = textTheme.bodyMedium;

    return AlertDialog(
      title: Text(l10n.presence_legendDialog_title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text(l10n.presence_legendDialog_sourcesTitle, style: heading),
            _NumberedLine(number: 1, text: l10n.presence_legendDialog_sourceDirect),
            _NumberedLine(number: 2, text: l10n.presence_legendDialog_sourceSip),
            _NumberedLine(number: 3, text: l10n.presence_legendDialog_sourceRegistration),
            Text(l10n.presence_legendDialog_sourcesNote, style: body),
            const SizedBox(height: 4),
            Text(l10n.presence_legendDialog_marksTitle, style: heading),
            _MarkLine(text: l10n.presence_legendDialog_markAvailable, presenceInfo: [_sample(available: true)]),
            _MarkLine(text: l10n.presence_legendDialog_markUnavailable, presenceInfo: [_sample(available: false)]),
            _MarkLine(
              text: l10n.presence_legendDialog_markActivity,
              presenceInfo: [_sample(available: true, activity: PresenceActivity.away)],
            ),
            _MarkLine(
              text: l10n.presence_legendDialog_markDoNotDisturb,
              presenceInfo: [_sample(available: false, activity: PresenceActivity.doNotDisturb)],
            ),
            _MarkLine(
              text: l10n.presence_legendDialog_markOnCall,
              presenceInfo: [_sample(available: true, activity: PresenceActivity.onThePhone)],
            ),
            _MarkLine(text: l10n.presence_legendDialog_markRegistered, presenceInfo: const [], registered: true),
            _MarkLine(text: l10n.presence_legendDialog_markUnregistered, presenceInfo: const [], registered: false),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.alertDialogActions_ok))],
    );
  }

  /// A record that exists only to make the mark draw one of its forms.
  static PresenceInfo _sample({required bool available, PresenceActivity? activity}) => PresenceInfo(
    id: 'legend',
    number: '',
    available: available,
    note: '',
    statusIcon: null,
    device: null,
    timeOffsetMin: null,
    timestamp: null,
    activities: [?activity],
    source: PresenceInfoSource.direct,
    arrivalTime: DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class _NumberedLine extends StatelessWidget {
  const _NumberedLine({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text('$number.', style: style),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

class _MarkLine extends StatelessWidget {
  const _MarkLine({required this.text, required this.presenceInfo, this.registered});

  final String text;
  final List<PresenceInfo> presenceInfo;
  final bool? registered;

  static const double _side = 20;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 10,
      children: [
        SizedBox.square(
          dimension: _side,
          // The mark is a picture of what the text beside it says; read out
          // twice it would only be noise.
          child: ExcludeSemantics(
            child: SipPresenceIndicator(
              presenceInfo: presenceInfo,
              dialogInfo: const [],
              presenceRect: const Rect.fromLTWH(0, 0, _side, _side),
              registered: registered,
            ),
          ),
        ),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
