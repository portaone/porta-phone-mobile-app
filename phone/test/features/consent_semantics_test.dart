import 'package:flutter_test/flutter_test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/blocs/blocs.dart';
import 'package:webtrit_phone/features/contacts_agreement/contacts_agreement.dart';
import 'package:webtrit_phone/features/permissions/widgets/permission_tips.dart';
import 'package:webtrit_phone/features/user_agreement/user_agreement.dart';
import 'package:webtrit_phone/models/models.dart';

import '../helpers/screen_presets.dart';
import '../helpers/semantics.dart';
import 'consent_harness.dart';

void main() {
  late ConsentHarness harness;

  setUpAll(() => registerFallbackValue(AppAgreementAccepted.updateContactsAgreement(AgreementStatus.pending)));
  setUp(() => harness = ConsentHarness());

  for (final preset in watchPresets) {
    group('on $preset', () {
      testWidgets('the contacts consent and Continue are tapped through semantics', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);
        await pumpCollectingOverflows(tester, harness.wrap(const ContactsAgreementScreen()));

        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(contactsAgreementCheckboxId),
          label: 'Allow access to contacts',
          identifier: contactsAgreementCheckboxId,
          pressArea: find.byKey(contactsAgreementCheckboxKey),
        );
        await tapViaSemantics(tester, find.bySemanticsIdentifier(contactsAgreementCheckboxId));
        await tapViaSemantics(tester, find.bySemanticsIdentifier(contactsAgreementAcceptButtonId));

        final event = verify(() => harness.appBloc.add(captureAny())).captured.single;
        expect(event, AppAgreementAccepted.updateContactsAgreement(AgreementStatus.accepted));

        handle.dispose();
      });

      testWidgets('the terms link is tapped through semantics', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);
        await pumpCollectingOverflows(
          tester,
          harness.wrap(
            const UserAgreementScreen(appTermsAndConditionsUrl: 'https://example.com/terms', appName: 'WebTrit'),
          ),
        );

        // Below the consent; on the smallest faces it is a scroll away.
        await tester.scrollUntilVisible(find.byKey(userAgreementTermsLinkKey), 50);
        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(userAgreementTermsLinkId),
          label: 'Read the terms',
          identifier: userAgreementTermsLinkId,
          isButton: true,
          pressArea: find.byKey(userAgreementTermsLinkKey),
        );

        handle.dispose();
      });

      testWidgets('the permission tips are dismissed and opened in settings through semantics', (tester) async {
        final handle = tester.ensureSemantics();
        preset.apply(tester);
        var dismissed = 0;
        var settings = 0;
        await pumpCollectingOverflows(
          tester,
          harness.wrap(
            PermissionTips(
              title: 'Manage Full-Screen Notification Permissions',
              instruction: const ['Open the settings', 'Allow full-screen notifications'],
              onGoToAppSettings: () => settings++,
              onPop: () => dismissed++,
              dismissLabel: 'Not now',
            ),
          ),
        );

        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(permissionTipsButtonId),
          label: 'Not now',
          identifier: permissionTipsButtonId,
          isButton: true,
        );
        await tapViaSemantics(tester, find.bySemanticsIdentifier(permissionTipsButtonId));
        expect(dismissed, 1);

        await tester.scrollUntilVisible(find.byKey(permissionTipsSettingsButtonKey), 100);
        expectTapTargetSemantics(
          tester,
          find.bySemanticsIdentifier(permissionTipsSettingsButtonId),
          identifier: permissionTipsSettingsButtonId,
          isButton: true,
          pressArea: find.byKey(permissionTipsSettingsButtonKey),
        );
        await tapViaSemantics(tester, find.bySemanticsIdentifier(permissionTipsSettingsButtonId));
        expect(settings, 1);

        handle.dispose();
      });
    });
  }
}
