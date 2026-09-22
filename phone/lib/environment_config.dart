// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:logging/logging.dart';

final _logger = Logger('EnvRegistry');

/// Application configuration sourced from `--dart-define` values.
///
/// Each value is read through the shared [_env] registry, which resolves a
/// runtime override (see [applyOverrides]) first and falls back to the
/// compile-time `*.fromEnvironment` default otherwise. Consumers (the getters
/// below, and their callers) never deal with the override map directly - they
/// only declare a key and a compile-time default and ask the registry for the
/// value. This lets embedders such as the theme configurator's realtime preview
/// inject the whole dart-define set at runtime, while standalone builds behave
/// exactly as before (no overrides applied).
///
/// The `*__NAME` members stay compile-time constants because they are the
/// dart-define keys, not values, and are used as registry/override keys.
class EnvironmentConfig {
  EnvironmentConfig._();

  /// Shared resolver: override-first, compile-time-default fallback.
  static final EnvRegistry _env = EnvRegistry();

  /// Replaces the runtime override set consulted by every value getter.
  ///
  /// Keys are the `WEBTRIT_APP_*` dart-define names (the `*__NAME` members).
  /// Must be applied before any consumer (e.g. `bootstrap()`) reads a value.
  /// Pass an empty map (or call [clearOverrides]) to fall back to the
  /// compile-time defines.
  static void applyOverrides(Map<String, String> overrides) => _env.apply(overrides);

  /// Drops all runtime overrides, restoring the compile-time dart-define values.
  static void clearOverrides() => _env.clear();

  /// Whether a runtime override is currently set for [name].
  static bool hasOverride(String name) => _env.has(name);

  /// Resolves a polling interval in seconds. A non-positive override would
  /// produce a zero/negative [Duration] (a request storm or assertion), so it is
  /// rejected in favour of the compile-time default.
  static int _pollingSeconds(String name, int compileTime) {
    final seconds = _env.integer(name, compileTime);
    return seconds > 0 ? seconds : compileTime;
  }

  static const DATABASE_LOG_STATEMENTS__NAME = 'WEBTRIT_APP_DATABASE_LOG_STATEMENTS';
  static bool get DATABASE_LOG_STATEMENTS => _env.boolean(
    DATABASE_LOG_STATEMENTS__NAME,
    const bool.fromEnvironment(DATABASE_LOG_STATEMENTS__NAME, defaultValue: false),
  );

  static const CORE_URL__NAME = 'WEBTRIT_APP_CORE_URL';
  static const String? _CORE_URL_ENV = bool.hasEnvironment(CORE_URL__NAME)
      ? String.fromEnvironment(CORE_URL__NAME)
      : null;
  static String? get CORE_URL => _env.stringOrNull(CORE_URL__NAME, _CORE_URL_ENV);

  static const DEMO_CORE_URL__NAME = 'WEBTRIT_APP_DEMO_CORE_URL';
  static String get DEMO_CORE_URL => _env.string(
    DEMO_CORE_URL__NAME,
    const String.fromEnvironment(DEMO_CORE_URL__NAME, defaultValue: 'http://localhost:4000'),
  );

  static const PREDEFINED_CORE_URLS__NAME = 'WEBTRIT_APP_PREDEFINED_CORE_URLS';
  static List<String> get PREDEFINED_CORE_URLS {
    final raw = _env.string(PREDEFINED_CORE_URLS__NAME, const String.fromEnvironment(PREDEFINED_CORE_URLS__NAME));
    return raw.split(';').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  }

  static const CORE_VERSION_CONSTRAINT__NAME = 'WEBTRIT_APP_CORE_VERSION_CONSTRAINT';
  static String get CORE_VERSION_CONSTRAINT => _env.string(
    CORE_VERSION_CONSTRAINT__NAME,
    const String.fromEnvironment(CORE_VERSION_CONSTRAINT__NAME, defaultValue: '>=0.7.0-alpha <2.0.0'),
  );

  static const APP_LINK_DOMAIN__NAME = 'WEBTRIT_APP_LINK_DOMAIN';

