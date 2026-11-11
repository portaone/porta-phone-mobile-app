import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/agreement_status.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/network_tester_cubit.dart';
import 'diagnostic_network_test_item.dart';

/// How a check of the diagnostic stands, worst first: the order the watch
/// lists them in.
enum DiagnosticWatchLevel { fail, warn, checking, ok }

/// One check of the diagnostic as a watch shows it: its name, its status in
/// a word, how it stands, what it means, and the fix where there is one.
class DiagnosticWatchCheck {
  const DiagnosticWatchCheck({
    required this.title,
    required this.status,
    required this.level,
    required this.description,
    this.fix,
    this.identifier,
    this.page,
  });

  final String title;
  final String status;
  final DiagnosticWatchLevel level;

  /// What the status means, on the check's page.
  final String description;

  /// The check's fix, on the edge of its page: asking for a permission,
  /// opening the watch's settings.
  final WatchAction? fix;

  final String? identifier;

  /// A page of its own in place of the plain one, for a check that keeps
  /// running there (the network).
  final WidgetBuilder? page;
}

/// The diagnostic on a watch: a row per check - its name, its status in a
/// word and its mark - what fails first, outlined, then what to look at, then
/// what is fine. A tap opens the check's page.
class DiagnosticWatchList extends StatelessWidget {
  const DiagnosticWatchList({super.key, required this.title, required this.checks});

  final String title;
  final List<DiagnosticWatchCheck> checks;

  @override
  Widget build(BuildContext context) {
    // Grouped level by level rather than sorted: List.sort is not stable, and
    // checks of one level keep the phone's order.
    final sorted = [for (final level in DiagnosticWatchLevel.values) ...checks.where((check) => check.level == level)];
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: WatchScrollList(
        title: title,
        spacing: context.adaptiveMetrics.gap,
        children: [
          for (final check in sorted)
            WatchListTile(
              identifier: check.identifier,
              title: check.title,
              subtitle: check.status,
              outlined: check.level == DiagnosticWatchLevel.fail,
              trailing: DiagnosticWatchMark(level: check.level, errorColor: colorScheme.error),
              onTap: () => _open(context, check),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, DiagnosticWatchCheck check) {
    unawaited(
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: check.page ?? (_) => DiagnosticWatchCheckPage(check: check))),
    );
  }
}

/// The mark of how a check stands: a tick, a warning, a failure, or a spinner
/// while it runs. The status word beside it says the same for a screen reader.
class DiagnosticWatchMark extends StatelessWidget {
  const DiagnosticWatchMark({super.key, required this.level, required this.errorColor});

  final DiagnosticWatchLevel level;
  final Color errorColor;

  // The phone's colours for the same states, which its diagnostic draws
  // from the same constants.
  static const _ok = Colors.green;
  static const _warn = Colors.orange;

  @override
  Widget build(BuildContext context) {
    return switch (level) {
      DiagnosticWatchLevel.ok => const Icon(Icons.check_circle, color: _ok),
      DiagnosticWatchLevel.warn => const Icon(Icons.error_outline, color: _warn),
      DiagnosticWatchLevel.fail => Icon(Icons.error_outline, color: errorColor),
      // The kit's spinner, in the size of the marks beside it; the status word
      // already says it is running.
      DiagnosticWatchLevel.checking => ExcludeSemantics(
        child: WatchSpinner(label: context.l10n.common_SemanticsLabel_loading),
      ),
    };
  }
}

/// A check on a watch: its name, its status under it, what the status means,
/// and the fix on the edge where there is one.
class DiagnosticWatchCheckPage extends StatelessWidget {
  const DiagnosticWatchCheckPage({super.key, required this.check});

  final DiagnosticWatchCheck check;

  @override
  Widget build(BuildContext context) {
    final fix = check.fix;
    return Scaffold(
      body: WatchScrollList.builder(
        title: check.title,
        header: [_Status(text: check.status, level: check.level)],
        itemCount: 1,
        itemBuilder: (context, _) => _Description(check.description),
        edge: fix == null ? null : (context, overlay) => _closingAfter(context, fix).buildButton(overlay),
      ),
    );
  }

