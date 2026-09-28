import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/models/models.dart';
import 'package:webtrit_phone/features/call_center/view/call_center_screen_styles.dart';
import 'package:webtrit_phone/features/system_notifications/view/system_notifications_screen_styles.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen_styles.dart';
import 'package:webtrit_phone/theme/factory/theme_style_factory_provider.dart';
import 'package:webtrit_phone/widgets/blurred_surface.dart';

/// The voicemail, call center and system notifications screens take their app
/// bar tint from a page of their own, the way the main screens do. Before, the
/// tint was fixed in code, so a brand that changed or removed it on the pages
/// saw these screens stay as they were.
void main() {
  List<ThemeExtension<dynamic>> extensionsFor(ThemePageConfig pages) => ThemeStyleFactoryProvider(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
    widgetConfig: const ThemeWidgetConfig(),
    pageConfig: pages,
    seedThemeData: ThemeData.light(),
  ).createThemeExtensions();

  const tint = BlurredSurfaceConfig(color: '#96123456', sigmaX: 7, sigmaY: 7);
  const expected = Color(0x96123456);

  BlurredSurfaceStyle? voicemail(List<ThemeExtension<dynamic>> e) =>
      e.whereType<VoicemailScreenStyles>().single.primary?.appBarBlurredSurface;
  BlurredSurfaceStyle? callCenter(List<ThemeExtension<dynamic>> e) =>
      e.whereType<CallCenterScreenStyles>().single.primary?.appBarBlurredSurface;
  BlurredSurfaceStyle? notifications(List<ThemeExtension<dynamic>> e) =>
      e.whereType<SystemNotificationsScreenStyles>().single.primary?.appBarBlurredSurface;

  test('each page hands its screen the tint the theme gives it', () {
    final e = extensionsFor(
      const ThemePageConfig(
        voicemail: VoicemailPageConfig(appBarBlurredSurface: tint),
        callCenter: CallCenterPageConfig(appBarBlurredSurface: tint),
        systemNotifications: SystemNotificationsPageConfig(appBarBlurredSurface: tint),
      ),
    );

    for (final style in [voicemail(e), callCenter(e), notifications(e)]) {
      expect(style?.color, expected);
      expect(style?.sigmaX, 7);
    }
  });

  test('a page the theme does not carry hands over no tint', () {
    // Themes made before these pages existed; the screen then decides through
    // BlurredSurface.forPage, like every other page without a tint.
    final e = extensionsFor(const ThemePageConfig());

    expect(voicemail(e), isNull);
    expect(callCenter(e), isNull);
    expect(notifications(e), isNull);
  });

  test('the pages read from JSON under their own keys', () {
    final pages = ThemePageConfig.fromJson({
      'voicemail': {'appBarBlurredSurface': tint.toJson()},
      'callCenter': {'appBarBlurredSurface': tint.toJson()},
      'systemNotifications': {'appBarBlurredSurface': tint.toJson()},
    });

    expect(pages.voicemail.appBarBlurredSurface, tint);
    expect(pages.callCenter.appBarBlurredSurface, tint);
    expect(pages.systemNotifications.appBarBlurredSurface, tint);
  });
}
