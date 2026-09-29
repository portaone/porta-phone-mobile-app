import 'package:material_ui/material_ui.dart';

import 'package:logging/logging.dart';

import 'package:webtrit_phone/theme/extension/extension.dart';
import 'package:webtrit_phone/theme/factory/styles/call_center_screen_style_factory.dart';
import 'package:webtrit_phone/theme/factory/styles/conversations_screen_style_factory.dart';
import 'package:webtrit_phone/theme/factory/styles/embedded_screen_style_factory.dart';
import 'package:webtrit_phone/theme/factory/styles/favorites_screen_style_factory.dart';
import 'package:webtrit_phone/theme/factory/styles/recents_screen_style_factory.dart';
import 'package:webtrit_phone/theme/factory/styles/system_notifications_screen_style_factory.dart';
import 'package:webtrit_phone/theme/factory/styles/voicemail_screen_style_factory.dart';

import './styles/styles.dart';
import '../models/models.dart';

import 'theme_data/theme_data.dart';

final _logger = Logger('ThemeStyleFactoryProvider');

// TODO(Serdun): Decompose correctly common widget styles configurations from the page styles configurations
class ThemeStyleFactoryProvider {
  ThemeStyleFactoryProvider({
    required this.colorScheme,
    required this.widgetConfig,
    required this.pageConfig,
    required this.seedThemeData,
  }) {
    defaultTextTheme = TextThemeDataFactory(colorScheme, widgetConfig.fonts, seedThemeData).create();
  }

  /// The color scheme used as a basis for all themed components.
  final ColorScheme colorScheme;

  /// Configuration for common widget styles across the application.
  final ThemeWidgetConfig widgetConfig;

  /// Configuration for page-specific styles.
  final ThemePageConfig pageConfig;

  /// The seed theme data used to inherit base styles.
  final ThemeData seedThemeData;

  /// The default text theme derived from the color scheme and widget configuration.
  late final TextTheme defaultTextTheme;

  /// The pages as the style factories read them: a page whose bar tint the
  /// theme leaves unset gets one built from the colour scheme.
  ///
  /// A theme from the configurator sets no page tint at all, and one built into
  /// the app sets the same tint on every page, so without this the screens
  /// either all went without a tint or took it from wherever the code held its
  /// own. The number history is left out: its bar is chrome-less on purpose.
  late final ThemePageConfig _pages = _withSchemeTints(pageConfig);

  ThemePageConfig _withSchemeTints(ThemePageConfig p) {
    BlurredSurfaceConfig? tint(BlurredSurfaceConfig? own, AppBarConfig? pageBar) => own ?? _schemeTint(pageBar);
    return p.copyWith(
      about: p.about.copyWith(appBarBlurredSurface: tint(p.about.appBarBlurredSurface, p.about.appBarStyle)),
      keypad: p.keypad.copyWith(appBarBlurredSurface: tint(p.keypad.appBarBlurredSurface, p.keypad.appBarStyle)),
      settings: p.settings.copyWith(
        appBarBlurredSurface: tint(p.settings.appBarBlurredSurface, p.settings.appBarStyle),
      ),
      contacts: p.contacts.copyWith(
        appBarBlurredSurface: tint(p.contacts.appBarBlurredSurface, p.contacts.appBarStyle),
      ),
      embedded: p.embedded.copyWith(
        appBarBlurredSurface: tint(p.embedded.appBarBlurredSurface, p.embedded.appBarStyle),
      ),
      favorites: p.favorites.copyWith(
        appBarBlurredSurface: tint(p.favorites.appBarBlurredSurface, p.favorites.appBarStyle),
      ),
      conversations: p.conversations.copyWith(
        appBarBlurredSurface: tint(p.conversations.appBarBlurredSurface, p.conversations.appBarStyle),
      ),
      recents: p.recents.copyWith(appBarBlurredSurface: tint(p.recents.appBarBlurredSurface, p.recents.appBarStyle)),
      voicemail: p.voicemail.copyWith(
        appBarBlurredSurface: tint(p.voicemail.appBarBlurredSurface, p.voicemail.appBarStyle),
      ),
      callCenter: p.callCenter.copyWith(
        appBarBlurredSurface: tint(p.callCenter.appBarBlurredSurface, p.callCenter.appBarStyle),
      ),
      systemNotifications: p.systemNotifications.copyWith(
        appBarBlurredSurface: tint(p.systemNotifications.appBarBlurredSurface, p.systemNotifications.appBarStyle),
      ),
    );
  }

