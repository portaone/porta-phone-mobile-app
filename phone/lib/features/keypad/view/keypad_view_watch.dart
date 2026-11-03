import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The keypad on a watch face.
///
/// The twelve keys fill the face, without the letters under the digits -
/// they only help with vanity numbers and take the room the digits need. The
/// number sits above them on one line with backspace beside it and the
/// matched contact under it; the call is the edge button along the bottom.
///
/// On the smallest face a key is about 44 x 24 points, under the usual tap
/// floor: twelve keys and a call button do not fit otherwise. The keys have
/// no gaps, so every whole cell is the target.
class KeypadViewWatch extends StatelessWidget {
  const KeypadViewWatch({
    super.key,
    required this.numberField,
    required this.contactName,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onClear,
    required this.action,
  });

  /// The number being typed, the same field the phone shows, in a size for
  /// the face.
  final Widget numberField;

  final Widget contactName;
  final ValueChanged<String> onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  /// The edge button: the call, or the choice being made.
  final Widget Function(ButtonStyle overlay) action;

  @override
  Widget build(BuildContext context) {
    return WatchEdgeLayout(
      compact: true,
      padding: context.watchContentPadding().copyWith(bottom: 2),
      edge: (context, overlay) => action(overlay),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(child: numberField),
              SemanticAction(
                label: context.l10n.actionpad_SemanticsLabel_backspace,
                identifier: actionPadBackspaceId,
                child: InkResponse(
                  key: actionPadBackspaceKey,
                  onTap: onBackspace,
                  onLongPress: onClear,
                  radius: 18,
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.backspace_outlined, size: 16)),
                ),
              ),
            ],
          ),
          contactName,
          // The same id the phone's key carries, so automation dials the same
          // way on both.
          Expanded(
            child: WatchKeyGrid(keys: watchDialKeys, onPressed: onKeyPressed, identifier: keypadKeyId),
          ),
        ],
      ),
    );
  }
}
