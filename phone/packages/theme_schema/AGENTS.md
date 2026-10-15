# theme_schema

Pure Dart package (no Flutter dependency): the DTOs of the theme and app configuration
documents, their JSON, and the JSON Schema (draft 2020-12) of that JSON. The app reads the
documents in `assets/themes/` through these classes; `tools/` (the brand CLI) depends on it by
path. The Flutter bridge (`ThemeData`, `ThemeExtension`) lives in `lib/theme/` of the app and
must not move here: no `package:flutter` import in this package.

## Hierarchy

```
ThemeSettings                 root: light and dark variants of each part
  +-- ColorSchemeConfig       seed color + ColorSchemeOverride
  +-- ThemeWidgetConfig       widget-level styling (buttons, bars, inputs, dialogs)
  +-- ThemePageConfig         per-page overrides (call, keypad, login, settings, ...)
AppConfig                     separate root: app behaviour and feature flags
EmbeddedResource              separate root: an embedded page or resource
```

The three roots are the ones `bin/print_json_schema.dart` lists in `_roots`. A nested type is
not a root: it appears in a root's `$defs` and is addressable as `#/$defs/<Type>`.

## DTO shape

State lives on the class - a constructor and `final` fields - with freezed adding equality
and `copyWith`, and json_serializable the JSON:

```dart
@freezed
@JsonSerializable(explicitToJson: true)
class FooConfig with _$FooConfig {
  const FooConfig({this.size = 0.0, this.label});

  @override
  final double size;

  @override
  final String? label;

  factory FooConfig.fromJson(Map<String, Object?> json) => _$FooConfigFromJson(json);
  Map<String, Object?> toJson() => _$FooConfigToJson(this);
}
```

- A new field is nullable or has a default, so a document written before it still parses.
- `explicitToJson: true` on every class with nested DTOs.
- A discriminated union (`PageBackground`, `SupportedFeature`, `BottomMenuTabScheme`) is a
  `sealed` base with an ordinary class per variant, not a freezed union. The base holds the
  redirecting factories, a `fromJson` that switches on `type` and throws
  `CheckedFromJsonException` on an unknown word, and the getters common to every variant. Each
  variant declares its own `type` field with its word as the default.
- The only converter is `UriConverter` (`lib/converters/`). That is why
  `IconDataConfig.codePoint` and `embeddedResourceId` are `String`s.

## Schema contract

The schema is derived from the DTO source and nothing else. It is meant to be complete (every
key `toJson` writes appears in it) and true of the app's own documents; only the second is
tested, by [shipped_theme_validates_test.dart](../../test/theme/shipped_theme_validates_test.dart),
which runs a JSON Schema validator over every file in `assets/themes/`.

| Path | Role |
|---|---|
| `lib/models/**` | the DTOs |
| `lib/builder.dart` | build-time only: writes the three tables below and holds `contractViolations` |
| `lib/schema/enum_properties.g.dart` | generated: enum-typed properties, the words each accepts, its default |
| `lib/schema/union_variants.g.dart` | generated: which classes each union is made of |
| `lib/schema/nullable_properties.g.dart` | generated: which properties accept `null` |
| `lib/schema/union_assembly.dart` | the three `assemble*` functions that use those tables |
| `bin/print_json_schema.dart` | the CLI, with `_roots` |

- json_serializable writes a `_$<Type>JsonSchema` constant only for a class whose annotation
  carries `createJsonSchema: true`: the three roots and the 17 union variants. `build.yaml` does
  not enable the option globally - that would emit one for every annotated class, read by
  nothing.
- The constant is private to its library, so a `jsonSchema` member on the class is the only way
  anything outside the file reaches it. A root's member wraps it in the three assemblies, which
  is why it is `static final`, not `static const`.
- The assemblies fill what the generator leaves out: a sealed base becomes a `oneOf` over its
  variants with their `$defs` lifted in; an enum gets its words and default instead of a bare
  `{"type": "object"}`; a discriminator is pinned with `const` (without it, every `bottomMenu`
  tab of the shipped `app.config.json` matched six of seven variants and `oneOf` rejected it);
  a nullable property is widened to accept `null`.
- The builder parses the source without resolving it. Resolving needs the `part` files, which
  need these tables first - a cycle. The price: a type counts as an enum or a variant only where
  this package declares it.
- `lib/builder.dart` sits under `lib/` because `build.yaml` names a builder by `package:` URI,
  so it imports dev dependencies (`depend_on_referenced_packages` is silenced at its top).
  Nothing imports it; keep it that way.
