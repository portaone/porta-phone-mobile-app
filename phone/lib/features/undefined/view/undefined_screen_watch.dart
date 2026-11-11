import 'package:material_ui/material_ui.dart';

import 'package:auto_route/auto_route.dart';

import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/widgets/widgets.dart';

import '../extensions/extensions.dart';
import '../models/models.dart';

/// The undefined screen on a watch face: the state page - the badge, the
/// title, the text, Continue on the edge.
class UndefinedScreenWatch extends StatelessWidget {
  const UndefinedScreenWatch({super.key, required this.undefinedType});

  final UndefinedType undefinedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WatchStatePage(
        title: undefinedType.titleL10n(context),
        icon: const Icon(Icons.info_outline),
        message: undefinedType.descriptionL10n(context),
        action: WatchAction(label: context.l10n.permission_Button_request, onPressed: () => context.router.maybePop()),
      ),
    );
  }
}