  /// Trimmed, because the build decides on the trimmed value whether to declare the App Links
  /// intent filter at all and which host it names. Comparing incoming links against an untrimmed
  /// value here would reject the very hosts the manifest was generated for.
  static String get APP_LINK_DOMAIN =>
      _env.string(APP_LINK_DOMAIN__NAME, const String.fromEnvironment(APP_LINK_DOMAIN__NAME, defaultValue: '')).trim();

  static const APP_NAME__NAME = 'WEBTRIT_APP_NAME';
  static String get APP_NAME =>
      _env.string(APP_NAME__NAME, const String.fromEnvironment(APP_NAME__NAME, defaultValue: 'PortaPhone'));

  // Web has no platform bundle identifier, so `packageInfo.packageName` resolves
  // to the pubspec project name on web, which the backend rejects with
  // `unconfigured_bundle_id`. This build-time override lets a web build send a
  // bundle_id that is registered on the server for the `web` app type.
  // TODO(web): the cleaner long-term fix is to register the web bundle_id on the
  // server (PortaOne/Core) for the `web` app type, so this client override is no
  // longer needed.
  static const WEB_BUNDLE_ID__NAME = 'WEBTRIT_APP_WEB_BUNDLE_ID';
  // An empty dart-define (key disabled or blanked) is treated as unset so the
  // resolver falls back to packageName and the bootstrap diagnostic fires.
  static String? get WEB_BUNDLE_ID {
    final raw = _env.string(WEB_BUNDLE_ID__NAME, const String.fromEnvironment(WEB_BUNDLE_ID__NAME));
    return raw == '' ? null : raw;
  }

  /// The bundle_id sent to the backend in session/autoprovision requests.
  ///
  /// On web there is no platform bundle id, so [WEB_BUNDLE_ID] (the
  /// WEBTRIT_APP_WEB_BUNDLE_ID dart-define) overrides [packageName] when set;
  /// otherwise it falls back to [packageName]. Native always uses [packageName].
  static String resolveBundleId(String packageName) => (kIsWeb ? WEB_BUNDLE_ID : null) ?? packageName;

  static const APP_ABOUT_URL__NAME = 'WEBTRIT_APP_ABOUT_URL';
  static const String? _APP_ABOUT_URL_ENV = bool.hasEnvironment(APP_ABOUT_URL__NAME)
      ? String.fromEnvironment(APP_ABOUT_URL__NAME)
      : null;
  static String? get APP_ABOUT_URL => _env.stringOrNull(APP_ABOUT_URL__NAME, _APP_ABOUT_URL_ENV);

  static const APP_CREDENTIALS_REQUEST_URL__NAME = 'WEBTRIT_APP_CREDENTIALS_REQUEST_URL';
  static const String? _APP_CREDENTIALS_REQUEST_URL_ENV = bool.hasEnvironment(APP_CREDENTIALS_REQUEST_URL__NAME)
      ? String.fromEnvironment(APP_CREDENTIALS_REQUEST_URL__NAME)
      : null;
  static String? get APP_CREDENTIALS_REQUEST_URL =>
      _env.stringOrNull(APP_CREDENTIALS_REQUEST_URL__NAME, _APP_CREDENTIALS_REQUEST_URL_ENV);

  static const SALES_EMAIL__NAME = 'WEBTRIT_APP_SALES_EMAIL';
  static String get SALES_EMAIL => _env.string(
    SALES_EMAIL__NAME,
    const String.fromEnvironment(SALES_EMAIL__NAME, defaultValue: 'sales@portaone.com'),
  );

  static const FCM_VAPID_KEY__NAME = 'WEBTRIT_APP_FCM_VAPID_KEY';
  static const String? _FCM_VAPID_KEY_ENV = bool.hasEnvironment(FCM_VAPID_KEY__NAME)
      ? String.fromEnvironment(FCM_VAPID_KEY__NAME)
      : null;
  static String? get FCM_VAPID_KEY => _env.stringOrNull(FCM_VAPID_KEY__NAME, _FCM_VAPID_KEY_ENV);

