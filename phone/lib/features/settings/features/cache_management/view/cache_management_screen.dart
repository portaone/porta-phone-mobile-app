import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../cubit/cache_management_cubit.dart';
import '../utils/cache_usage_formatter.dart';

/// Central place to inspect and free the app's local caches.
///
/// Renders one entry per registered cache section with its current usage and
/// a clear action; measuring and clearing live in [CacheManagementCubit].
class CacheManagementScreen extends StatelessWidget {
  const CacheManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => AdaptiveLayout(handset: _handset, watch: _watch);

  /// A row per store with its size and a bin for what a tap does; the tap
  /// asks on the watch confirm, the store's description under the question -
  /// a watch row has no room for the phone's paragraph and Clear button.
  Widget _watch(BuildContext context) {
    final l10n = context.l10n;
    final title = l10n.cacheManagement_Widget_screenTitle;
    return Scaffold(
      body: BlocBuilder<CacheManagementCubit, CacheManagementState>(
        builder: (context, state) {
          if (state.sections.isEmpty) {
            return WatchStatePage(
              title: title,
              icon: const Icon(Icons.storage),
              message: l10n.cacheManagement_Label_empty,
            );
          }
          return WatchScrollList(
            title: title,
            spacing: context.adaptiveMetrics.gap,
            children: [for (final section in state.sections) _CacheSectionWatchRow(section: section)],
          );
        },
      ),
    );
  }

  Widget _handset(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cacheManagement_Widget_screenTitle), leading: const ExtBackButton()),
      body: BlocBuilder<CacheManagementCubit, CacheManagementState>(
        builder: (context, state) {
          if (state.sections.isEmpty) {
            return Center(child: Text(context.l10n.cacheManagement_Label_empty));
          }
          return ListView(
            children: [
              for (final section in state.sections) ...[
                _CacheSectionTile(
                  section: section,
                  onClear: () => context.read<CacheManagementCubit>().clearSection(section.id),
                ),
                const Divider(height: 1),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// How much a store holds, in the words the phone uses; "Unknown" when it
/// could not be measured, null while it is being measured.
String? _usageLabel(BuildContext context, CacheSectionState section) {
  final usage = section.usage;
  if (usage != null) {
    return switch (usage.unit) {
      CacheUsageUnit.bytes => formatBytes(usage.amount, context.l10n),
      CacheUsageUnit.items => context.l10n.cacheManagement_Label_itemsCount(usage.amount),
    };
  }
  return section.measureFailed ? context.l10n.cacheManagement_Label_unknown : null;
}

/// One store on a watch: its name and size, a spinner while it is measured or
/// cleared, a bin otherwise; a tap asks before clearing it.
class _CacheSectionWatchRow extends StatelessWidget {
  const _CacheSectionWatchRow({required this.section});

  final CacheSectionState section;

  @override
  Widget build(BuildContext context) {
    final usage = _usageLabel(context, section);
    final busy = section.clearing || usage == null;
    return WatchListTile(
      leading: const Icon(Icons.storage),
      title: context.parseL10n(section.titleL10n),
      subtitle: usage,
      // What a tap does, for a screen reader: the bin says it to the eye.
      semanticsLabel: [
        context.parseL10n(section.titleL10n),
        ?usage,
        context.l10n.cacheManagement_Button_clear,
      ].join(', '),
      trailing: busy
          ? const SizedCircularProgressIndicator(size: 16, strokeWidth: 2)
          : const Icon(Icons.delete_outline),
      onTap: section.clearing ? null : () => _clear(context),
    );
  }

  Future<void> _clear(BuildContext context) async {
    final cubit = context.read<CacheManagementCubit>();
    final name = context.parseL10n(section.titleL10n);
    final clear = await ConfirmDialog.showDangerous(
      context,
      title: context.l10n.cacheManagement_Watch_clearQuestion(name),
      content: context.parseL10n(section.descriptionL10n),
    );
    if (clear == true) await cubit.clearSection(section.id);
  }
}

class _CacheSectionTile extends StatelessWidget {
  const _CacheSectionTile({required this.section, required this.onClear});

  final CacheSectionState section;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.storage),
          title: Text(context.parseL10n(section.titleL10n)),
          subtitle: Text(context.parseL10n(section.descriptionL10n), style: theme.textTheme.bodySmall),
          trailing: switch (_usageLabel(context, section)) {
            final label? => Text(label, style: theme.textTheme.titleSmall),
            null => const SizedCircularProgressIndicator(size: 16, strokeWidth: 2),
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: TextButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(context.l10n.cacheManagement_Button_clear),
              onPressed: section.clearing ? null : onClear,
            ),
          ),
        ),
      ],
    );
  }
}
