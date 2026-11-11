import 'dart:ui';

import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/widgets/widgets.dart';

import '../messaging_state_wrapper.dart';

/// The body of a conversation: the [list] of its messages filling the screen,
/// and the [bar] a message is written in laid over the bottom of it.
///
/// The bar is translucent and blurs what is behind it, so the list is not cut
/// off above the bar but runs under it. Above the bar, on the right, sits the
/// button that brings a list scrolled into its history back to the newest
/// message; under the app bar, the notice of the messaging connection.
class ConversationLayout extends StatelessWidget {
  const ConversationLayout({
    required this.list,
    required this.bar,
    required this.scrolledAway,
    required this.onScrollToBottom,
    super.key,
  });

  /// The scrolling list of the conversation's messages.
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

    return Stack(
      children: [
        list,
        Positioned(top: MediaQuery.of(context).padding.top, left: 0, right: 0, child: const MessagingStateBar()),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerRight,
                child: ScrollToBottomButton(scrolledAway, onScrollToBottom),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Column(
                    children: [
                      bar,
                      Container(
                        height: MediaQuery.of(context).padding.bottom,
                        color: colorScheme.surface.withAlpha(200),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
