import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';

/// The arrangement every sign-in form shares - OTP, password, sign-up and
/// their code screens.
///
/// A form hands over its parts: [content] (descriptions and fields, with the
/// gaps between them), an optional [secondary] action such as Resend, and
/// [primary], which builds the form's main button over the style the
/// arrangement lays on top of the theme's.
///
/// The parts stand in a column with the actions at the bottom, as the forms
/// always did.
class LoginFormLayout extends StatelessWidget {
  const LoginFormLayout({
    super.key,
    required this.content,
    required this.primary,
    this.secondary,
    this.wrapHandsetColumn,
  });

  final List<Widget> content;
  final Widget? secondary;

  /// Builds the main button; [overlay] is the arrangement's size and shape,
  /// to merge over the theme's style, null on a phone.
  final Widget Function(ButtonStyle? overlay) primary;

  /// Wraps the phone column, for a form that puts it in a [SafeArea].
  final Widget Function(Widget column)? wrapHandsetColumn;

  @override
  Widget build(BuildContext context) {
    return _Handset(layout: this);
  }
}

class _Handset extends StatelessWidget {
  const _Handset({required this.layout});

  final LoginFormLayout layout;

  @override
  Widget build(BuildContext context) {
    final secondary = layout.secondary;
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...layout.content,
        const Spacer(),
        const SizedBox(height: kInset),
        if (secondary != null) ...[secondary, const SizedBox(height: kInset / 4)],
        layout.primary(null),
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(kInset, kInset / 2, kInset, kInset),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: layout.wrapHandsetColumn?.call(column) ?? column,
    );
  }
}