  /// The fix that also closes the page, as the phone's sheet closes: the page
  /// shows the check as it was when opened, so after the fix it would go on
  /// offering it under the old status. The list reads the new one.
  WatchAction _closingAfter(BuildContext context, WatchAction fix) {
    final onPressed = fix.onPressed;
    return WatchAction(
      label: fix.label,
      style: fix.style,
      identifier: fix.identifier,
      buttonKey: fix.buttonKey,
      onPressed: onPressed == null ? null : () => _applyAndClose(context, onPressed),
    );
  }

  void _applyAndClose(BuildContext context, VoidCallback onPressed) {
    onPressed();
    Navigator.of(context).maybePop();
  }
}

/// The network check on a watch: how it stands and what was found, kept up
/// to date while the check runs, and Run again on the edge.
class DiagnosticWatchNetworkPage extends StatelessWidget {
  const DiagnosticWatchNetworkPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<NetworkTesterCubit>().state;
    final summary = NetworkTestSummary.of(state, l10n);
    return Scaffold(
      body: WatchScrollList.builder(
        title: title,
        header: [_Status(text: summary.title, level: networkWatchLevel(summary.level))],
        itemCount: 1,
        itemBuilder: (context, _) => _Description(summary.subtitle),
        edge: (context, overlay) => WatchAction(
          label: l10n.diagnostic_Watch_runAgain,
          onPressed: summary.gathering ? null : () => context.read<NetworkTesterCubit>().refresh(),
        ).buildButton(overlay),
      ),
    );
  }
}

/// How the network check stands, in the watch's order.
DiagnosticWatchLevel networkWatchLevel(NetworkTestLevel level) => switch (level) {
  NetworkTestLevel.reachable => DiagnosticWatchLevel.ok,
  NetworkTestLevel.restricted => DiagnosticWatchLevel.warn,
  NetworkTestLevel.checking => DiagnosticWatchLevel.checking,
  NetworkTestLevel.offline || NetworkTestLevel.unreachable => DiagnosticWatchLevel.fail,
};

class _Status extends StatelessWidget {
  const _Status({required this.text, required this.level});

  final String text;
  final DiagnosticWatchLevel level;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    return Text(
      text,
      textAlign: TextAlign.center,
      style: themeData.textTheme.labelMedium?.copyWith(
        color: level == DiagnosticWatchLevel.fail
            ? themeData.colorScheme.error
            : themeData.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall);
  }
}

/// The contacts agreement on a watch: what it allows, the consent as a toggle
/// pill, and Continue on the edge, as the phone's sheet has them.
class DiagnosticWatchAgreementPage extends StatefulWidget {
  const DiagnosticWatchAgreementPage({
    super.key,
    required this.title,
    required this.description,
    required this.status,
    required this.onApply,
  });

  final String title;
  final String description;
  final AgreementStatus status;
  final ValueChanged<AgreementStatus> onApply;

  @override
  State<DiagnosticWatchAgreementPage> createState() => _DiagnosticWatchAgreementPageState();
}

class _DiagnosticWatchAgreementPageState extends State<DiagnosticWatchAgreementPage> {
  late var _status = widget.status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: WatchScrollList.builder(
        title: widget.title,
        itemCount: 2,
        itemBuilder: (context, index) => index == 0
            ? _Description(widget.description)
            : WatchToggleChip(
                label: l10n.contacts_agreement_checkbox_text,
                value: _status.isAccepted,
                onChanged: (value) =>
                    setState(() => _status = value ? AgreementStatus.accepted : AgreementStatus.declined),
              ),
        edge: (context, overlay) =>
            WatchAction(label: l10n.contacts_agreement_button_text, onPressed: _apply).buildButton(overlay),
      ),
    );
  }

  void _apply() {
    widget.onApply(_status);
    Navigator.of(context).maybePop();
  }
}
