// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'padding_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaddingConfig {


/// Create a copy of PaddingConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaddingConfigCopyWith<PaddingConfig> get copyWith => _$PaddingConfigCopyWithImpl<PaddingConfig>(this as PaddingConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PaddingConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaddingConfig&&(identical(other.left, _this.left) || other.left == _this.left)&&(identical(other.top, _this.top) || other.top == _this.top)&&(identical(other.right, _this.right) || other.right == _this.right)&&(identical(other.bottom, _this.bottom) || other.bottom == _this.bottom));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaddingConfig;
  return Object.hash(runtimeType,_this.left,_this.top,_this.right,_this.bottom);
}

@override
String toString() {
  final _this = this as PaddingConfig;
  return 'PaddingConfig(left: ${_this.left}, top: ${_this.top}, right: ${_this.right}, bottom: ${_this.bottom})';
}


}

/// @nodoc
abstract mixin class $PaddingConfigCopyWith<$Res>  {
  factory $PaddingConfigCopyWith(PaddingConfig value, $Res Function(PaddingConfig) _then) = _$PaddingConfigCopyWithImpl;
@useResult
$Res call({
 double left, double top, double right, double bottom
});




}
/// @nodoc
class _$PaddingConfigCopyWithImpl<$Res>
    implements $PaddingConfigCopyWith<$Res> {
  _$PaddingConfigCopyWithImpl(this._self, this._then);

  final PaddingConfig _self;
  final $Res Function(PaddingConfig) _then;

/// Create a copy of PaddingConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? left = null,Object? top = null,Object? right = null,Object? bottom = null,}) {
  return _then(PaddingConfig(
left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PaddingConfig].
extension PaddingConfigPatterns on PaddingConfig {
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
