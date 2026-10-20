import 'package:material_ui/material_ui.dart';

import 'package:pub_semver/pub_semver.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

class CoreInfoTile extends StatelessWidget {
  const CoreInfoTile({super.key, required this.coreUrl, required this.coreVersion, required this.progress});

  final Uri? coreUrl;
  final Version? coreVersion;
  final bool progress;

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    final versionLabel = context.l10n.settings_AboutText_CoreVersion;
    final versionValue = progress
        ? ''
        : (coreVersion ?? context.l10n.settings_AboutText_CoreVersionUndefined).toString();

    final copyData = '${coreUrl.toString()}\n$versionLabel $versionValue';

    // The address is a node of its own so it can be read without the version
    // lines, and it carries the copy itself: an identifier inside the copy
    // would leave the address without the copy action. Both parts copy the
    // same text, so a long press anywhere on the tile copies the whole of it.
    return Column(
      children: [
        SemanticId(
          identifier: aboutCoreUrlId,
          child: CopyToClipboard(
            data: copyData,
            child: Text(coreUrl.toString(), textAlign: TextAlign.center),
          ),
        ),
        CopyToClipboard(
          data: copyData,
          child: Column(
            children: [
              Text(versionLabel),
              Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  Text(versionValue, style: themeData.textTheme.bodyMedium),
                  if (progress)
                    SizedCircularProgressIndicator(size: themeData.textTheme.bodyMedium!.fontSize!, strokeWidth: 2),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
