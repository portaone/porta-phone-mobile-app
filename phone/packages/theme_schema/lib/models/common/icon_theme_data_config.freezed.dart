// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'icon_theme_data_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IconThemeDataConfig {


/// Create a copy of IconThemeDataConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IconThemeDataConfigCopyWith<IconThemeDataConfig> get copyWith => _$IconThemeDataConfigCopyWithImpl<IconThemeDataConfig>(this as IconThemeDataConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as IconThemeDataConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IconThemeDataConfig&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.fill, _this.fill) || other.fill == _this.fill)&&(identical(other.weight, _this.weight) || other.weight == _this.weight)&&(identical(other.grade, _this.grade) || other.grade == _this.grade)&&(identical(other.opticalSize, _this.opticalSize) || other.opticalSize == _this.opticalSize)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.opacity, _this.opacity) || other.opacity == _this.opacity)&&const DeepCollectionEquality().equals(other.shadows, _this.shadows)&&(identical(other.applyTextScaling, _this.applyTextScaling) || other.applyTextScaling == _this.applyTextScaling));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IconThemeDataConfig;
  return Object.hash(runtimeType,_this.size,_this.fill,_this.weight,_this.grade,_this.opticalSize,_this.color,_this.opacity,const DeepCollectionEquality().hash(_this.shadows),_this.applyTextScaling);
}

@override
String toString() {
  final _this = this as IconThemeDataConfig;
  return 'IconThemeDataConfig(size: ${_this.size}, fill: ${_this.fill}, weight: ${_this.weight}, grade: ${_this.grade}, opticalSize: ${_this.opticalSize}, color: ${_this.color}, opacity: ${_this.opacity}, shadows: ${_this.shadows}, applyTextScaling: ${_this.applyTextScaling})';
}


}

/// @nodoc
abstract mixin class $IconThemeDataConfigCopyWith<$Res>  {
  factory $IconThemeDataConfigCopyWith(IconThemeDataConfig value, $Res Function(IconThemeDataConfig) _then) = _$IconThemeDataConfigCopyWithImpl;
@useResult
$Res call({
 double? size, double? fill, double? weight, double? grade, double? opticalSize, String? color, double? opacity, List<ShadowConfig>? shadows, bool? applyTextScaling
});




}
/// @nodoc
class _$IconThemeDataConfigCopyWithImpl<$Res>
    implements $IconThemeDataConfigCopyWith<$Res> {
  _$IconThemeDataConfigCopyWithImpl(this._self, this._then);

  final IconThemeDataConfig _self;
  final $Res Function(IconThemeDataConfig) _then;

/// Create a copy of IconThemeDataConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? size = freezed,Object? fill = freezed,Object? weight = freezed,Object? grade = freezed,Object? opticalSize = freezed,Object? color = freezed,Object? opacity = freezed,Object? shadows = freezed,Object? applyTextScaling = freezed,}) {
  return _then(IconThemeDataConfig(
size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double?,fill: freezed == fill ? _self.fill : fill // ignore: cast_nullable_to_non_nullable
as double?,weight: freezed == weight ? _self.weight : weight // ignore: cast_nullable_to_non_nullable
as double?,grade: freezed == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as double?,opticalSize: freezed == opticalSize ? _self.opticalSize : opticalSize // ignore: cast_nullable_to_non_nullable
as double?,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,opacity: freezed == opacity ? _self.opacity : opacity // ignore: cast_nullable_to_non_nullable
as double?,shadows: freezed == shadows ? _self.shadows : shadows // ignore: cast_nullable_to_non_nullable
as List<ShadowConfig>?,applyTextScaling: freezed == applyTextScaling ? _self.applyTextScaling : applyTextScaling // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [IconThemeDataConfig].
extension IconThemeDataConfigPatterns on IconThemeDataConfig {
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
mixin _$ShadowConfig {


/// Create a copy of ShadowConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShadowConfigCopyWith<ShadowConfig> get copyWith => _$ShadowConfigCopyWithImpl<ShadowConfig>(this as ShadowConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ShadowConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShadowConfig&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.offset, _this.offset) || other.offset == _this.offset)&&(identical(other.blurRadius, _this.blurRadius) || other.blurRadius == _this.blurRadius));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ShadowConfig;
  return Object.hash(runtimeType,_this.color,_this.offset,_this.blurRadius);
}

@override
String toString() {
  final _this = this as ShadowConfig;
  return 'ShadowConfig(color: ${_this.color}, offset: ${_this.offset}, blurRadius: ${_this.blurRadius})';
}


}

/// @nodoc
abstract mixin class $ShadowConfigCopyWith<$Res>  {
  factory $ShadowConfigCopyWith(ShadowConfig value, $Res Function(ShadowConfig) _then) = _$ShadowConfigCopyWithImpl;
@useResult
$Res call({
 String? color, OffsetConfig? offset, double blurRadius
});




}
/// @nodoc
class _$ShadowConfigCopyWithImpl<$Res>
    implements $ShadowConfigCopyWith<$Res> {
  _$ShadowConfigCopyWithImpl(this._self, this._then);

  final ShadowConfig _self;
  final $Res Function(ShadowConfig) _then;

/// Create a copy of ShadowConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? color = freezed,Object? offset = freezed,Object? blurRadius = null,}) {
  return _then(ShadowConfig(
color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,offset: freezed == offset ? _self.offset : offset // ignore: cast_nullable_to_non_nullable
as OffsetConfig?,blurRadius: null == blurRadius ? _self.blurRadius : blurRadius // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ShadowConfig].
extension ShadowConfigPatterns on ShadowConfig {
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
mixin _$OffsetConfig {


/// Create a copy of OffsetConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OffsetConfigCopyWith<OffsetConfig> get copyWith => _$OffsetConfigCopyWithImpl<OffsetConfig>(this as OffsetConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OffsetConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OffsetConfig&&(identical(other.dx, _this.dx) || other.dx == _this.dx)&&(identical(other.dy, _this.dy) || other.dy == _this.dy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OffsetConfig;
  return Object.hash(runtimeType,_this.dx,_this.dy);
}

@override
String toString() {
  final _this = this as OffsetConfig;
  return 'OffsetConfig(dx: ${_this.dx}, dy: ${_this.dy})';
}


}

/// @nodoc
abstract mixin class $OffsetConfigCopyWith<$Res>  {
  factory $OffsetConfigCopyWith(OffsetConfig value, $Res Function(OffsetConfig) _then) = _$OffsetConfigCopyWithImpl;
@useResult
$Res call({
 double dx, double dy
});




}
/// @nodoc
class _$OffsetConfigCopyWithImpl<$Res>
    implements $OffsetConfigCopyWith<$Res> {
  _$OffsetConfigCopyWithImpl(this._self, this._then);

  final OffsetConfig _self;
  final $Res Function(OffsetConfig) _then;

/// Create a copy of OffsetConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dx = null,Object? dy = null,}) {
  return _then(OffsetConfig(
dx: null == dx ? _self.dx : dx // ignore: cast_nullable_to_non_nullable
as double,dy: null == dy ? _self.dy : dy // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [OffsetConfig].
extension OffsetConfigPatterns on OffsetConfig {
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
