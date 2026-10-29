// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'call_service_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CallServiceState {


/// Create a copy of CallServiceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CallServiceStateCopyWith<CallServiceState> get copyWith => _$CallServiceStateCopyWithImpl<CallServiceState>(this as CallServiceState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CallServiceState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CallServiceState&&(identical(other.signalingClientStatus, _this.signalingClientStatus) || other.signalingClientStatus == _this.signalingClientStatus)&&(identical(other.registration, _this.registration) || other.registration == _this.registration)&&(identical(other.networkStatus, _this.networkStatus) || other.networkStatus == _this.networkStatus)&&const DeepCollectionEquality().equals(other.lastSignalingClientConnectError, _this.lastSignalingClientConnectError)&&const DeepCollectionEquality().equals(other.lastSignalingClientDisconnectError, _this.lastSignalingClientDisconnectError)&&(identical(other.lastSignalingDisconnectCode, _this.lastSignalingDisconnectCode) || other.lastSignalingDisconnectCode == _this.lastSignalingDisconnectCode));
}


@override
int get hashCode {
  final _this = this as CallServiceState;
  return Object.hash(runtimeType,_this.signalingClientStatus,_this.registration,_this.networkStatus,const DeepCollectionEquality().hash(_this.lastSignalingClientConnectError),const DeepCollectionEquality().hash(_this.lastSignalingClientDisconnectError),_this.lastSignalingDisconnectCode);
}

@override
String toString() {
  final _this = this as CallServiceState;
  return 'CallServiceState(signalingClientStatus: ${_this.signalingClientStatus}, registration: ${_this.registration}, networkStatus: ${_this.networkStatus}, lastSignalingClientConnectError: ${_this.lastSignalingClientConnectError}, lastSignalingClientDisconnectError: ${_this.lastSignalingClientDisconnectError}, lastSignalingDisconnectCode: ${_this.lastSignalingDisconnectCode})';
}


}

/// @nodoc
abstract mixin class $CallServiceStateCopyWith<$Res>  {
  factory $CallServiceStateCopyWith(CallServiceState value, $Res Function(CallServiceState) _then) = _$CallServiceStateCopyWithImpl;
@useResult
$Res call({
 SignalingClientStatus signalingClientStatus, Registration? registration, NetworkStatus? networkStatus, Object? lastSignalingClientConnectError, Object? lastSignalingClientDisconnectError, int? lastSignalingDisconnectCode
});




}
/// @nodoc
class _$CallServiceStateCopyWithImpl<$Res>
    implements $CallServiceStateCopyWith<$Res> {
  _$CallServiceStateCopyWithImpl(this._self, this._then);

  final CallServiceState _self;
  final $Res Function(CallServiceState) _then;

/// Create a copy of CallServiceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? signalingClientStatus = null,Object? registration = freezed,Object? networkStatus = freezed,Object? lastSignalingClientConnectError = freezed,Object? lastSignalingClientDisconnectError = freezed,Object? lastSignalingDisconnectCode = freezed,}) {
  return _then(CallServiceState(
signalingClientStatus: null == signalingClientStatus ? _self.signalingClientStatus : signalingClientStatus // ignore: cast_nullable_to_non_nullable
as SignalingClientStatus,registration: freezed == registration ? _self.registration : registration // ignore: cast_nullable_to_non_nullable
as Registration?,networkStatus: freezed == networkStatus ? _self.networkStatus : networkStatus // ignore: cast_nullable_to_non_nullable
as NetworkStatus?,lastSignalingClientConnectError: freezed == lastSignalingClientConnectError ? _self.lastSignalingClientConnectError : lastSignalingClientConnectError ,lastSignalingClientDisconnectError: freezed == lastSignalingClientDisconnectError ? _self.lastSignalingClientDisconnectError : lastSignalingClientDisconnectError ,lastSignalingDisconnectCode: freezed == lastSignalingDisconnectCode ? _self.lastSignalingDisconnectCode : lastSignalingDisconnectCode // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CallServiceState].
extension CallServiceStatePatterns on CallServiceState {
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
