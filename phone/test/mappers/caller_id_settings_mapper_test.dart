import 'package:flutter_test/flutter_test.dart';

import 'package:api/api.dart' as api;

import 'package:webtrit_phone/mappers/api/caller_id_settings_mapper.dart';
import 'package:webtrit_phone/mappers/json/caller_id_settings_mapper.dart';
import 'package:webtrit_phone/models/models.dart';

class _Mapper with CallerIdSettingsApiMapper, CallerIdSettingsJsonMapper {}

void main() {
  final mapper = _Mapper();

  // A rule is matched by its dial code, but several countries can share one
  // (+1 is the US, Canada and the Caribbean), so the country picked for it
  // travels with the rule for the flag to show the pick and not a guess.
  group('the country of a rule', () {
    test('comes from the backend with the rule', () {
      final matcher = mapper.prefixMatcherFromApi(const api.PrefixMatcher(prefix: '+1', number: '100', country: 'CA'));

      expect(matcher, PrefixMatcher('+1', '100', country: 'CA'));
    });

    test('goes to the backend with the rule', () {
      final json = mapper.prefixMatcherToApi(PrefixMatcher('+1', '100', country: 'CA')).toJson();

      expect(json, {'prefix': '+1', 'number': '100', 'country': 'CA'});
    });

    test('is left out of the request when unknown, so the backend keeps the one it has', () {
      // An explicit null would read the same to the backend, but a backend
      // older than the field gets no key it does not know.
      final json = mapper.prefixMatcherToApi(PrefixMatcher('+1', '100')).toJson();

      expect(json, {'prefix': '+1', 'number': '100'});
    });

    test('is absent from a rule of a backend that does not store it', () {
      final matcher = mapper.prefixMatcherFromApi(api.PrefixMatcher.fromJson({'prefix': '+1', 'number': '100'}));

      expect(matcher, PrefixMatcher('+1', '100'));
    });

    test('survives the local cache', () {
      final settings = CallerIdSettings(matchers: [PrefixMatcher('+1', '100', country: 'CA')]);

      expect(mapper.callerIdSettingsFromJson(mapper.callerIdSettingsToJson(settings)), settings);
    });

    test('is absent from a rule cached before it was kept', () {
      const cached = '{"defaultNumber":null,"matchers":[{"type":"prefix_matcher","prefix":"+1","number":"100"}]}';

      expect(mapper.callerIdSettingsFromJson(cached), CallerIdSettings(matchers: [PrefixMatcher('+1', '100')]));
    });
  });
}