  /// The tint for a page the theme gives none: the surface at the opacity the
  /// shipped pages use, so the content under a transparent bar stays behind it.
  ///
  /// None for a bar with a colour of its own - a translucent one shows the
  /// brand's colour, as configured, and an opaque one has nothing to blur.
  BlurredSurfaceConfig? _schemeTint(AppBarConfig? pageBar) {
    final barColor = pageBar?.backgroundColor ?? widgetConfig.bar.appBarConfig.backgroundColor;
    if (barColor != null && barColor.toColor().a > 0) return null;
    return BlurredSurfaceConfig(
      color: colorScheme.surface.withValues(alpha: 0x96 / 255).toCSSColorString(),
      sigmaX: 10,
      sigmaY: 10,
    );
  }

  List<ThemeExtension> createThemeExtensions() {
    final defaultFontFamily = defaultTextTheme.bodyMedium?.fontFamily;

    _logger.finer('Default font family: $defaultFontFamily');

    // Page schema
    final loginPageScheme = _pages.login;
    final callPageScheme = _pages.dialing;

    // Widget images config
    final imageAssetsConfig = widgetConfig.imageAssets;

    // Other widgets config
    final appIconConfig = imageAssetsConfig.appIcon;
    final confirmDialog = widgetConfig.dialog.confirmDialog;
    final snackBar = widgetConfig.dialog.snackBar;
    final callStatuses = widgetConfig.statuses.callStatuses;
    final registrationStatuses = widgetConfig.statuses.registrationStatuses;
    final elevatedButton = widgetConfig.button.primaryElevatedButton;
    final groupTitleListTile = widgetConfig.group?.groupTitleListTile;
    final linkify = widgetConfig.text.linkify;

    // Specific widget styles
    final appIconStylesProvider = AppIconStyleFactory(colorScheme, appIconConfig);
    final confirmDialogStylesProvider = ConfirmDialogStyleFactory(colorScheme, confirmDialog, defaultFontFamily);
    final inputDecorationStyleFactory = InputDecorationStyleFactory(colorScheme);
    final callStatusStyleFactory = CallStatusStyleFactory(colorScheme, callStatuses);
    final elevatedButtonStyleFactory = ElevatedButtonStyleFactory(colorScheme, elevatedButton, defaultFontFamily);
    final linkifyStyleFactory = LinkifyStyleFactory(colorScheme, linkify);
    final outlinedButtonStyleFactory = OutlinedButtonStyleFactory(colorScheme);
    final registrationStatusStyleFactory = RegisteredStatusStyleFactory(colorScheme, registrationStatuses);
    final snackBarStyleFactory = SnackBarStyleFactory(colorScheme, snackBar);
    final groupTitleListStyleFactory = GroupTitleListStyleFactory(colorScheme, groupTitleListTile, defaultFontFamily);
    final loginModeSelectStyleFactory = LoginModeSelectScreenStyleFactory(
      loginPageScheme.modeSelect,
      colorScheme,
      defaultFontFamily,
      appBarTheme: _pageAppBarThemeWithDefault(
        loginPageScheme.modeSelect.appBarStyle,
        const AppBarConfig(backgroundColor: '#00000000'),
      ),
    );
    final leadingAvatarStyleFactory = LeadingAvatarStyleFactory(
      colorScheme,
      widgetConfig.imageAssets.leadingAvatarStyle,
      defaultFontFamily,
    );
    final keypadStyleFactory = KeypadStyleFactory(
      colorScheme,
      defaultFontFamily,
      config: null,
      textTheme: defaultTextTheme,
    );
    final embeddedRequestErrorDialogFactory = EmbeddedRequestErrorDialogFactory(imageAssetsConfig);

    // Screen-specific styles
    final aboutScreenStyleFactory = AboutScreenStyleFactory(
      _pages.about,
      appBarTheme: _pageAppBarTheme(_pages.about.appBarStyle),
    );
    final callScreenStyleFactory = CallScreenStyleFactory(colorScheme, callPageScheme, defaultFontFamily);
    final keypadScreenStyleFactory = KeypadScreenStyleFactory(
      colorScheme,
      defaultFontFamily,
      config: _pages.keypad,
      textTheme: defaultTextTheme,
      appBarTheme: _pageAppBarTheme(_pages.keypad.appBarStyle),
    );
    final loginOtpSigninVerifyScreenStyleFactory = LoginOtpSigninVerifyScreenStyleFactory(
      colorScheme,
      loginPageScheme.otpSigninVerify,
    );
    final loginSignupVerifyScreenStyleFactory = LoginSignupVerifyScreenStyleFactory(
      colorScheme,
      loginPageScheme.signupVerify,
    );
    final loginSwitchScreenStyleFactory = LoginSwitchScreenStyleFactory(
      loginPageScheme.switchPage,
      colorScheme,
      defaultFontFamily,
      appBarTheme: _pageAppBarThemeWithDefault(
        loginPageScheme.switchPage.appBarStyle,
        const AppBarConfig(backgroundColor: '#00000000'),
      ),
    );
    final loginOtpSigninPageStyleFactory = LoginOtpSigninPageStyleFactory(
      colorScheme,
      defaultFontFamily,
      config: loginPageScheme.otpSignin,
      textTheme: defaultTextTheme,
    );
    final loginPasswordSigninPageStyleFactory = LoginPasswordSigninPageStyleFactory(
      colorScheme,
      defaultFontFamily,
      config: loginPageScheme.passwordSignin,
      textTheme: defaultTextTheme,
    );
    final settingsScreenStyleFactory = SettingsScreenStyleFactory(
      colorScheme,
      _pages.settings,
      defaultFontFamily,
      appBarTheme: _pageAppBarTheme(_pages.settings.appBarStyle),
    );
    final contactsScreenStyleFactory = ContactsScreenStyleFactory(
      colorScheme,
      _pages.contacts,
      appBarTheme: _pageAppBarTheme(_pages.contacts.appBarStyle),
    );
    final recentsScreenStyleFactory = RecentsScreenStyleFactory(
      colorScheme,
      _pages.recents,
      appBarTheme: _pageAppBarTheme(_pages.recents.appBarStyle),
    );
    final favoritesScreenStyleFactory = FavoritesScreenStyleFactory(
      colorScheme,
      _pages.favorites,
      appBarTheme: _pageAppBarTheme(_pages.favorites.appBarStyle),
    );
    final conversationsScreenStyleFactory = ConversationsScreenStyleFactory(
      colorScheme,
      _pages.conversations,
      appBarTheme: _pageAppBarTheme(_pages.conversations.appBarStyle),
    );
    final voicemailScreenStyleFactory = VoicemailScreenStyleFactory(
      colorScheme,
      _pages.voicemail,
      appBarTheme: _pageAppBarTheme(_pages.voicemail.appBarStyle),
    );
    final callCenterScreenStyleFactory = CallCenterScreenStyleFactory(
      colorScheme,
      _pages.callCenter,
      appBarTheme: _pageAppBarTheme(_pages.callCenter.appBarStyle),
    );
    final systemNotificationsScreenStyleFactory = SystemNotificationsScreenStyleFactory(
      colorScheme,
      _pages.systemNotifications,
      appBarTheme: _pageAppBarTheme(_pages.systemNotifications.appBarStyle),
    );
    final embeddedScreenStyleFactory = EmbeddedScreenStyleFactory(
      colorScheme,
      _pages.embedded,
      appBarTheme: _pageAppBarTheme(_pages.embedded.appBarStyle),
    );
    final numberCdrsScreenStyleFactory = NumberCdrsScreenStyleFactory(
      colorScheme,
      _pages.numberCdrs,
      // A deliberately chrome-less screen: when the theme does not configure
      // this page's bar, default to a transparent one.
      appBarTheme: _pageAppBarThemeWithDefault(
        _pages.numberCdrs.appBarStyle,
        const AppBarConfig(backgroundColor: '#00000000'),
      ),
    );
    final loginCoreUrlAssignScreenStyleFactory = LoginCoreUrlAssignScreenStyleFactory(
      loginPageScheme.coreUrlAssign,
      colorScheme,
      appBarTheme: _pageAppBarThemeWithDefault(
        loginPageScheme.coreUrlAssign.appBarStyle,
        const AppBarConfig(backgroundColor: '#00000000'),
      ),
    );

    return <ThemeExtension?>[
      appIconStylesProvider.create(),
      confirmDialogStylesProvider.create(),
      inputDecorationStyleFactory.create(),
      callStatusStyleFactory.create(),
      elevatedButtonStyleFactory.create(),
      linkifyStyleFactory.create(),
      outlinedButtonStyleFactory.create(),
      registrationStatusStyleFactory.create(),
      snackBarStyleFactory.create(),
      groupTitleListStyleFactory.create(),
      loginModeSelectStyleFactory.create(),
      leadingAvatarStyleFactory.create(),
      keypadStyleFactory.create(),
      embeddedRequestErrorDialogFactory.create(),

      /// Screen-specific styles
      keypadScreenStyleFactory.create(),
      aboutScreenStyleFactory.create(),
      callScreenStyleFactory.create(),
      loginOtpSigninVerifyScreenStyleFactory.create(),
      loginSignupVerifyScreenStyleFactory.create(),
      loginSwitchScreenStyleFactory.create(),
      loginOtpSigninPageStyleFactory.create(),
      loginPasswordSigninPageStyleFactory.create(),
      settingsScreenStyleFactory.create(),
      contactsScreenStyleFactory.create(),
      recentsScreenStyleFactory.create(),
      favoritesScreenStyleFactory.create(),
      conversationsScreenStyleFactory.create(),
      voicemailScreenStyleFactory.create(),
      callCenterScreenStyleFactory.create(),
      systemNotificationsScreenStyleFactory.create(),
      embeddedScreenStyleFactory.create(),
      numberCdrsScreenStyleFactory.create(),
      loginCoreUrlAssignScreenStyleFactory.create(),
    ].nonNulls.toList();
  }

