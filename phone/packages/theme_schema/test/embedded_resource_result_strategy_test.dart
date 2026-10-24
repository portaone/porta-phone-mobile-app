import 'package:test/test.dart';
import 'package:theme_schema/theme_schema.dart';

/// `resultStrategy` was added to embedded resources after configurations were already out
/// there, and configurations outlive the builds that read them; both directions must load.
void main() {
  EmbeddedResource parse(Map<String, Object?> extra) =>
      EmbeddedResource.fromJson({'id': 'login', 'uri': 'https://example.com/login', ...extra});

  group('resultStrategy of an embedded resource', () {
    test('is unset in a configuration written before it existed', () {
      expect(parse({}).resultStrategy, isNull);
    });

    test('reads every value it names', () {
      for (final value in ResultStrategyConfig.values) {
        expect(parse({'resultStrategy': value.name}).resultStrategy, value);
      }
    });

    test('is unset, not an error, for a value from a newer configuration', () {
      expect(parse({'resultStrategy': 'somethingNewer'}).resultStrategy, isNull);
    });

    test('is written back under its name', () {
      final resource = parse({'resultStrategy': 'notify'});

      expect(resource.toJson()['resultStrategy'], 'notify');
    });

    test('is listed with its values in the published schema', () {
      final properties = EmbeddedResource.jsonSchema['properties'] as Map<String, Object?>;
      final schema = properties['resultStrategy'] as Map<String, Object?>;

      expect(schema.toString(), contains('historyBack'));
      expect(schema.toString(), contains('notify'));
    });
  });
}
