import 'dart:ui' show SemanticsRole;

import 'package:material_ui/material_ui.dart';

import 'package:adaptive_kit/adaptive_kit.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';

import 'confirm_dialog_style.dart';
import 'confirm_dialog_styles.dart';

export 'confirm_dialog_style.dart';
export 'confirm_dialog_styles.dart';

class ConfirmDialog extends StatelessWidget {
  // Anchor the dialog to the nearest navigator instead of the app-wide root. The
  // originating theme is preserved by showDialog's InheritedTheme capture, so the
  // appearance and behavior are unchanged in the app; this only matters when a
  // screen is hosted inside another navigator (the configurator preview), where the
  // root navigator belongs to the host and the dialog would otherwise escape its
  // surface and lose the phone's Localizations.
  ///
  /// [confirmLabel] names the yes where a plain "Yes" would not say what it
  /// does: a statement rather than a question, such as a warning with a way
  /// to the settings that lift it.
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? content,
    String? confirmLabel,
    ConfirmDialogStyle? style,
  }) {
    return showDialog<bool?>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return ConfirmDialog._(title: title, content: content, confirmLabel: confirmLabel, style: style);
      },
    );
  }

  static Future<bool?> showDangerous(
    BuildContext context, {
    required String title,
    String? content,
    ConfirmDialogStyle? style,
  }) {
    return showDialog<bool?>(
      context: context,
      useRootNavigator: false,
      builder: (context) {
        return ConfirmDialog._(dangerous: true, title: title, content: content, style: style);
      },
    );
  }

  const ConfirmDialog._({
    this.dangerous = false,
    required this.title,
    this.content,
    this.confirmLabel,
    required this.style,
  });

  final bool dangerous;
  final String title;

  /// What the confirmation is about, under the question.
  ///
  /// Optional because some questions are complete on their own - "Leave this
  /// group?" says everything - and a dialog that repeats its title in smaller
  /// type reads worse than one without.
  final String? content;

  /// The yes, when "Yes" would not say what it does.
  final String? confirmLabel;

  final ConfirmDialogStyle? style;

  @override
  Widget build(BuildContext context) {
    final localStyle = ConfirmDialogStyle.merge(style, Theme.of(context).extension<ConfirmDialogStyles>()?.primary);

    return AdaptiveLayout(
      handset: (context) => _ConfirmCard(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        dangerous: dangerous,
        style: localStyle,
      ),
      watch: (context) => _ConfirmFace(
        title: title,
        content: content,
        confirmLabel: confirmLabel,
        dangerous: dangerous,
        style: localStyle,
      ),
    );
  }
}

/// A watch has no room around a card: the question takes the whole face,
/// answered by two round buttons.
class _ConfirmFace extends StatelessWidget {
  const _ConfirmFace({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.dangerous,
    required this.style,
  });

  final String title;
  final String? content;
  final String? confirmLabel;
  final bool dangerous;
  final ConfirmDialogStyle style;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final dialogTheme = DialogTheme.of(context);
    final apple = switch (themeData.platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => true,
      _ => false,
    };

    // Named as an alert the way AlertDialog names itself, so a screen reader
    // announces the face as one when it opens; on Apple platforms, as there,
    // the question names it.
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: apple ? null : MaterialLocalizations.of(context).alertDialogLabel,
      child: Dialog.fullscreen(
        // The face shows the dialog's own surface and text colours, so a theme
        // that colours the dialog colours it on a watch too; without one it is
        // the screen's.
        backgroundColor: style.backgroundColor ?? dialogTheme.backgroundColor ?? themeData.scaffoldBackgroundColor,
        semanticsRole: SemanticsRole.alertDialog,
        child: WatchConfirm(
          question: title,
          detail: content,
          destructive: dangerous,
          confirmColor: (dangerous ? style.activeButtonStyle2 : style.defaultButtonStyle)?.foregroundColor?.resolve(
            const {},
          ),
          questionColor: (style.titleTextStyle ?? dialogTheme.titleTextStyle)?.color,
          detailColor: (style.contentTextStyle ?? dialogTheme.contentTextStyle)?.color,
          cancelLabel: context.l10n.alertDialogActions_no,
          confirmLabel: confirmLabel ?? context.l10n.alertDialogActions_yes,
          cancelIdentifier: confirmDialogNoButtonId,
          confirmIdentifier: confirmDialogYesButtonId,
          cancelKey: confirmDialogNoButtonKey,
          confirmKey: confirmDialogYesButtonKey,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
        ),
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  const _ConfirmCard({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.dangerous,
    required this.style,
  });

  final String title;
  final String? content;
  final String? confirmLabel;
  final bool dangerous;
  final ConfirmDialogStyle style;

  @override
  Widget build(BuildContext context) {
    final content = this.content;
    return AlertDialog(
      backgroundColor: style.backgroundColor,
      surfaceTintColor: style.surfaceTintColor,
      elevation: style.elevation,
      shape: style.shape,
      titleTextStyle: style.titleTextStyle,
      contentTextStyle: style.contentTextStyle,
      title: Text(title),
      content: content == null ? null : Text(content),
      actions: [
        SemanticAction(
          identifier: confirmDialogNoButtonId,
          child: TextButton(
            key: confirmDialogNoButtonKey,
            onPressed: () => Navigator.of(context).pop(false),
            style: style.activeButtonStyle1,
            child: Text(context.l10n.alertDialogActions_no),
          ),
        ),
        SemanticAction(
          identifier: confirmDialogYesButtonId,
          child: TextButton(
            key: confirmDialogYesButtonKey,
            onPressed: () => Navigator.of(context).pop(true),
            style: dangerous ? style.activeButtonStyle2 : style.defaultButtonStyle,
            child: Text(confirmLabel ?? context.l10n.alertDialogActions_yes),
          ),
        ),
      ],
    );
  }
}
