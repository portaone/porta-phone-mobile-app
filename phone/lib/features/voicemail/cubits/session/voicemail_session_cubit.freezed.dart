// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voicemail_session_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VoicemailSessionState {

 VoicemailStatus get status; List<Voicemail> get items; int get unreadCount; Map<String, String> get forwarderNames; Map<String, VoicemailForward> get forwards; Object? get error;
/// Create a copy of VoicemailSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VoicemailSessionStateCopyWith<VoicemailSessionState> get copyWith => _$VoicemailSessionStateCopyWithImpl<VoicemailSessionState>(this as VoicemailSessionState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VoicemailSessionState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other.forwarderNames, forwarderNames)&&const DeepCollectionEquality().equals(other.forwards, forwards)&&const DeepCollectionEquality().equals(other.error, error));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(items),unreadCount,const DeepCollectionEquality().hash(forwarderNames),const DeepCollectionEquality().hash(forwards),const DeepCollectionEquality().hash(error));



}

/// @nodoc
abstract mixin class $VoicemailSessionStateCopyWith<$Res>  {
  factory $VoicemailSessionStateCopyWith(VoicemailSessionState value, $Res Function(VoicemailSessionState) _then) = _$VoicemailSessionStateCopyWithImpl;
@useResult
$Res call({
 VoicemailStatus status, List<Voicemail> items, int unreadCount, Map<String, String> forwarderNames, Map<String, VoicemailForward> forwards, Object? error
});




}
/// @nodoc
class _$VoicemailSessionStateCopyWithImpl<$Res>
    implements $VoicemailSessionStateCopyWith<$Res> {
  _$VoicemailSessionStateCopyWithImpl(this._self, this._then);

  final VoicemailSessionState _self;
  final $Res Function(VoicemailSessionState) _then;

/// Create a copy of VoicemailSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? items = null,Object? unreadCount = null,Object? forwarderNames = null,Object? forwards = null,Object? error = freezed,}) {
  return _then(VoicemailSessionState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VoicemailStatus,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Voicemail>,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,forwarderNames: null == forwarderNames ? _self.forwarderNames : forwarderNames // ignore: cast_nullable_to_non_nullable
as Map<String, String>,forwards: null == forwards ? _self.forwards : forwards // ignore: cast_nullable_to_non_nullable
as Map<String, VoicemailForward>,error: freezed == error ? _self.error : error ,
  ));
}

}


/// Adds pattern-matching-related methods to [VoicemailSessionState].
extension VoicemailSessionStatePatterns on VoicemailSessionState {
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
