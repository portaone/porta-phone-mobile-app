import '../constants/constants.dart';

/// Whether a bundle carries the one embedded page the phone cannot start without.
///
/// The phone reads the embedded pages when it launches and looks among them for
/// the page of type `terms`, the terms and privacy policy it shows before sign
/// in. It has no fallback: without that page it raises an error before the
/// first screen is drawn and stays on the splash screen for good. Nothing in a
/// build reads the list - to the compiler it is one more asset - so a brand
/// without the page builds, signs and ships, and fails only in the hands of
/// whoever installs it. This check moves that failure to the moment the bundle
/// is fetched.
abstract final class TermsEmbedCheck {
  /// The value of `type` the phone looks for.
  static const termsType = 'terms';

  /// What is wrong with the terms page of the documents in [files], keyed by
  /// their path in the checkout, or `null` when the phone will find it.
  static String? problemIn(Map<String, dynamic> files) {
    final embeddeds = files[assetAppConfigEmbeddedsPath];
    final entries = embeddeds is List ? embeddeds.whereType<Map<dynamic, dynamic>>() : const <Map<dynamic, dynamic>>[];

    // The phone takes the first page of the type, so that is the one to judge:
    // a second, complete one behind an empty first would never be opened.
    final terms = entries.where((entry) => entry['type'] == termsType).firstOrNull;
    if (terms == null) {
      return 'Terms resource is missing: the brand has no embedded page of type "$termsType".';
    }

    final uri = terms['uri'];
    if (uri is! String || uri.trim().isEmpty) {
      return 'Terms resource has no address: the embedded page of type "$termsType" has an empty "uri".';
    }

    return null;
  }
}
