import 'package:flutter/material.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/widgets/semantic_action.dart';

class TransferBottomNavigationBar extends StatelessWidget {
  const TransferBottomNavigationBar(this.data, {super.key, this.onCancel, this.cancelLabel});

  final String data;

  /// Gives up on whatever is being chosen, where that is something the person
  /// can do from here. Null leaves the banner a statement rather than a
  /// control.
  final VoidCallback? onCancel;

  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    // A state that appears and disappears on its own, not something to reach:
    // read out when it arrives, or someone listening is left picking a
    // destination with no idea a transfer is under way.
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(kMainAppBarBottomPaddingGap),
        // Translucent so the blur behind it shows: opaque, the banner reads as
        // a strip pasted on the glass rather than part of it.
        color: themeData.colorScheme.secondary.withAlpha(200),
        child: Row(
          children: [
            Expanded(
              child: Text(data, style: TextStyle(color: themeData.colorScheme.onSecondary)),
            ),
            if (onCancel != null && cancelLabel != null)
              // At the end of the line the banner already occupies: a way out
              // belongs with the thing it is a way out of, and there is no
              // other surface that stays on screen across the sections a
              // person is browsing.
              SemanticAction(
                label: cancelLabel!,
                child: TextButton(
                  onPressed: onCancel,
                  child: Text(cancelLabel!, style: TextStyle(color: themeData.colorScheme.onSecondary)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
