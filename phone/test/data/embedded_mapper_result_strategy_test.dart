import 'package:flutter_test/flutter_test.dart';

import 'package:theme_schema/theme_schema.dart';

import 'package:webtrit_phone/data/data.dart';
import 'package:webtrit_phone/models/models.dart';

// What a page is given when a request it posted to the app ends without success comes from its
// resource. Pages configured before the setting existed must keep what they always had.
void main() {
  EmbeddedData mapped(ResultStrategyConfig? config) {
    final resource = EmbeddedResource(id: 'login', uri: 'https://example.com/login', resultStrategy: config);
    return EmbeddedMapper.map([resource]).embeddedResources.single;
  }

  group('the result strategy of an embedded resource', () {
    test('is history back when the resource does not set it', () {
      expect(mapped(null).resultStrategy, ResultStrategy.historyBack);
    });

    test('is the one the resource sets', () {
      expect(mapped(ResultStrategyConfig.historyBack).resultStrategy, ResultStrategy.historyBack);
      expect(mapped(ResultStrategyConfig.notify).resultStrategy, ResultStrategy.notify);
      expect(mapped(ResultStrategyConfig.restart).resultStrategy, ResultStrategy.restart);
      expect(mapped(ResultStrategyConfig.reload).resultStrategy, ResultStrategy.reload);
      expect(mapped(ResultStrategyConfig.none).resultStrategy, ResultStrategy.none);
    });

    test('is history back for a value from a newer configuration', () {
      final resource = EmbeddedResource.fromJson({
        'id': 'login',
        'uri': 'https://example.com/login',
        'resultStrategy': 'somethingNewer',
      });

      expect(EmbeddedMapper.map([resource]).embeddedResources.single.resultStrategy, ResultStrategy.historyBack);
    });
  });
}
