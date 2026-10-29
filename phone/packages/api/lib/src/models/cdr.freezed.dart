// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cdr.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CdrRecord {


/// Create a copy of CdrRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CdrRecordCopyWith<CdrRecord> get copyWith => _$CdrRecordCopyWithImpl<CdrRecord>(this as CdrRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CdrRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CdrRecord&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.callee, _this.callee) || other.callee == _this.callee)&&(identical(other.caller, _this.caller) || other.caller == _this.caller)&&(identical(other.connectTime, _this.connectTime) || other.connectTime == _this.connectTime)&&(identical(other.direction, _this.direction) || other.direction == _this.direction)&&(identical(other.disconnectReason, _this.disconnectReason) || other.disconnectReason == _this.disconnectReason)&&(identical(other.disconnectTime, _this.disconnectTime) || other.disconnectTime == _this.disconnectTime)&&(identical(other.duration, _this.duration) || other.duration == _this.duration)&&const DeepCollectionEquality().equals(other.recordingId, _this.recordingId)&&(identical(other.status, _this.status) || other.status == _this.status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CdrRecord;
  return Object.hash(runtimeType,_this.callId,_this.callee,_this.caller,_this.connectTime,_this.direction,_this.disconnectReason,_this.disconnectTime,_this.duration,const DeepCollectionEquality().hash(_this.recordingId),_this.status);
}

@override
String toString() {
  final _this = this as CdrRecord;
  return 'CdrRecord(callId: ${_this.callId}, callee: ${_this.callee}, caller: ${_this.caller}, connectTime: ${_this.connectTime}, direction: ${_this.direction}, disconnectReason: ${_this.disconnectReason}, disconnectTime: ${_this.disconnectTime}, duration: ${_this.duration}, recordingId: ${_this.recordingId}, status: ${_this.status})';
}


}

/// @nodoc
abstract mixin class $CdrRecordCopyWith<$Res>  {
  factory $CdrRecordCopyWith(CdrRecord value, $Res Function(CdrRecord) _then) = _$CdrRecordCopyWithImpl;
@useResult
$Res call({
 String callId, String callee, String caller, DateTime connectTime, CdrDirection direction, String disconnectReason, DateTime disconnectTime, int duration, dynamic recordingId, CdrStatus status
});




}
/// @nodoc
class _$CdrRecordCopyWithImpl<$Res>
    implements $CdrRecordCopyWith<$Res> {
  _$CdrRecordCopyWithImpl(this._self, this._then);

  final CdrRecord _self;
  final $Res Function(CdrRecord) _then;

/// Create a copy of CdrRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callId = null,Object? callee = null,Object? caller = null,Object? connectTime = null,Object? direction = null,Object? disconnectReason = null,Object? disconnectTime = null,Object? duration = null,Object? recordingId = freezed,Object? status = null,}) {
  return _then(CdrRecord(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,callee: null == callee ? _self.callee : callee // ignore: cast_nullable_to_non_nullable
as String,caller: null == caller ? _self.caller : caller // ignore: cast_nullable_to_non_nullable
as String,connectTime: null == connectTime ? _self.connectTime : connectTime // ignore: cast_nullable_to_non_nullable
as DateTime,direction: null == direction ? _self.direction : direction // ignore: cast_nullable_to_non_nullable
as CdrDirection,disconnectReason: null == disconnectReason ? _self.disconnectReason : disconnectReason // ignore: cast_nullable_to_non_nullable
as String,disconnectTime: null == disconnectTime ? _self.disconnectTime : disconnectTime // ignore: cast_nullable_to_non_nullable
as DateTime,duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as int,recordingId: freezed == recordingId ? _self.recordingId : recordingId // ignore: cast_nullable_to_non_nullable
as dynamic,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CdrStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [CdrRecord].
extension CdrRecordPatterns on CdrRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}


/// @nodoc
mixin _$CdrHistoryResponse {


/// Create a copy of CdrHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CdrHistoryResponseCopyWith<CdrHistoryResponse> get copyWith => _$CdrHistoryResponseCopyWithImpl<CdrHistoryResponse>(this as CdrHistoryResponse, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CdrHistoryResponse;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CdrHistoryResponse&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.pagination, _this.pagination) || other.pagination == _this.pagination));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CdrHistoryResponse;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.pagination);
}

@override
String toString() {
  final _this = this as CdrHistoryResponse;
  return 'CdrHistoryResponse(items: ${_this.items}, pagination: ${_this.pagination})';
}


}

/// @nodoc
abstract mixin class $CdrHistoryResponseCopyWith<$Res>  {
  factory $CdrHistoryResponseCopyWith(CdrHistoryResponse value, $Res Function(CdrHistoryResponse) _then) = _$CdrHistoryResponseCopyWithImpl;
@useResult
$Res call({
 List<CdrRecord> items, Pagination? pagination
});




}
/// @nodoc
class _$CdrHistoryResponseCopyWithImpl<$Res>
    implements $CdrHistoryResponseCopyWith<$Res> {
  _$CdrHistoryResponseCopyWithImpl(this._self, this._then);

  final CdrHistoryResponse _self;
  final $Res Function(CdrHistoryResponse) _then;

/// Create a copy of CdrHistoryResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? pagination = freezed,}) {
  return _then(CdrHistoryResponse(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CdrRecord>,pagination: freezed == pagination ? _self.pagination : pagination // ignore: cast_nullable_to_non_nullable
as Pagination?,
  ));
}

}


/// Adds pattern-matching-related methods to [CdrHistoryResponse].
extension CdrHistoryResponsePatterns on CdrHistoryResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({required TResult orElse(),}){
final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(){
final _that = this;
switch (_that) {
case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({required TResult orElse(),}) {final _that = this;
switch (_that) {
case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>() {final _that = this;
switch (_that) {
case _:
  return null;

}
}

}

// dart format on
