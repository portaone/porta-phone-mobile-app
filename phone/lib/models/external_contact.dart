import 'package:equatable/equatable.dart';

import '../utils/utils.dart';

class ExternalContact extends Equatable {
  const ExternalContact({
    this.id,
    this.registered,
    this.userRegistered,
    this.isCurrentUser,
    this.firstName,
    this.lastName,
    this.aliasName,
    this.number,
    this.ext,
    this.additional,
    this.smsNumbers,
    this.email,
  });

  final String? id;

  /// SIP Registered status
  final bool? registered;

  /// User account registered status
  final bool? userRegistered;

  /// Is currently loggined user
  final bool? isCurrentUser;

  final String? firstName;
  final String? lastName;
  final String? aliasName;
  final String? number;
  final String? ext;
  final List<String>? additional;
  final List<String>? smsNumbers;
  final String? email;

  /// What a [safeSourceId] starts with when the server gave no id of its own.
  ///
  /// Stored verbatim in the contacts table, so this is the only thing telling a
  /// real server id from one this app made up - and anything that needs a real
  /// one, such as addressing a user on the backend, has to ask.
  static const syntheticSourceIdPrefixes = ['number_', 'email_', 'hash_'];

  /// Whether [sourceId] was invented here rather than issued by the server.
  ///
  /// A prefix match is all there is to go on: nothing records which branch of
  /// [safeSourceId] produced a value. A server id that genuinely began with one
  /// of these prefixes would be misread as synthetic, which errs towards not
  /// offering an action rather than towards addressing the wrong user.
  static bool isSyntheticSourceId(String sourceId) => syntheticSourceIdPrefixes.any(sourceId.startsWith);

  /// Returns a stable, non-null sourceId for synchronization and deduplication purposes.
  /// Priority:
  ///   1. `id` (API-provided unique identifier)
  ///   2. `number`, `mobile`, `email`
  ///   3. deterministic hash of name/email
  ///   4. fallback hash for anonymous or incomplete contacts (e.g. empty fields)
  String get safeSourceId {
    if (id?.trim().isNotEmpty ?? false) {
      return id!;
    }

    if (number?.trim().isNotEmpty ?? false) {
      return 'number_${number!.trim()}';
    }

    if (email?.trim().isNotEmpty ?? false) {
      return 'email_${email!.trim()}';
    }

    // Generate a deterministic fallback sourceId based on contact's name and email.
    // Ensures stable identity across syncs when no ID, number, mobile, or email is available.
    // May still produce collisions if fields are empty or identical across multiple contacts.
    final stableKey = '${firstName ?? ''}_${lastName ?? ''}_${email ?? ''}'.toLowerCase().trim();
    final hash = stableKey.hashCode;

    return 'hash_$hash';
  }

  @override
  List<Object?> get props => [
    id,
    registered,
    userRegistered,
    isCurrentUser,
    firstName,
    lastName,
    aliasName,
    number,
    ext,
    additional != null ? EquatablePropToString.list(additional!) : null,
    smsNumbers != null ? EquatablePropToString.list(smsNumbers!) : null,
    email,
  ];
}
