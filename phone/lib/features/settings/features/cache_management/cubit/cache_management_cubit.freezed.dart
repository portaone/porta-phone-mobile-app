// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cache_management_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CacheSectionState {


/// Create a copy of CacheSectionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheSectionStateCopyWith<CacheSectionState> get copyWith => _$CacheSectionStateCopyWithImpl<CacheSectionState>(this as CacheSectionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CacheSectionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheSectionState&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.titleL10n, _this.titleL10n) || other.titleL10n == _this.titleL10n)&&(identical(other.descriptionL10n, _this.descriptionL10n) || other.descriptionL10n == _this.descriptionL10n)&&(identical(other.usage, _this.usage) || other.usage == _this.usage)&&(identical(other.measureFailed, _this.measureFailed) || other.measureFailed == _this.measureFailed)&&(identical(other.clearing, _this.clearing) || other.clearing == _this.clearing));
}


@override
int get hashCode {
  final _this = this as CacheSectionState;
  return Object.hash(runtimeType,_this.id,_this.titleL10n,_this.descriptionL10n,_this.usage,_this.measureFailed,_this.clearing);
}

@override
String toString() {
  final _this = this as CacheSectionState;
  return 'CacheSectionState(id: ${_this.id}, titleL10n: ${_this.titleL10n}, descriptionL10n: ${_this.descriptionL10n}, usage: ${_this.usage}, measureFailed: ${_this.measureFailed}, clearing: ${_this.clearing})';
}


}

/// @nodoc
abstract mixin class $CacheSectionStateCopyWith<$Res>  {
  factory $CacheSectionStateCopyWith(CacheSectionState value, $Res Function(CacheSectionState) _then) = _$CacheSectionStateCopyWithImpl;
@useResult
$Res call({
 String id, String titleL10n, String descriptionL10n, CacheUsage? usage, bool measureFailed, bool clearing
});




}
/// @nodoc
class _$CacheSectionStateCopyWithImpl<$Res>
    implements $CacheSectionStateCopyWith<$Res> {
  _$CacheSectionStateCopyWithImpl(this._self, this._then);

  final CacheSectionState _self;
  final $Res Function(CacheSectionState) _then;

/// Create a copy of CacheSectionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleL10n = null,Object? descriptionL10n = null,Object? usage = freezed,Object? measureFailed = null,Object? clearing = null,}) {
  return _then(CacheSectionState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titleL10n: null == titleL10n ? _self.titleL10n : titleL10n // ignore: cast_nullable_to_non_nullable
as String,descriptionL10n: null == descriptionL10n ? _self.descriptionL10n : descriptionL10n // ignore: cast_nullable_to_non_nullable
as String,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as CacheUsage?,measureFailed: null == measureFailed ? _self.measureFailed : measureFailed // ignore: cast_nullable_to_non_nullable
as bool,clearing: null == clearing ? _self.clearing : clearing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CacheSectionState].
extension CacheSectionStatePatterns on CacheSectionState {
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
mixin _$CacheManagementState {


/// Create a copy of CacheManagementState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CacheManagementStateCopyWith<CacheManagementState> get copyWith => _$CacheManagementStateCopyWithImpl<CacheManagementState>(this as CacheManagementState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CacheManagementState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CacheManagementState&&const DeepCollectionEquality().equals(other.sections, _this.sections));
}


@override
int get hashCode {
  final _this = this as CacheManagementState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.sections));
}

@override
String toString() {
  final _this = this as CacheManagementState;
  return 'CacheManagementState(sections: ${_this.sections})';
}


}

/// @nodoc
abstract mixin class $CacheManagementStateCopyWith<$Res>  {
  factory $CacheManagementStateCopyWith(CacheManagementState value, $Res Function(CacheManagementState) _then) = _$CacheManagementStateCopyWithImpl;
@useResult
$Res call({
 List<CacheSectionState> sections
});




}
/// @nodoc
class _$CacheManagementStateCopyWithImpl<$Res>
    implements $CacheManagementStateCopyWith<$Res> {
  _$CacheManagementStateCopyWithImpl(this._self, this._then);

  final CacheManagementState _self;
  final $Res Function(CacheManagementState) _then;

/// Create a copy of CacheManagementState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sections = null,}) {
  return _then(CacheManagementState(
sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<CacheSectionState>,
  ));
}

}


/// Adds pattern-matching-related methods to [CacheManagementState].
extension CacheManagementStatePatterns on CacheManagementState {
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
