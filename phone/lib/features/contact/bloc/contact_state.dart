part of 'contact_bloc.dart';

@freezed
class ContactState with _$ContactState {
  const ContactState({this.contact, this.registeredAsOf, this.deleted = false, this.presenceInfo = const []});

  final Contact? contact;

  /// When the contact's registration flag was last read from the contact
  /// list. Kept beside the contact, not in it: it moves on every refresh of
  /// the list, and the card has to follow it while the contact itself stays
  /// equal.
  final DateTime? registeredAsOf;

  final bool deleted;

  final List<PresenceInfo> presenceInfo;
}
