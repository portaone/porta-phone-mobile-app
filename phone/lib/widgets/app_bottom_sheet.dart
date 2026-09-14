import 'package:flutter/material.dart';

/// The app's [showModalBottomSheet]: the same sheet, with its barrier named
/// for what it does.
///
/// Flutter labels the barrier behind a modal bottom sheet "Scrim" - the
/// Material name of the dimming layer - and on Android and iOS that barrier
/// is a real control: it is in the accessibility tree, and a tap on it closes
/// the sheet. A sheet that fills the screen leaves the barrier one strip
/// high, at the status bar, and that strip then announces itself as "Scrim".
/// Dialogs name the same barrier "Dismiss" ([showDialog] does), which says
/// what a tap on it does. This helper does the same for sheets.
///
/// Only the parameters the app uses are forwarded; add one here rather than
/// call [showModalBottomSheet] directly, so the label stays on every sheet.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool? showDragHandle,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  );
}
