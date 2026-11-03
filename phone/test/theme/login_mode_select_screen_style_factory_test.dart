import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/models/models.dart';
import 'package:webtrit_phone/theme/factory/styles/login_mode_select_screen_style_factory.dart';

/// Which colour an action that sits on the landing's page gets. The greeting
/// is not always a guide: on a plate of its own its colour answers the plate.
void main() {
  final colors = ColorScheme.fromSeed(seedColor: Colors.blue);

  Color secondaryActionColor(LoginModeSelectPageConfig config) {
    return LoginModeSelectScreenStyleFactory(config, colors, null).create().primary!.secondaryActionColor!;
  }

  const white = TextStyleConfig(color: '#FFFFFF');
  const whiteOnPlate = TextStyleConfig(color: '#FFFFFF', backgroundColor: '#CC123752', backgroundBorderRadius: 8);
  const whiteOnBareColor = TextStyleConfig(color: '#FFFFFF', backgroundColor: '#CC123752');

  test('without a plate the greeting colour is the one set against the page', () {
    expect(secondaryActionColor(const LoginModeSelectPageConfig(greetingTextStyle: white)), const Color(0xFFFFFFFF));
  });

  test('with no greeting style it is the default greeting colour', () {
    expect(secondaryActionColor(const LoginModeSelectPageConfig()), colors.onPrimary);
  });

  for (final greeting in [whiteOnPlate, whiteOnBareColor]) {
    test('on a plate it answers a light page, not the plate', () {
      final color = secondaryActionColor(
        LoginModeSelectPageConfig(
          greetingTextStyle: greeting,
          background: const PageBackground.solid(color: '#FFFFFF'),
        ),
      );
      expect(color, colors.onSurface);
    });

    test('on a plate it answers a dark page, not the plate', () {
      final color = secondaryActionColor(
        LoginModeSelectPageConfig(
          greetingTextStyle: greeting,
          background: const PageBackground.solid(color: '#101418'),
        ),
      );
      expect(color, colors.surface);
    });
  }

  test('on a plate over an image it is the colour for the page', () {
    final color = secondaryActionColor(
      const LoginModeSelectPageConfig(
        greetingTextStyle: whiteOnPlate,
        background: PageBackground.image(imageUrl: 'https://example.com/a.png'),
      ),
    );
    expect(color, colors.onPrimary);
  });
}
