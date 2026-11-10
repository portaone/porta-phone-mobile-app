import 'package:flutter/widgets.dart';

import 'package:provider/provider.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/l10n/l10n.dart';
import 'package:webtrit_phone/models/models.dart';

extension FeatureAccessResolver on FeatureAccess {
  FeatureChecker get checker => FeatureChecker(this);

  List<Permission> get excludedPermissions {
    final sourceTypes = bottomMenuConfig.getTabEnabled<ContactsBottomMenuTab>()?.contactSourceTypes;

    final hasLocalContacts = sourceTypes?.contains(ContactSourceType.local) ?? false;
    final isSmsFallbackEnabled = callConfig.triggerConfig.smsFallback.enabled;

    return [if (!hasLocalContacts) Permission.contacts, if (!isSmsFallbackEnabled) Permission.sms];
  }
}

extension WatchSectionTitle on BuildContext {
  /// The name a section shows over its list on a watch: the hub's name for
  /// its tab, or [fallback] when the tab has none.
  String watchSectionTitle<T extends BottomMenuTab>({required String fallback}) =>
      parseL10n(read<FeatureAccess>().bottomMenuConfig.getTabEnabled<T>()?.titleL10n, fallback: fallback);
}
