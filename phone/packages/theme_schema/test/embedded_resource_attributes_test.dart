import 'package:test/test.dart';
import 'package:theme_schema/theme_schema.dart';

/// An embedded resource used to carry a free-form `attributes` map, and configurations written then are still
/// out there - the launch page was once chosen by `{"launch": true}` in it. Nothing reads it any more, so it is
/// gone from the resource; a configuration that still has it must load as if it did not.
void main() {
  const plain = {'id': 'login', 'uri': 'https://example.com/login'};

  test('a resource with attributes reads as the same resource without them', () {
    final withAttributes = EmbeddedResource.fromJson({
      ...plain,
      'attributes': {'launch': true},
    });

    expect(withAttributes, EmbeddedResource.fromJson(plain));
  });

  test('a resource is written without attributes', () {
    expect(EmbeddedResource.fromJson(plain).toJson().containsKey('attributes'), isFalse);
  });

  // That the schema still takes a resource carrying them is checked by validating one, in the app's
  // shipped_theme_validates_test.
  test('the published schema does not name attributes', () {
    final properties = EmbeddedResource.jsonSchema['properties'] as Map<String, Object?>;

    expect(properties.containsKey('attributes'), isFalse);
  });
}
