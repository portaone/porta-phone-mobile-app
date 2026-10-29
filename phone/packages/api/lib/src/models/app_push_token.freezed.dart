// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_push_token.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppPushToken {


/// Create a copy of AppPushToken
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppPushTokenCopyWith<AppPushToken> get copyWith => _$AppPushTokenCopyWithImpl<AppPushToken>(this as AppPushToken, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppPushToken;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppPushToken&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.value, _this.value) || other.value == _this.value)&&(identical(other.env, _this.env) || other.env == _this.env));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppPushToken;
  return Object.hash(runtimeType,_this.type,_this.value,_this.env);
}

@override
String toString() {
  final _this = this as AppPushToken;
  return 'AppPushToken(type: ${_this.type}, value: ${_this.value}, env: ${_this.env})';
}


}

/// @nodoc
abstract mixin class $AppPushTokenCopyWith<$Res>  {
  factory $AppPushTokenCopyWith(AppPushToken value, $Res Function(AppPushToken) _then) = _$AppPushTokenCopyWithImpl;
@useResult
$Res call({
 AppPushTokenType type, String value, AppPushTokenEnv? env
});




}
/// @nodoc
class _$AppPushTokenCopyWithImpl<$Res>
    implements $AppPushTokenCopyWith<$Res> {
  _$AppPushTokenCopyWithImpl(this._self, this._then);

  final AppPushToken _self;
  final $Res Function(AppPushToken) _then;

/// Create a copy of AppPushToken
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? value = null,Object? env = freezed,}) {
  return _then(AppPushToken(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AppPushTokenType,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,env: freezed == env ? _self.env : env // ignore: cast_nullable_to_non_nullable
as AppPushTokenEnv?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppPushToken].
extension AppPushTokenPatterns on AppPushToken {
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
