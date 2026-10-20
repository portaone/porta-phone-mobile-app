import 'package:equatable/equatable.dart';

import 'settings_sync_metadata.dart';

class CallerIdSettings extends Equatable {
  const CallerIdSettings({this.defaultNumber, this.matchers = const []});

  final String? defaultNumber;
  final List<NumberMatcher> matchers;

  @override
  List<Object?> get props => [defaultNumber, matchers];

  @override
  String toString() {
    return 'CallerIdSettings(defaultNumber: $defaultNumber, matchers: $matchers)';
  }

  CallerIdSettings copyWithDefaultNumber(String? defaultNumber) {
    return CallerIdSettings(defaultNumber: defaultNumber, matchers: matchers);
  }

  CallerIdSettings copyWithMatchers(List<NumberMatcher> matchers) {
    return CallerIdSettings(defaultNumber: defaultNumber, matchers: matchers);
  }
}

sealed class NumberMatcher {
  bool match(String destinationNumber);
  String get number;
  int get matchIndex;
}

final class PrefixMatcher extends NumberMatcher with EquatableMixin {
  PrefixMatcher(this.prefix, this.number, {this.country});
  final String prefix;

  @override
  final String number;

  /// ISO 3166-1 alpha-2 code of the country picked for [prefix], or null for a
  /// rule saved before the country was kept. Several countries can share one
  /// dial code, so the prefix alone cannot say which flag to show; matching
  /// ignores it and goes by [prefix] only.
  final String? country;

  @override
  bool match(String destinationNumber) {
    final prefixTrim = prefix.startsWith('+') ? prefix.substring(1) : prefix;
    final destTrim = destinationNumber.startsWith('+') ? destinationNumber.substring(1) : destinationNumber;
    return destTrim.startsWith(prefixTrim);
  }

  @override
  int get matchIndex => prefix.length;

  @override
  String toString() => 'PrefixMatcher(prefix: $prefix, number: $number, country: $country)';

  @override
  List<Object?> get props => [prefix, number, country];

  /// A new [prefix] drops the country unless one comes with it: a country is
  /// picked for a dial code and does not carry over to another one.
  PrefixMatcher copyWith({String? prefix, String? number, String? country}) {
    final keepsPrefix = prefix == null || prefix == this.prefix;
    return PrefixMatcher(
      prefix ?? this.prefix,
      number ?? this.number,
      country: country ?? (keepsPrefix ? this.country : null),
    );
  }
}

typedef SyncableCallerIdSettings = (CallerIdSettings settings, SettingsSyncMetadata metadata);
