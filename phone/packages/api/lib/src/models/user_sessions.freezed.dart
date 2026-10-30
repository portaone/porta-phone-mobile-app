// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_sessions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$UserSessionList {


/// Create a copy of UserSessionList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSessionListCopyWith<UserSessionList> get copyWith => _$UserSessionListCopyWithImpl<UserSessionList>(this as UserSessionList, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserSessionList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSessionList&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.autoTerminate, _this.autoTerminate) || other.autoTerminate == _this.autoTerminate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserSessionList;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.autoTerminate);
}

@override
String toString() {
  final _this = this as UserSessionList;
  return 'UserSessionList(items: ${_this.items}, autoTerminate: ${_this.autoTerminate})';
}


}

/// @nodoc
abstract mixin class $UserSessionListCopyWith<$Res>  {
  factory $UserSessionListCopyWith(UserSessionList value, $Res Function(UserSessionList) _then) = _$UserSessionListCopyWithImpl;
@useResult
$Res call({
 List<UserSession> items, UserSessionsAutoTerminate? autoTerminate
});




}
/// @nodoc
class _$UserSessionListCopyWithImpl<$Res>
    implements $UserSessionListCopyWith<$Res> {
  _$UserSessionListCopyWithImpl(this._self, this._then);

  final UserSessionList _self;
  final $Res Function(UserSessionList) _then;

/// Create a copy of UserSessionList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? autoTerminate = freezed,}) {
  return _then(UserSessionList(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<UserSession>,autoTerminate: freezed == autoTerminate ? _self.autoTerminate : autoTerminate // ignore: cast_nullable_to_non_nullable
as UserSessionsAutoTerminate?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSessionList].
extension UserSessionListPatterns on UserSessionList {
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
mixin _$UserSessionsAutoTerminate {


/// Create a copy of UserSessionsAutoTerminate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserSessionsAutoTerminateCopyWith<UserSessionsAutoTerminate> get copyWith => _$UserSessionsAutoTerminateCopyWithImpl<UserSessionsAutoTerminate>(this as UserSessionsAutoTerminate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as UserSessionsAutoTerminate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserSessionsAutoTerminate&&(identical(other.inactivityTimeoutDays, _this.inactivityTimeoutDays) || other.inactivityTimeoutDays == _this.inactivityTimeoutDays)&&(identical(other.installationMaxDays, _this.installationMaxDays) || other.installationMaxDays == _this.installationMaxDays));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as UserSessionsAutoTerminate;
  return Object.hash(runtimeType,_this.inactivityTimeoutDays,_this.installationMaxDays);
}

@override
String toString() {
  final _this = this as UserSessionsAutoTerminate;
  return 'UserSessionsAutoTerminate(inactivityTimeoutDays: ${_this.inactivityTimeoutDays}, installationMaxDays: ${_this.installationMaxDays})';
}


}

/// @nodoc
abstract mixin class $UserSessionsAutoTerminateCopyWith<$Res>  {
  factory $UserSessionsAutoTerminateCopyWith(UserSessionsAutoTerminate value, $Res Function(UserSessionsAutoTerminate) _then) = _$UserSessionsAutoTerminateCopyWithImpl;
@useResult
$Res call({
 int? inactivityTimeoutDays, int? installationMaxDays
});




}
/// @nodoc
class _$UserSessionsAutoTerminateCopyWithImpl<$Res>
    implements $UserSessionsAutoTerminateCopyWith<$Res> {
  _$UserSessionsAutoTerminateCopyWithImpl(this._self, this._then);

  final UserSessionsAutoTerminate _self;
  final $Res Function(UserSessionsAutoTerminate) _then;

/// Create a copy of UserSessionsAutoTerminate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inactivityTimeoutDays = freezed,Object? installationMaxDays = freezed,}) {
  return _then(UserSessionsAutoTerminate(
inactivityTimeoutDays: freezed == inactivityTimeoutDays ? _self.inactivityTimeoutDays : inactivityTimeoutDays // ignore: cast_nullable_to_non_nullable
as int?,installationMaxDays: freezed == installationMaxDays ? _self.installationMaxDays : installationMaxDays // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserSessionsAutoTerminate].
extension UserSessionsAutoTerminatePatterns on UserSessionsAutoTerminate {
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
