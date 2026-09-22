import 'package:flutter/material.dart';

/// The coloured dot that repeats, at a glance, what the row's caption says.
///
/// It carries no semantics of its own: the caption next to it already says
/// "Online" or "Offline", and a second announcement of the same fact is noise
/// to a screen reader.
class QueueStatusDot extends StatelessWidget {
  const QueueStatusDot({super.key, required this.loggedIn, this.size = 8});

  final bool loggedIn;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: loggedIn ? colorScheme.primary : colorScheme.outline, shape: BoxShape.circle),
      ),
    );
  }
}
