import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webtrit_phone/app/keys.dart';
import 'package:webtrit_phone/features/contacts/contacts.dart';

import '../../helpers/helpers.dart';
import 'contacts_tab_harness.dart';

void main() {
  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');

  late ContactsTabHarness harness;
  late List<String> settingsCalls;

  setUp(() {
    harness = ContactsTabHarness();
    settingsCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      settingsCalls.add(call.method);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('the way out of a refused permission is named and opens the settings', (tester) async {
    final semantics = tester.ensureSemantics();
    await harness.pumpLocal(tester, contacts: const [], status: ContactsLocalTabStatus.permissionFailure);

    final control = find.byKey(contactsLocalGrantAccessKey);
    expectTapTargetSemantics(
      tester,
      control,
      label: 'Grant access to your phone contacts',
      identifier: contactsLocalGrantAccessId,
      isButton: true,
      pressArea: control,
    );
    await tapViaSemantics(tester, control);
    expect(settingsCalls, ['openAppSettings']);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    semantics.dispose();
  });

  testWidgets('the change-selection control under a list is named and opens the settings', (tester) async {
    final semantics = tester.ensureSemantics();
    await harness.pumpLocal(tester, contacts: [buildListContact(id: 1, name: 'Anna')], selectionOnly: true);

    final control = find.byKey(contactsLocalChangeSelectionKey);
    expectTapTargetSemantics(
      tester,
      control,
      label: 'Change selection',
      identifier: contactsLocalChangeSelectionId,
      isButton: true,
      pressArea: control,
    );
    await tapViaSemantics(tester, control);
    expect(settingsCalls, ['openAppSettings']);
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    semantics.dispose();
  });

  testWidgets('an empty selection names both of its controls', (tester) async {
    final semantics = tester.ensureSemantics();
    await harness.pumpLocal(tester, contacts: const [], selectionOnly: true);

    expectTapTargetSemantics(
      tester,
      find.byKey(contactsLocalChangeSelectionKey),
      label: 'Change selection',
      identifier: contactsLocalChangeSelectionId,
      isButton: true,
    );
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    semantics.dispose();
  });
}