  // LOGZIO service-specific configuration.
  // If additional logging services are introduced, consider moving these to a separate logging configuration file.
  static const REMOTE_LOGZIO_LOGGING_URL__NAME = 'WEBTRIT_APP_REMOTE_LOGZIO_LOGGING_URL';
  static const String? _REMOTE_LOGZIO_LOGGING_URL_ENV = bool.hasEnvironment(REMOTE_LOGZIO_LOGGING_URL__NAME)
      ? String.fromEnvironment(REMOTE_LOGZIO_LOGGING_URL__NAME)
      : null;
  static String? get REMOTE_LOGZIO_LOGGING_URL =>
      _env.stringOrNull(REMOTE_LOGZIO_LOGGING_URL__NAME, _REMOTE_LOGZIO_LOGGING_URL_ENV);

  // LOGZIO service-specific configuration.
  // If additional logging services are introduced, consider moving these to a separate logging configuration file.
  static const REMOTE_LOGZIO_LOG_LEVEL__NAME = 'WEBTRIT_APP_REMOTE_LOGZIO_LOG_LEVEL';
  static String get REMOTE_LOGZIO_LOG_LEVEL => _env.string(
    REMOTE_LOGZIO_LOG_LEVEL__NAME,
    const String.fromEnvironment(REMOTE_LOGZIO_LOG_LEVEL__NAME, defaultValue: 'INFO'),
  );

  // LOGZIO service-specific configuration.
  // If additional logging services are introduced, consider moving these to a separate logging configuration file.
  static const REMOTE_LOGZIO_LOGGING_TOKEN__NAME = 'WEBTRIT_APP_REMOTE_LOGZIO_LOGGING_TOKEN';
  static const String? _REMOTE_LOGZIO_LOGGING_TOKEN_ENV = bool.hasEnvironment(REMOTE_LOGZIO_LOGGING_TOKEN__NAME)
      ? String.fromEnvironment(REMOTE_LOGZIO_LOGGING_TOKEN__NAME)
      : null;
  static String? get REMOTE_LOGZIO_LOGGING_TOKEN =>
      _env.stringOrNull(REMOTE_LOGZIO_LOGGING_TOKEN__NAME, _REMOTE_LOGZIO_LOGGING_TOKEN_ENV);

  // LOGZIO service-specific configuration.
  // If additional logging services are introduced, consider moving these to a separate logging configuration file.
  static const _REMOTE_LOGZIO_LOGGING_BUFFER_SIZE__KB = 0;
  static const REMOTE_LOGZIO_LOGGING_BUFFER_SIZE__NAME = 'WEBTRIT_APP_REMOTE_LOGZIO_LOGGING_BUFFER_SIZE';
  static int get REMOTE_LOGZIO_LOGGING_BUFFER_SIZE => _env.integer(
    REMOTE_LOGZIO_LOGGING_BUFFER_SIZE__NAME,
    int.tryParse(const String.fromEnvironment(REMOTE_LOGZIO_LOGGING_BUFFER_SIZE__NAME)) ??
        _REMOTE_LOGZIO_LOGGING_BUFFER_SIZE__KB,
  );

  // SMS-based incoming call trigger mechanism (fallback).
  // If enabled, the app listens for specially formatted incoming SMS messages to trigger incoming calls.
  static const CALL_TRIGGER_MECHANISM_SMS__NAME = 'WEBTRIT_CALL_TRIGGER_MECHANISM_SMS';
  static bool get CALL_TRIGGER_MECHANISM_SMS => _env.boolean(
    CALL_TRIGGER_MECHANISM_SMS__NAME,
    const bool.fromEnvironment(CALL_TRIGGER_MECHANISM_SMS__NAME, defaultValue: false),
  );

