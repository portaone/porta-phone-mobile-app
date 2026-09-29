import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show GlobalMaterialLocalizations;

import 'package:webtrit_phone/l10n/app_localizations.g.mapper.dart';

import 'app_localizations.g.dart';
export 'app_localizations.g.dart';

export 'default_error_l10n.dart';

/// The delegates every app root and test harness registers.
///
/// Not [AppLocalizations.localizationsDelegates]: gen-l10n still emits the
/// flutter_localizations delegates, which register the framework's
/// MaterialLocalizations - a type material_ui widgets never look up.
const List<LocalizationsDelegate<dynamic>> appLocalizationsDelegates = [
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Returns a localized string for the given [translationKey], or a fallback.
  ///
  /// If the key exists in ARB, the localized value is returned. If the key is
  /// null, empty, missing, or cannot be parsed, the [fallback] is used instead.
  ///
  /// When [fallback] is not provided, null or empty keys return an empty string,
  /// and invalid keys return the original [translationKey].
  ///
  /// Supports optional [arguments] passed to formatted localization entries
  String parseL10n(String? translationKey, {List<Object>? arguments, String? fallback}) {
    if (translationKey == null || translationKey.isEmpty) {
      return fallback ?? '';
    }

    try {
      final value = l10n.parseL10n(translationKey, arguments: arguments);
      return value ?? fallback ?? translationKey;
    } catch (_) {
      return fallback ?? translationKey;
    }
  }
}
