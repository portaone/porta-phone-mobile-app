enum CallkeepCallRequestError {
  unknown,
  unentitled,
  unknownCallUuid,
  callUuidAlreadyExists,
  maximumCallGroupsReached,
  internal,
  emergencyNumber,

  /// Android only.
  ///
  /// Triggered when the phone is not registered as a self-managed
  /// [PhoneAccount]. As a result, the `ConnectionService` cannot create
  /// a connection, and the system throws an exception such as
  /// `CALL_PHONE permission required to place calls`, because it attempts
  /// to use the GSM dialer instead of VoIP.
  selfManagedPhoneAccountNotRegistered,

  /// Android only.
  ///
  /// Occurs when the outgoing/incoming call request times out because the
  /// system TelecomManager failed to bind to the ConnectionService or provide
  /// a response within the expected timeframe.
  ///
  /// Typical causes:
  /// - Stale Binding: After an app crash or OS kill, TelecomManager might
  ///   retain a dead connection to the previous process (Zombie State).
  /// - System Overload: The OS fails to trigger `onCreateOutgoingConnection`
  ///   due to internal resource constraints.
  /// - Cold Start Race: On some vendors, the service takes too long to bind
  ///   during a cold start following a "dirty" process termination.
  timeout,

  /// The active call backend cannot group calls at the OS level.
  ///
  /// Grouping is a presentation concern: the calls themselves keep working, the
  /// system simply shows them separately. Callers are expected to log this and
  /// carry on rather than tear the calls down.
  callGroupingNotSupported,

  /// The call is a member of a call group, and a member is never held on its own.
  ///
  /// Hold is refused rather than performed: the calls of a group are one thing
  /// to the OS, and holding one of them would leave the group with a member
  /// nobody can hear. Ungroup first, then hold.
  callIsGrouped,
}