  // SMS-based incoming call trigger prefix.
  // Used to filter incoming SMS messages. Only messages starting with this prefix are processed.
  //
  // The prefix is one half of a contract: the sender has to emit exactly what the app matches on.
  // The default below only applies to a build that enables the mechanism without configuring the
  // prefix, so a brand that turns the mechanism on is expected to set both sides deliberately.
  static const CALL_TRIGGER_MECHANISM_SMS_PREFIX__NAME = 'WEBTRIT_CALL_TRIGGER_MECHANISM_SMS_PREFIX';
  static String get CALL_TRIGGER_MECHANISM_SMS_PREFIX => _env.string(
    CALL_TRIGGER_MECHANISM_SMS_PREFIX__NAME,
    const String.fromEnvironment(CALL_TRIGGER_MECHANISM_SMS_PREFIX__NAME, defaultValue: '<#> PORTAPHONE:'),
  );

  // ICU regex pattern to extract callId, handle, displayName and hasVideo from SMS body.
  static const CALL_TRIGGER_MECHANISM_SMS_REGEX_PATTERN__NAME = 'WEBTRIT_CALL_TRIGGER_MECHANISM_SMS_REGEX_PATTERN';
  static String get CALL_TRIGGER_MECHANISM_SMS_REGEX_PATTERN => _env.string(
    CALL_TRIGGER_MECHANISM_SMS_REGEX_PATTERN__NAME,
    const String.fromEnvironment(
      CALL_TRIGGER_MECHANISM_SMS_REGEX_PATTERN__NAME,
      // Host-agnostic on purpose: every brand serves this link from its own domain, so naming one
      // here would make the default wrong for all the others.
      defaultValue: r'https://[^/]+/call\?callId=([^&]+)&handle=([^&]+)&displayName=([^&]+)&hasVideo=(true|false)',
    ),
  );

  static const CONNECTIVITY_CHECK_URL__NAME = 'WEBTRIT_APP_CONNECTIVITY_CHECK_URL';
  static const String? _CONNECTIVITY_CHECK_URL_ENV = bool.hasEnvironment(CONNECTIVITY_CHECK_URL__NAME)
      ? String.fromEnvironment(CONNECTIVITY_CHECK_URL__NAME)
      : null;
  static String? get CONNECTIVITY_CHECK_URL =>
      _env.stringOrNull(CONNECTIVITY_CHECK_URL__NAME, _CONNECTIVITY_CHECK_URL_ENV);

  static const POLLING_MAX_BACKOFF_SECONDS__NAME = 'WEBTRIT_APP_POLLING_MAX_BACKOFF_SECONDS';

  /// Application-wide retry cap, read when the shell creates its polling service.
  /// Invalid/non-positive build values fall back to 900 seconds; invalid runtime
  /// overrides fall back to that validated build value. A task's base interval
  /// remains a floor even when it exceeds this cap.
  static int get POLLING_MAX_BACKOFF_SECONDS {
    const defaultSeconds = 900;
    const compileTime = int.fromEnvironment(POLLING_MAX_BACKOFF_SECONDS__NAME, defaultValue: defaultSeconds);
    return _pollingSeconds(POLLING_MAX_BACKOFF_SECONDS__NAME, compileTime > 0 ? compileTime : defaultSeconds);
  }

  static const POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS__NAME =
      'WEBTRIT_APP_POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS';

  /// Freshness cap for leading refresh, snapshotted when the shell is created.
  /// Zero disables the gate. Invalid/negative overrides use the validated build
  /// value; invalid/negative build values use the 30-second default.
  static int get POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS {
    const defaultSeconds = 30;
    const compileTime = int.fromEnvironment(
      POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS__NAME,
      defaultValue: defaultSeconds,
    );
    const fallback = compileTime >= 0 ? compileTime : defaultSeconds;
    final seconds = _env.integer(POLLING_LEADING_REFRESH_MIN_AGE_CAP_SECONDS__NAME, fallback);
    return seconds >= 0 ? seconds : fallback;
  }

