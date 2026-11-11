import 'package:material_ui/material_ui.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';
import 'package:webtrit_phone/theme/theme.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

/// An embedded page on a watch, which has no web view: a page on the network
/// opens on the paired phone from the open-on-phone page; one built into the
/// app (an asset or inline content) has no address the phone could open, so
/// the face says to open it in the app on the phone.
///
/// The phone's page is handed what the app injects into it - the session's
/// payload, the device's metrics; the page opened on the phone gets none of
/// that, as any link opened in a browser.
class EmbeddedWatchPage extends StatelessWidget {
  const EmbeddedWatchPage({super.key, required this.title, required this.uri});

  /// The page's configured name; a page on the network without one is called
  /// by its host.
  final String? title;
  final Uri uri;

  @override
  Widget build(BuildContext context) {
    // Decided by the scheme alone, the way [ResourceLoader.fromUri] picks the
    // network loader: building the loader would throw on a scheme no loader
    // takes and decode inline content eagerly, only to be thrown away.
    if (NetworkResourceLoader.supportedSchemes.contains(uri.scheme)) {
      return WatchOpenOnPhonePage(title: title ?? uri.host, uri: uri);
    }
    // No host fallback here: an asset's "host" is its folder and inline
    // content has none, neither of them a name.
    return Scaffold(
      body: WatchStatePage(
        title: title,
        icon: const Icon(Icons.phone_android),
        message: context.l10n.common_Watch_phoneOnly,
      ),
    );
  }
}

/// An embedded page opened from a link in the app, on a watch: the page under
/// its configured name, if it has one.
class EmbeddedScreenPageWatch extends StatelessWidget {
  const EmbeddedScreenPageWatch({super.key, required this.data});

  final EmbeddedData data;

  @override
  Widget build(BuildContext context) {
    return EmbeddedWatchPage(
      title: switch (data.titleL10n) {
        final title? => context.parseL10n(title),
        null => null,
      },
      uri: data.uri,
    );
  }
}

/// An embedded page that is a section of the bottom menu, on a watch: the
/// section's page under the section's name.
class EmbeddedTabPageWatch extends StatelessWidget {
  const EmbeddedTabPageWatch({super.key, required this.id});

  /// The section's id in the bottom menu's configuration.
  final String id;

  @override
  Widget build(BuildContext context) {
    final data = context.read<FeatureAccess>().bottomMenuConfig.getEmbeddedTabById(id);
    return EmbeddedWatchPage(title: context.parseL10n(data.titleL10n), uri: data.data!.uri);
  }
}
