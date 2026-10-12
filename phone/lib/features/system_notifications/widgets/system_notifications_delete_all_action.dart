import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/system_notifications_screen_cubit.dart';

/// Deletes every notification stored on this device, after asking.
///
/// "Every" is what the device holds, not the whole history on the backend:
/// older notifications are not counted and not deleted (see
/// [SystemNotificationsScreenCubit.storedNotificationIds]). The question
/// carries the count because it is the part a person cannot check once the
/// dialog covers the list.
class SystemNotificationsDeleteAllAction extends StatefulWidget {
  const SystemNotificationsDeleteAllAction({super.key});

  @override
  State<SystemNotificationsDeleteAllAction> createState() => _SystemNotificationsDeleteAllActionState();
}

class _SystemNotificationsDeleteAllActionState extends State<SystemNotificationsDeleteAllAction> {
  @override
  Widget build(BuildContext context) {
    final enabled = context.select<SystemNotificationsScreenCubit, bool>(
      (cubit) => cubit.state.notifications.isNotEmpty,
    );

    return SemanticAction(
      label: context.l10n.system_notifications_SemanticsLabel_deleteAll,
      identifier: systemNotificationsDeleteAllId,
      child: IconButton(icon: const Icon(Icons.delete_sweep), onPressed: enabled ? _onDeleteAll : null),
    );
  }

  void _onDeleteAll() async {
    final cubit = context.read<SystemNotificationsScreenCubit>();
    final ids = await cubit.storedNotificationIds();
    if (ids.isEmpty || !mounted) return;

    final confirmed =
        (await ConfirmDialog.showDangerous(
          context,
          title: context.l10n.system_notifications_Dialog_deleteAllTitle(ids.length),
          content: context.l10n.system_notifications_Dialog_deleteAllContent,
        )) ??
        false;

    if (confirmed && mounted) cubit.deleteNotifications(ids);
  }
}
