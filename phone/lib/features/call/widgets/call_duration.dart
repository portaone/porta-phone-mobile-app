import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:clock/clock.dart';

import 'package:webtrit_phone/extensions/extensions.dart';

/// Rebuilds [builder] once a second while [since] is set, so a call's elapsed
/// time stays current.
///
/// Three widgets used to keep a timer of their own for this, and the three had
/// already drifted: they started on different conditions and re-armed on
/// different ones. They all want the same thing - tick while there is a
/// duration to tick, stop when there is not - so it lives here.
class CallDuration extends StatefulWidget {
  const CallDuration({super.key, required this.since, required this.builder});

  /// When the call was answered; `null` means there is nothing to count yet,
  /// and the ticker stays off.
  final DateTime? since;

  /// Given the elapsed time, or `null` while [since] is.
  final Widget Function(BuildContext context, Duration? elapsed) builder;

  @override
  State<CallDuration> createState() => _CallDurationState();
}

class _CallDurationState extends State<CallDuration> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant CallDuration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.since != oldWidget.since) _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _syncTicker() {
    _ticker?.cancel();
    _ticker = widget.since == null ? null : Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final since = widget.since;
    return widget.builder(context, since == null ? null : clock.now().difference(since));
  }
}

/// The elapsed time of a call as text, kept current; [placeholder] stands in
/// its place while there is nothing to count.
class CallDurationText extends StatelessWidget {
  const CallDurationText({super.key, required this.since, this.style, this.placeholder});

  final DateTime? since;
  final TextStyle? style;

  /// What to say before the call is answered - its direction, on a roster row.
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    return CallDuration(
      since: since,
      builder: (context, elapsed) => Text(elapsed?.format() ?? placeholder ?? '', style: style),
    );
  }
}
