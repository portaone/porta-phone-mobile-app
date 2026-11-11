import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

class AcknowledgeDialog extends StatelessWidget {
  static Future<void> show(BuildContext context, {required String title, required String content}) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AcknowledgeDialog._(title: title, content: content);
      },
    );
  }

  const AcknowledgeDialog._({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// A watch has no room around a card: the title and the text take the whole
  /// face, OK on the edge.
  Widget _watch(BuildContext context) {
    final themeData = Theme.of(context);
    final apple = switch (themeData.platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    // Named as an alert the way AlertDialog names itself, so a screen reader
    // announces the face as one when it opens; on Apple platforms, as there,
    // the title names it.
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: apple ? null : MaterialLocalizations.of(context).alertDialogLabel,
      child: Dialog.fullscreen(
        // The dialog's own surface, as a watch confirm has it, so the two
        // shown one after the other look the same.
        backgroundColor: DialogTheme.of(context).backgroundColor ?? themeData.scaffoldBackgroundColor,
        semanticsRole: SemanticsRole.alertDialog,
        child: WatchActionLayout(
          title: title,
          content: [Text(content, textAlign: TextAlign.center)],
          action: WatchAction(
            label: context.l10n.alertDialogActions_ok,
            identifier: acknowledgeDialogOkButtonId,
            buttonKey: acknowledgeDialogOkButtonKey,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  Widget _handset(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(context.l10n.alertDialogActions_ok)),
      ],
    );
  }
}
