import 'package:webtrit_phone/environment_config.dart';
import 'package:webtrit_phone/services/services.dart';

/// The slices this deployment walks call history by.
///
/// One place reads the configuration, because the walk has to look the same
/// from wherever it is started: the sync worker filling an empty store and a
/// list reaching further back are the same walk over the same archive, and a
/// deployment that narrows it narrows both.
HistoryWindows configuredCdrsHistoryWindows() => HistoryWindows(
  firstWidth: Duration(days: EnvironmentConfig.CDRS_HISTORY_FIRST_WINDOW_DAYS),
  maxWidth: Duration(days: EnvironmentConfig.CDRS_HISTORY_MAX_WINDOW_DAYS),
  horizon: Duration(days: EnvironmentConfig.CDRS_HISTORY_HORIZON_DAYS),
);
