import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../bloc/about_bloc.dart';
import 'about_screen_style.dart';
import 'about_screen_styles.dart';

/// About on a watch face.
///
/// A short page: the app and its version under the title, the device, then
/// the values as rows. The logo, the developer taps, the embedded links,
/// the backend capabilities and the licenses stay on the phone.
class AboutScreenWatch extends StatelessWidget {
  const AboutScreenWatch({super.key, this.style});

  final AboutScreenStyle? style;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeData = Theme.of(context);
    final localStyle = style ?? themeData.extension<AboutScreenStyles>()?.primary;
    final lineStyle = themeData.textTheme.labelSmall?.copyWith(color: themeData.colorScheme.onSurfaceVariant);
    return ThemedScaffold(
      background: localStyle?.background,
      body: BlocBuilder<AboutBloc, AboutState>(
        builder: (context, state) => WatchScrollList(
          title: l10n.settings_ListViewTileTitle_about,
          spacing: context.adaptiveMetrics.gap,
          children: [
            Text(state.appInfo, textAlign: TextAlign.center, style: themeData.textTheme.labelMedium),
            Text(state.deviceInfo, textAlign: TextAlign.center, style: lineStyle),
            // The Core's address, under the phone's id: the stand reads it to
            // tell which Core a run is signed in to.
            SemanticId(
              identifier: aboutCoreUrlId,
              child: Text(state.coreUrl.toString(), textAlign: TextAlign.center, style: lineStyle),
            ),
            WatchInfoRow(
              label: l10n.settings_AboutText_CoreVersion,
              // While the Core is asked a spinner stands on the phone; here the
              // row waits with the dash the phone shows for no value.
              value: state.progress
                  ? '-'
                  : (state.coreVersion ?? l10n.settings_AboutText_CoreVersionUndefined).toString(),
            ),
            WatchInfoRow(
              label: l10n.settings_AboutText_AppSessionIdentifier,
              value: state.appIdentifier,
              valueIdentifier: aboutAppSessionIdentifierId,
            ),
            if (state.fcmPushToken case final token?)
              WatchInfoRow(label: l10n.settings_AboutText_FCMPushNotificationToken, value: token),
            if (state.bundleVersion case final bundle?)
              WatchInfoRow(label: l10n.settings_AboutText_BundleVersion, value: bundle),
          ],
        ),
      ),
    );
  }
}
