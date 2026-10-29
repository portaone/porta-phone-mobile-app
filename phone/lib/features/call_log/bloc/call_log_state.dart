part of 'call_log_bloc.dart';

@freezed
class CallLogState with _$CallLogState {
  const CallLogState({required this.number, this.contact, this.callLog});

  final String number;

  final Contact? contact;

  final List<CallLogEntry>? callLog;

  @override
  toString() {
    return 'CallLogState {number: $number, contact: $contact, callLog: ${callLog?.length ?? 0}}';
  }
}
