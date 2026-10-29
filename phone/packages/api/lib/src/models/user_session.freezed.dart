// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSession {


/// Create a copy of UserSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSessionCopyWith<UserSession> get copyWith => _$UserSessionCopyWithImpl<UserSession>(this as UserSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.current, _this.current) || other.current == _this.current)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.userAgent, _this.userAgent) || other.userAgent == _this.userAgent)&&(identical(other.ip, _this.ip) || other.ip == _this.ip)&&(identical(other.location, _this.location) || other.location == _this.location)&&(identical(other.lastActivityIp, _this.lastActivityIp) || other.lastActivityIp == _this.lastActivityIp)&&(identical(other.lastActivityLocation, _this.lastActivityLocation) || other.lastActivityLocation == _this.lastActivityLocation)&&(identical(other.appType, _this.appType) || other.appType == _this.appType)&&(identical(other.appIdentifier, _this.appIdentifier) || other.appIdentifier == _this.appIdentifier)&&(identical(other.appBundleId, _this.appBundleId) || other.appBundleId == _this.appBundleId)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.lastActivityAt, _this.lastActivityAt) || other.lastActivityAt == _this.lastActivityAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserSession;
  return Object.hash(runtimeType,_this.id,_this.current,_this.status,_this.userAgent,_this.ip,_this.location,_this.lastActivityIp,_this.lastActivityLocation,_this.appType,_this.appIdentifier,_this.appBundleId,_this.createdAt,_this.lastActivityAt);
}

@override
String toString() {
  final _this = this as UserSession;
  return 'UserSession(id: ${_this.id}, current: ${_this.current}, status: ${_this.status}, userAgent: ${_this.userAgent}, ip: ${_this.ip}, location: ${_this.location}, lastActivityIp: ${_this.lastActivityIp}, lastActivityLocation: ${_this.lastActivityLocation}, appType: ${_this.appType}, appIdentifier: ${_this.appIdentifier}, appBundleId: ${_this.appBundleId}, createdAt: ${_this.createdAt}, lastActivityAt: ${_this.lastActivityAt})';
}


}

/// @nodoc
abstract mixin class $UserSessionCopyWith<$Res>  {
  factory $UserSessionCopyWith(UserSession value, $Res Function(UserSession) _then) = _$UserSessionCopyWithImpl;
@useResult
$Res call({
 String id, bool current, UserSessionStatus status, String? userAgent, String? ip, String? location, String? lastActivityIp, String? lastActivityLocation, AppType? appType, String? appIdentifier, String? appBundleId, DateTime? createdAt, DateTime? lastActivityAt
});




}
/// @nodoc
class _$UserSessionCopyWithImpl<$Res>
    implements $UserSessionCopyWith<$Res> {
  _$UserSessionCopyWithImpl(this._self, this._then);

  final UserSession _self;
  final $Res Function(UserSession) _then;

/// Create a copy of UserSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? current = null,Object? status = null,Object? userAgent = freezed,Object? ip = freezed,Object? location = freezed,Object? lastActivityIp = freezed,Object? lastActivityLocation = freezed,Object? appType = freezed,Object? appIdentifier = freezed,Object? appBundleId = freezed,Object? createdAt = freezed,Object? lastActivityAt = freezed,}) {
  return _then(UserSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,current: null == current ? _self.current : current // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as UserSessionStatus,userAgent: freezed == userAgent ? _self.userAgent : userAgent // ignore: cast_nullable_to_non_nullable
as String?,ip: freezed == ip ? _self.ip : ip // ignore: cast_nullable_to_non_nullable
as String?,location: freezed == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as String?,lastActivityIp: freezed == lastActivityIp ? _self.lastActivityIp : lastActivityIp // ignore: cast_nullable_to_non_nullable
as String?,lastActivityLocation: freezed == lastActivityLocation ? _self.lastActivityLocation : lastActivityLocation // ignore: cast_nullable_to_non_nullable
as String?,appType: freezed == appType ? _self.appType : appType // ignore: cast_nullable_to_non_nullable
as AppType?,appIdentifier: freezed == appIdentifier ? _self.appIdentifier : appIdentifier // ignore: cast_nullable_to_non_nullable
as String?,appBundleId: freezed == appBundleId ? _self.appBundleId : appBundleId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActivityAt: freezed == lastActivityAt ? _self.lastActivityAt : lastActivityAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSession].
extension UserSessionPatterns on UserSession {
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