- `build.yaml` lists two of the three outputs the builder writes in `build_extensions`
  (`nullable_properties.g.dart` is missing there); the builder writes all three regardless.

### Rules for extending the contract

`test/contract_rules_test.dart` reads this package's source and fails with the rule, the type or
field, and what to write instead. You do not have to remember these; read the failure.

| Rule | Write this instead | Why |
|---|---|---|
| no non-empty collection default | an empty collection, with the default resolved when read | a non-empty one crashes generation for the whole library, `fromJson`/`toJson` included |
| no new `JsonConverter` | a field whose Dart type is what the JSON carries | the schema describes the Dart type, so a converted field is published as something no document contains |
| no freezed union | a sealed base with an ordinary class per variant | freezed writes the variant classes, so there are no fields for the generator to read |
| state on the class, not a generated impl | a constructor plus `final` fields, not `const factory X(...) = _X` | a class with no fields of its own is published as an empty object, and nested types get no `$def` |
| a schema asked for is a schema exposed | `createJsonSchema: true` together with a `jsonSchema` member, plus an entry in `_roots` for a root | the generated constant is private to its library |

Naming an enum property, listing a union's variants and marking a field nullable need no rule:
they are read off the source. Add the field and run `build_runner`.

## Recipes

**A property on an existing type.** Add the field (nullable or with a default), run
`build_runner`. An enum or nullable type is picked up on its own. Then:

1. if a shipped document should carry it, add it to `phone/assets/themes/*.json` - the tests
   read those files through the loaders in `test/helpers/fixtures.dart`;
2. map it in the bridge, `phone/lib/theme/`;
3. read it in widgets through `Theme.of(context).extension<T>()`.

**A variant of an existing union.** In the same file, a redirecting factory and a `fromJson`
case on the base:

```dart
const factory BottomMenuTabScheme.dialer({...}) = DialerTabScheme;

factory BottomMenuTabScheme.fromJson(Map<String, Object?> json) => switch (json['type']) {
  'dialer' => DialerTabScheme.fromJson(json),
  ...
};
```

The variant class takes `@JsonSerializable(explicitToJson: true, createJsonSchema: true)`, a
`type` field defaulting to its word, and
`static const Map<String, Object?> jsonSchema = _$DialerTabSchemeJsonSchema;`.
`union_variants.g.dart` picks it up because it extends the base.

**A new union.** A sealed base as above and one class per variant. Nothing to register: the
builder finds the base by `sealed` and the variants by `extends`.

**A new root.** `createJsonSchema: true` on the annotation, all three wrappers on the member
(each skips what the root does not reach), and an entry in `_roots`:

```dart
static final Map<String, Object?> jsonSchema = assembleNullability(
  assembleEnums(assembleUnions(_$NewRootJsonSchema, unionVariants), 'NewRoot', enumProperties),
  'NewRoot',
  nullableProperties,
);
```

## Schema export

```bash
fvm dart run bin/print_json_schema.dart                           # ThemeSettings, inside the package
fvm dart run theme_schema:print_json_schema --list                # roots, from a dependent package
fvm dart run theme_schema:print_json_schema AppConfig --out app_config.schema.json
```

`*.schema.json` is gitignored in `phone/`. `pubspec.yaml` also exposes the CLI as the
`webtrit_theme_schema` executable.

## Testing

```bash
fvm dart run build_runner build --delete-conflicting-outputs   # tables and schema constants
fvm flutter test                                               # in this package
```

| Test | Catches |
|---|---|
| `test/contract_rules_test.dart` | a DTO written in a shape the schema cannot describe |
| `test/enum_property_test.dart` | a property the schema still describes as a bare object |
| `test/union_schema_test.dart` | a word a decoder takes that the schema does not offer as a variant, and the reverse |
| `test/union_wire_test.dart` | a variant that does not come back as itself through `toJson`/`fromJson`, an unknown `type` not refused |
| `test/schema_tables_builder_test.dart` | what the builder reads out of a source file |
| `phone/test/theme/shipped_theme_validates_test.dart` | a shipped theme document the schema rejects |

- The pre-push gate does not run this package's tests: run them here by hand, and the app's
  `test/theme/` tests from `phone/`.
- A change under this package also triggers the Jenkins tools check
  (`gerrit_check_tools.groovy`), because `tools/` depends on it: run `fvm dart test` in
  `tools/` too.
