part of 'contact_bloc.dart';

@freezed
class ContactState with _$ContactState {
  const ContactState({this.contact, this.deleted = false, this.presenceInfo = const []});

  final Contact? contact;

  final bool deleted;

  final List<PresenceInfo> presenceInfo;
}
