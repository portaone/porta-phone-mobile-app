import 'dart:convert';

import 'package:webtrit_phone/data/app_preferences.dart';

import 'remote_logging_config.dart';

/// Where the last [RemoteLoggingConfig] is kept between runs and between the
/// app and its background isolates.
abstract interface class RemoteLoggingConfigStore {
  /// The stored settings, or null when the app has never heard from a core.
  RemoteLoggingConfig? read();

  Future<void> write(RemoteLoggingConfig config);
}

/// [RemoteLoggingConfigStore] in shared preferences.
///
/// The key is outside what the logout cleanup removes, so the settings stay
/// after the user signs out.
class RemoteLoggingConfigPrefsStore implements RemoteLoggingConfigStore {
  const RemoteLoggingConfigPrefsStore(this._appPreferences);

  static const key = 'remote-logging-config';

  final AppPreferences _appPreferences;

  @override
  RemoteLoggingConfig? read() {
    final source = _appPreferences.getString(key);
    return source != null ? RemoteLoggingConfig.tryFromJson(source) : null;
  }

  @override
  Future<void> write(RemoteLoggingConfig config) => _appPreferences.setString(key, jsonEncode(config.toJson()));
}
