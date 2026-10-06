import 'package:test/test.dart';

import 'package:app_database/app_database.dart';
import 'package:app_database/src/daos/contact_search.dart';

void main() {
  var nextId = 0;

  FullContactData contact({
    String? firstName,
    String? lastName,
    String? aliasName,
    List<String> numbers = const [],
    List<String> emails = const [],
  }) {
    final id = ++nextId;
    return FullContactData(
      contact: ContactData(
        id: id,
        sourceType: ContactSourceTypeEnum.external,
        kind: ContactKindTypeEnum.visible,
        firstName: firstName,
        lastName: lastName,
        aliasName: aliasName,
      ),
      phones: [
        for (final number in numbers)
          ContactPhoneData(id: id * 10 + numbers.indexOf(number), number: number, label: 'ext', contactId: id),
      ],
      emails: [
        for (final email in emails)
          ContactEmailData(id: id * 10 + emails.indexOf(email), address: email, label: 'work', contactId: id),
      ],
      favorites: [],
      presenceInfo: [],
      dialogInfo: [],
      sipSubscriptions: [],
    );
  }

  ContactSearchMatch? matchOf(String query, FullContactData data) => ContactSearch(query.split(' ')).matchOf(data);

  group('where a word is found', () {
    test('at the start of the first name, the last name or the alias', () {
      expect(matchOf('ann', contact(firstName: 'Anna', lastName: 'Kovalenko')), ContactSearchMatch.nameStart);
      expect(matchOf('kov', contact(firstName: 'Anna', lastName: 'Kovalenko')), ContactSearchMatch.nameStart);
      expect(matchOf('boss', contact(firstName: 'Anna', aliasName: 'Boss')), ContactSearchMatch.nameStart);
    });

    test('at the start of a later word of a name', () {
      expect(matchOf('mar', contact(firstName: 'Anna Maria')), ContactSearchMatch.nameWordStart);
      expect(matchOf('kov', contact(lastName: 'Petrenko-Kovalenko')), ContactSearchMatch.nameWordStart);
      expect(matchOf('hq', contact(lastName: 'Acme (HQ)')), ContactSearchMatch.nameWordStart);
    });

    test('inside a name', () {
      expect(matchOf('val', contact(lastName: 'Kovalenko')), ContactSearchMatch.insideName);
    });

    test('in a number, when no name carries it', () {
      expect(matchOf('2002', contact(firstName: 'Anna', numbers: ['2001', '2002'])), ContactSearchMatch.number);
    });

    test('in an email, when nothing else carries it', () {
      expect(matchOf('example', contact(firstName: 'Anna', emails: ['anna@example.com'])), ContactSearchMatch.email);
    });

    test('nowhere', () {
      expect(matchOf('zzz', contact(firstName: 'Anna', numbers: ['2001'], emails: ['anna@example.com'])), isNull);
    });

    test('the best place wins when a word is in several', () {
      final data = contact(firstName: 'Anna', emails: ['anna@example.com']);

      expect(matchOf('anna', data), ContactSearchMatch.nameStart);
    });

    test('a name padded with spaces still starts with the word', () {
      expect(matchOf('anna', contact(firstName: '  Anna')), ContactSearchMatch.nameStart);
    });

    test('an empty name carries nothing and breaks nothing', () {
      expect(matchOf('kov', contact(firstName: '', lastName: 'Kovalenko')), ContactSearchMatch.nameStart);
      expect(matchOf('kov', contact(firstName: '', lastName: '')), isNull);
    });

    test('letter case is ignored, Cyrillic included', () {
      expect(matchOf('ШЕВ', contact(lastName: 'Шевченко')), ContactSearchMatch.nameStart);
    });

    test('a word is compared as typed, not as a pattern', () {
      expect(matchOf('.*', contact(firstName: 'Anna')), isNull);
      expect(matchOf('c++', contact(lastName: 'C++ Developer')), ContactSearchMatch.nameStart);
    });
  });

  group('several words', () {
    test('every word has to be found', () {
      expect(matchOf('anna kov', contact(firstName: 'Anna', lastName: 'Kovalenko')), ContactSearchMatch.nameStart);
      expect(matchOf('anna kov', contact(firstName: 'Anna', lastName: 'Bondar')), isNull);
    });

    test('a contact is as relevant as its weakest word', () {
      final data = contact(firstName: 'Anna', lastName: 'Bondar', emails: ['kov@example.com']);

      expect(matchOf('anna kov', data), ContactSearchMatch.email);
    });

    test('the words may be found in different fields', () {
      final data = contact(firstName: 'Anna', numbers: ['2002']);

      expect(matchOf('anna 2002', data), ContactSearchMatch.number);
    });
  });

  group('the list a search returns', () {
    test('is ordered by relevance and keeps the incoming order inside one', () {
      final byEmail = contact(firstName: 'Adam', emails: ['kov@example.com']);
      final inside = contact(firstName: 'Bohdan', lastName: 'Makovsky');
      final startB = contact(firstName: 'Kovalenko B');
      final byNumber = contact(firstName: 'Dmytro', numbers: ['kov1']);
      final wordStart = contact(firstName: 'Ivan Kovalenko');
      final startA = contact(firstName: 'Kovalenko A');

      final ranked = ContactSearch(['kov']).rank([byEmail, inside, startB, byNumber, wordStart, startA]);

      expect(ranked, [startB, startA, wordStart, inside, byNumber, byEmail]);
    });

    test('keeps a contact that does not answer the query, at the end', () {
      final unrelated = contact(firstName: 'Zoya');
      final found = contact(firstName: 'Anna', emails: ['kov@example.com']);

      expect(ContactSearch(['kov']).rank([unrelated, found]), [found, unrelated]);
    });

    test('puts a first name starting with the word above a last name starting with it', () {
      final lastName = contact(firstName: 'Andriy', lastName: 'Yevtushenko');
      final firstName = contact(firstName: 'Yevhen', lastName: 'Dem');

      expect(ContactSearch(['yev']).rank([lastName, firstName]), [firstName, lastName]);
    });

    test('puts the earlier position in the name first inside one relevance', () {
      final late = contact(firstName: 'Oleksandr', lastName: 'Makovsky');
      final early = contact(firstName: 'Petro', lastName: 'Akovsky');
      final alias = contact(firstName: 'Zoya', lastName: 'Bondar', aliasName: 'Kovcheh');

      // "kov" sits at 12 in "oleksandr makovsky", at 7 in "petro akovsky" and opens the alias.
      expect(ContactSearch(['kov']).rank([late, early, alias]), [alias, early, late]);
    });

    test('takes the latest position among the words of the query', () {
      final wide = contact(firstName: 'Anna', lastName: 'Kovalenko-Bondar');
      final tight = contact(firstName: 'Anna', lastName: 'Bondar');

      expect(ContactSearch(['anna', 'bon']).rank([wide, tight]), [tight, wide]);
    });

    test('is the whole list for a query with no words', () {
      final contacts = [contact(firstName: 'Anna'), contact(firstName: 'Zoya')];

      expect(ContactSearch(['', '']).rank(contacts), contacts);
    });
  });
}
