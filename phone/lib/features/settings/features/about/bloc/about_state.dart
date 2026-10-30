part of 'about_bloc.dart';

@freezed
class AboutState with _$AboutState {
  const AboutState({
    this.progress = false,
    this.embeddedResources = const [],
    required this.packageName,
    required this.appIdentifier,
    required this.coreUrl,
    required this.userAgent,
    required this.appInfo,
    required this.deviceInfo,
    this.fcmPushToken,
    this.coreVersion,
    this.bundleVersion,
  });

  final bool progress;

  /// Every embedded resource this build is configured with, in configuration
  /// order. Carried as the resources themselves rather than their addresses:
  /// the About screen opens one, and that needs the whole resource.
  final List<EmbeddedData> embeddedResources;

  final String packageName;

  final String appIdentifier;

  final Uri coreUrl;

  final String userAgent;

  final String appInfo;

  final String deviceInfo;

  final String? fcmPushToken;

  final Version? coreVersion;

  /// Version of the deployment bundle (e.g. the Add-on Mart package version).
  /// `null` = the backend does not provide it; the About screen hides the row.
  final String? bundleVersion;
}
