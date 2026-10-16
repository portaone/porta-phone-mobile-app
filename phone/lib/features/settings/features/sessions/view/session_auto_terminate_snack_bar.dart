import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/extensions/extensions.dart';

/// Owns the snack bar reported by an idle-period save.
///
/// The screen shares its [ScaffoldMessenger] with session-revoke actions. A
/// later save may dismiss an earlier save report, but must not dismiss an
/// unrelated revoke report that happens to be current.
class SessionAutoTerminateSnackBar {
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _controller;

  void hide() {
    _controller?.close();
    _controller = null;
  }

  void showError(BuildContext context, String message, {SnackBarAction? action}) {
    hide();
    final controller = context.showErrorSnackBar(message, action: action);
    _controller = controller;
    unawaited(
      controller.closed.whenComplete(() {
        if (identical(_controller, controller)) _controller = null;
      }),
    );
  }
}