  AppBarTheme? _pageAppBarTheme(AppBarConfig? pageStyle) {
    if (pageStyle == null) return null;
    return AppBarThemeDataFactory(
      colorScheme,
      pageStyle.mergeOver(widgetConfig.bar.appBarConfig),
      defaultTextTheme.bodyMedium?.fontFamily,
    ).create();
  }

  /// Like [_pageAppBarTheme], but a screen's design default sits UNDER the
  /// page style, so a partial page override keeps the default's other fields.
  AppBarTheme? _pageAppBarThemeWithDefault(AppBarConfig? pageStyle, AppBarConfig designDefault) {
    return _pageAppBarTheme(pageStyle == null ? designDefault : pageStyle.mergeOver(designDefault));
  }

  ElevatedButtonThemeData createElevatedButtonThemeData() {
    return ElevatedButtonThemeDataFactory(colorScheme).create();
  }

  OutlinedButtonThemeData createOutlinedButtonThemeData() {
    return OutlinedButtonThemeFataFactory(colorScheme).create();
  }

  TextButtonThemeData createTextButtonThemeData() {
    return TextButtonThemeDataFactory(colorScheme).create();
  }

  SnackBarThemeData createSnackBarThemeData() {
    return SnackBarThemeDataFactory(colorScheme).create();
  }

