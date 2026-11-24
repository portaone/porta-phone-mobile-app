import 'package:test/test.dart';

import 'package:webtrit_phone_tools/src/commands/app_resources/constants/constants.dart';
import 'package:webtrit_phone_tools/src/commands/app_resources/utils/utils.dart';

void main() {
  Map<String, dynamic> filesWith(Object? embeddeds) => {
        assetAppConfigEmbeddedsPath: embeddeds,
      };

  group('TermsEmbedCheck.problemIn', () {
    test('finds nothing wrong with a terms page that has an address', () {
      final files = filesWith([
        {'id': 'terms-1', 'type': 'terms', 'uri': 'https://brand.one/terms'},
      ]);

      expect(TermsEmbedCheck.problemIn(files), isNull);
    });

    test('finds the terms page among pages of other types', () {
      final files = filesWith([
        {'id': 'help-1', 'type': 'unknown', 'uri': 'https://brand.one/help'},
        {'id': 'terms-1', 'type': 'terms', 'uri': 'https://brand.one/terms'},
      ]);

      expect(TermsEmbedCheck.problemIn(files), isNull);
    });

    test('names the missing page when the brand has no embedded pages', () {
      expect(
        TermsEmbedCheck.problemIn(filesWith(<Object?>[])),
        contains('Terms resource is missing'),
      );
    });

    test('names the missing page when none of the pages is of type terms', () {
      final files = filesWith([
        {'id': 'help-1', 'type': 'unknown', 'uri': 'https://brand.one/help'},
      ]);

      expect(
        TermsEmbedCheck.problemIn(files),
        contains('Terms resource is missing'),
      );
    });

    test('names the missing page when the bundle carries no embedded document at all', () {
      expect(
        TermsEmbedCheck.problemIn(const {}),
        contains('Terms resource is missing'),
      );
    });

    test('names the missing page when the embedded document is not a list', () {
      expect(
        TermsEmbedCheck.problemIn(filesWith({'type': 'terms'})),
        contains('Terms resource is missing'),
      );
    });

    test('names the missing address of a terms page without one', () {
      for (final uri in <Object?>[null, '', '   ']) {
        final files = filesWith([
          {'id': 'terms-1', 'type': 'terms', 'uri': uri},
        ]);

        expect(
          TermsEmbedCheck.problemIn(files),
          contains('has no address'),
          reason: 'uri: "$uri"',
        );
      }
    });

    test('judges the first terms page, the one the phone opens', () {
      final files = filesWith([
        {'id': 'terms-1', 'type': 'terms', 'uri': ''},
        {'id': 'terms-2', 'type': 'terms', 'uri': 'https://brand.one/terms'},
      ]);

      expect(TermsEmbedCheck.problemIn(files), contains('has no address'));
    });
  });
}
