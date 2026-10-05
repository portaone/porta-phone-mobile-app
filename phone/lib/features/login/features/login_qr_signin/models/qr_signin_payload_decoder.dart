import 'qr_signin_parse_result.dart';

/// One payload format the QR sign-in understands.
///
/// Decoders are probed in order by `QrSigninPayloadParser`: the first one that
/// RECOGNIZES the payload wins and fully decides the outcome (including
/// failures such as a host mismatch). Returning null means "this is not my
/// format, let the next decoder try" - it must be reserved for payloads the
/// decoder cannot claim at all, never for recognized-but-invalid ones.
abstract interface class QrSigninPayloadDecoder {
  QrSigninParseResult? decode(String raw);
}

/// Key names with a meaning fixed for every payload format.
///
/// A key is compared by its [normalize]d form, so `CORE` or ` core` is the
/// same reserved key as `core` and cannot pass as an unknown extra.
abstract final class QrSigninReservedKeys {
  /// Keys that would redirect the sign-in to another core; rejected because a
  /// scanned code must not choose where credentials go.
  static const coreOverride = {'core', 'tenant', 'core_url', 'tenant_id'};

  static String normalize(String key) => key.trim().toLowerCase();

  static bool isCoreOverride(String key) => coreOverride.contains(normalize(key));
}