  DialogThemeData createDialogThemeData() {
    return DialogThemeDataFactory(
      colorScheme,
      widgetConfig.dialog.theme,
      defaultTextTheme.bodyMedium?.fontFamily,
    ).create();
  }

  ListTileThemeData createListTileThemeData() {
    return ListTileThemeDataFactory(colorScheme).create();
  }

  BottomNavigationBarThemeData createBottomNavigationBarThemeData() {
    return BottomNavigationBarThemeDataFactory(
      colorScheme,
      widgetConfig.bar.bottomNavigationBar,
      defaultTextTheme.bodyMedium?.fontFamily,
    ).create();
  }

  TabBarThemeData createTabBarTheme() {
    return TabBarThemeDataFactory(
      colorScheme,
      widgetConfig.bar.tabBarConfig,
      defaultTextTheme.bodyMedium?.fontFamily,
    ).create();
  }

  AppBarTheme createAppBarTheme() {
    return AppBarThemeDataFactory(
      colorScheme,
      widgetConfig.bar.appBarConfig,
      defaultTextTheme.bodyMedium?.fontFamily,
    ).create();
  }

  InputDecorationTheme createInputDecorationTheme() {
    return InputDecorationThemeDataFactory(colorScheme, widgetConfig.input.primary).create();
  }

  TextSelectionThemeData createTextSelectionThemeData() {
    return TextSelectionThemeDataFactory(colorScheme, widgetConfig.text.selection).create();
  }

  ProgressIndicatorThemeData createProgressIndicatorThemeData() {
    return ProgressIndicatorThemeDataFactory(colorScheme).create();
  }
}
