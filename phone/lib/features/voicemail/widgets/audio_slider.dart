import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/l10n/l10n.dart';

import '../utils/utils.dart';

class AudioSlider extends StatelessWidget {
  const AudioSlider({super.key, required this.position, required this.duration, required this.onSeek});

  final Duration position;

  /// How long the recording is; null while nobody knows - the mailbox did not
  /// say and the recording has not been loaded. No time is drawn then: a
  /// `0:00` would be a length the message does not have.
  final Duration? duration;

  final ValueChanged<Duration> onSeek;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleChanged(double value) {
    onSeek(Duration(milliseconds: value.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final duration = this.duration;
    final clampedPosition = duration != null && position > duration ? duration : position;
    final timeStyle = textTheme.labelSmall?.copyWith(color: colorScheme.onSurface.withValues(alpha: 0.5));

    return Stack(
      children: [
        Slider(
          padding: EdgeInsets.zero,
          value: duration == null ? 0 : clampedPosition.inMilliseconds.toDouble(),
          max: (duration?.inMilliseconds.toDouble() ?? 0).clamp(1, double.infinity),
          onChanged: _handleChanged,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.onSurface.withValues(alpha: 0.1),
          // Without it a screen reader says where the thumb is as a percentage,
          // which tells nobody how far into the message they are.
          semanticFormatterCallback: duration == null
              ? null
              : (value) => l10n.voicemail_SemanticsValue_playbackPosition(
                  spokenDuration(l10n, Duration(milliseconds: value.toInt())),
                  spokenDuration(l10n, duration),
                ),
        ),
        if (duration != null)
          // Drawn for the eye only. Read out, `0:10` is a time of day; the
          // slider above and the message's row say the same in words.
          ExcludeSemantics(
            child: Transform.translate(
              offset: const Offset(0, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(clampedPosition), style: timeStyle),
                  Text(_formatDuration(duration), style: timeStyle),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
