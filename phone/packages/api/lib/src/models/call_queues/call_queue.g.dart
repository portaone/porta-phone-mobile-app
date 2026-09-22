// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallQueue _$CallQueueFromJson(Map<String, dynamic> json) => CallQueue(
  id: json['id'] as String,
  name: json['name'] as String,
  loggedIn: json['logged_in'] as bool,
  agentsTotal: (json['agents_total'] as num).toInt(),
  agentsLoggedIn: (json['agents_logged_in'] as num).toInt(),
  callersWaiting: (json['callers_waiting'] as num?)?.toInt(),
);

Map<String, dynamic> _$CallQueueToJson(CallQueue instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'logged_in': instance.loggedIn,
  'agents_total': instance.agentsTotal,
  'agents_logged_in': instance.agentsLoggedIn,
  'callers_waiting': instance.callersWaiting,
};
