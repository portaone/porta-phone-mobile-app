import 'package:webtrit_phone/data/app_preferences.dart';
import 'package:webtrit_phone/models/feature_access/call_audio_config.dart';

/// What this device chose about a call's audio output, over what the
/// deployment was built with.
abstract interface class CallAudioSettingsRepository {
  /// This device's choice, or null when it has made none.
  bool? getSpeakerOnMinimize();

  /// The value actually in force: this device's choice where the deployment
  /// offers the control, and the value it was built with otherwise - so a
  /// choice stored while the control was offered stops applying once a later
  /// build withdraws it.
  bool resolveSpeakerOnMinimize(CallAudioConfig config);

  /// Null puts the device back to following the deployment.
  Future<void> setSpeakerOnMinimize(bool? value);

  Future<void> clear();
}

class CallAudioSettingsRepositoryPrefsImpl implements CallAudioSettingsRepository {
  CallAudioSettingsRepositoryPrefsImpl(this._appPreferences);

  final AppPreferences _appPreferences;
  final _speakerOnMinimizeKey = 'call-audio-speaker-on-minimize';

  @override
  bool? getSpeakerOnMinimize() => _appPreferences.getBool(_speakerOnMinimizeKey);

  @override
  bool resolveSpeakerOnMinimize(CallAudioConfig config) {
    if (!config.speakerOnMinimizeConfigurable) return config.speakerOnMinimize;
    return getSpeakerOnMinimize() ?? config.speakerOnMinimize;
  }

  @override
  Future<void> setSpeakerOnMinimize(bool? value) {
    if (value == null) return clear();
    return _appPreferences.setBool(_speakerOnMinimizeKey, value);
  }

  @override
  Future<void> clear() => _appPreferences.remove(_speakerOnMinimizeKey);
}