  /// Reachability probe cache in positive whole seconds. A tick within this
  /// window reuses the last probe instead of hitting the check URL again, which
  /// is what turns the task intervals into the observed health-check rate. A
  /// non-positive build value falls back to 30 seconds.
  static const POLLING_REACHABILITY_TTL_SECONDS__NAME = 'WEBTRIT_APP_POLLING_REACHABILITY_TTL_SECONDS';
  static int get POLLING_REACHABILITY_TTL_SECONDS {
    const defaultSeconds = 30;
    const compileTime = int.fromEnvironment(POLLING_REACHABILITY_TTL_SECONDS__NAME, defaultValue: defaultSeconds);
    return _pollingSeconds(POLLING_REACHABILITY_TTL_SECONDS__NAME, compileTime > 0 ? compileTime : defaultSeconds);
  }

  /// Maximum jitter added to every computed polling delay, as a whole percent
  /// of that delay (0..100). Spreads clients that reconnect together; 0
  /// disables it. Out-of-range values fall back to 10.
  static const POLLING_JITTER_PERCENT__NAME = 'WEBTRIT_APP_POLLING_JITTER_PERCENT';
  static int get POLLING_JITTER_PERCENT {
    const defaultPercent = 10;
    const compileTime = int.fromEnvironment(POLLING_JITTER_PERCENT__NAME, defaultValue: defaultPercent);
    final build = _isPercent(compileTime) ? compileTime : defaultPercent;
    final runtime = _env.integer(POLLING_JITTER_PERCENT__NAME, build);
    return _isPercent(runtime) ? runtime : build;
  }

  static bool _isPercent(int value) => value >= 0 && value <= 100;

  /// Delay between a call ending and the refresh of what it changed (call
  /// history, balance), in positive whole seconds: the backend needs a moment
  /// to publish the CDR and charge the call. A non-positive build value falls
  /// back to 1 second.
  static const POST_CALL_REFRESH_DELAY_SECONDS__NAME = 'WEBTRIT_APP_POST_CALL_REFRESH_DELAY_SECONDS';
  static int get POST_CALL_REFRESH_DELAY_SECONDS {
    const defaultSeconds = 1;
    const compileTime = int.fromEnvironment(POST_CALL_REFRESH_DELAY_SECONDS__NAME, defaultValue: defaultSeconds);
    return _pollingSeconds(POST_CALL_REFRESH_DELAY_SECONDS__NAME, compileTime > 0 ? compileTime : defaultSeconds);
  }

  /// System notifications sync interval in positive whole seconds. A
  /// non-positive build value falls back to 10 seconds.
  static const SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS';
  static int get SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS {
    const defaultSeconds = 10;
    const compileTime = int.fromEnvironment(
      SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS__NAME,
      defaultValue: defaultSeconds,
    );
    return _pollingSeconds(
      SYSTEM_NOTIFICATIONS_POLLING_INTERVAL_SECONDS__NAME,
      compileTime > 0 ? compileTime : defaultSeconds,
    );
  }

  /// How often the queue of system notification read receipts is sent, in
  /// positive whole seconds. Queueing one asks for a send at once, so this is
  /// only the safety net for what an earlier session left behind. A
  /// non-positive build value falls back to 300 seconds.
  static const SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS';
  static int get SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS {
    const defaultSeconds = 300;
    const compileTime = int.fromEnvironment(
      SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS__NAME,
      defaultValue: defaultSeconds,
    );
    return _pollingSeconds(
      SYSTEM_NOTIFICATIONS_OUTBOX_POLLING_INTERVAL_SECONDS__NAME,
      compileTime > 0 ? compileTime : defaultSeconds,
    );
  }

