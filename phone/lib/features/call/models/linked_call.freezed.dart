// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'linked_call.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LinkedCall {

 String get callId; String get anchorCallId; LinkedCallPurpose get purpose; bool get anchorWasLive; LinkedCallFailure? get failure;
/// Create a copy of LinkedCall
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkedCallCopyWith<LinkedCall> get copyWith => _$LinkedCallCopyWithImpl<LinkedCall>(this as LinkedCall, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkedCall&&(identical(other.callId, callId) || other.callId == callId)&&(identical(other.anchorCallId, anchorCallId) || other.anchorCallId == anchorCallId)&&(identical(other.purpose, purpose) || other.purpose == purpose)&&(identical(other.anchorWasLive, anchorWasLive) || other.anchorWasLive == anchorWasLive)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,callId,anchorCallId,purpose,anchorWasLive,failure);

@override
String toString() {
  return 'LinkedCall(callId: $callId, anchorCallId: $anchorCallId, purpose: $purpose, anchorWasLive: $anchorWasLive, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $LinkedCallCopyWith<$Res>  {
  factory $LinkedCallCopyWith(LinkedCall value, $Res Function(LinkedCall) _then) = _$LinkedCallCopyWithImpl;
@useResult
$Res call({
 String callId, String anchorCallId, LinkedCallPurpose purpose, bool anchorWasLive, LinkedCallFailure? failure
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
@pragma('vm:prefer-inline') @override $Res call({Object? callId = null,Object? anchorCallId = null,Object? purpose = null,Object? anchorWasLive = null,Object? failure = freezed,}) {
  return _then(LinkedCall(
callId: null == callId ? _self.callId : callId // ignore: cast_nullable_to_non_nullable
as String,anchorCallId: null == anchorCallId ? _self.anchorCallId : anchorCallId // ignore: cast_nullable_to_non_nullable
as String,purpose: null == purpose ? _self.purpose : purpose // ignore: cast_nullable_to_non_nullable
as LinkedCallPurpose,anchorWasLive: null == anchorWasLive ? _self.anchorWasLive : anchorWasLive // ignore: cast_nullable_to_non_nullable
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
