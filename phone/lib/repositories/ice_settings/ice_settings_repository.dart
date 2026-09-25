import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/mappers/json/ice_settings_mapper.dart';
import 'package:webtrit_phone/models/ice_settings.dart';

abstract interface class IceSettingsRepository {
  IceSettings getIceSettings();

  /// The verification policy actually in force: this device's choice, or the
  /// value the deployment was built with when the device has made none.
  ///
  /// Kept here rather than at each call site so that the two consumers - the
  /// peer connection and the diagnostic screen - cannot drift apart and report
  /// different things about the same connection.
  TurnCertificateVerification resolveCertificateVerification(TurnCertificateVerification defaultValue);

  Future<void> setIceSettings(IceSettings settings);

  Future<void> clear();
}

class IceSettingsRepositoryPrefsImpl with IceSettingsJsonMapper implements IceSettingsRepository {
  IceSettingsRepositoryPrefsImpl(this._appPreferences);

  final AppPreferences _appPreferences;
  final _prefsKey = 'ice-settings';

  @override
  IceSettings getIceSettings() {
    final iceSettingsString = _appPreferences.getString(_prefsKey);
    if (iceSettingsString != null) {
      return iceSettingsFromJson(iceSettingsString);
    } else {
      return IceSettings.blank();
    }
  }

  @override
  TurnCertificateVerification resolveCertificateVerification(TurnCertificateVerification defaultValue) {
    return getIceSettings().certificateVerification ?? defaultValue;
  }

  @override
  Future<void> setIceSettings(IceSettings settings) {
    return _appPreferences.setString(_prefsKey, iceSettingsToJson(settings));
  }

  @override
  Future<void> clear() => _appPreferences.remove(_prefsKey);
}
