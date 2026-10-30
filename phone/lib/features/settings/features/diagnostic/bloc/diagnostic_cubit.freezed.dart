// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'diagnostic_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DiagnosticState {


/// Create a copy of DiagnosticState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiagnosticStateCopyWith<DiagnosticState> get copyWith => _$DiagnosticStateCopyWithImpl<DiagnosticState>(this as DiagnosticState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DiagnosticState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiagnosticState&&const DeepCollectionEquality().equals(other.permissions, _this.permissions)&&(identical(other.pushTokenStatus, _this.pushTokenStatus) || other.pushTokenStatus == _this.pushTokenStatus)&&(identical(other.batteryMode, _this.batteryMode) || other.batteryMode == _this.batteryMode)&&(identical(other.callDeliveryMode, _this.callDeliveryMode) || other.callDeliveryMode == _this.callDeliveryMode)&&(identical(other.isXiaomiDevice, _this.isXiaomiDevice) || other.isXiaomiDevice == _this.isXiaomiDevice)&&(identical(other.backgroundActivityStartStatus, _this.backgroundActivityStartStatus) || other.backgroundActivityStartStatus == _this.backgroundActivityStartStatus)&&(identical(other.showWhenLockedStatus, _this.showWhenLockedStatus) || other.showWhenLockedStatus == _this.showWhenLockedStatus)&&(identical(other.fullScreenIntentStatus, _this.fullScreenIntentStatus) || other.fullScreenIntentStatus == _this.fullScreenIntentStatus));
}


@override
int get hashCode {
  final _this = this as DiagnosticState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.permissions),_this.pushTokenStatus,_this.batteryMode,_this.callDeliveryMode,_this.isXiaomiDevice,_this.backgroundActivityStartStatus,_this.showWhenLockedStatus,_this.fullScreenIntentStatus);
}

@override
String toString() {
  final _this = this as DiagnosticState;
  return 'DiagnosticState(permissions: ${_this.permissions}, pushTokenStatus: ${_this.pushTokenStatus}, batteryMode: ${_this.batteryMode}, callDeliveryMode: ${_this.callDeliveryMode}, isXiaomiDevice: ${_this.isXiaomiDevice}, backgroundActivityStartStatus: ${_this.backgroundActivityStartStatus}, showWhenLockedStatus: ${_this.showWhenLockedStatus}, fullScreenIntentStatus: ${_this.fullScreenIntentStatus})';
}


}

/// @nodoc
abstract mixin class $DiagnosticStateCopyWith<$Res>  {
  factory $DiagnosticStateCopyWith(DiagnosticState value, $Res Function(DiagnosticState) _then) = _$DiagnosticStateCopyWithImpl;
@useResult
$Res call({
 List<PermissionWithStatus> permissions, PushTokenStatus pushTokenStatus, CallkeepAndroidBatteryMode batteryMode, CallkeepAndroidCallDeliveryMode callDeliveryMode, bool isXiaomiDevice, CallkeepSpecialPermissionStatus backgroundActivityStartStatus, CallkeepSpecialPermissionStatus showWhenLockedStatus, CallkeepSpecialPermissionStatus fullScreenIntentStatus
});




}
/// @nodoc
class _$DiagnosticStateCopyWithImpl<$Res>
    implements $DiagnosticStateCopyWith<$Res> {
  _$DiagnosticStateCopyWithImpl(this._self, this._then);

  final DiagnosticState _self;
  final $Res Function(DiagnosticState) _then;

/// Create a copy of DiagnosticState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? permissions = null,Object? pushTokenStatus = null,Object? batteryMode = null,Object? callDeliveryMode = null,Object? isXiaomiDevice = null,Object? backgroundActivityStartStatus = null,Object? showWhenLockedStatus = null,Object? fullScreenIntentStatus = null,}) {
  return _then(DiagnosticState(
permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<PermissionWithStatus>,pushTokenStatus: null == pushTokenStatus ? _self.pushTokenStatus : pushTokenStatus // ignore: cast_nullable_to_non_nullable
as PushTokenStatus,batteryMode: null == batteryMode ? _self.batteryMode : batteryMode // ignore: cast_nullable_to_non_nullable
as CallkeepAndroidBatteryMode,callDeliveryMode: null == callDeliveryMode ? _self.callDeliveryMode : callDeliveryMode // ignore: cast_nullable_to_non_nullable
as CallkeepAndroidCallDeliveryMode,isXiaomiDevice: null == isXiaomiDevice ? _self.isXiaomiDevice : isXiaomiDevice // ignore: cast_nullable_to_non_nullable
as bool,backgroundActivityStartStatus: null == backgroundActivityStartStatus ? _self.backgroundActivityStartStatus : backgroundActivityStartStatus // ignore: cast_nullable_to_non_nullable
as CallkeepSpecialPermissionStatus,showWhenLockedStatus: null == showWhenLockedStatus ? _self.showWhenLockedStatus : showWhenLockedStatus // ignore: cast_nullable_to_non_nullable
as CallkeepSpecialPermissionStatus,fullScreenIntentStatus: null == fullScreenIntentStatus ? _self.fullScreenIntentStatus : fullScreenIntentStatus // ignore: cast_nullable_to_non_nullable
as CallkeepSpecialPermissionStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [DiagnosticState].
extension DiagnosticStatePatterns on DiagnosticState {
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
