import 'package:permission_handler/permission_handler.dart';

class PermissionWithStatus {
  final Permission permission;
  final PermissionStatus status;

  PermissionWithStatus(this.permission, this.status);

  /// Whether the permission does its job as it stands. A selection of contacts
  /// is the grant the user chose, not a half-granted one to be fixed.
  bool get isWorking =>
      status == PermissionStatus.granted || (permission == Permission.contacts && status == PermissionStatus.limited);

  /// The status to colour the permission by: a working one reads as granted.
  PermissionStatus get severity => isWorking ? PermissionStatus.granted : status;
}
