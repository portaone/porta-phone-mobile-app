// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_autoprovision_credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SessionAutoProvisionCredential {


/// Create a copy of SessionAutoProvisionCredential
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SessionAutoProvisionCredentialCopyWith<SessionAutoProvisionCredential> get copyWith => _$SessionAutoProvisionCredentialCopyWithImpl<SessionAutoProvisionCredential>(this as SessionAutoProvisionCredential, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SessionAutoProvisionCredential;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SessionAutoProvisionCredential&&(identical(other.bundleId, _this.bundleId) || other.bundleId == _this.bundleId)&&(identical(other.type, _this.type) || other.type == _this.type)&&(identical(other.identifier, _this.identifier) || other.identifier == _this.identifier)&&(identical(other.configToken, _this.configToken) || other.configToken == _this.configToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SessionAutoProvisionCredential;
  return Object.hash(runtimeType,_this.bundleId,_this.type,_this.identifier,_this.configToken);
}

@override
String toString() {
  final _this = this as SessionAutoProvisionCredential;
  return 'SessionAutoProvisionCredential(bundleId: ${_this.bundleId}, type: ${_this.type}, identifier: ${_this.identifier}, configToken: ${_this.configToken})';
}


}

/// @nodoc
abstract mixin class $SessionAutoProvisionCredentialCopyWith<$Res>  {
  factory $SessionAutoProvisionCredentialCopyWith(SessionAutoProvisionCredential value, $Res Function(SessionAutoProvisionCredential) _then) = _$SessionAutoProvisionCredentialCopyWithImpl;
@useResult
$Res call({
 String? bundleId, AppType type, String identifier, String configToken
});




}
/// @nodoc
class _$SessionAutoProvisionCredentialCopyWithImpl<$Res>
    implements $SessionAutoProvisionCredentialCopyWith<$Res> {
  _$SessionAutoProvisionCredentialCopyWithImpl(this._self, this._then);

  final SessionAutoProvisionCredential _self;
  final $Res Function(SessionAutoProvisionCredential) _then;

/// Create a copy of SessionAutoProvisionCredential
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bundleId = freezed,Object? type = null,Object? identifier = null,Object? configToken = null,}) {
  return _then(SessionAutoProvisionCredential(
bundleId: freezed == bundleId ? _self.bundleId : bundleId // ignore: cast_nullable_to_non_nullable
as String?,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AppType,identifier: null == identifier ? _self.identifier : identifier // ignore: cast_nullable_to_non_nullable
as String,configToken: null == configToken ? _self.configToken : configToken // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SessionAutoProvisionCredential].
extension SessionAutoProvisionCredentialPatterns on SessionAutoProvisionCredential {
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
