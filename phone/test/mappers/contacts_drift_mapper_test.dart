import 'package:flutter_test/flutter_test.dart';

import 'package:app_database/app_database.dart';

import 'package:webtrit_phone/mappers/drift/contacts_mapper.dart';
import 'package:webtrit_phone/mappers/drift/dialog_info_drift_mapper.dart';
import 'package:webtrit_phone/mappers/drift/presence_info_drift_mapper.dart';

class _Mapper with PresenceInfoDriftMapper, DialogInfoDriftMapper, ContactsDriftMapper {}

void main() {
  test('a contact carries the time its row was last written', () {
    // For a contact from the server that is the last refresh of the contact
    // list, which is what dates its registration flag.
    final written = DateTime(2026, 11, 25, 12);
    final row = ContactData(
      id: 1,
      sourceType: ContactSourceTypeEnum.external,
      kind: ContactKindTypeEnum.visible,
      sourceId: 'user-1',
      registered: true,
      updatedAt: written,
    );

    expect(_Mapper().contactFromDrift(row).updatedAt, written);
  });

  test('a contact is the same contact after a refresh that changed nothing', () {
    // Every refresh of the list rewrites the row and moves its time. A contact
    // picked into a set has to be found there afterwards, and a list must not
    // be rebuilt for it.
    ContactData row(DateTime written) => ContactData(
      id: 1,
      sourceType: ContactSourceTypeEnum.external,
      kind: ContactKindTypeEnum.visible,
      sourceId: 'user-1',
      registered: true,
      updatedAt: written,
    );
    final before = _Mapper().contactFromDrift(row(DateTime(2026, 11, 25, 12)));
    final after = _Mapper().contactFromDrift(row(DateTime(2026, 11, 25, 12, 5)));

    expect(after, before);
    expect({before}.contains(after), isTrue);
  });
}
