import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';
import 'package:provider/provider.dart';

import 'package:signaling_service/signaling_service.dart' show WebtritSignalingService;

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/settings/widgets/widgets.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/repositories/repositories.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class DevToolsScreen extends StatelessWidget {
  const DevToolsScreen({super.key, this.endProcess = _exitProcess});

  /// Ends the app's process. Stands in for it in a test, which cannot end its
  /// own process.
  @visibleForTesting
  final void Function() endProcess;

  static void _exitProcess() => exit(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton(), title: Text(context.l10n.devTools_AppBarTitle)),
      body: ListView(
        children: [
          GroupTitleListTile(titleData: context.l10n.devTools_signalingService_groupTitle),
          ListTile(
            title: Text(context.l10n.devTools_signalingService_simulateKill_title),
            subtitle: Text(context.l10n.devTools_signalingService_simulateKill_subtitle),
            trailing: const Icon(Icons.stop_circle_outlined),
            onTap: () => _confirmSimulateKill(context),
          ),
          GroupTitleListTile(titleData: context.l10n.devTools_systemInfo_groupTitle),
          SemanticAction(
            identifier: devToolsClearSystemInfoId,
            child: ListTile(
              key: devToolsClearSystemInfoKey,
              title: Text(context.l10n.devTools_systemInfo_clear_title),
              subtitle: Text(context.l10n.devTools_systemInfo_clear_subtitle),
              trailing: const Icon(Icons.delete_sweep_outlined),
              onTap: () => _confirmClearSystemInfo(context),
            ),
          ),
        ],
      ),
    );
  }

  void _onSimulateKillConfirmed(BuildContext ctx) {
    Navigator.of(ctx).pop();
    unawaited(WebtritSignalingService.simulateKill());
  }

  void _confirmSimulateKill(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.devTools_signalingService_simulateKill_title),
        content: Text(context.l10n.devTools_signalingService_simulateKill_confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.devTools_signalingService_simulateKill_cancel),
          ),
          TextButton(
            onPressed: () => _onSimulateKillConfirmed(ctx),
            child: Text(context.l10n.devTools_signalingService_simulateKill_confirm),
          ),
        ],
      ),
    );
  }

  /// Removes the stored system info and ends the process.
  ///
  /// Only a cold start is a start without it: a running app stores it again on
  /// its next refresh - every resume and every few minutes - and the parts of a
  /// session already built read it synchronously. Leaving the app in the
  /// background would not do: coming back resumes it.
  Future<void> _onClearSystemInfoConfirmed(BuildContext ctx, SystemInfoRepository repository) async {
    Navigator.of(ctx).pop();
    await repository.clear();
    endProcess();
  }

  void _confirmClearSystemInfo(BuildContext context) {
    final repository = context.read<SystemInfoRepository>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.devTools_systemInfo_clear_title),
        content: Text(context.l10n.devTools_systemInfo_clear_confirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.devTools_systemInfo_clear_cancel),
          ),
          TextButton(
            onPressed: () => unawaited(_onClearSystemInfoConfirmed(ctx, repository)),
            child: Text(context.l10n.devTools_systemInfo_clear_confirm),
          ),
        ],
      ),
    );
  }
}
