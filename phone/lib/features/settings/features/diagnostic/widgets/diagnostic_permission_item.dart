import 'package:material_ui/material_ui.dart';

import '../extensions/extensions.dart';
import '../models/models.dart';

class DiagnosticPermissionItem extends StatelessWidget {
  const DiagnosticPermissionItem({super.key, required this.permissionWithStatus, required this.onTap});

  final PermissionWithStatus permissionWithStatus;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final title = permissionWithStatus.permission.title(context);
    final statusText = permissionWithStatus.status.title(context);
    final statusColor = permissionWithStatus.severity.color(context);
    final statusIcon = permissionWithStatus.isWorking ? Icons.check_circle : Icons.error_outline;

    return ListTile(
      onTap: onTap.call,
      title: Text(title),
      subtitle: Text(statusText),
      trailing: Icon(statusIcon, color: statusColor),
    );
  }
}
