import 'package:flutter/material.dart';

import '../view/call_screen_style.dart';
import 'call_action_button.dart';

/// The one action offered above a list of calls: Merge for a set of calls
/// that could become a room, Add for calls standing outside one.
///
/// Both are the same control in the same place saying different things, so
/// they are one widget with a different [label] rather than two that have to
/// be kept looking alike.
class CallListAction {
  const CallListAction({
    required this.label,
    required this.semanticsLabel,
    required this.identifier,
    required this.icon,
    required this.onPressed,
  });

  /// The word on the button.
  final String label;

  /// What a screen reader says instead: which calls, and into what.
  final String semanticsLabel;

  /// Stable automation id (see the `...Id` constants in keys.dart).
  final String identifier;

  final IconData icon;

  /// `null` leaves the control visible and disabled - what this particular
  /// set of calls cannot do now it may be able to do a moment later, and a
  /// control that comes and goes is harder to find than one that greys out.
  final VoidCallback? onPressed;
}

/// The pill that renders a [CallListAction] beside a list header.
///
/// It takes its colour from the header's own text style rather than a slot of
/// its own, so it sits on the call screen's background whatever theme the
/// deployment ships.
class CallListActionButton extends StatelessWidget {
  const CallListActionButton({super.key, required this.action, this.style});

  final CallListAction action;
  final CallInfoStyle? style;

  @override
  Widget build(BuildContext context) {
    final foreground = style?.callStatus?.color ?? Theme.of(context).colorScheme.onSurface;
    final enabled = action.onPressed != null;
    return CallActionButton(
      label: action.semanticsLabel,
      identifier: action.identifier,
      onPressed: action.onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        disabledForegroundColor: foreground.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const StadiumBorder(),
        side: BorderSide(color: enabled ? foreground : foreground.withValues(alpha: 0.4)),
      ),
      // The glyph and the word are what the control looks like; what it is
      // called is the label above, and a visible text left in the tree is
      // announced after it as a second name.
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [Icon(action.icon, size: 20), Text(action.label)],
        ),
      ),
    );
  }
}
