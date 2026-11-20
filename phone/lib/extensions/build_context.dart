import 'package:material_ui/material_ui.dart';
import 'package:material_ui/material_ui.dart' as material show showModalBottomSheet;

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
  const AppSnackBars._(this._messenger, this._theme, this._screenReaderOn);

  final ScaffoldMessengerState _messenger;
  final ThemeData _theme;

  /// Whether a screen reader was on when this was taken. Read once, here,
  /// because the widget that asked is usually gone by the time the bar shows.
  final bool _screenReaderOn;

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    return _show(content: data, action: action, duration: duration, persist: persist, identifier: identifier);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showError(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    final styles = _theme.extension<SnackBarStyles>()?.primary;

    return _show(
      content: data,
      action: action,
      duration: duration,
      persist: persist,
      identifier: identifier,
      backgroundColor: styles?.errorBackgroundColor ?? _theme.colorScheme.error,
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccess(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    final styles = _theme.extension<SnackBarStyles>()?.primary;

    return _show(
      content: data,
      action: action,
      duration: duration,
      persist: persist,
      identifier: identifier,
      backgroundColor: styles?.successBackgroundColor ?? _theme.colorScheme.tertiary,
    );
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showFloating(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 1),
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    return _show(
      content: data,
      action: action,
      duration: duration,
      persist: persist,
      identifier: identifier,
      behavior: SnackBarBehavior.floating,
    );
  }

  /// Shows the one snack bar the app has, so every message is announced the
  /// same way and can be found by the same id - [appSnackBarId], unless the
  /// message is one a flow has to tell from the others, which then carries
  /// an [identifier] of its own.
  ///
  /// A message that offers something to do waits for the answer instead of
  /// timing out: three seconds is not enough to notice an action, let alone
  /// to reach it. [persist] false is for a message whose action is an offer
  /// rather than a question - an undo after a confirmation - which goes away
  /// with the messages around it. Under a screen reader a message with an
  /// action waits whatever was asked, because there three seconds is not
  /// enough to reach anything.
  ///
  /// The close button belongs to the waiting rather than to the action: a bar
  /// that stays until it is answered needs a way out, and one that leaves on
  /// its own already has one - offering both puts a second target next to the
  /// action in the seconds there are to reach it. So a bar with nothing to do
  /// cannot be asked to wait: it would stay with neither, which is refused
  /// here rather than quietly turned back into a timeout.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> _show({
    required String content,
    required SnackBarAction? action,
    required Duration duration,
    required bool? persist,
    required String identifier,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    assert(
      persist != true || action != null,
      'A snack bar with nothing to do cannot wait: it would stay with no action and no close button.',
    );

    final waits = action != null && ((persist ?? true) || _screenReaderOn);

    return (_messenger..removeCurrentSnackBar()).showSnackBar(
      SnackBar(
        content: SemanticId(identifier: identifier, child: Text(content)),
        action: action,
        backgroundColor: backgroundColor,
        behavior: behavior,
        duration: duration,
        persist: waits,
        showCloseIcon: waits,
      ),
    );
  }
}

extension BuildContextSnackBar on BuildContext {
  /// The screen's snack bar, to keep past an await. See [AppSnackBars].
  AppSnackBars get snackBars =>
      AppSnackBars._(ScaffoldMessenger.of(this), Theme.of(this), MediaQuery.maybeAccessibleNavigationOf(this) ?? false);

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
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    return snackBars.show(data, action: action, duration: duration, persist: persist, identifier: identifier);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    return snackBars.showError(data, action: action, duration: duration, persist: persist, identifier: identifier);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showFloatingSnackBar(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 1),
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    return snackBars.showFloating(data, action: action, duration: duration, persist: persist, identifier: identifier);
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessSnackBar(
    String data, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 5),
    bool? persist,
    String identifier = appSnackBarId,
  }) {
    return snackBars.showSuccess(data, action: action, duration: duration, persist: persist, identifier: identifier);
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
