import 'package:material_ui/material_ui.dart';

import 'package:webtrit_phone/app/constants.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The arrangement every sign-in form shares - OTP, password, sign-up and
/// their code screens - and the one place a form decides on the device class.
///
/// A form hands over its parts: [content] (descriptions and fields, with the
/// gaps between them), an optional [secondary] action such as Resend, and
/// [primary], which builds the form's main button with the style the layout
/// hands it: the theme's [buttonStyle], with the arrangement's laid over it.
///
/// On a phone the parts stand in a column with the actions at the bottom, as
/// the forms always did. On a watch the content scrolls in a short column,
/// the secondary action at its end, and the primary action is the edge button
/// along the bottom of the face, with the column fading out above it.
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

  /// Builds the main button with [style]: [buttonStyle] with whatever the
  /// arrangement lays over it.
  final Widget Function(ButtonStyle? style) primary;

  /// The theme's style of the main button.
  final ButtonStyle? buttonStyle;

  /// Wraps the phone column, for a form that puts it in a [SafeArea].
  final Widget Function(Widget column)? wrapHandsetColumn;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      handset: (context) => _Handset(layout: this),
      watch: (context) => _Watch(layout: this),
    );
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
        layout.primary(layout.buttonStyle),
      ],
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(kInset, kInset / 2, kInset, kInset),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: layout.wrapHandsetColumn?.call(column) ?? column,
    );
  }
}

class _Watch extends StatelessWidget {
  const _Watch({required this.layout});

  final LoginFormLayout layout;

  @override
  Widget build(BuildContext context) {
    return WatchActionLayout(
      content: layout.content,
      secondary: layout.secondary,
      primary: (overlay) => layout.primary(overlay.merge(layout.buttonStyle)),
    );
  }
}