  static const USER_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME = 'WEBTRIT_APP_USER_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get USER_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    USER_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(USER_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 900),
  );

  static const SYSTEM_INFO_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_SYSTEM_INFO_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get SYSTEM_INFO_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    SYSTEM_INFO_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(SYSTEM_INFO_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 300),
  );

  /// Contacts poll when the badge presence comes from the contacts payload itself
  /// (hybrid presence off): the poll is the presence source, so it stays fairly fresh.
  /// A non-positive build value would become a zero delay and a request storm, so it
  /// falls back to 300 seconds like the backoff cap does.
  static const EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS {
    const defaultSeconds = 300;
    const compileTime = int.fromEnvironment(
      EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
      defaultValue: defaultSeconds,
    );
    return _pollingSeconds(
      EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
      compileTime > 0 ? compileTime : defaultSeconds,
    );
  }

  /// Contacts poll when hybrid presence is on: presence rides the SIP channel and the
  /// badge ignores the contacts payload, so this fetch only refreshes the directory
  /// (names/numbers, which change rarely) and can run much less often. A non-positive
  /// build value falls back to 1800 seconds for the same reason as above.
  static const EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS';
  static int get EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS {
    const defaultSeconds = 1800;
    const compileTime = int.fromEnvironment(
      EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS__NAME,
      defaultValue: defaultSeconds,
    );
    return _pollingSeconds(
      EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS__NAME,
      compileTime > 0 ? compileTime : defaultSeconds,
    );
  }

  /// Resolves the contacts polling interval for the deployment's presence mode.
  /// With hybrid presence the contacts payload's registration status is unused, so the
  /// directory can be polled slowly; without it the poll is the presence source.
  static int externalContactsPollingSeconds({required bool hybridPresence}) => hybridPresence
      ? EXTERNAL_CONTACTS_HYBRID_PRESENCE_POLLING_INTERVAL_SECONDS
      : EXTERNAL_CONTACTS_REPOSITORY_POLLING_INTERVAL_SECONDS;

  static const CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME = 'WEBTRIT_APP_CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(CDRS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 300),
  );

  /// Width of the first slice the call history is walked back by, in positive
  /// whole days. The slices widen from here, so this is the resolution of the
  /// recent past rather than a limit on how far back the walk reaches. A
  /// non-positive value falls back to a week.
  static const CDRS_HISTORY_FIRST_WINDOW_DAYS__NAME = 'WEBTRIT_APP_CDRS_HISTORY_FIRST_WINDOW_DAYS';
  static int get CDRS_HISTORY_FIRST_WINDOW_DAYS => _positiveDays(
    CDRS_HISTORY_FIRST_WINDOW_DAYS__NAME,
    const int.fromEnvironment(CDRS_HISTORY_FIRST_WINDOW_DAYS__NAME, defaultValue: 7),
    fallback: 7,
  );

  /// Ceiling the history slice widens up to, in positive whole days. It bounds
  /// what a single request may ask the backend to look through, which is the
  /// cost the wide end of the walk pays. A non-positive value falls back to 90
  /// days.
  static const CDRS_HISTORY_MAX_WINDOW_DAYS__NAME = 'WEBTRIT_APP_CDRS_HISTORY_MAX_WINDOW_DAYS';
  static int get CDRS_HISTORY_MAX_WINDOW_DAYS => _positiveDays(
    CDRS_HISTORY_MAX_WINDOW_DAYS__NAME,
    const int.fromEnvironment(CDRS_HISTORY_MAX_WINDOW_DAYS__NAME, defaultValue: 90),
    fallback: 90,
  );

  /// A width in positive whole days: a non-positive build value takes
  /// [fallback], and a non-positive override takes the validated build value.
  ///
  /// A day is the unit of all three history knobs, so a deployment reads them
  /// against each other without converting anything.
  static int _positiveDays(String name, int compileTime, {required int fallback}) {
    final validBuild = compileTime > 0 ? compileTime : fallback;
    final days = _env.integer(name, validBuild);
    return days > 0 ? days : validBuild;
  }

  /// How far back the call history may be walked, in whole days. Zero switches
  /// the walk off entirely - the app then asks for history the way it did
  /// before the walk existed - so a build with this define is the way back to
  /// the previous behaviour without a code change. A negative value falls back
  /// to a year.
  static const CDRS_HISTORY_HORIZON_DAYS__NAME = 'WEBTRIT_APP_CDRS_HISTORY_HORIZON_DAYS';
  static int get CDRS_HISTORY_HORIZON_DAYS {
    const defaultDays = 365;
    const compileTime = int.fromEnvironment(CDRS_HISTORY_HORIZON_DAYS__NAME, defaultValue: defaultDays);
    const fallback = compileTime >= 0 ? compileTime : defaultDays;
    final days = _env.integer(CDRS_HISTORY_HORIZON_DAYS__NAME, fallback);
    return days >= 0 ? days : fallback;
  }

  static const CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS';

  /// How often the call queues are re-read while their screen is open.
  ///
  /// Ten seconds is the slow end of what the backend contract allows, and the
  /// one to prefer: every read reaches the PBX, and the adapter re-reads the
  /// customer's whole hunt group list on each one.
  static int get CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(CALL_QUEUES_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 10),
  );

  static const VOICEMAIL_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_VOICEMAIL_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get VOICEMAIL_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    VOICEMAIL_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(VOICEMAIL_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 300),
  );

  static const ICE_SERVERS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_ICE_SERVERS_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get ICE_SERVERS_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    ICE_SERVERS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(ICE_SERVERS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 300),
  );

  static const CALLER_ID_SETTINGS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_CALLER_ID_SETTINGS_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get CALLER_ID_SETTINGS_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    CALLER_ID_SETTINGS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(CALLER_ID_SETTINGS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 300),
  );

  static const FAVORITES_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_FAVORITES_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get FAVORITES_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    FAVORITES_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(FAVORITES_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 300),
  );

  static const SIP_SUBSCRIPTIONS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME =
      'WEBTRIT_APP_SIP_SUBSCRIPTIONS_REPOSITORY_POLLING_INTERVAL_SECONDS';
  static int get SIP_SUBSCRIPTIONS_REPOSITORY_POLLING_INTERVAL_SECONDS => _pollingSeconds(
    SIP_SUBSCRIPTIONS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME,
    const int.fromEnvironment(SIP_SUBSCRIPTIONS_REPOSITORY_POLLING_INTERVAL_SECONDS__NAME, defaultValue: 300),
  );
}

