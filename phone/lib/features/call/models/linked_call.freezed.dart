// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'linked_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LinkedCall {


/// Create a copy of LinkedCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedCallCopyWith<LinkedCall> get copyWith => _$LinkedCallCopyWithImpl<LinkedCall>(this as LinkedCall, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as LinkedCall;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedCall&&(identical(other.callId, _this.callId) || other.callId == _this.callId)&&(identical(other.anchorCallId, _this.anchorCallId) || other.anchorCallId == _this.anchorCallId)&&(identical(other.purpose, _this.purpose) || other.purpose == _this.purpose)&&(identical(other.anchorWasLive, _this.anchorWasLive) || other.anchorWasLive == _this.anchorWasLive)&&(identical(other.intoRoom, _this.intoRoom) || other.intoRoom == _this.intoRoom)&&(identical(other.awaitingRoom, _this.awaitingRoom) || other.awaitingRoom == _this.awaitingRoom)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as LinkedCall;
  return Object.hash(runtimeType,_this.callId,_this.anchorCallId,_this.purpose,_this.anchorWasLive,_this.intoRoom,_this.awaitingRoom,_this.failure);
}

@override
String toString() {
  final _this = this as LinkedCall;
  return 'LinkedCall(callId: ${_this.callId}, anchorCallId: ${_this.anchorCallId}, purpose: ${_this.purpose}, anchorWasLive: ${_this.anchorWasLive}, intoRoom: ${_this.intoRoom}, awaitingRoom: ${_this.awaitingRoom}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $LinkedCallCopyWith<$Res>  {
  factory $LinkedCallCopyWith(LinkedCall value, $Res Function(LinkedCall) _then) = _$LinkedCallCopyWithImpl;
@useResult
$Res call({
 String callId, String anchorCallId, LinkedCallPurpose purpose, bool anchorWasLive, bool intoRoom, bool awaitingRoom, LinkedCallFailure? failure
});




}
/// @nodoc
class _$LinkedCallCopyWithImpl<$Res>
    implements $LinkedCallCopyWith<$Res> {
  _$LinkedCallCopyWithImpl(this._self, this._then);

  final LinkedCall _self;
  final $Res Function(LinkedCall) _then;

/// Create a copy of LinkedCall
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? callId = null,Object? anchorCallId = null,Object? purpose = null,Object? anchorWasLive = null,Object? intoRoom = null,Object? awaitingRoom = null,Object? failure = freezed,}) {
  return _then(LinkedCall(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,anchorCallId: null == anchorCallId ? _self.anchorCallId : anchorCallId // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as LinkedCallPurpose,anchorWasLive: null == anchorWasLive ? _self.anchorWasLive : anchorWasLive // ignore: cast_nullable_to_non_nullable
as bool,intoRoom: null == intoRoom ? _self.intoRoom : intoRoom // ignore: cast_nullable_to_non_nullable
as bool,awaitingRoom: null == awaitingRoom ? _self.awaitingRoom : awaitingRoom // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as LinkedCallFailure?,
  ));
}

}


/// Adds pattern-matching-related methods to [LinkedCall].
extension LinkedCallPatterns on LinkedCall {
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
