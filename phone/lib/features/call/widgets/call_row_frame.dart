import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/contact_resolver.dart';
import '../view/call_screen_style.dart';
import 'call_duration.dart';
import 'call_list_action.dart';
import 'call_remote_avatar.dart';

/// The shape every row on the call screen has: who it is about on the left,
/// their state over their name, and whatever controls the row offers on the
/// right.
///
/// The roster and the conference panel are two lists of the same thing - one
/// line of the call the screen is showing - so they are one widget. They were
/// two for a while, and the pictures the roster grew never reached the panel
/// because of it.
class CallRowFrame extends StatelessWidget {
  const CallRowFrame({
    super.key,
    required this.name,
    required this.trailing,
    this.status,
    this.statusBuilder,
    this.since,
    this.leading,
    this.onTap,
    this.focused = false,
    this.style,
    this.listStyle,
  });

  final String name;

  /// The state above the name, where it does not change with time.
  final String? status;

  /// The state above the name, where it counts the call's elapsed time with
  /// it; given `null` until the call is answered. Use one of this and
  /// [status].
  final String Function(BuildContext context, Duration? elapsed)? statusBuilder;

  /// When the call was answered, for [statusBuilder] to count from.
  final DateTime? since;

  /// The controls or labels at the end of the row.
  final List<Widget> trailing;

  /// Who the row is about; [CallRowAvatar] for a call, and absent only where
  /// the row is about nobody the app can picture.
  final Widget? leading;

  /// Makes the row itself the control that focuses that call; a row of a room
  /// is not one to choose between, so it has none.
  final VoidCallback? onTap;

  final bool focused;
  final CallInfoStyle? style;
  final CallListStyle? listStyle;

  /// The colour the row is painted in, for whatever a caller puts on the row
  /// and needs to match it - the badge on a picture, say.
  ///
  /// Row colors come from the themed call-list palette (CallListStyle, fed by
  /// the theme JSONs); the fallbacks derive from the row text color so an
  /// unthemed harness keeps the design polarity (focused = brighter). It is
  /// resolved here alone: a caller working it out again would go on painting
  /// the old colour after this one changed.
  static Color rowColor(BuildContext context, {required bool focused, CallInfoStyle? style, CallListStyle? listStyle}) {
    final base = baseColor(context, style);
    return focused
        ? (listStyle?.rowFocusedBackground ?? base.withValues(alpha: 0.26))
        : (listStyle?.rowBackground ?? base.withValues(alpha: 0.10));
  }

  /// What every row colour is derived from: the row's own text colour, or the
  /// surface behind it where the theme says nothing.
  static Color baseColor(BuildContext context, CallInfoStyle? style) =>
      style?.callStatus?.color ?? Theme.of(context).colorScheme.surface;

  @override
  Widget build(BuildContext context) {
    final nameStyle = style?.number ?? const TextStyle();
    final statusStyle = style?.callStatus ?? const TextStyle();

    final base = baseColor(context, style);
    final listStyle = this.listStyle;
    final rowColor = CallRowFrame.rowColor(context, focused: focused, style: style, listStyle: listStyle);
    final borderColor = listStyle?.rowFocusedBorder ?? base.withValues(alpha: 0.55);

    final content = Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: focused && onTap != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        spacing: 8,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (statusBuilder case final statusBuilder?)
                  CallDuration(
                    since: since,
                    builder: (context, elapsed) => Text(
                      statusBuilder(context, elapsed),
                      style: statusStyle.copyWith(fontSize: 10, letterSpacing: 1.1),
                    ),
                  )
                else
                  Text(status ?? '', style: statusStyle.copyWith(fontSize: 10, letterSpacing: 1.1)),
                Text(name, style: nameStyle.copyWith(fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ...trailing,
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: rowColor,
        borderRadius: BorderRadius.circular(16),
        child: onTap == null ? content : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: content),
      ),
    );
  }
}

/// The person a row is about, with the row's state as a badge on them.
///
/// The badge carried the state on its own before every row had a picture; on
/// the picture it still does, and the row leads with one thing rather than
/// two.
class CallRowAvatar extends StatelessWidget {
  const CallRowAvatar({
    super.key,
    required this.call,
    required this.contactResolver,
    this.dotColor,
    this.dotBorderColor,
  });

  static const double radius = 18;
  static const double _dot = 10;

  final ActiveCall call;
  final ContactResolver? contactResolver;

  /// The state to show on the picture; absent where the row says its state in
  /// words alone, as a room's rows do.
  final Color? dotColor;

  /// The row's own colour, so the badge reads as sitting on the row rather
  /// than on the picture.
  final Color? dotBorderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: radius * 2,
      child: Stack(
        children: [
          CallRemoteAvatar(activeCall: call, radius: radius, contactResolver: contactResolver),
          if (dotColor case final dotColor?)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _dot,
                height: _dot,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(color: dotBorderColor ?? Colors.transparent, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stands where a picture would, for a row about somebody the app has no
/// picture of - the host's own row. Without it the panel's names would start
/// at two different places down the list.
class CallRowSelfAvatar extends StatelessWidget {
  const CallRowSelfAvatar({super.key, this.style});

  final CallInfoStyle? style;

  @override
  Widget build(BuildContext context) {
    final color = CallRowFrame.baseColor(context, style);
    return SizedBox.square(
      dimension: CallRowAvatar.radius * 2,
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.18)),
        child: Icon(Icons.person, size: CallRowAvatar.radius, color: color),
      ),
    );
  }
}

/// What a list of rows is, above the rows, with whatever that list offers
/// beside it.
///
/// The roster and the conference panel head their lists the same way, and
/// this is the one place that says how: the panel's header went without an
/// action slot for as long as the two were written separately.
class CallRowHeader extends StatelessWidget {
  const CallRowHeader({super.key, required this.label, this.action, this.style});

  final String label;

  /// The control offered beside the label; absent where the list offers none.
  final CallListAction? action;

  final CallInfoStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: (style?.callStatus ?? const TextStyle()).copyWith(fontSize: 11, letterSpacing: 1.2),
            ),
          ),
          if (action case final action?) CallListActionButton(action: action, style: style),
        ],
      ),
    );
  }
}
