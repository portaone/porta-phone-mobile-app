import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/models/models.dart';

RecentsBottomMenuTab _recents({RecentsLayout? layout, bool supportsCallHistory = true}) => RecentsBottomMenuTab(
  supportsCallHistory: supportsCallHistory,
  layout: layout ?? RecentsLayout.tabbed,
  enabled: true,
  initial: false,
  titleL10n: 'main_BottomNavigationBarItemLabel_recents',
  icon: Icons.history,
);

void main() {
  group('which recents arrangement a deployment gets', () {
    test('a tab that says nothing keeps the one it has', () {
      const tab = RecentsBottomMenuTab(
        supportsCallHistory: true,
        enabled: true,
        initial: false,
        titleL10n: 'main_BottomNavigationBarItemLabel_recents',
        icon: Icons.history,
      );

      expect(tab.layout, RecentsLayout.tabbed);
    });

    test('the arrangement does not move the tab to another route', () {
      // One screen draws both, so a path saved under one arrangement still
      // opens the section under the other.
      for (final supportsCallHistory in [true, false]) {
        expect(
          _recents(layout: RecentsLayout.unified, supportsCallHistory: supportsCallHistory).routePath,
          _recents(layout: RecentsLayout.tabbed, supportsCallHistory: supportsCallHistory).routePath,
        );
      }
    });

    test('the two are not the same tab', () {
      expect(_recents(layout: RecentsLayout.unified), isNot(_recents(layout: RecentsLayout.tabbed)));
    });
  });
}
