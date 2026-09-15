import 'api_failure_rules.dart';

enum ResponseType { json, bytes, raw }

class ResponseOptions {
  final ResponseType responseType;

  /// Marks the endpoint as optional in the adapter contract: a 404 or 501
  /// response is reported as [EndpointNotSupportedException] instead of a
  /// plain [RequestFailure].
  ///
  /// This one stays a flag rather than a rule because it reads the ABSENCE of a
  /// backend error code - an endpoint that is not there at all - where a rule
  /// recognises a code that is present.
  final bool optionalEndpoint;

  /// Failures that mean something particular to this endpoint.
  ///
  /// Consulted before [defaultFailureRules], so an endpoint can both add a
  /// condition of its own and answer one of the shared ones differently.
  final List<FailureRule> failures;

  const ResponseOptions({
    this.responseType = ResponseType.json,
    this.optionalEndpoint = false,
    this.failures = const [],
  });
}
