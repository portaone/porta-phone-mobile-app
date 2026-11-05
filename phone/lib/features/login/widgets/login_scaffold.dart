import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// The scaffold of the sign-in screens, themed from the screen's style:
/// theme override, bar theme, status bar.
class LoginScaffold extends StatelessWidget {
  /// The phone's: the body scrolls as a page under [appBar].
  const LoginScaffold({
    super.key,
    this.appBar,
    this.body,
    this.contentThemeOverride,
    this.applyToAppBar,
    this.appBarTheme,
    this.systemUiOverlayStyle,
  }) : _watch = false;

  /// A watch face's: no bar, the body is the whole face and scrolls itself.
  const LoginScaffold.watch({
    super.key,
    this.body,
    this.contentThemeOverride,
    this.applyToAppBar,
    this.appBarTheme,
    this.systemUiOverlayStyle,
  }) : appBar = null,
       _watch = true;

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final ThemeMode? contentThemeOverride;
  final bool? applyToAppBar;
  final AppBarTheme? appBarTheme;
  final SystemUiOverlayStyle? systemUiOverlayStyle;
  final bool _watch;

  @override
  Widget build(BuildContext context) {
    final overlayStyle = systemUiOverlayStyle ?? systemOverlayStyleOf(Theme.of(context).brightness);
    if (_watch) {
      return ThemedScaffold(
        contentThemeOverride: contentThemeOverride,
        applyToAppBar: applyToAppBar ?? true,
        appBarTheme: appBarTheme,
        resizeToAvoidBottomInset: watchResizesForKeyboard,
        body: AnnotatedRegion<SystemUiOverlayStyle>(value: overlayStyle, child: body ?? const SizedBox.shrink()),
      );
    }
    return ThemedScaffold(
      contentThemeOverride: contentThemeOverride,
      applyToAppBar: applyToAppBar ?? true,
      appBarTheme: appBarTheme,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: LayoutBuilder(
          builder: (context, viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
                child: IntrinsicHeight(child: body),
              ),
            );
          },
        ),
      ),
    );
  }
}
