import 'package:in_app_update/in_app_update.dart';

/// What Play answers to an update check; nothing to offer unless told otherwise.
AppUpdateInfo appUpdateInfo({
  UpdateAvailability updateAvailability = UpdateAvailability.updateNotAvailable,
  bool immediateUpdateAllowed = false,
  bool flexibleUpdateAllowed = false,
  InstallStatus installStatus = InstallStatus.unknown,
  int updatePriority = 0,
  int? availableVersionCode,
}) {
  return AppUpdateInfo(
    updateAvailability: updateAvailability,
    immediateUpdateAllowed: immediateUpdateAllowed,
    immediateAllowedPreconditions: null,
    flexibleUpdateAllowed: flexibleUpdateAllowed,
    flexibleAllowedPreconditions: null,
    availableVersionCode: availableVersionCode,
    installStatus: installStatus,
    packageName: 'com.webtrit.phone',
    clientVersionStalenessDays: null,
    updatePriority: updatePriority,
  );
}