/// Resolves dart-define values for [EnvironmentConfig], hiding the source from
/// callers: a runtime override (set via [apply]) wins, otherwise the
/// compile-time default supplied by the caller is used.
///
/// Overrides always arrive as strings (the form a `--dart-define` injection
/// takes), so typed reads parse them against the typed compile-time fallback.
class EnvRegistry {
  Map<String, String> _overrides = const {};

  /// Replaces the override set. Pass an empty map to clear.
  void apply(Map<String, String> overrides) => _overrides = Map<String, String>.unmodifiable(overrides);

  /// Removes all overrides.
  void clear() => _overrides = const {};

  /// Whether an override is set for [name].
  bool has(String name) => _overrides.containsKey(name);

  /// Resolves a required string value. An empty override is treated as "unset"
  /// (a blank `--dart-define` means not-set), so it falls back to [compileTime]
  /// rather than yielding an empty app name, core URL, etc.
  String string(String name, String compileTime) {
    final value = _overrides[name];
    return (value == null || value.isEmpty) ? compileTime : value;
  }

  /// Resolves an optional string value; an empty override is treated as "unset".
  String? stringOrNull(String name, String? compileTime) {
    final value = _overrides[name];
    return (value == null || value.isEmpty) ? compileTime : value;
  }

  /// Resolves a boolean value. `'true'`/`'false'` (case-insensitive) are
  /// honoured; an empty override is treated as unset; any other value is logged
  /// and falls back to [compileTime] instead of being silently coerced.
  bool boolean(String name, bool compileTime) {
    final value = _overrides[name];
    if (value == null || value.isEmpty) return compileTime;
    switch (value.toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        _logger.warning('Override "$name"="$value" is not a bool; using $compileTime');
        return compileTime;
    }
  }

  /// Resolves an integer value. An empty override is treated as unset; a
  /// non-numeric override is logged and falls back to [compileTime].
  int integer(String name, int compileTime) {
    final value = _overrides[name];
    if (value == null || value.isEmpty) return compileTime;
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    _logger.warning('Override "$name"="$value" is not an int; using $compileTime');
    return compileTime;
  }
}
