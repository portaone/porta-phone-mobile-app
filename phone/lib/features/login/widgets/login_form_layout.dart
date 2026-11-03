import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';

/// The layout every sign-in form shares - OTP, password, sign-up and
/// their code screens.
///
/// A form hands over its parts: [content] (descriptions and fields, with the
/// gaps between them), an optional [secondary] action such as Resend, and
/// [primary], which builds the form's main button with the style the layout
/// hands it, the theme's [buttonStyle].
///
/// The parts stand in a column with the actions at the bottom, as the forms
/// always did.
class LoginFormLayout extends StatelessWidget {
  const LoginFormLayout({
    super.key,
    required this.content,
    required this.primary,
    required this.buttonStyle,
    this.secondary,
    this.wrapHandsetColumn,
  });

  /// The form's descriptions and fields, with the gaps between them.
  final List<Widget> content;

  /// A second action under the content, such as Resend.
  final Widget? secondary;

  /// Builds the main button with [style], the theme's [buttonStyle].
  final Widget Function(ButtonStyle? style) primary;

  /// The theme's style of the main button.
  final ButtonStyle? buttonStyle;

  /// Wraps the phone column, for a form that puts it in a [SafeArea].
  final Widget Function(Widget column)? wrapHandsetColumn;

  @override
  Widget build(BuildContext context) {
    final secondary = this.secondary;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...content,
        const Spacer(),
        const SizedBox(height: kInset),
        if (secondary != null) ...[secondary, const SizedBox(height: kInset / 4)],
        primary(buttonStyle),
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(kInset, kInset / 2, kInset, kInset),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: wrapHandsetColumn?.call(column) ?? column,
    );
  }
}
