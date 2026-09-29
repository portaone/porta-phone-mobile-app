import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/models/models.dart';
import 'package:webtrit_phone/features/call_center/view/call_center_screen_styles.dart';
import 'package:webtrit_phone/features/cdrs/features/number_cdrs_log/view/number_cdrs_screen_styles.dart';
import 'package:webtrit_phone/features/keypad/view/keypad_screen_styles.dart';
import 'package:webtrit_phone/features/messaging/features/conversations/view/conversations_screen_styles.dart';
import 'package:webtrit_phone/features/system_notifications/view/system_notifications_screen_styles.dart';
import 'package:webtrit_phone/features/voicemail/view/voicemail_screen_styles.dart';
import 'package:webtrit_phone/theme/factory/theme_style_factory_provider.dart';
import 'package:webtrit_phone/widgets/blurred_surface.dart';

/// Where a screen's app bar tint comes from.
///
/// Every page takes it from the theme, and a page the theme leaves without one
/// gets it from the colour scheme - unless the bar has a colour of its own,
/// which is then shown as configured. The voicemail, call center and system
/// notifications screens used to hold a tint of their own in code, so a brand
/// that changed the pages saw them stay as they were.
void main() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8));
  final schemeTint = scheme.surface.withValues(alpha: 0x96 / 255);

  List<ThemeExtension<dynamic>> extensionsFor(ThemePageConfig pages, {String? bar}) => ThemeStyleFactoryProvider(
    colorScheme: scheme,
    widgetConfig: ThemeWidgetConfig(
      bar: BarWidgetConfig(appBarConfig: AppBarConfig(backgroundColor: bar)),
    ),
    pageConfig: pages,
    seedThemeData: ThemeData.light(),
  ).createThemeExtensions();

  Map<String, BlurredSurfaceStyle?> tints(List<ThemeExtension<dynamic>> e) => {
    'keypad': e.whereType<KeypadScreenStyles>().single.primary?.appBarBlurredSurface,
    'conversations': e.whereType<ConversationsScreenStyles>().single.primary?.appBarBlurredSurface,
    'voicemail': e.whereType<VoicemailScreenStyles>().single.primary?.appBarBlurredSurface,
    'callCenter': e.whereType<CallCenterScreenStyles>().single.primary?.appBarBlurredSurface,
    'systemNotifications': e.whereType<SystemNotificationsScreenStyles>().single.primary?.appBarBlurredSurface,
  };

  const tint = BlurredSurfaceConfig(color: '#96123456', sigmaX: 7, sigmaY: 7);

  test('a tint the theme gives a page is the one its screen gets', () {
    final e = extensionsFor(
      const ThemePageConfig(
        keypad: KeypadPageConfig(appBarBlurredSurface: tint),
        conversations: ConversationsPageConfig(appBarBlurredSurface: tint),
        voicemail: VoicemailPageConfig(appBarBlurredSurface: tint),
        callCenter: CallCenterPageConfig(appBarBlurredSurface: tint),
        systemNotifications: SystemNotificationsPageConfig(appBarBlurredSurface: tint),
      ),
      bar: '#CA50173F',
    );

    for (final MapEntry(:key, :value) in tints(e).entries) {
      expect(value?.color, const Color(0x96123456), reason: key);
      expect(value?.sigmaX, 7, reason: key);
    }
  });

  test('a page with no tint, under a bar with no colour, takes it from the colour scheme', () {
    // The usual theme from the configurator: no page tint, no bar colour.
    // Screens draw such a bar transparent; the tint keeps content behind it.
    for (final bar in [null, '#00000000']) {
      for (final MapEntry(:key, :value) in tints(extensionsFor(const ThemePageConfig(), bar: bar)).entries) {
        expect(value?.color, schemeTint, reason: '$key under bar $bar');
      }
    }
  });

  test('a bar with a colour of its own is left to show it', () {
    for (final bar in ['#CA50173F', '#FF50173F']) {
      for (final MapEntry(:key, :value) in tints(extensionsFor(const ThemePageConfig(), bar: bar)).entries) {
        expect(value, isNull, reason: '$key under bar $bar');
      }
    }
  });

  test("a page's own bar colour decides over the theme's", () {
    final e = extensionsFor(
      const ThemePageConfig(
        voicemail: VoicemailPageConfig(appBarStyle: AppBarConfig(backgroundColor: '#CA50173F')),
      ),
    );

    expect(tints(e)['voicemail'], isNull);
    expect(tints(e)['keypad']?.color, schemeTint);
  });

  test('the chrome-less number history gets no tint made up for it', () {
    final e = extensionsFor(const ThemePageConfig());

    expect(e.whereType<NumberCdrsScreenStyles>().single.primary?.appBarBlurredSurface, isNull);
  });

  test('the new pages read from JSON under their own keys', () {
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
