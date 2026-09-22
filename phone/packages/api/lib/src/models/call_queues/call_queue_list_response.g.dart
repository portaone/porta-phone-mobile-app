// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_queue_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallQueueListResponse _$CallQueueListResponseFromJson(Map<String, dynamic> json) => CallQueueListResponse(
  items: (json['items'] as List<dynamic>).map((e) => CallQueue.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$CallQueueListResponseToJson(CallQueueListResponse instance) => <String, dynamic>{
  'items': instance.items.map((e) => e.toJson()).toList(),
};
