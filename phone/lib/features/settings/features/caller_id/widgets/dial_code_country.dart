/// The country a dial code is shown as when several countries share it.
///
/// A rule keeps the dial code alone - it applies to every country behind that
/// code, and neither the backend nor the web dialer stores which one was
/// picked. The flag beside a saved rule is therefore a label for the code, not
/// the choice: a rule made by picking Canada reads +1 and shows this table's
/// country like any other +1 rule.
///
/// The choices are the web dialer's, so that one rule, synchronised through
/// the backend, carries the same flag in both. Left to the picker, the first
/// country of its alphabetical list won - Canada for +1, Guernsey for +44.
///
/// Every code the picker lists for more than one country has a row, except
/// +7, which is left to the picker's own choice on purpose; a test holds
/// that, so a new shared code cannot fall back to list order unnoticed.
const mainCountryOfSharedDialCode = <String, String>{
  '+1': 'US',
  '+44': 'GB',
  '+47': 'NO',
  '+61': 'AU',
  '+64': 'NZ',
  '+262': 'TF',
  '+358': 'FI',
  '+500': 'FK',
  '+590': 'GP',
  '+672': 'AQ',
};

/// What to hand the country picker for it to show [dialCode].
///
/// The picker takes a country code as readily as a dial code; a dial code one
/// country owns identifies it already and goes through as it is.
String countrySelectionForDialCode(String dialCode) => mainCountryOfSharedDialCode[dialCode] ?? dialCode;
