# phone_number

`PhoneParser.normalize(String)`: replaces look-alike characters (styled and fullwidth digits,
enclosed letters, ...) with ASCII using the table in `lib/src/constants.dart`, and keeps
everything else. Used by the app's keypad formatter
(`lib/features/keypad/utils/phone_normalizing_formatter.dart`), `ExtendedTextFormField` and
`CallkeepHandle.normalizedValue()` (`lib/extensions/callkeep_handle.dart`).

- The table maps letters with diacritics too (`e` with an acute accent becomes `e`), not only
  digits, so normalizing changes text that is not a number.
- `CallkeepHandle.normalizedValue()` goes through it, and `CallBloc` sends that value as the
  `number` of an outgoing call and of a transfer: a change to the table changes what signaling
  dials.
- Iterate by `runes`, never `split('')`: a styled digit such as U+1D7D7 is a surrogate pair, and
  its two halves match nothing in the table.

Tests: `test/src/phone_parser_test.dart`; `fvm flutter test` here. The pre-push gate does not run
them.
