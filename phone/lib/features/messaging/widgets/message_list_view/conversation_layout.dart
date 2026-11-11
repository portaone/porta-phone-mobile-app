import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../messaging_state_wrapper.dart';

/// The body of a conversation: the list of its messages filling the screen,
/// and the [bar] a message is written in laid over the bottom of it.
///
/// The bar is translucent and blurs what is behind it, so the list is not cut
/// off above the bar but runs under it. Above the bar, on the right, sits the
/// button that brings a list scrolled into its history back to the newest
/// message; under the app bar, the notice of the messaging connection.
///
/// The bar has no fixed height: the message field grows with the lines typed
/// into it, and a conversation may put a quoted message above the field. So
/// the room the list must leave at its bottom is the height the bar has in
/// this very frame, and no number can stand in for it. The layout is a
/// [Scaffold] with the bar as its bottom bar and the body extended under it:
/// a scaffold measures its bottom bar before it lays the body out and hands
/// the body that height as the bottom padding of its [MediaQuery].
///
/// The [list] must therefore be a scroll view that sets no padding of its
/// own: such a view pads itself by the [MediaQuery] it is built under, and so
/// follows the bar. When the bar changes height only the scroll view is
/// rebuilt - the list given here is the same widget, so its messages are not.
class ConversationLayout extends StatelessWidget {
  const ConversationLayout({
    required this.list,
    required this.bar,
    required this.scrolledAway,
    required this.onScrollToBottom,
    super.key,
  });

  /// The scrolling list of the conversation's messages, with no padding set:
  /// it takes the room to leave under the app bar and above [bar] from the
  /// [MediaQuery] this layout builds it under.
  final Widget list;

  /// What the bottom of the conversation holds: the message field and whatever
  /// a conversation shows above it.
  final Widget bar;

  /// Whether the list is far enough from its newest message to offer the way
  /// back to it.
  final bool scrolledAway;

  /// Called when the way back to the newest message is taken.
  final VoidCallback onScrollToBottom;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // The screen's own scaffold paints the background and moves the body
      // above the keyboard; this one only places the bar over the list, and
      // must not make room for the keyboard a second time.
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: _ConversationBody(list: list, scrolledAway: scrolledAway, onScrollToBottom: onScrollToBottom),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            // A scaffold offers its bottom bar the whole height of the screen.
            mainAxisSize: MainAxisSize.min,
            children: [
              bar,
              Container(height: MediaQuery.paddingOf(context).bottom, color: colorScheme.surface.withAlpha(200)),
            ],
          ),
        ),
      ),
    );
  }
}

/// What lies under the bar: the list, and over it the two things placed
/// against the edges the list scrolls under. A widget of its own because the
/// height of the bar is only in the [MediaQuery] below the scaffold.
class _ConversationBody extends StatelessWidget {
  const _ConversationBody({required this.list, required this.scrolledAway, required this.onScrollToBottom});

  final Widget list;
  final bool scrolledAway;
  final VoidCallback onScrollToBottom;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Stack(
      children: [
        list,
        Positioned(top: padding.top, left: 0, right: 0, child: const MessagingStateBar()),
        Positioned(right: 16, bottom: padding.bottom + 24, child: ScrollToBottomButton(scrolledAway, onScrollToBottom)),
      ],
    );
  }
}
