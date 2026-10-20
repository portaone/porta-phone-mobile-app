import 'package:country_code_picker/country_code_picker.dart';

/// The country a dial code is shown as when several countries share it and
/// the rule does not say which one was picked.
///
/// A rule applies to every country behind its dial code. The country picked
/// for it is kept with the rule and shown when present; rules saved before
/// that, or by a client that does not send it, carry the dial code alone, and
/// for them the flag is a label for the code: such a +1 rule shows this
/// table's country whatever was picked.
///
/// The choices are the web dialer's, which shows every rule this way, so a
/// rule without a country carries the same flag in both. Left to the picker,
/// the first country of its alphabetical list won - Canada for +1, Guernsey
/// for +44.
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

/// The country picked for a rule on [dialCode], or null when [country] is
/// absent or is not a country the picker lists behind that code.
///
/// The country comes with the rule from the backend and is only a label: it
/// can be unknown to the picker or belong to another code. The picker draws
/// the dial code of the country it is handed, so such a country would show a
/// code the rule does not match - or the first country of the list for one it
/// does not know.
String? pickedCountryOfRule(String dialCode, String? country) {
  if (country == null) return null;
  final known = codes.any((entry) => entry['code'] == country && entry['dial_code'] == dialCode);
  return known ? country : null;
}

/// What to hand the country picker for it to show a rule on [dialCode]: the
/// country picked for the rule when it is a country of that code, otherwise
/// what [countrySelectionForDialCode] gives.
String countrySelectionForRule(String dialCode, String? country) =>
    pickedCountryOfRule(dialCode, country) ?? countrySelectionForDialCode(dialCode);
