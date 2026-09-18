import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material show showModalBottomSheet;

import 'package:provider/provider.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/theme/styles/styles.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The snack bar of a screen, held apart from the widget that asked for it.
///
/// A message about something that has just left the screen has nowhere to come
/// from by the time there is anything to say: a row acted on and then removed
/// takes its element with it, and a context belonging to it is unmounted. Taken
/// before the await, this outlives that - the messenger sits above the route,
/// not inside the list.
class AppSnackBars {
  const AppSnackBars._(this._messenger, this._theme);

  final ScaffoldMessengerState _messenger;
  final ThemeData _theme;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    return _show(content: data, action: action, duration: duration);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    final styles = _theme.extension<SnackBarStyles>()?.primary;

    return _show(
      content: data,
      action: action,
      duration: duration,
      backgroundColor: styles?.errorBackgroundColor ?? _theme.colorScheme.error,
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    final styles = _theme.extension<SnackBarStyles>()?.primary;

    return _show(
      content: data,
      action: action,
      duration: duration,
      backgroundColor: styles?.successBackgroundColor ?? _theme.colorScheme.tertiary,
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showFloating(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 1),
  }) {
    return _show(content: data, action: action, duration: duration, behavior: SnackBarBehavior.floating);
  }

  /// Shows the one snack bar the app has, so every message is announced the
  /// same way and can be found by the same id.
  ///
  /// A message that offers something to do waits for the answer instead of
  /// timing out (and gets a close button, so it can always be dismissed):
  /// three seconds is not enough to notice an action, let alone to reach it
  /// with a screen reader.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show({
    required String content,
    required SnackBarAction? action,
    required Duration duration,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    return (_messenger..removeCurrentSnackBar()).showSnackBar(
      SnackBar(
        content: SemanticId(identifier: appSnackBarId, child: Text(content)),
        action: action,
        backgroundColor: backgroundColor,
        behavior: behavior,
        duration: duration,
        showCloseIcon: action != null,
      ),
    );
  }
}

extension BuildContextSnackBar on BuildContext {
  /// The screen's snack bar, to keep past an await. See [AppSnackBars].
  AppSnackBars get snackBars => AppSnackBars._(ScaffoldMessenger.of(this), Theme.of(this));

  void removeCurrentSnackBar() {
    ScaffoldMessenger.of(this).removeCurrentSnackBar();
  }

  void hideCurrentSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    return snackBars.show(data, action: action, duration: duration);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    return snackBars.showError(data, action: action, duration: duration);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showFloatingSnackBar(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 1),
  }) {
    return snackBars.showFloating(data, action: action, duration: duration);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessSnackBar(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
  }) {
    return snackBars.showSuccess(data, action: action, duration: duration);
  }

  T? readOrNull<T>() {
    try {
      return read<T>();
    } on ProviderNotFoundException catch (_) {
      return null;
    }
  }
}

extension BuildContextBottomSheet on BuildContext {
  /// Shows the one modal bottom sheet the app has, with its barrier named for
  /// what it does.
  ///
  /// Flutter labels the barrier behind a modal bottom sheet "Scrim" - the
  /// Material name of the dimming layer - and on Android and iOS that barrier
  /// is a real control: it is in the accessibility tree, and a tap on it
  /// closes the sheet. A sheet that fills the screen leaves the barrier one
  /// strip high, at the status bar, and that strip then announces itself as
  /// "Scrim". Dialogs name the same barrier "Dismiss" ([showDialog] does),
  /// which says what a tap on it does. So does this.
  ///
  /// Only the options the app uses are taken; add one here rather than call
  /// Flutter's function directly, so the label stays on every sheet.
  Future<T?> showModalBottomSheet<T>({
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool useSafeArea = false,
    bool? showDragHandle,
    Color? backgroundColor,
    Clip? clipBehavior,
  }) {
    return material.showModalBottomSheet<T>(
      context: this,
      builder: builder,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor,
      clipBehavior: clipBehavior,
      barrierLabel: MaterialLocalizations.of(this).modalBarrierDismissLabel,
    );
  }
}
