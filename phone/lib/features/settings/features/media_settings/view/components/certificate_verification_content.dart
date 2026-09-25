import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/features/settings/features/media_settings/media_settings.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/ice_settings.dart';

/// Lets a person decide how the certificate of a `turns:` relay is verified.
///
/// Shown only where the deployment asked for it - see
/// [MediaSettingsState.certificateVerificationConfigurable] - because the value
/// that rescues an outage is also the value that leaves the relay connection
/// unverified, and that is not a choice to put in front of everyone.
class CertificateVerificationContent extends StatelessWidget {
  const CertificateVerificationContent({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MediaSettingsCubit>();
    final theme = Theme.of(context);

    return BlocBuilder<MediaSettingsCubit, MediaSettingsState>(
      buildWhen: (p, c) => p.iceSettings.certificateVerification != c.iceSettings.certificateVerification,
      builder: (context, state) {
        final selected = state.iceSettings.certificateVerification ?? TurnCertificateVerification.auto;

        // Shaped like the sibling contents: a plain Column with the same
        // spacing, and no sub-heading, which is what the other single-group
        // sections do - `ChoosableSection` only draws one when given a title.
        return Column(
          spacing: 16,
          children: [
            ChoosableSection<TurnCertificateVerification>(
              title: null,
              buildOptionTitle: (option) => Text(switch (option) {
                TurnCertificateVerification.enabled => context.l10n.settings_certificateVerification_enabled,
                TurnCertificateVerification.disabled => context.l10n.settings_certificateVerification_disabled,
                // `ChoosableSection` renders the unlisted option as null, which
                // is where "automatic" lives - the same shape the ICE filters
                // use for "no filtering".
                _ => context.l10n.settings_certificateVerification_auto,
              }),
              options: const [TurnCertificateVerification.enabled, TurnCertificateVerification.disabled],
              selected: selected == TurnCertificateVerification.auto ? null : selected,
              onSelect: (option) => cubit.setCertificateVerification(option ?? TurnCertificateVerification.auto),
            ),
            // Only under "do not verify": a warning shown beside every option is
            // one nobody reads by the time it matters. Amber rather than the
            // error colour, and the same inset as the tiles above, so it reads
            // as part of this screen rather than as something bolted on - the
            // diagnostic screen already uses that pairing for "degraded but
            // working".
            if (selected == TurnCertificateVerification.disabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    Expanded(
                      child: Text(
                        context.l10n.settings_certificateVerification_warning,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
